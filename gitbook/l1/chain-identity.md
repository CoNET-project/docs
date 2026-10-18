# Chain identity

**Evidence level: Production reference.** Values below describe the active CoNET L1 and must be checked against an active endpoint when used operationally.

## Canonical network

| Field | Value |
| --- | --- |
| Network | CoNET L1 |
| `chainId` | **224422** |
| Hex chain ID | `0x36ca6` |
| Native gas asset | **CNET** |
| Execution environment | EVM compatible |
| Explorer | `https://mainnet.conet.network` |

The chain ID is necessary for signing and replay-domain separation, but it is not sufficient to identify a healthy chain tip. Two endpoints can report the same chain ID while exposing different state.

## RPC authority

Use only these general-purpose CoNET L1 endpoints:

1. `https://rpc1.conet.network` — primary
2. `https://publicrpc.conet.network` — backup

`https://rpc.conet.network` is deprecated and unreliable. It has been observed out of sync or divergent from the active network. Do not use it for block height, contract code, balances, transaction submission, deployment verification, or incident diagnosis.

Applications should fail over from the primary endpoint to the backup only after treating the failed response as untrusted. A timeout, malformed response, or unavailable RPC must not be converted into a zero balance or an empty on-chain result.

## What L1 anchors

CoNET L1 is the canonical layer for:

- proof-of-stake block production and finality;
- native CNET balances and transaction fees;
- canonical CoNET assets such as conet-USDC and GBToken;
- protocol registries, identity, routing, node, and treasury contracts; and
- application contracts that explicitly target `chainId 224422`.

Individual contract addresses can change through deployment or upgrade procedures. Verify an address against current deployment records and its code on the active RPC, then inspect it at the canonical Explorer.

## Fork schedule

| Fork | Time (UTC) | Status |
| --- | --- | --- |
| Prague / Electra | 2026-10-18 05:32:31 | Active |
| Osaka / Fulu | 2026-10-18 13:26:07 | Scheduled |

See [L1 network upgrades](upgrades.md).

## Source anchors

- [RPC and Explorer](rpc-explorer.md) — endpoint table and `eth_chainId` check
- [L1 network upgrades](upgrades.md) — fork schedule and upgrade record
- [Run an L1 node](../developers/l1-node.md) — genesis files, DHT hubs, and geth bootnodes
- [Assets](assets.md) — active asset identifiers
- [Resources](../resources.md) — service and repository index

## Next

[Validators →](validators.md)
