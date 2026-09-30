# Developers

Use this section to build or operate against CoNET. Read the architecture in
dependency order: [L0 cloud resources](../l0/README.md),
[Layer Minus privacy routing](../l0/layer-minus.md),
[L1 shared state](../l1/README.md), and
[DLE L2 specialized ledgers](../l2/README.md). Application protocols and
user-facing products are documented separately.

A change to an L0 wire contract must update both the architecture and
developer tracks in the same task.

## Maturity labels

This section uses the book-wide labels defined on [Home](../README.md):
**Production reference**, **Implemented capability**, **Under development**,
**Normative design**, and **Design study**. A runnable command is not by
itself proof of production availability or an audit.

## Tracks

| Track | What you build or operate | Maturity | Start here |
|---|---|---|---|
| **Layer Minus development** | A client using `POST /post`, mailbox receive, Chat, UDP, or another encrypted application envelope | Implemented capability | [L0 development](l0.md) |
| **`web3://` applications** | Wallet-addressed request/response or persistent application streams | Under development | [Protocol](../l0/web3-application-protocol.md) |
| **Linux `web3://` runtime** | Publish or open services with `conet-l0d` | Under development | [`conet-l0d`](conet-l0d.md) |
| **L1 node** | A permissionless geth + Prysm full node and optional validator | Production reference | [Run an L1 node](l1-node.md) |
| **L1 checkpoint confirmation** | An independent operator reproduces slot 155646 from a local beacon | Production reference | [Confirm the period-18 checkpoint](l1-independent-confirmation.md) |
| **L1 mining** | Guardian / LayerMinus participation and verified mining gossip | Implemented capability | [Participate in mining](l1-mining.md) |
| **L1 ERC-20 ingress** | Implement the specified admission path for a foreign ERC-20 through TreasuryBridgeV3; deployed Treasury references are documented separately | Normative design | [Bring an ERC-20 into CoNET](l1-erc20-bridge.md) |
| **L2 development** | Implement or review the CoNET-DLE specifications; lab evidence is separate from production | Normative design | [L2 development](l2.md) |

## Choose the right track

- Understand contributed infrastructure resources: start with
  [L0](../l0/README.md).
- Forward ciphertext by wallet or OpenPGP key ID over those resources: use
  [Layer Minus](../l0/layer-minus.md) and [L0 development](l0.md).
- Build a wallet-addressed application: implement the
  [`web3://` protocol](../l0/web3-application-protocol.md).
- Host that application on Linux or open it from a Linux client: use
  [`conet-l0d`](conet-l0d.md).
- Implement the client on Windows, macOS, Android, iOS, or in a browser:
  implement the same `web3://` locator, caller-signed request, encrypted
  response correlation, and rendering contract in client code.
- Run geth and Prysm: use [Run an L1 node](l1-node.md). The public P2P path is
  independent of `web3://`. A laboratory overlay that keeps those same
  clients and dials remotes as `web3://<wallet>:<port>` is recorded in
  [L1 overlay lab](conet-l0d-l1-overlay-lab.md).
- Join DePIN mining: use [Participate in mining](l1-mining.md).
- Move an ERC-20 into CoNET: use
  [Treasury ERC-20 ingress](l1-erc20-bridge.md).
- Implement a parallel ledger: use [L2 development](l2.md); do not treat the
  lab explorer as a production DLE SDK.

## Reusable constants

| Item | Value |
|---|---|
| CoNET L1 | `chainId` **224422** |
| Primary RPC | `https://rpc1.conet.network` |
| Backup public RPC | `https://publicrpc.conet.network` |
| Explorer | `https://mainnet.conet.network` |
| AddressPGP | `0x684b0ac760cEE9c9b85de36d69746420648Cf9e2` |
| GuardianNodesInfoV6 | `0xBC6b53065b5647261396d002bDBA0d3396E0722f` |
| TreasuryBridgeV3 | `0xa208982212978550594A7FEEB70a61665d129003` |

Do not use deprecated `https://rpc.conet.network`. Do not invent an SI
hostname; use existing Guardian domains from the live registry.

## Public source

CoNET infrastructure, protocols, clients, contracts, SDKs, and documentation
are developed in public repositories. Use the
[Open source repository index](../open-source.md) to find the source owner for
each component before opening an issue or submitting a change.

## Next

1. [L0 development](l0.md)
2. [Layer Minus](../l0/layer-minus.md)
3. [`web3://` Application Protocol](../l0/web3-application-protocol.md)
4. [`conet-l0d` Linux runtime](conet-l0d.md)
5. [Run an L1 node](l1-node.md)
6. [Participate in mining](l1-mining.md)
7. [Bring an ERC-20 into CoNET](l1-erc20-bridge.md)
8. [L2 development](l2.md)
