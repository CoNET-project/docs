# CoNET

## From infrastructure to applications

CoNET is a wallet-addressed infrastructure stack. Three infrastructure
layers supply cloud resources, shared state, and specialized ledgers.
**Layer Minus** uses the L0 cloud to route OpenPGP-encrypted application
traffic by wallet-linked identity. Application protocols and products then
combine only the capabilities they need.

| Plane | Responsibility | Start here |
|---|---|---|
| **L0 — Decentralized Cloud** | Permissionless forwarding, ciphertext storage, service hosting, contributed CPU/GPU capacity, and GB metering | [L0 overview](l0/README.md) |
| **Layer Minus — Privacy Protocol** | Wallet/OpenPGP-addressed routing, zero-trust entry and mailbox roles, and HTTP(S)-shaped encrypted transport on L0 | [Layer Minus](l0/layer-minus.md) · [How to use it](l0/using-l0.md) |
| **L1 — CoNET Blockchain** | EVM state, identity registries, validators, canonical assets, Treasury, and settlement (`chainId` **224422**) | [L1 overview](l1/README.md) · [Run an L1 node](developers/l1-node.md) |
| **L2 — CoNET-DLE** | Specialized parallel application-ledger classes with explicit archive, finality, availability, and settlement rules | [L2 overview](l2/README.md) · [DLE explorer](l2/explorer.md) |

## Open source

CoNET is developed in public open-source repositories. Protocol,
infrastructure, client, contract, SDK, and documentation source links are
collected in the [Open source repository index](open-source.md). Individual
hosted deployments may also depend on private operator configuration and
secrets that are not part of the public source.

```text
L0 cloud resources
        │
        ▼
Layer Minus privacy routing ───────┐
                                   │
L1 shared state and settlement ────┼──► application protocols ───► applications
                                   │
DLE L2 specialized ledgers ────────┘
```

This is a dependency map, not a mandatory pipeline. [SilentPass](applications/silentpass-vpn.md)
focuses on privacy-oriented Internet access, [CoNET Chat](applications/depin-chat.md)
on relationship-private wallet communication, and [Beamio](applications/beamio.md)
on consumer, merchant, and POS workflows.

## Where things stand (October 2026)

| Area | Status | Read |
|---|---|---|
| **CoNET L1** | Production, `chainId` 224422. Osaka / Fulu active since 2026-10-18; the official Geth release runs current blocks | [L1 overview](l1/README.md) · [Run an L1 node](developers/l1-node.md) |
| **Cross-chain settlement** | AAC read-only Shadow in production since 2026-10-16; Obstacles 1–5 Accepted; miner-vote path closed and paid-GB bridge paused since 2026-10-15; AAC custody closed | [AAC](l1/aac-cross-chain.md) · [Treasury](l1/cross-chain-treasury.md) |
| **GB** | The live GBToken is unchanged. A replacement GB and conet-USDC design is a discussion draft, not deployed | [GB whitepaper](l1/gb-whitepaper.md) · [GB AMM whitepaper](l1/gb-amm-whitepaper.md) |
| **CoNET-DLE** | Normative design with a public lab. The 30-day lab assessment was partial success, not qualified; production archive signing and asset ingress are not enabled | [L2 overview](l2/README.md) · [Lab honesty track](l2/lab-honesty-track.md) |
| **Order-book exchange** | Whitepaper draft for an exchange that runs inside DLE; not implemented | [Exchange whitepaper](applications/miner-orderbook-dex-whitepaper.md) |

## Design drafts and whitepapers

These documents propose designs. Rules they mark as decided are operator
decisions, not DAO approval, and none of the designs below is deployed.

- [GB token whitepaper (draft v0.3)](l1/gb-whitepaper.md) — paid GB issued
  only by burning conet-USDC, consume-only free GB, Base USDC as the only
  reserve, DAO-voted parameters executed by contracts, and a cross-chain
  forged-message gate before any mint or release path opens.
- [GB AMM whitepaper (draft v0.2)](l1/gb-amm-whitepaper.md) — GB markets,
  treasury open-market operations and risk management for that design.
- [Order-book exchange whitepaper (draft v0.2)](applications/miner-orderbook-dex-whitepaper.md)
  — a non-custodial order book on CoNET-DLE: users freeze their own DLE
  balances, miners split and match orders in batch auctions, and anyone can
  open a liquidity pool for a fast lane. It also compares today's
  centralized and decentralized exchanges.
- [Privacy-first Decentralized AI whitepaper](applications/privacy-first-ai-whitepaper.md)
  — independent model, data and agent roles over wallet-addressed
  infrastructure.

## Wallet-addressed applications

[`web3://`](applications/web3-url.md) is an **application protocol using Layer
Minus on L0 infrastructure**. It defines wallet-addressed locators, exact
identity resolution, caller-signed requests, correlated encrypted responses,
persistent application streams, and client security rules without adding
another L0 wire command.

Linux servers and clients can use the
[`conet-l0d` runtime](developers/conet-l0d.md). Windows, macOS, Android, iOS,
and browser applications implement the same `web3://` contract in browser or
native client code. See the [protocol contract](l0/web3-application-protocol.md)
for interoperable URI and envelope rules.

## Privacy boundary

Layer Minus does not remove TCP/IP from the Internet and does not promise
absolute anonymity. OpenPGP protects application plaintext, while role
separation reduces the need for one intermediary to observe both endpoints.
An entry can still observe the connecting client, a mailbox can observe route
activity, and traffic timing and size remain metadata. Ordinary HTTP-shaped
transport can reduce dependence on a distinctive custom carrier or TLS
handshake, but it is not guaranteed to be indistinguishable from all Web
traffic.

## How to read this book

- Architecture: [System overview](overview.md), then
  [L0](l0/README.md) → [Layer Minus](l0/layer-minus.md) →
  [L1](l1/README.md) → [L2](l2/README.md).
- Application protocol: [`web3://`](applications/web3-url.md) →
  [protocol contract](l0/web3-application-protocol.md) →
  [Linux runtime](developers/conet-l0d.md).
- Products: [Applications](applications/README.md).
- L0 and Layer Minus implementation: [L0 development](developers/l0.md),
  [SI developer guide](l0/si-developer-guide.md), and
  [security limits](l0/security-limits.md).
- L1 operations: [Run an L1 node](developers/l1-node.md),
  [RPC and Explorer](l1/rpc-explorer.md), and
  [decentralization evidence](l1/decentralization.md).
- Cross-chain assets: [Cross-chain Treasury](l1/cross-chain-treasury.md) →
  [AAC proof-driven settlement](l1/aac-cross-chain.md) →
  [cross-chain assets in DLE](l2/cross-chain-assets.md).
- Economics: [Core L1 assets](l1/assets.md) →
  [GB whitepaper](l1/gb-whitepaper.md) →
  [GB AMM whitepaper](l1/gb-amm-whitepaper.md).
- Trading on DLE: [Exchange design study](applications/miner-orderbook-dex.md) →
  [exchange whitepaper](applications/miner-orderbook-dex-whitepaper.md).
- Public source: [Open source repository index](open-source.md).
- Current endpoints and evidence: [Resources](resources.md).

## Status and evidence

| Evidence level | Meaning |
|---|---|
| **Production reference** | Live chain, endpoint, contract, or public application entry |
| **Implemented capability** | Present in source, but not necessarily enabled in every deployment |
| **Under development** | Active implementation or integration work |
| **Normative design** | Controlled by a specification; deployment status is separate |
| **Design study** | Non-normative application or economic proposal |

A production reference is not by itself an audit, uptime guarantee, or claim
that every feature is enabled. Historical imported documentation is not the
source of truth for this book.
