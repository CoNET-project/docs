# SilentPass VPN

**Maturity: Production reference.** Public clients and node-side
implementations exist. This label does not imply identical behavior on every
platform, independent privacy certification, or a universal VPN replacement.

Public site: [https://gitbook.conet.network/applications/silentpass-vpn.html](https://gitbook.conet.network/applications/silentpass-vpn.html)

App Store listing: [Silent Pass VPN](https://apps.apple.com/ca/app/silent-pass-vpn/id6740261324)

## Product role

SilentPass is a **privacy-oriented access product**. It captures traffic from
a device or selected applications, authorizes access with a wallet, and uses
Layer Minus over L0 resources to reach an egress node that opens an ordinary
Internet connection.

It does not turn L0 into a universal VPN protocol and does not replace the Internet underlay. L0 remains a [PGP / wallet-address forwarding network](../l0/using-l0.md); SilentPass is one combination that asks an SI egress to open `host:port`:

- TCP/IP still carries traffic between clients, entries, nodes, egresses, and destinations.
- HTTPS/TLS between the application and destination remains responsible for end-to-end website security.
- L0 supplies decentralized network resources; Layer Minus supplies
  wallet-addressed control, entry routing, and a node path. Neither is a new
  global IP network.
- Datagram-oriented applications require a separate UDP-forwarding path and should not be inferred from the TCP/SOCKS implementation.

Two product surfaces use this model:

| Surface | Application behavior |
| --- | --- |
| **SilentPass VPN** | A device tunnel captures eligible operating-system traffic and forwards supported flows through the SilentPass client. |
| **SilentPass Proxy** | A local SOCKS or HTTP proxy sends only configured applications through SilentPass. |

Use the VPN surface for device-level capture and the proxy surface for selective routing. Their capture boundaries differ; their Layer Minus dependency is shared.

SilentPass provides wallet-authorized privacy egress to ordinary Internet
destinations. It is not an L1 consensus transport and it is not a
`web3://` application host. For wallet-addressed applications, use
[`web3://` wallet-addressed applications](web3-url.md).

## Protocol dependencies

| Dependency | Why SilentPass needs it |
| --- | --- |
| [TCP/IP](../l0/tcp-ip.md) | The actual network underlay and the egress-to-destination connection |
| **Wallet identity and OpenPGP** | Signs access commands and encrypts control data to the selected egress |
| **Layer Minus entry routing** | Accepts HTTP `/post` (HTTPS optional) at an entry that is distinct from the selected egress. The posted object is already encrypted; nodes route by OpenPGP key ID. |
| **CoNET-SI egress commands** | `SilentPass`, `SaaS_Sock5`, and `SaaS_Sock5_v2` validate admission and open a normal `host:port` connection |
| **Payment / admission state** | Lets an egress check whether a wallet is authorized to use the service. Today admission requires a valid Passport NFT, and traffic is not charged by volume. Egress bytes are metered per wallet but not charged. Charging rules for SaaS egress are not decided; node service fees under the new GB design are described in [GB purchase, metering, fees and settlement](../l1/gb-billing.md) (approved, not yet live) |
| [UDP forward](../l0/udp-forward.md) | Separate capability for applications that require datagram-shaped frames |

The application must preserve the role separation: a client submits an encrypted command through an entry; it must not publish or treat the egress as a conventional, fixed “VPN server IP.”

## How protocol capability becomes access

For a supported TCP connection, the intended flow is:

```text
Application or OS
  │
  ├─ device tunnel, or
  └─ local SOCKS / HTTP proxy
  │
  ▼
SilentPass client
  │  select an entry and an egress for a new supported connection
  │  sign the command and encrypt it to the egress
  │  POST /post to the entry
  ▼
Layer Minus routing
  │
  ▼
CoNET-SI egress
  │  admission check
  └─ ordinary TCP connect(host, port) ──► destination
```

Current client code includes per-connection entry and egress selection. This can reduce reuse of one network path when an application opens separate connections. It must not be generalized into the claim that **every web resource always uses a different egress**: browser connection pooling, HTTP/2 or HTTP/3 multiplexing, caching, operating-system behavior, and platform-specific client implementations determine the actual granularity. That property requires runtime measurement for each client and workload.

The destination still receives a normal Internet connection from the egress. SilentPass changes the access path and identity model; it does not make destination protocols disappear.

## What exists today

The following public surfaces and implementation sources exist:

| Component | GitHub | npm |
| --- | --- | --- |
| **iOS VPN client** | [CoNET-project/SilentPass-iOS](https://github.com/CoNET-project/SilentPass-iOS) | — |
| **Android client** | [CoNET-project/SilentPass-Android](https://github.com/CoNET-project/SilentPass-Android) | — |
| **macOS client** | [CoNET-project/SilentPass-MacOS](https://github.com/CoNET-project/SilentPass-MacOS) | — |
| **Desktop proxy (Mac)** | [CoNET-project/SilentPassProxy-Mac](https://github.com/CoNET-project/SilentPassProxy-Mac) | — |
| **Desktop proxy (Windows)** | [CoNET-project/SilentPassProxy-win](https://github.com/CoNET-project/SilentPassProxy-win) | — |
| **vpn2socks helper** | [CoNET-project/vpn2socks](https://github.com/CoNET-project/vpn2socks) | — |
| **CoNET-SI egress** (`SilentPass` / `SaaS_Sock5`) | [CoNET-project/CoNET-SI](https://github.com/CoNET-project/CoNET-SI) | [`@conet.project/mvp-si`](https://www.npmjs.com/package/@conet.project/mvp-si) |
| **Layer Minus / DL client plane** | [CoNET-project/CoNET-DL](https://github.com/CoNET-project/CoNET-DL) | [`@conet.project/mvp-dl`](https://www.npmjs.com/package/@conet.project/mvp-dl) |

Existing loader hosts:

| Host | Intended use |
| --- | --- |
| `https://vpn9.conet.network/` | Production SilentPass WebView / loader |
| `https://vpn-beta.conet.network/` | Beta / test loader |

The source and public endpoints establish that the access product exists. They do not, by themselves, verify current store availability in every region, node capacity, path diversity, traffic-classification resistance, or behavior parity across all clients.

## What remains in development

- Measure and publish path-selection behavior under browser connection reuse, multiplexing, retries, and mobile background execution.
- Continue cross-platform feature and security parity work across the VPN and proxy clients.
- Harden failure handling for unavailable entries, unavailable egresses, interrupted streams, and admission-service failures.
- Define and test the supported UDP and real-time application envelope rather than describing TCP/SOCKS as a complete substitute.
- Publish independent security and privacy assessments for the clients, node commands, key handling, and traffic-analysis claims.
- Document capacity, latency, observability, abuse handling, and operational service objectives with measured data.

## Trust and security boundary

SilentPass reduces some direct relationships, but it does not remove trust or metadata.

| Participant | What it can observe or affect |
| --- | --- |
| **Entry** | Client network address, timing, volume, and routing-visible ciphertext metadata; it can drop or delay traffic |
| **Intermediate Layer Minus nodes** | Routing metadata and ciphertext needed for forwarding; they can disrupt availability |
| **Egress** | Destination `host:port`, timing, volume, and the client wallet information required by admission; for HTTPS, destination content remains protected by application TLS |
| **Destination** | Egress IP plus normal application identifiers such as cookies, logins, browser fingerprints, and request content |
| **Payment / chain observers** | Public wallet activity and timing that may be correlated with service use |
| **Client device** | Plaintext before encryption and after decryption; compromise of the device defeats network-path protections |

Important limits:

- Wallet identity is pseudonymous, not automatically unlinkable.
- Rotating paths does not defeat cookies, account logins, browser fingerprinting, malware, or endpoint compromise.
- A global observer that can correlate all entries and egresses is outside this product claim.
- An egress can refuse service, censor destinations, or provide poor performance.
- HTTPS-shaped transport should not be described as guaranteed indistinguishability from all Web traffic.
- The accurate product claim is privacy-oriented access with a different routing and identity model, not absolute anonymity.

## Related

- [TCP/IP protocol](../l0/tcp-ip.md)
- [TCP/IP privacy threats](../l0/tcp-ip-privacy.md)
- [Wallet-address P2P](../l0/wallet-address-p2p.md)
- [HTTP mimicry & Fetch-and-Close](../l0/http-mimicry.md)
- [Zero-trust mailbox routing](../l0/mailbox-routing.md)
- [UDP forward](../l0/udp-forward.md)
- [Applications](README.md)
- [Beamio](beamio.md)
- [DePIN DCDN / BT](bt-dcdn.md) — under development; a separate bulk-distribution application
- [Resources](../resources.md) — source and npm index
