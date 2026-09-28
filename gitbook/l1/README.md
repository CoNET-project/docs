# L1 — CoNET Blockchain

**Evidence level: Production reference.** The network identifiers and public services below describe the active CoNET L1. Individual contracts and indexed Explorer views still require address-specific verification.

CoNET L1 is an EVM-compatible proof-of-stake network. It provides the canonical settlement, asset, identity, registry, and cross-chain Treasury layer used by CoNET protocols.

EVM compatibility means that the chain executes Ethereum-style smart-contract bytecode and supports familiar account, signature, ABI, and JSON-RPC tooling. It does **not** mean that CoNET shares Ethereum or Base state, validators, balances, or finality.

## Network facts

| Field | Canonical value |
| --- | --- |
| `chainId` | **224422** (`0x36ca6`) |
| Native gas asset | **CNET** |
| Primary RPC | `https://rpc1.conet.network` |
| Backup RPC | `https://publicrpc.conet.network` |
| Explorer | `https://mainnet.conet.network` |
| Explorer alias | `https://scan.conet.network` |

`https://rpc.conet.network` is deprecated. It has returned state from an out-of-sync or divergent chain tip and must not be used as a source of truth, even if it reports `chainId 224422`.

## Two node roles

CoNET documentation uses two distinct node terms:

- **L1 validators** participate in proof-of-stake consensus and determine the canonical L1 chain. Their consensus-layer identity is a Beacon / Prysm `validator_index` (already observed **≥ 2000**). Do not use `ValidatorDepositRedeem.totalStakedValidatorCount()` as that census.
- **Guardian Nodes** belong to the DePIN service plane of the [Layer Minus cloud](../l0/permissionless-cloud.md). They may offer routing, mailbox delivery, bandwidth, storage, and CPU / GPU work. A listed Guardian is **not** a trusted host and is **not** an L1 validator. The registry snapshot near **472** is the **L0** scale.

Network-layer privacy and censorship resistance are transport objectives. Wallet-address routing and DePIN overlays can reduce dependence on directly exposed service endpoints, but they are **not a consensus algorithm called “stealth consensus.”** L1 consensus remains proof of stake.

## Read this section

1. [Chain identity](chain-identity.md)
2. [Validators](validators.md)
3. [Decentralization and verifiability](decentralization.md)
4. [Guardian Nodes](guardian-staking.md)
5. [RPC and Explorer](rpc-explorer.md)
6. [Assets](assets.md)
7. [Decentralized cross-chain Treasury](cross-chain-treasury.md)
8. [AAC proof-driven cross-chain settlement](aac-cross-chain.md)

Developer how-tos for this layer: [Run an L1 node](../developers/l1-node.md), [Participate in mining](../developers/l1-mining.md), and [Bring an ERC-20 into CoNET](../developers/l1-erc20-bridge.md).

## Source anchors

- [Chain identity](chain-identity.md) — network identifiers and endpoint policy
- [Decentralization and verifiability](decentralization.md) — reproducible validator, Guardian, stake, client, and governance views
- [RPC and Explorer](rpc-explorer.md) — connection and verification examples
- [Decentralized cross-chain Treasury](cross-chain-treasury.md) — current Treasury proxy, route modes, miner quorum, and the conditional hand-off to DLE
- [AAC proof-driven cross-chain settlement](aac-cross-chain.md) — production read-only Shadow and still-closed proof/finality/custody boundary
- [Resources](../resources.md) — public git map and live-service index

## Next

[Chain identity →](chain-identity.md)
