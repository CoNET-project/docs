# Open source

CoNET is developed through public open-source repositories. The protocol,
infrastructure, application clients, contracts, SDKs, and this documentation
can be inspected, built, and contributed to through the repositories below.

Public source does not mean that every production deployment, operator secret,
infrastructure configuration, or hosted service is reproduced in a public
repository. Source availability and operational maturity are documented
separately.

## Infrastructure and protocols

| Project | Repository |
|---|---|
| CoNET SI — L0 node, entry, mailbox, and forwarding services | [CoNET-project/CoNET-SI](https://github.com/CoNET-project/CoNET-SI) |
| CoNET DL — Layer Minus and mining client plane | [CoNET-project/CoNET-DL](https://github.com/CoNET-project/CoNET-DL) |
| CoNET L0D — Linux `web3://` runtime | [CoNET-project/CoNET-L0D](https://github.com/CoNET-project/CoNET-L0D) |
| `web3://` browser client | [CoNET-project/web3Url](https://github.com/CoNET-project/web3Url) |
| CoNET DLE — L2 specifications, runtime, and Explorer | [CoNET-project/CoNET-DLE](https://github.com/CoNET-project/CoNET-DLE) |
| bridgeAAC — Rust reference state machine for proof-driven cross-chain settlement | [CoNET-project/bridgeAAC](https://github.com/CoNET-project/bridgeAAC) |
| CoNET Chat SDK | [CoNET-project/chat-sdk](https://github.com/CoNET-project/chat-sdk) |

## Beamio

| Project | Repository |
|---|---|
| Consumer PWA — `cashtree` branch | [CoNET-project/SilentPassUI](https://github.com/CoNET-project/SilentPassUI/tree/cashtree) |
| Merchant OS — `cashtrees` branch | [CoNET-project/SilentPassUI](https://github.com/CoNET-project/SilentPassUI/tree/cashtrees) |
| Alliance client — `Alliance` branch | [CoNET-project/SilentPassUI](https://github.com/CoNET-project/SilentPassUI/tree/Alliance) |
| API, Cluster, Master, and Paymaster relay | [settleonbase/x402sdk](https://github.com/settleonbase/x402sdk) |
| Marketing homepage | [beamio-APP/homepage](https://github.com/beamio-APP/homepage) |
| Smart contracts | [beamio-APP/BeamioContract](https://github.com/beamio-APP/BeamioContract) |

The POS PWA has live public endpoints, but this documentation has not
identified a standalone public repository for it. See the
[Beamio source-availability table](applications/beamio.md#what-exists-today)
for the component-level boundary.

## SilentPass clients

| Project | Repository |
|---|---|
| iOS VPN client | [CoNET-project/SilentPass-iOS](https://github.com/CoNET-project/SilentPass-iOS) |
| Android client | [CoNET-project/SilentPass-Android](https://github.com/CoNET-project/SilentPass-Android) |
| macOS client | [CoNET-project/SilentPass-MacOS](https://github.com/CoNET-project/SilentPass-MacOS) |
| Desktop proxy for macOS | [CoNET-project/SilentPassProxy-Mac](https://github.com/CoNET-project/SilentPassProxy-Mac) |
| Desktop proxy for Windows | [CoNET-project/SilentPassProxy-win](https://github.com/CoNET-project/SilentPassProxy-win) |
| `vpn2socks` helper | [CoNET-project/vpn2socks](https://github.com/CoNET-project/vpn2socks) |

The SilentPass product page provides the corresponding
[implementation and package table](applications/silentpass-vpn.md#what-exists-today).

## Documentation

| Project | Repository |
|---|---|
| CoNET GitBook source | [CoNETProject/docs](https://github.com/CoNETProject/docs) |

Documentation fixes and source contributions should be submitted to the
repository that owns the affected component. Before relying on a repository
for production operations, also check the maturity and deployment boundaries
on [Resources](resources.md).
