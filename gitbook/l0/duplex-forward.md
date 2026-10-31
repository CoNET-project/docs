# Persistent application streams

> **Removed from CoNET-SI (2026-10-31).** The exclusive L0 attachment primitives this page relies on (`l0_listen`, `l0_connect`, `mining` with `listenKind: "l0"`, and idle-L0 delivery of mailbox work) are no longer implemented by SI; `l0_listen` / `l0_connect` close the connection. The rest of this page is kept as a historical reference and does not describe current network behavior.

**Evidence level: Implemented capability.** Layer Minus provides the encrypted
forwarding and exclusive attachment primitives used by persistent application
streams. [`web3://`](web3-application-protocol.md) defines the portable
application contract. Linux implements that contract with
[`conet-l0d`](../developers/conet-l0d.md).

This page explains the boundary between those layers. It does not define a new
SI command family.

## Layer boundary

| Layer | Responsibility |
|---|---|
| **Layer Minus / SI** | Route encrypted control data and attach one opaque writer to one waiting receive line |
| **`web3://` application protocol** | Exact target and logical-port selection, authenticated offer/accept, frame ordering, close, and errors |
| **Runtime** | Map a local socket to one application session and enforce queue, timeout, and reconnect bounds |
| **Origin service** | Read and write its native TCP byte protocol without knowing the L0 route |

The implemented SI attachment primitives are `l0_listen` and `l0_connect`.
An application may also use the compatibility form `command: "mining"` with
`listenKind: "l0"`. These are L0 transport controls, not browser-facing
`web3://` methods.

SI does **not** implement `duplex_offer`, `duplex_accept`, `duplex_reject`, or
application frame objects. Those objects remain encrypted application data.
Do not add `p2p_stream_*`, `listenKind: "duplex"`, or
`listenKind: "l1p2p"` as SI commands.

## Stream lifecycle

```text
local client socket
  → parse exact web3:// target and logical port
  → create a fresh application session
  → sign and encrypt an offer to the target user PGP
  → submit through entry A
  → target host validates the offer and configured port
  → target opens its configured local origin
  → both endpoints attach opaque L0 lines through entries C/D
  → authenticated accept
  → ordered encrypted bytes in both directions
  → explicit close, timeout, or bounded reconnect
```

Each accepted local socket is a separate session. A runtime must not reuse
identity, queue, upstream-socket, close state, or attachment handles merely
because two sockets use the same wallet and port.

An incoming offer is **attach-only**. The host must first match:

- the exact destination wallet or exact tag result;
- a configured logical port;
- an expected, fresh session; and
- local origin policy.

An unmatched, replayed, stale, or ambiguous offer must not allocate a line or
open an arbitrary local socket.

When the same process is also a client of another wallet's identical
logical port, inbound and outbound lines stay separate. Only an offer
addressed to **this** host's billing wallet plus that port may open the
`--proxyDuplex` origin. An outbound `web3://<other>:8400` session keeps
the same port number as remote metadata and must not drain the local
origin. See [URI grammar](web3-application-protocol.md#2-uri-grammar).

## Why two attached lines

An SSE receive line is server-to-listener. Full duplex therefore uses two
independently attached directions:

```text
endpoint A receive line  ←  endpoint B writer
endpoint B receive line  ←  endpoint A writer
```

Each endpoint owns its receive identity. A client must not create a receive
line under another application's wallet or attach directly to mailbox B.
Control and receive traffic follow the same entry-to-mailbox routing boundary
as other conforming L0 applications. POST entry A/C is always a random
qualified SI (`A ≠ B`, `C ≠ B`). Production picks mailbox B at random from
the SI pool. `conet-l0d start --debugSI [SI]` pins mailbox B only.

## Duplex handshake (temporary SSE)

One local TCP is one incarnation. SI never parses `duplex_*` JSON.

```text
1. Initiator: `l0_listen` (command) on mailbox B. The signed command contains
   only `userPgpKeyId` and `timestamp`; it does **not** contain the temporary
   EOA. SI recovers the signer only for local capability bookkeeping. POST via
   random entry C ≠ B. SI returns a fresh random `listenId` capability.
2. duplex_offer: encrypt to the destination's **registered** user PGP;
   mailbox-work wrap to that destination's **registered** mailbox.
   JSON announces the initiator temp line (listenWallet, listenUserPgp,
   listenRoutePgp, listenMailboxWallet).
3. Responder: own temp l0_listen, then duplex_accept encrypted to initiator
   listenUserPgp, mailbox-work wrap to initiator listenRoutePgp.
   POST via random entry A ≠ initiator B.
4. Mailbox B of the initiator: unwrap work → match idle `l0_listen` by inner
   user PGP (not `getRoute`) → SSE gossip. Initiator decrypts, writes
   responseChunk, then `l0_connect` to the responder using its opaque
   `targetListenId`.
5. Only after the initiator occupies the responder listen may the responder
   reverse-occupy the initiator mailbox. Occupying the initiator SSE first
   turns it into a pipe and **drops** the Chat accept.
```

A `--proxy` / `proxy_duplex` hub does not retry a failed temporary line. It
posts one `duplex_reject` (`retryable=true`) to the initiator request listen
(same wrap as accept). The client L0d closes that TCP; the application must
open a new connection (new temporary wallet and offer). Do not occupy the
initiator SSE only to deliver reject.

`l0_connect` is a signed command to the **peer's** mailbox route PGP. Its
only target selector is the one-time opaque `targetListenId` returned by the
peer's `l0_listen` SSE handshake; `targetWallet` is not a wire fallback.
The command does not carry the temporary connector EOA. SI recovers the
signer internally after signature verification. It must not share a race with
mailbox-work `duplex_accept` on the same idle SSE.

## SI attachment behavior

| Event | Required behavior |
|---|---|
| Idle receive line | Keep the SSE usable without application data |
| First valid `l0_connect` | Attach the writer and keep the HTTP connection open |
| Successful attachment | Return HTTP `200` transport readiness; continue carrying opaque bytes |
| Second writer for the same live line | Return `409 Conflict` |
| Receive line disappeared before attachment | Return a non-success transport result such as `410 Gone` |
| Attached line closes or becomes stale | Release only that line and its local resources |
| Replacement after the old line is dead | Accept a fresh line instead of preserving a zombie occupancy |

Chat, mining, presence, acknowledgements, and UDP use separate pools. Occupying
an application stream must not return `409` for unrelated Chat or mining
traffic.

Once attached, SI treats application bytes as opaque. It must not:

- decrypt the endpoint-to-endpoint stream key;
- parse the origin application's byte protocol;

The `l0_listen` handshake exposes only the random `listenId`. It must not
return the temporary EOA, mailbox `nodeWallet`, connector address, or PGP key
ID. `listenId` is CSPRNG-generated, single-use, scoped to the live SSE, and
must not be derived from an EOA, timestamp, route key, or PGP key ID.
- save active stream frames as offline Chat messages;
- send Chat push notifications for stream frames; or
- move a failed stream onto another application transport and report success.

## Identity and encryption

| Material | Visible to | Purpose |
|---|---|---|
| Long-lived target EOA | Client and host | Stable application identity |
| Target user PGP | Client and host | Encrypt the application offer |
| Mailbox route PGP | L0 routing controls | Reach the target mailbox |
| Temporary session identity | The two endpoints and required route registration | Isolate one stream incarnation |
| End-to-end stream key | The two endpoints only | Protect accept, reject, control, and data frames |
| Hop-local attachment handle | One local attachment path | Release the correct line without cross-hop correlation |

The end-to-end stream key must never appear in a command encrypted to mailbox
B's route key. Business negotiation is encrypted to the target **user PGP**;
mailbox controls are encrypted to the **route PGP**.

Fresh session identities and random opaque attachment handles prevent one
socket incarnation from being confused with another. Do not derive a handle
from public wallets, ports, IP addresses, or route keys.

## Socket bootstrap

For `--clientDuplex`, the accepted local TCP socket is the session boundary.
The client may include the first local bytes in the authenticated offer. A
`--proxyDuplex` host opens only the upstream configured for that logical port,
forwards the initial bytes, and may return the first upstream bytes with the
accept.

Only after authentication and acceptance may either paused application socket
resume. This ordering prevents:

- bytes reaching the wrong session;
- an unmatched offer opening an origin socket;
- a response racing ahead of accept; and
- pre-accept data being attached to a dead line.

## Readiness and failure semantics

The following signals are not interchangeable:

| Signal | Meaning |
|---|---|
| Entry HTTP `2xx` for an encrypted offer | An entry accepted transport work |
| Receive SSE handshake | A receive path exists |
| `l0_connect` HTTP `200` | One opaque writer is attached |
| Authenticated application accept | The remote runtime accepted this exact session |
| Origin response bytes | The configured local service processed stream data |

A runtime must report the stream ready only after the authenticated application
accept. An HTTP `404`, `409`, timeout, EOF, or missing accept is a failed stream,
not an empty successful response.

Reconnect must be bounded and generation-aware:

1. clear the dead writer and old attachment state;
2. create a fresh session incarnation where required;
3. wait for a valid replacement receive line;
4. retry with bounded backoff; and
5. stop when policy, expiry, or retry limits are reached.

Old bytes and handles must never be written into the replacement session.

## Backpressure and limits

Every implementation must bound:

- concurrent sessions per wallet and per logical port;
- queued bytes and frame count per direction;
- initial-offer and response-chunk size;
- idle and total handshake time;
- reconnect attempts and retry age; and
- local-origin connect and read timeouts.

`socket.write() === false` or its runtime equivalent means backpressure, not
successful delivery and not necessarily a closed socket. Pause reads, retain
only a bounded queue, resume on drain, and close on overflow or drain timeout.

A receive-only SSE can remain healthy after its request body has ended.
`readableEnded` alone is therefore not proof that the line is stale. Use
write failure, close/error events, and bounded liveness policy.

## Real-time voice and video frames

Voice and video media frames are application ciphertext carried over the
opaque attached lines. The relay does not reorder, decrypt, or persist them.
Each participant maintains an independent reorder buffer keyed by
`sessionId + direction`; a timestamp is metadata only and never replaces the
sequence number.

Send path: each media `voice_uplink` / video chunk posts to **one** entry
(`fanout: 1`). Parallel multi-entry fanout of the same `seq` is forbidden;
text gossip may still fan out.

The receiver must:

- deliver contiguous `seq` values in order;
- discard an exact duplicate `(seq, payload, frame metadata)`;
- reject a pending frame that reuses `seq` with different payload or metadata
  and emit `voice_conflict_v1`;
- when a later `seq` is buffered while `nextSeq` is still missing, **immediately**
  emit `voice_gap_v1` with reason `skip_ahead` and continue with the later
  frame (do not wait out a full reorder timeout before skipping); a short
  timer may apply only to incomplete video-chunk groups at `nextSeq`;
- keep late frames behind the delivery cursor from being delivered again;
- reassemble video chunks only when `frameId`, `chunkIndex`, and `chunkCount`
  form a complete, valid set.

Implementations must cap payload size, pending frame count, pending chunk
count, and reassembly memory. Invalid sequence numbers and chunk metadata are
discarded. These rules provide bounded live playback, not infinite
retransmission or recovery of lost media.

The end-to-end AES-GCM associated data binds the session, direction, sequence,
timestamp, and (for video) frame/chunk metadata. A frame must be authenticated
before it enters the reorder buffer. The Worker performs ordering, duplicate
suppression, conflict/gap event emission, and chunk reassembly; UI code
consumes only the resulting ordered events.

The same rules apply to `voice_uplink` and `voice_downlink`. Do not use a
continuous OpenPGP stream for media frames: one lost packet must not make the
remaining real-time frames undecryptable.

## Platform implementations

| Platform | Persistent-stream implementation |
|---|---|
| Linux server | `conet-l0d --proxyDuplex <host:port>` |
| Linux client | `conet-l0d --clientDuplex web3://<wallet-or-exact-tag>:<port>` |
| Windows / macOS | Browser extension, browser client, or native runtime implementing the same `web3://` contract |
| Android / iOS | Web or native client implementing the same contract |
| Browser | Client-side target resolution, signing, encryption, response verification, and stream adaptation |

The application protocol is portable. `conet-l0d` is the Linux runtime, not a
requirement for every client platform.

## Security boundary

When endpoint keys remain secure and routing follows the entry/mailbox model:

- intermediary nodes carry ciphertext rather than origin plaintext;
- mailbox B does not receive the endpoint stream key;
- the local origin accepts connections only from its trusted host adapter; and
- application identity remains the verified wallet rather than a public
  origin address.

This does not hide a client IP from its selected entry, defeat a global timing
observer, provide padding, or make a compromised endpoint safe. See
[Security limits and threat grades](security-limits.md).

## Implementation anchors

- Linux application runtime:
  `src/conet-l0d/src/l0/{duplex,client,pipe,listen}.rs`
- SI exclusive attachment pool:
  `src/CoNET-SI/src/util/l0Exclusive.ts`
- Portable application contract:
  [`web3://` Application Protocol](web3-application-protocol.md)
- Linux operator guide:
  [Developers — `conet-l0d`](../developers/conet-l0d.md)
- Laboratory geth / Prysm overlay:
  [L1 overlay lab](../developers/conet-l0d-l1-overlay-lab.md)

## Related

- [`web3://` Application Protocol](web3-application-protocol.md)
- [How to use Layer Minus](using-l0.md)
- [Zero-trust mailbox routing](mailbox-routing.md)
- [SI developer guide](si-developer-guide.md)
- [UDP frame forwarding](udp-forward.md)
- [Security limits and threat grades](security-limits.md)
