# `web3://` wallet-addressed applications

> **Not usable on the current network.** The official `web3://` gateway still receives through the legacy listen pool, which CoNET-SI nodes stopped serving on 2 November 2026, so `web3://` browsing through it does not work today. A fix is not scheduled. Persistent application streams also depend on L0 primitives that were removed from CoNET-SI on 31 October 2026.

**Maturity: Under development.** `web3://` is a wallet-addressed application
protocol using Layer Minus over CoNET L0 resources. The Linux runtime, signed GET/HEAD
gateway, locator parser, persistent application streams, and early
cross-browser client are implemented. A
complete cross-platform protocol handler and general public hosting service
are not yet production releases.

**One-line definition:** a wallet-addressed, caller-authenticated,
privacy-routed application protocol with encrypted response correlation.

Protocol contract: [`web3://` Application Protocol](../l0/web3-application-protocol.md)  
Linux runtime: [Developers — `conet-l0d`](../developers/conet-l0d.md)  
Browser client source: [CoNET-project/web3Url](https://github.com/CoNET-project/web3Url)  
Linux source: [CoNET-project/CoNET-L0D](https://github.com/CoNET-project/CoNET-L0D)

## Product model

`web3://` names an application by wallet identity instead of exposing its
origin as the application identity. Layer Minus supplies encrypted entry
routing and mailbox delivery; the application protocol supplies the URI,
caller-signed request or stream, correlated encrypted response, and error
semantics.

The layers have distinct responsibilities:

1. **CoNET L0** is the decentralized cloud resource plane: network forwarding,
   ciphertext storage, service-hosting adapters, and contributed CPU/GPU
   capacity.
2. **Layer Minus** is the privacy communication protocol that composes those
   L0 resources into encrypted, wallet-addressed routes.
3. **CoNET L1 and CoNET-DLE L2** can use Layer Minus for privacy-routed peer
   and application-led mining gossip.
4. **`web3://`** is the private application-server surface on the same
   infrastructure. It addresses a Web, API, AI, or TCP service by wallet or
   exact tag and authenticates the caller.

```text
web3://0x<wallet>/<resource>
web3://<exact-tag>.web3/<resource>
                 │
                 ├─ browser or native client
                 └─ Linux client using conet-l0d
                                │
                     Layer Minus on CoNET L0
                                │
                 Linux server using conet-l0d
                                │
                    local Web/API/TCP origin
```

This is an **application protocol that uses Layer Minus over L0
infrastructure**. It is not a new SI command family and does not turn L0 into
a product-specific protocol.

## Platform choices

| Platform | How to use `web3://` |
|---|---|
| **Linux server** | Publish a local service with `conet-l0d gateway`, `--proxy`, or `--proxyDuplex` |
| **Linux client** | Open a remote service with `conet-l0d --clientDuplex web3://...` |
| **Windows / macOS** | Use a browser extension, browser application, or native client implementing this protocol |
| **Android / iOS** | Use a browser/PWA, WebView application, or native client implementing this protocol |
| **Browser client** | Resolve, sign, encrypt, submit, receive, verify, and render in client code |

Windows, macOS, and phone users do not need to run the Linux daemon. The
protocol is portable; `conet-l0d` is its Linux server/client runtime.

## Access flow

For a signed resource request:

1. Parse `web3://<target>/<path>`.
2. Resolve the target to an exact EOA. Exact BeamioTag matching is required.
3. Read the target user PGP key and mailbox route through AddressPGP.
4. Build a versioned request with target, method, path, query, request ID,
   nonce, and expiry.
5. Sign the canonical request with the caller EOA.
6. Encrypt the application request to the target user PGP key.
7. Submit the ciphertext through a healthy Layer Minus entry.
8. The host validates the request and accesses only its configured local
   origin.
9. The host encrypts the response to the caller's registered user PGP key.
10. The client matches the response request ID and nonce, checks its expiry,
    and renders it under the browser or application policy.

The HTTP body sent to an entry remains:

```json
{ "data": "<OpenPGP armor>" }
```

An entry HTTP `200` is transport progress, not proof that the application
request completed.

## Application profiles

| Profile | Purpose | Linux runtime |
|---|---|---|
| Signed request + correlated response | Bounded Web/API reads | `gateway` and `--proxy` |
| Persistent application stream | WebSocket-like or raw bidirectional application stream | `--proxyDuplex` + `--clientDuplex` |
| Browser resource | Resolve and render a `web3://` path in a browser client | `web3Url` client |

The current signed gateway permits `GET` and `HEAD`, uses a loopback origin,
checks EIP-191 identity and expiry, limits body size and timeout, and encrypts
the response to the requester.

## Current implementation evidence

### Browser client

The `web3Url` repository currently includes:

- EOA and exact-tag locator parsing;
- versioned request and response envelopes;
- local communication wallet and PGP identity creation;
- an encrypted extension-local identity vault;
- AddressPGP lookup;
- entry retry/failover abstraction;
- page-to-extension bridge;
- options and service-worker request paths; and
- mock gateway round-trip tests.

Browser operating-system navigation registration and the final production
entry policy remain under development.

### Linux host and client

`conet-l0d` currently includes:

- request/response server publishing;
- persistent duplex server and client endpoints;
- a signed GET/HEAD application gateway;
- wallet/tag locator parsing;
- bounded reconnect and runtime status; and
- systemd examples for the runtime and gateway.

An end-to-end smoke test on 2026-08-20 requested:

```text
web3://0xA838…5A53/
```

through a real entry and AddressPGP registration. The encrypted response was
`200 text/html`, and its SHA-256 matched the direct
`https://conet.network/` response. This proves the implemented request path;
it does not establish a general hosting SLA.

## Identity and storage

Client private material remains client-side:

- browser implementations store encrypted identity material and keep unlocked
  secrets in memory;
- Linux hosts use local key files with restricted permissions;
- entries and mailbox nodes receive ciphertext, not application plaintext;
- complete private keys, plaintext requests, and complete ciphertexts must not
  be logged.

The protocol authenticates wallet control. Applications still decide which
wallets may access each resource.

## Privacy boundary

| Participant | May observe |
|---|---|
| Client entry | Client IP, timing, size, and routing-visible metadata |
| Intermediate node | Ciphertext and the metadata required for its hop |
| Mailbox | Route activity and ciphertext |
| Application host | Authenticated caller wallet and request plaintext |
| Chain observer | Public wallet and registration activity |

The accurate claim is that the client and host need not use stable public
origin locations as their application identity. The protocol does not claim
that no IP exists or that a global observer cannot correlate timing.

## Product boundaries

`web3://` is not ERC-4804 content resolution, a conventional DNS alias for a
public origin, or SilentPass egress to an arbitrary Internet `host:port`.
Browser scheme registration is still platform-dependent. The normative
authorization, rendering, transport, and failure boundaries are defined once
in the [Application Protocol contract](../l0/web3-application-protocol.md).

## Related

- [L0 decentralized cloud](../l0/README.md)
- [Layer Minus privacy routing](../l0/layer-minus.md)
- [`web3://` Application Protocol contract](../l0/web3-application-protocol.md)
- [Linux runtime (`conet-l0d`)](../developers/conet-l0d.md)
- [How to use Layer Minus](../l0/using-l0.md)
- [Zero-trust mailbox routing](../l0/mailbox-routing.md)
- [Security limits](../l0/security-limits.md)
- [L0 development](../developers/l0.md)
