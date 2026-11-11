# RPC and Explorer

**Evidence level: Production reference.** These are the active public connection and inspection endpoints for CoNET L1.

CoNET L1 uses **`chainId 224422`** (`0x36ca6`). The following are the only active general-purpose RPC endpoints documented for this chain.

## Active JSON-RPC endpoints

| Priority | URL | Use |
| --- | --- | --- |
| Primary | `https://rpc1.conet.network` | Default endpoint for applications and operational queries |
| Backup | `https://publicrpc.conet.network` | Fallback when the primary endpoint is unavailable |

Use explicit failover. Do not merge partial responses from different endpoints into one result, and do not turn a transport or parse failure into a valid zero or empty value.

## Deprecated endpoint

`https://rpc.conet.network` is deprecated and must not be used. It has exposed an out-of-sync or divergent chain tip while still returning the expected chain ID. Therefore, `eth_chainId` alone cannot establish that an endpoint is a valid CoNET L1 source.

## Verify the network

```bash
curl -s https://rpc1.conet.network \
  -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}'
```

Expected result:

```json
{"jsonrpc":"2.0","id":1,"result":"0x36ca6"}
```

For operational checks, also compare the latest block and required contract code against a second active endpoint. Treat disagreement as an incident to investigate, not as permission to select the numerically highest result.

## Explorer

The canonical Explorer is:

`https://mainnet.conet.network`

`https://scan.conet.network` is an alternate entry alias. Documentation, verification links, and canonical references use `mainnet.conet.network`.

Use it for blocks, transactions, addresses, tokens, contract source verification, and proxy metadata. Explorer indexing can lag the chain, so direct RPC remains the authority for current contract state.

The **DLE lab explorer** (paused) is not this L1 Explorer. Its `eth_chainId` `0x44c45` is **CoNET-DLE Testnet**, not CoNET L1. The Home page shows that testnet chain id plus the bootstrap **Group ID** (L1 register tx hash). The Archives page may overlay participant wallets read from the L1 [Global Archive Routing Registry](../l2/routing-registry.md) on `224422`. See [DLE explorer](../l2/explorer.md).

Peering a self-hosted geth / Prysm stack is a different interface. Genesis files, DHT hubs, and execution bootnodes are on [Run an L1 node](../developers/l1-node.md).

## Client guidance

- Read contract views and balances directly from an active RPC where practical.
- Cache only successfully parsed responses that match the requested chain, account, and contract.
- Preserve the last trusted value when an RPC request fails.
- Use the Explorer for inspection, not as a replacement for signing-domain or runtime RPC checks.

## Source anchors

- [Chain identity](chain-identity.md) — canonical network definition
- [Run an L1 node](../developers/l1-node.md) — P2P join, not JSON-RPC
- [Resources](../resources.md) — non-RPC service directory

## Next

[Assets →](assets.md)
