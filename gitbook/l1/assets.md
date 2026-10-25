# Assets

**Evidence level: Production reference.** Contract addresses identify current CoNET L1 assets; economic policy and upgrade authority require separate review.

This page identifies the principal assets referenced by CoNET L1 documentation. It is an asset map, not a tokenomics specification.

All assets below are associated with CoNET L1, **`chainId 224422`**.

| Asset | Type | Protocol use |
| --- | --- | --- |
| **CNET** | Native asset | Pays L1 gas and participates in protocol staking or bond mechanisms where a contract explicitly requires it |
| **wCNET** | Canonical ERC-20, 18 decimals | 1:1 wrapped native CNET on CoNET. Bridge mint and burn go through TreasuryBridgeV3. Base holds a separate unwrap-disabled representation |
| **conet-USDC** | Canonical ERC-20 | USD-denominated settlement and accounting asset used by CoNET contracts |
| **GBToken** (`GB`) | ERC-20, **9 decimals** | Active GB balance and transfer asset for DePIN service and bandwidth-related flows |

## Canonical contracts

| Component | Address |
| --- | --- |
| TreasuryBridgeV3 proxy (sole Treasury) | [`0xa208982212978550594A7FEEB70a61665d129003`](https://mainnet.conet.network/address/0xa208982212978550594A7FEEB70a61665d129003) |
| ConetTreasuryPeer v4 (module, not a Treasury) | [`0x6093871d8a3EE6EaADc9869451D1693973cFBCC0`](https://mainnet.conet.network/address/0x6093871d8a3EE6EaADc9869451D1693973cFBCC0) |
| conet-USDC | [`0x5209865D404aA5646eDe5B91CD4218909eA72eDA`](https://mainnet.conet.network/token/0x5209865D404aA5646eDe5B91CD4218909eA72eDA) |
| wCNET | [`0x5a2D096968fC85861d8FDC7CE9A747Fe4bcb87D5`](https://mainnet.conet.network/token/0x5a2D096968fC85861d8FDC7CE9A747Fe4bcb87D5) |
| GBToken | [`0xC3EF02DaE632b4C10abB66e07d92a387c10838D8`](https://mainnet.conet.network/token/0xC3EF02DaE632b4C10abB66e07d92a387c10838D8) |

The Treasury controls explicit cross-chain route and canonical-asset policy. A foreign ERC-20 does not become canonical merely because it has been wrapped or assigned matching metadata. See [Decentralized cross-chain Treasury](cross-chain-treasury.md).

The [AAC settlement track](aac-cross-chain.md) specifies proof-driven movement for canonical USDC, **paid GB**, wCNET, and unbound developer ERC-20s. Its production read-only Shadow is deployed, but AAC custody is not. It does not permit free GB or a developer token bound to a GB exchange rate to cross. Miner completion reverts `VoteBridgeClosed`. Base → CoNET proofs need the EIP-2537 precompiles, which CoNET has run natively since Prague (2026-10-18).

CoNET-USDC uses 6 decimals. Issued-NFT social exchange payouts must use this
canonical token; the legacy USDC factory address
`0xfD0D7B0706AaB5E4351bcED37bC3C77ed6813907` is deprecated. In that exchange,
the user's AA burns Reward PT `#13`, while the merchant card escrow pays the
canonical USDC reward to the user's EOA.

**ConetGB1155 is deprecated.** It is a legacy accounting track and must not be used as the canonical GB wallet balance, transfer asset, or default integration target. New integrations should use the GBToken ERC-20 contract and 9-decimal precision.

**GB and conet-USDC design status.** The GBToken and conet-USDC contracts above are live production contracts, and this page describes them as they are. A proposed replacement design is described in the [GB token whitepaper (draft)](gb-whitepaper.md): paid GB issued only by burning conet-USDC, free GB that is consume-only and non-transferable, and conet-USDC deployed as a new contract with no admin or upgrade authority. That design is not deployed and is not approved by the DAO. Its deployment waits for design discussion and an independent audit. Market structure and treasury operations for that design are described in the [GB AMM whitepaper (draft)](gb-amm-whitepaper.md).

## Endpoint note

Read balances and token metadata from `https://rpc1.conet.network`, with `https://publicrpc.conet.network` as backup. `https://rpc.conet.network` is deprecated. The canonical Explorer is `https://mainnet.conet.network`.

## Source anchors

- [Resources](../resources.md) — official services and source references
- [Chain identity](chain-identity.md) — network identity and RPC authority
- [RPC and Explorer](rpc-explorer.md) — query guidance
- [Decentralized cross-chain Treasury](cross-chain-treasury.md) — route, quorum, and asset-admission boundary
- [AAC proof-driven cross-chain settlement](aac-cross-chain.md) — production read-only Shadow; Obstacles 1–5 Accepted (2026-10-14); custody still closed

## Next

[Decentralized cross-chain Treasury →](cross-chain-treasury.md)
