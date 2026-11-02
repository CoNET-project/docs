# HTTP transport and Fetch-and-Close

## What it is

Layer Minus carries **already-encrypted OpenPGP armor** inside ordinary HTTP `POST /post` request/response shapes. The JSON body is **only** `{ "data": "<OpenPGP armor>" }`. Do not add sibling fields. Confidentiality of the business payload comes from OpenPGP, not from TLS. Therefore **HTTPS is optional** for delivery: a client may post the same ciphertext over **plain HTTP**.

The intended split is:

| Hop | Default carrier | Why |
| --- | --- | --- |
| Client → entry A/C | **HTTP or HTTPS** | The body is user-PGP or route-PGP ciphertext. HTTP is sufficient for confidentiality. HTTPS is a local-channel option, not a protocol requirement. |
| Entry → mailbox / next SI | **HTTP on port 80** | Nodes never decrypt **user-PGP business** armor. They read the OpenPGP **key ID**. Non-local → forward the same armor. Local decrypt + inner PGP for another key → forward the inner armor. |
| Mailbox listen | HTTP/SSE | Long-lived receive stream; still ciphertext until the recipient decrypts |

Browser pages that are themselves served over HTTPS may still be forced to use HTTPS to an entry because of mixed-content rules. Native, CLI, and censorship-sensitive clients are expected to use **HTTP** when TLS metadata would be the more dangerous signal.

This is an **HTTP-shaped carrier**, not a claim that every Layer Minus flow is indistinguishable from arbitrary web browsing.

## Why it matters

A bespoke binary handshake gives a network monitor a custom protocol classifier. Reusing HTTP lets browser, mobile, and server clients share one entry surface.

More important: because the `/post` body is already OpenPGP ciphertext, the protocol **does not need a TLS session to keep business content secret**. In a region that inspects or blocks TLS by SNI, JA3/JA4, or certificate, a client can deliver the same encrypted object over HTTP and avoid that handshake entirely.

It also keeps transport concerns separate:

| Layer | Responsibility |
| --- | --- |
| OpenPGP and EOA signatures | Recipient confidentiality and sender authentication |
| OpenPGP packet key ID | **Intentional routing side channel.** A node reads `getEncryptionKeyIDs()`. If it can decrypt and the plaintext is still PGP for another key, it forwards the inner armor. |
| HTTP (client → entry) | Delivery of ciphertext. Preferred where TLS fingerprints or SNI would be blocked or classified. |
| HTTPS (optional) | Extra protection of the HTTP headers and armor bytes against a local observer; not required for payload secrecy |
| HTTP :80 forwarding | Entry-to-mailbox or entry-to-exit relay of the same ciphertext |
| SSE | Long-lived mailbox and mining delivery where a receive stream is required |
| GB metering | Forwarding nodes count relayed bytes and are compensated in **GBToken (`GB`)** for successful relay, not for decrypting content |

An HTTPS error on one entry says nothing by itself about HTTP forwarding between SI nodes, and it is not evidence that clients must use TLS.

## Fetch-and-Close

Fetch-and-Close is an optional short-session mode:

```text
select an entry → send one bounded request → receive a bounded response → close
```

It can reduce long-connection duration, a fixed long-session fingerprint,
single-connection bidirectional volume, long-term entry binding, a continuous
exit identity, and the window for monitoring one socket.

It cannot remove the entry-IP set, request time, packet or ciphertext length, frequency, periodic polling, a stable client fingerprint, adjacent-request correlation, a large-download bandwidth curve, or global entry–exit matching.

Short independent requests may also let an application rotate entries or exits between supported connections. Resource-level granularity depends on browser pooling, HTTP/2 multiplexing, caching, operating-system behavior, and the specific client; it must be **measured** rather than assumed.

Fetch-and-Close is **not** the universal Layer Minus transport and is **not** a traffic-anonymity protocol. Chat and mining use long-lived SSE because the mailbox must push new frames. UDP client and server listens are also SSE. Individual UDP uplink and downlink control requests remain bounded.

### Trade-offs

- New connections add TCP setup cost, and TLS setup cost **only when the client chose HTTPS**.
- Repeated requests still expose destination, timing, size, frequency, and entry-selection patterns.
- HTTP `/post` makes the path and OpenPGP armor shape visible to a path observer; that is the cost of avoiding a TLS fingerprint.
- Aggressive rotation can reduce connection reuse and reliability.
- Application ordering, retries, and deduplication must be handled above the carrier.
- TLS 1.3 0-RTT, if used later for short HTTPS sessions, has no inherent anti-replay ([RFC 8446](https://www.rfc-editor.org/rfc/rfc8446.html)); non-idempotent work still needs application nonces.

Size padding and timing jitter are **not implemented** in the current SI protocol. Do not describe them as present mitigations. The full reduce / cannot table and threat grades are in [security limits](security-limits.md).

## HTTP in high-censorship networks

When a client posts OpenPGP armor over HTTP:

- a path observer can see `POST /post`, JSON wrapping, and ASCII armor;
- the same observer **cannot** read the business envelope;
- there is **no TLS ClientHello**, so there is no SNI and no client JA3/JA4 for that hop;
- the first hop shows the **outer** key ID. With a one-layer post that is R's key. With an outer envelope it is A's key; after A peels, A forwards the inner armor and learns the next key ID.

This is a deliberate trade: hide TLS metadata, accept an HTTP application-shape classifier. It is not a claim that `/post` is invisible. Destination IP or Host blocking can still occur. The protocol answer to payload secrecy remains OpenPGP, not camouflage.

## Guarantees and non-guarantees

The current implementation accepts client `/post` over HTTP or HTTPS and forwards SI-to-SI over HTTP port 80. Nodes route by the OpenPGP encryption key ID. They decrypt only **one** layer addressed to this node; if that plaintext is still PGP for another key and `X-CoNET-Hop-Sigs` is within the cap of **3**, they forward the inner armor. Same-node inner PGP, or more than three hop signatures, ends the socket. They do not decrypt user-PGP business content. The last hop meters verified prior-hop bytes against the user wallet for **GB**.

It does not guarantee that HTTP `/post` evades every classifier, hide the client from its entry, or provide anonymity against an observer that can correlate both sides of the route. A network can still block known hosts or addresses. HTTPS, when used, still exposes TLS metadata.

HTTP status is also not application delivery evidence:

- entry 2xx means the entry accepted a request;
- an SSE handshake means a listen route was attached; and
- recipient acknowledgement or an application receipt is required for stronger delivery semantics.

## Implementation anchors

- Native HTTP entry and optional HTTPS listener: `src/CoNET-SI/src/endpoint/server.ts`
- Recipient key-ID routing, HTTP :80 `socketForward`, and `BandwidthCount`: `src/CoNET-SI/src/util/localNodeCommand.ts`
- Chat SSE worker: `src/SilentPassUI/vendor/conet-chat-sdk/src/worker/gossip-core.ts`; native daemons in chat-sdk-ios / chat-sdk-android
- Product-level per-connection routing context: [SilentPass](../applications/silentpass-vpn.md)
- Planned piece-oriented use, explicitly under development: [BT download / DePIN DCDN](../applications/bt-dcdn.md)

## Next

[The IP-address privacy problem](tcp-ip-privacy.md) defines what HTTP shaping cannot hide. [Security limits](security-limits.md) grades Fetch-and-Close, SSE fingerprints, and replay. [Node and client roles](node-roles.md) shows which runtime terminates each hop.
