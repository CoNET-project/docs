# L0 security limits and threat grades

**Evidence level: Implemented capability** for the current CoNET-SI forwarding plane; **design study** for listed upgrades that are not in SI `main`.

This page states what Layer Minus actually protects. It answers common over-claims: Fetch-and-Close is not an anonymity protocol; Chat SSE is a traffic fingerprint; long-term user OpenPGP keys do not provide forward secrecy; a valid EOA signature does not by itself stop replay; A/B/C role names are not independent operators.

L0 remains a [permissionless decentralized cloud](permissionless-cloud.md) whose live wire is a [PGP / wallet-address forwarding network](using-l0.md). **Any node may be malicious.** Stronger privacy modes are **application compositions** (privacy routing + fragmentation + client crypto) unless SI implements them.

Public source for the live plane: [CoNET-project/CoNET-SI](https://github.com/CoNET-project/CoNET-SI).

## Fetch-and-Close is a short-session mode

[Fetch-and-Close](http-mimicry.md) is optional:

```text
select an entry → send one bounded request → receive a bounded response → close
```

It can reduce:

- long-lived connection duration;
- a fixed long-session fingerprint;
- single-connection bidirectional volume statistics;
- long-term binding to one entry;
- a continuous network identity at one exit;
- the window during which one connection can be monitored.

It cannot remove:

- the set of entry IPs a client uses;
- request time;
- packet or ciphertext length;
- request frequency;
- periodic polling;
- a stable client or TLS fingerprint when HTTPS is used;
- correlation of adjacent requests;
- the bandwidth curve of a large download;
- global entry–exit matching by a well-placed observer.

The current book already treats Fetch-and-Close as optional. Chat and mining use long-lived SSE. UDP client and server listens are also SSE. Browsers may reuse HTTP/2 connections. Browser pooling, caching, and OS behavior can break a “new connection per resource” assumption. Those effects must be **measured**, not inferred from the design.

**Grade:** Fetch-and-Close lowers persistent-flow features. It is **not** a traffic-anonymity protocol. Size padding and timing jitter are **not implemented**.

## Outer envelope and nested PGP hops

Byte-level freeze: [X-CoNET-Hop-Sigs v1](hop-sigs.md). The header is a **compact miner signature** used to meter forwarded bytes. It is **not** a public `HopRecordV1` itinerary (`messageId`, inner/outer hashes, previous-hop hash, hopIndex). That extra JSON would let a path observer reconstruct the forward chain.

SI routing is not limited to “one key ID, never decrypt.” After a **local** decrypt **once**:

1. If the plaintext is still OpenPGP armor, read the inner `getEncryptionKeyIDs()`.
2. If that inner key ID **is** this node's route PGP, treat it as an attack: emit socket `end` and stop. Do not peel again on the same node.
3. If the inner key ID is **not** this node, read SI-to-SI `X-CoNET-Hop-Sigs`. More than **3** hop signatures (or a count that cannot take another hop) is an all-node flood: emit `end` and **do not** forward. The packet is **discarded**.
4. Otherwise **forward the inner armor** and append this node's miner hop signature. When the destination SI ends the socket, the previous hop closes and frees that connection.
5. If the plaintext is mailbox-work JSON `{ data, NoPush? }` (not a signed command), unwrap the inner armor and deliver it locally; `NoPush: true` skips APNs.
6. If the plaintext is signed JSON `{ message, signMessage }`, the last hop verifies hop signatures, meters those prior-hop bytes against the **user** wallet for **GB**, and runs the API command (listen, proxy, storage, WASM / container, and so on).

The client `POST /post` JSON is **only** `{ "data": "<OpenPGP armor>" }`. It **must not** carry `X-CoNET-Hop-Sigs` or sibling fields (`NoPush`, `beamioNoPush`, flags). Mailbox instructions belong inside B-decryptable work armor. If the outer key ID is not a routable node / mailbox, A responds **404**. A then miner-signs and forwards to B; B sees the header because A created it.

### Loop protection

A loop that never reaches a valid recipient inside **3** miner signatures is discarded. `A → D → A` or `A → D → E → D` cannot complete a useful delivery or invent GB. The protocol therefore does **not** publish a previous-hop hash chain.

Adjacent and header checks already stop the useful cases:

- inner key ID equals this node → `end`;
- this miner wallet already appears in the hop list → refuse append;
- hop count already 3 → `end`.

There is **one** budget: **3 miner signatures**. Do not add a second `maxPeels` / `maxForwardHops` pair.

An application can wrap a user-PGP business message to entry A, or use a short hop chain. A first-hop path observer then sees the **outer** key ID, not R's. Each peel node still learns the **next** key ID, time, and size. Extra hops are extra **GB**. This is not a mix network and does not replace padding.

Current Chat clients may still post a single user-PGP layer (A forwards without decrypting when the key maps to a mailbox). The peel rule is available to any client that wraps.

## Long-lived SSE is a primary L0 traffic fingerprint

CoNET Chat’s recipient opens a long-lived HTTP/SSE listen through entry **C**
(`command: "mining"`, `listenKind: "chat"`). Mining collectors, UDP listeners,
and exclusive application attachments (`l0_listen`) also keep SSE sessions.
After `l0_connect` attaches an opaque writer, SI returns **409** to a second
writer for the same live line. Chat and mining traffic on the same node must
continue. An idle application receive line needs comment keepalives until it is
attached; after attachment, SI must stop those comments. Application stream
negotiation remains encrypted business data and cannot occupy the line by
itself. See [Persistent application streams](duplex-forward.md).

An ISP or entry C can observe:

- a long-lived HTTP/SSE;
- disconnect and reconnect;
- liveness heartbeats;
- a downlink push pattern;
- active hours;
- traffic peaks;
- online / offline cadence.

Content remains OpenPGP-encrypted. Metadata can still support inferences about when a user is online, how often messages arrive, device sleep/wake, and that a chat-like application is in use.

### Receive modes

| Mode | Mechanism | Status |
| --- | --- | --- |
| **Realtime** | Long-lived SSE. The listen command inside route-PGP carries the user’s `Securitykey`; the node encrypts SSE downlink with that key. Intermediate entries that only forward armor do not receive it. | **Implemented** |
| **Entry rotation** | The user may close C and open another SSE through a different healthy entry at any time. That breaks a long-lived bind to one ingress. It does **not** remove the SSE shape on the new C. | **Implemented** (client choice) |
| **Privacy poll** | Randomized short polls, batch fetch, optional padding and dummy polls | **Not implemented** |

Do not set every client to the same fixed poll period if a poll mode is added later — that creates a new sync fingerprint. Current SI mailbox delivery is store-then-push over SSE.

## Long-term user OpenPGP is not forward-secret

Business messages are encrypted to the recipient’s **registered user OpenPGP public key**. OpenPGP typically creates a per-message symmetric session key and wraps that key to the long-term recipient public key.

If that long-term private key is later compromised, an attacker who stored earlier ciphertext may decrypt it. The live model therefore provides:

- confidentiality against nodes that lack the user private key;
- sender authentication when the outer EOA signature verifies;
- a per-message random session key **wrapped by the long-term key**.

It does **not** currently specify or implement:

- forward secrecy for stored Chat ciphertext;
- post-compromise security;
- Double Ratchet;
- automatic session-key rotation after first contact;
- MLS group messaging ([RFC 9420](https://www.rfc-editor.org/rfc/rfc9420.html)).

Encrypted Chat history (IPFS fragments + `ChatIndexRegistry`) is likewise keyed from long-term EOA/OpenPGP material. Compromise of that authority can expose recoverable history.

## Voice-message security boundary

The live `voice_message_v1` profile adds media confidentiality and integrity
without changing the L0 threat model:

- audio is encrypted locally with a fresh AES-256-GCM key and 12-byte nonce;
- the encoded ciphertext is uploaded as ordered 512 KiB chunks, with a
  256 MiB gateway object boundary;
- the fragment store sees a ciphertext hash and encrypted bytes, while the
  recipient user-PGP manifest reveals the key and nonce only to the recipient;
- the recipient verifies the Chat signature, fragment hash, and GCM tag before
  decoding; and
- decoded audio and browser object URLs are local ephemeral playback state.

This does **not** provide forward secrecy, sender-controlled deletion after
delivery, DRM, protection against a compromised recipient device, or proof
that a human listened. The fragment hash is content addressing, not replay
protection: clients must bind the voice object to `sendId` and any
application nonce/expiry, deduplicate before playback, and keep consumed
state where the product requires it. A valid old Chat envelope can otherwise
be replayed.

Voice privacy is configurable at the application layer. A product may disable
voice, restrict it to contacts or a recipient allowlist, cap duration and
size, choose local retention behavior, or add padding/delayed upload. None of
these options hides ciphertext size, timing, fragment arrival, mailbox
presence, or endpoint compromise from the current infrastructure roles.

## Real-time voice: relay presence is not the privacy property

The real-time voice MVP avoids a direct peer socket and WebRTC candidate
exchange. Audio frames are AES-256-GCM ciphertext and use temporary
`voice_listen` SSE sessions. This protects media plaintext and prevents the
two endpoints from learning one another's direct IP through the media
channel.

The initiator-hidden field boundary is now enforced for voice route commands.
`voice_listen` has no business-wallet `walletAddress`; wake-up metadata uses
only an opaque random `callId`, and voice frames target an opaque session ID.
The initiating application wallet remains inside the recipient-user-PGP offer.
An outgoing `voice_listen` may attach that offer as `offerArmor`. The
executing mailbox forwards the ciphertext to the callee mailbox and must not
decrypt it.

The implemented initiator-hidden profile provides:

- the initiating application wallet only inside a signed offer encrypted to
  the callee user PGP;
- an opaque `callId` that does not reuse the caller BeamioTag or EOA;
- no initiating application EOA in mailbox-visible commands, SSE frames,
  push metadata, or logs; and
- expiry, replay rejection, and scope binding for every routing/session
  capability.

Even after that upgrade, the mailbox knows the separate routing identity it
serves, entries still observe connecting IPs, and timing/size correlation
remains. The stronger claim is specifically that the **mailbox is not given
the initiating application wallet as a field**.

Comparisons with other messengers must use this field-level model. Saying that
Signal and CoNET both use relays is insufficient: call relays can hide peer IP
addresses while exposing different account identifiers to different service
roles. The review question is what each entry, mailbox, push service, and
media relay actually receives and logs.

### Chat crypto profile (roadmap)

Acknowledging the gap does not raise the live grade. Until a later profile ships, do not describe Chat as forward-secret.

| Profile | Cryptography | Status |
| --- | --- | --- |
| **V1** | Long-term recipient OpenPGP (per-message session key wrapped to that key) | **Live** |
| **V2** | AddressPGP / OpenPGP handshake → X25519 identity and prekey bundle → Double Ratchet session keys on later messages; L0 still carries the ratchet ciphertext | **Planned** |
| **V3** | MLS (or equivalent tree-based group key agreement) instead of one PGP encrypt per member | **Research** |

AddressPGP remains the wallet identity, offline discovery, mailbox route, initial handshake, and session-recovery root. On-demand new wallets reduce *future* correlation after a leak; they do not decrypt-protect already captured V1 armor.

## HTTP versus HTTPS (neither is “more private”)

The `/post` body is **only** OpenPGP ciphertext. Confidentiality of business content does **not** come from TLS. That does **not** mean “HTTP is more private than HTTPS.”

| | HTTP | HTTPS |
| --- | --- | --- |
| **Hides from an ISP** | No SNI, no JA3/JA4, no certificate fingerprint, no TLS handshake | `/post` body, JSON wrap, ASCII armor, outer key ID, content-length |
| **Shows to an ISP** | `POST /post`, JSON, armor, outer key ID, length; active drop / delay / replay / fake status | SNI / certificate / JA3/JA4; a fixed entry domain; TLS client fingerprint |
| **Channel** | No TLS authentication of the hop | Authenticated, integrity-protected channel |

### Carrier decision

| Environment | Recommended carrier |
| --- | --- |
| Ordinary Internet / browser page served over HTTPS | **HTTPS** + OpenPGP body (mixed content forbids `http://`) |
| SNI / certificate blocking | **HTTP** + OpenPGP body |
| High privacy, delay acceptable | HTTP or HTTPS + **outer envelope** (wrap to A) |
| Payments / POS / Treasury / AA control | **HTTPS preferred** + **application consumed-nonce** (not hop-sigs) |
| Research / diagnostics | Label the capture; **not** a privacy baseline |

Protocol rule: both HTTP and HTTPS are valid client carriers. SI-to-SI stays HTTP `:80`. Do not advertise plain HTTP as the default privacy mode for every environment.

## Plain HTTP allows active path attacks

OpenPGP and EOA signatures stop a path observer from **quietly rewriting plaintext**. They do not stop an HTTP observer from:

- dropping or delaying packets;
- replaying an old request;
- injecting a false HTTP status;
- returning a fake entry response;
- blocking a recipient key ID;
- classifying by key ID;
- forcing client retries;
- measuring whether a mailbox accepted a copy.

`checkSign` in CoNET-SI recovers the EOA from `personal_sign(message)` and checks it against `walletAddress`. That is authentication of **that exact string**, not a consumed-nonce store. `X-CoNET-Hop-Sigs` is also **not** an anti-replay store — it meters miner-forwarded bytes ([hop-sigs v1](hop-sigs.md)).

Partial anti-replay exists only on some **route-key commands**:

| Object | Current binding | Replay store |
| --- | --- | --- |
| Generic `/post` business armor | OpenPGP integrity + client-defined inner fields | Mailbox `saveLocal` **appends**; identical armor can be stored again |
| `wallet_online_query` / `gossip_delivery_ack` | EIP-191 + `timestamp` within ±600 s | No durable nonce set |
| UDP listen / relay / uplink | EIP-191 + `timestamp` within ±600 s; payload size cap | No replay window beyond the skew |
| Duplex listen / relay / unlisten | EIP-191 + `timestamp` within ±600 s; payload cap 24000 b64 | No replay window beyond the skew |
| Chat `sendId` | Application field; clients may drop duplicates | Not an SI mailbox invariant |

A correct EOA signature therefore does **not** automatically reject a previously valid message. Replaying the same valid armor to entry 1, 2, and 3 can duplicate mailbox store, push, APNs, or application handling unless the **application** consumes an id.

### Required application bindings (normative for payments / POS / control)

Do **not** put a full `L0SignedObjectV1` on the hop header. That would publish `messageId` / `payloadHash` to every SI hop.

Non-idempotent application objects (payments, POS authorization, AA / Treasury control, spend) must bind at least `messageId`, `nonce`, `timestamp` / `expiry`, `senderWallet`, `recipientWallet`, `commandType`, `payloadHash` **inside** the encrypted application object, and persist **consumed** identifiers at the consumer:

| Location | Store |
| --- | --- |
| Recipient / Chat client | `sendId` / application `messageId` |
| POS / payment / AA / Treasury | Durable consumed nonce — **not** a 600-second window alone |
| UDP | Sliding sequence window (upgrade; not live) |
| GB accounting | Verified hop rows (`w,t,n,h,k,s`) on the last command hop |

Do not treat TLS, HTTP 2xx, `checkSign`, or hop-sigs alone as that store.

### TLS 1.3 0-RTT (not used by the HTTP-first path)

If a future Fetch-and-Close client uses TLS 1.3 0-RTT for performance, 0-RTT has **no inherent anti-replay** ([RFC 8446](https://www.rfc-editor.org/rfc/rfc8446.html)). Non-idempotent operations must still consume application nonces.

## Mailbox isolation fails under collusion

A/B/C separation prevents an ordinary mailbox from seeing the client’s direct IP. It is a **role** split, not a proof that A, B, and C are independent operators.

| Collusion | Combined view |
| --- | --- |
| **A + B** | A has sender IP, recipient key ID, mailbox identity, time, and size. B has the route, stored armor, and arrival time. Together they reconstruct a send relationship. |
| **C + B** | C has the recipient IP. B has the recipient wallet, presence, listen session, and message-arrival times. Together they bind wallet to network location. |
| **Same operator for A, B, and C** | Distinct chain addresses or Guardian IDs do not create independent trust domains. |

L1 has no public operator-domain census equivalent to the DLE `OperatorDomainRegistryV1` specification. Clients today pick healthy entries; SI does not enforce “this operator must not be both entry and mailbox on one path.”

### Proposed operator hygiene (not implemented on L0)

- Same operator domain must not be both entry and mailbox on one path.
- Clients check an operator-domain signal before selecting A/C.
- Diversify by ASN, cloud, and region.
- Rotate mailboxes.
- Publish independence metrics.
- Challenge and slash correlated multi-wallet operators.
- Remember recent path triples locally and avoid immediate reuse.

Until those exist, treat A/B/C as **correct use of roles**, not as multi-operator anonymity.

## UDP forward: cryptography vs native UDP

The cryptographic split is sound and implemented:

- session AES key is encrypted only to the UDP server **user PGP**;
- mailbox B must not receive that key;
- route commands must not carry `Securitykey`;
- frames are AES-256-GCM;
- client and server should reach B through different entries;
- UDP pools are separate from chat/mining.

UDP forward is **not** native UDP. It is HTTP request plus SSE. It does not automatically provide UDP timing, congestion control, retransmission, delivery ACK, application-consumption proof, packet ordering, or low-jitter realtime performance.

Mailbox B still sees `sessionId`, client and server wallets, frame timing and size, direction, and session duration. That metadata can classify VoIP-like, game-like, or sensor-like use even when payloads stay encrypted.

Implemented bounds: 12,000-character payload, ±600 s timestamp, session-count caps, 10-minute idle sweep, downlink `seq` for SSE writes.

### Proposed UDP hardening (not implemented)

Sequence numbers with a replay window, padding buckets, optional constant-rate mode, application ACKs, rekey, and tighter per-session byte limits. Document these as upgrades, not as the live relay.

## Wallet identity is a correlation paradox

A wallet solves problems IP cannot: cryptographic ownership, mobility without renaming the peer, and accounts that are not issued by a platform.

A **long-lived** wallet used for Chat, POS, Beamio, mining, L1 transfers, DLE, BT, Treasury, and public social identity becomes a stable join key. Observers can build `wallet → chat activity → payments → services → social graph`.

A wallet is more autonomous than an IP. It is **not** automatically harder to correlate than an IP.

### Layered identities (application, not L0)

L0 will forward whatever key ID it is given. Isolation is an **application registration** policy.

**Available now:** use a **routing wallet** for AddressPGP, listen, ACK, presence, and hop GB, and keep **sender / recipient** EOAs only inside the encrypted envelope. Mailbox B does not need the payment or display wallet. How to wire it: [wallet-addressed peer identity](wallet-address-p2p.md#routing-wallet-versus-sender--recipient-wallets).

```text
Master wallet
  ├── Routing wallet     ← mailbox + listen + GB (what B sees)
  ├── Chat / display
  ├── POS
  ├── BT session
  ├── DLE payment
  └── Temporary network
```

This does **not** hide an on-chain gas or token transfer from master → routing wallet. Putting both addresses in one plaintext command or hop header undoes the split. Delegation proofs, stealth addresses, or ZK membership are **not** L0 features.

## Current L0 threat grades

Grades describe the **current SI + intended A/B/C client path**, not a future ratchet, poll mode, or operator registry.

| Attack or observer goal | Current protection | Note |
| --- | --- | --- |
| Intermediate node reads business plaintext | **Strong** | User-PGP armor is not decrypted on forward |
| Mailbox reads business plaintext | **Strong** | B stores and pushes armor; decrypts only route-key commands |
| Recipient learns sender IP | **Moderately strong** | Intended path posts through A; inner envelope may still name the sender wallet |
| Mailbox learns client IP | **Moderately strong** on a correct A/B/C path | Direct-to-B use collapses this |
| ISP reads business plaintext | **Strong** | OpenPGP body |
| ISP classifies an HTTPS entry | **Weak to moderate** | SNI / JA3 / certificate |
| ISP classifies HTTP `POST /post` | **Weak** | Path, JSON, ASCII armor; key ID is the **outer** layer (R's key unless the client wrapped) |
| Entry learns recipient wallet / route | **Weak** on a one-layer post; **reduced for the first-hop observer** with an outer wrap | After a local peel, A still sees the next key ID |
| Long-term wallet graph | **Moderate to weak** | Public chain + reused EOA |
| Single malicious relay | **Moderately strong** | Cannot read user-PGP content; can drop, delay, or classify |
| Real-time voice media relay reads audio | **Strong** | AES-GCM frame key stays in recipient-user-PGP offer |
| Voice mailbox learns initiating application wallet | **Strong** | Voice route commands and wake-up metadata use opaque session/call identifiers |
| Entry + mailbox collusion | **Weak** | Role split ≠ operator split |
| Global timing correlation | **Weak** | No padding or mix |
| Endpoint compromise | **Weak** | Device or long-term key exposure |
| Historical-message forward secrecy | **Insufficient** | Long-term user PGP wrap |
| Sybil / correlated relays | **Economic and operational** | Guardian stake and ops; no L0 operator-domain enforcement |

## What applications must not claim

- Fetch-and-Close as mix-net or anonymity.
- Chat SSE as metadata-private presence.
- OpenPGP-to-AddressPGP as Double Ratchet / MLS (that is Chat crypto **V2/V3**, not live V1).
- `checkSign` or `X-CoNET-Hop-Sigs` as anti-replay for payments or POS.
- A detailed hop JSON (`HopRecordV1`) as required for loop safety — the cap is **3 miner signatures**, then discard.
- HTTP as “more private than HTTPS.”
- A/B/C as independent-operator anonymity.
- UDP forward as native realtime UDP.
- One wallet as an unlinkable identity across products.

## Implementation anchors

- Entry HTTP/HTTPS and `{ data }` POST: [CoNET-SI `server.ts`](https://github.com/CoNET-project/CoNET-SI/blob/main/src/endpoint/server.ts)
- Key-ID forward and `checkSign`: [CoNET-SI `localNodeCommand.ts`](https://github.com/CoNET-project/CoNET-SI/blob/main/src/util/localNodeCommand.ts)
- Mailbox append store: `saveLocal` in [CoNET-SI `util.ts`](https://github.com/CoNET-project/CoNET-SI/blob/main/src/util/util.ts)
- UDP bounds: [CoNET-SI `udpForward.ts`](https://github.com/CoNET-project/CoNET-SI/blob/main/src/util/udpForward.ts)
- Chat listen composition: [CoNET Chat](../applications/depin-chat.md)

## Next

- [How to use Layer Minus](using-l0.md) — compose only the primitives that exist.
- [X-CoNET-Hop-Sigs v1](hop-sigs.md) — compact miner hop encoding and failure codes.
- [HTTP transport and Fetch-and-Close](http-mimicry.md) — short-session carrier.
- [Zero-trust mailbox routing](mailbox-routing.md) — A/B/C roles.
- [Wallet-addressed peer identity](wallet-address-p2p.md) — key roles and reuse risk.
- [UDP frame forwarding](udp-forward.md) — AES split and remaining metadata.
- [Persistent application streams](duplex-forward.md) — endpoint stream keys
  never enter a B-decryptable control; missing authenticated accept fails the
  stream.
