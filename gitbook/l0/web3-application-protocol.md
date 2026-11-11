# `web3://` Application Protocol contract

**Status: Draft with implemented v1 components.**

> **Not usable on the current network.** The official `web3://` gateway still receives through the legacy listen pool, which CoNET-SI nodes stopped serving on 2 November 2026, so `web3://` browsing through it does not work today. A fix is not scheduled. Persistent application streams also depend on L0 primitives that were removed from CoNET-SI on 31 October 2026.

This page defines `web3://` as an **application protocol over CoNET Layer
Minus (L0)**. It defines application naming, identity, caller-signed
requests, encrypted response correlation, and persistent stream behavior. It
does not add an SI command or change the L0 `/post` envelope.

Product and platform overview: [`web3://`](../applications/web3-url.md)  
Linux implementation: [Developers — `conet-l0d`](../developers/conet-l0d.md)

## 1. Layer boundary

| Layer | Responsibility |
|---|---|
| Layer Minus | Encrypted entry routing, mailbox selection, forwarding, and receive sessions |
| `web3://` | Destination URI, request/stream contract, response correlation, and application errors |
| Client | Resolve, sign, encrypt, submit, receive, decrypt, verify, and render |
| Host adapter | Validate the application envelope and access a configured local origin |

The L0 HTTP contract remains:

```http
POST /post HTTP/1.1
Content-Type: application/json

{"data":"<OpenPGP armored message>"}
```

Application fields must remain inside the encrypted object. Clients must not
add plaintext routing or product fields beside `data`.

## 2. URI grammar

The application forms are:

```text
Resource: web3://0x<40-hex>/<path>
Resource: web3://<exact-tag>.web3/<path>
Stream:   web3://0x<40-hex>:<logical-port>
Stream:   web3://<exact-tag>.web3:<logical-port>
```

A resource request may include a path and query:

```text
web3://0x1111111111111111111111111111111111111111/dashboard?range=7d
web3://ExampleMerchant.web3/api/orders?id=42
```

Rules:

1. An EOA host is normalized to lowercase `0x` + 40-hex form.
2. A tag must resolve by exact name, with address context used to disambiguate
   case-insensitive collisions.
3. A prefix search result must never be selected implicitly.
4. An exact-tag URI is a client-facing alias. Before signing, the client
   replaces it with the resolved EOA in the canonical request `target`.
5. The host resolves to the target user PGP identity and mailbox route.
6. The port is logical application metadata; it is not the target's public
   network location.
7. A URI fragment is client-local. It is never included in the request
   `target`, `path`, or `query` sent to the host.

## 3. Identity roles

| Identity | Purpose |
|---|---|
| Target EOA | Stable application owner named by the URI |
| Target user PGP | Encrypt application requests so only the target host can read them |
| Target route PGP | Select and reach the target mailbox |
| Caller EOA | Sign the canonical application request |
| Caller user PGP | Encrypt the host response back to the caller |

Business payloads are encrypted to the recipient **user PGP**, not the
mailbox route key. Receive/listen commands are encrypted to the mailbox route
key and submitted through another healthy entry.

Clients must follow the L0 A/B/C model: submit through an entry distinct from
mailbox B and receive through an entry distinct from B. Direct mailbox access
is not a conforming optimization.

## 4. Canonical request

The implemented v1 wire object is:

```json
{
  "request": {
    "v": 1,
    "type": "conet_web3_request_v1",
    "requestId": "unique-id",
    "from": "0xCaller",
    "target": "web3://0xtarget/path?query",
    "method": "GET",
    "path": "/path",
    "query": "query",
    "headers": {},
    "nonce": "unique-nonce",
    "expiresAt": 1787446800
  },
  "signMessage": "0x..."
}
```

`bodyBase64` and `contentType` are optional request fields. `query` excludes
the leading `?`, and `expiresAt` is a Unix timestamp in seconds.

`signMessage` is EIP-191 over the exact canonical JSON serialization of the
nested `request` object. V1 emits request fields in the order shown by the
versioned implementation, sorts allowed header names lexicographically, and
omits absent optional fields. A future revision must publish any change to
those bytes; clients must not guess or sign the outer wrapper.

The host validates:

- supported type and version;
- exact target EOA;
- allowed method and path;
- non-empty request ID and nonce, plus expiry;
- request size;
- EIP-191 signer equals `from`; and
- local origin policy.

The current gateway supports `GET` and `HEAD`.

## 5. Response

The implemented v1 response plaintext is:

```json
{
  "v": 1,
  "type": "conet_web3_response_v1",
  "requestId": "same-id",
  "status": 200,
  "headers": {},
  "contentType": "text/html",
  "bodyBase64": "...",
  "nonce": "same-request-nonce",
  "expiresAt": 1787446800
}
```

The host encrypts the response to the caller's registered user PGP key and
submits it through an ordinary L0 entry. The client decrypts it, validates the
versioned shape, matches both `requestId` and `nonce`, checks expiry, and only
then adapts the response for the requesting application or browser page.

V1 does **not** carry a separate target EIP-191 response signature or a
`from` field. Its responder binding comes from possession of the target user
PGP private key needed to read the random request identifiers, plus exact
`requestId` and `nonce` correlation in the encrypted response. Applications
that require a separately signed receipt must define one above this profile
rather than treating entry HTTP success as that receipt.

An entry `200`, mailbox handshake, or open receive session is not an
application response.

## 6. Persistent duplex profile

For continuous application protocols, one local connection maps to one
duplex session:

```text
local connection
  → signed/encrypted duplex offer
  → exact target and logical port validation
  → remote local-origin connection
  → duplex accept
  → ordered encrypted frames in both directions
  → explicit close or bounded reconnect
```

Each line has an independent session ID, temporary identity, queues,
upstream socket, and close state. Reusing one logical port does not permit
sharing identity or socket state between lines.

The L0 infrastructure carries encrypted frames. It does not parse or
reinterpret the origin application's byte protocol.

## 7. Implementations

The protocol is cross-platform. Linux servers and clients can use
[`conet-l0d`](../developers/conet-l0d.md). Browser, Windows, macOS, Android,
and iOS implementations use the same URI and envelope contract directly and
do not require the Linux runtime.

## 8. Host security

A host adapter must:

- connect only to explicitly configured loopback or private origins;
- reject arbitrary upstream hosts;
- strip untrusted identity headers;
- inject identity only after signature validation;
- bound method, path, body, response size, and execution time;
- keep private EOA and PGP material in restricted local storage;
- never log plaintext bodies, private keys, or complete ciphertexts; and
- fail closed if identity or routing data is unavailable.

An origin must not trust caller-supplied `X-CoNET-*` identity headers.

## 9. Browser security

A browser client must:

- keep unlocked private material in memory;
- use encrypted local storage for persistent identity material;
- isolate request IDs and responses between pages;
- validate response status, headers, body length, request ID, nonce, and
  expiry;
- apply a restrictive content policy before rendering active content;
- never expose decrypted private responses to an unrelated page; and
- reject unsupported or ambiguous URI targets.

Browser navigation registration and content rendering policy are product
concerns above this transport specification.

## 10. Errors

| Error class | Required interpretation |
|---|---|
| Invalid or ambiguous locator | Fail before sending |
| Missing AddressPGP identity | Fail closed; do not select another wallet |
| Entry unavailable | Retry another configured healthy entry |
| Mailbox route mismatch | Treat as routing failure |
| Signature or expiry failure | Reject the request or response |
| Local origin unavailable | Return an authenticated application error |
| Stream interrupted | Close or reconnect under a bounded policy |
| Timeout | No successful application result |

A transport failure must not be converted into a successful empty result.

## 11. Versioning

Versioned request, response, and stream types are protocol contracts.
Changing URI grammar, canonical signing bytes, encryption target, route
selection, response shape, storage boundary, or browser lifecycle requires
updating:

1. this specification;
2. the [Applications page](../applications/web3-url.md);
3. the [`conet-l0d` developer guide](../developers/conet-l0d.md) when the
   Linux runtime is affected; and
4. the general L0 protocol pages when the underlying L0 wire contract changes.

## 12. Non-goals

This protocol does not:

- define a new L0 wire command;
- expose a plaintext application side channel;
- make mailbox nodes trusted origins;
- replace TLS for ordinary `https://` endpoints;
- define payments, delegation, or every authorization policy in v1;
- guarantee operating-system scheme registration on every client; or
- define the origin application's internal protocol.
