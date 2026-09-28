# Decentralized cross-chain Treasury

**Evidence level: mixed.** The deployed `TreasuryBridgeV3` proxy and its canonical CoNET assets are production references. The bridge policy, quorum, and replay controls are implemented capabilities. The AAC read-only Shadow is production-approved, but AAC custody and the hand-off from a bridged asset into CoNET-DLE remain closed.

Public site: [https://gitbook.conet.network/l1/cross-chain-treasury.html](https://gitbook.conet.network/l1/cross-chain-treasury.html)

## Purpose

An ERC-20 issued on another chain is not automatically a CoNET asset. Its source-chain contract, supply, decimals, finality, and custody model all belong to a different trust domain.

The CoNET Treasury provides an explicit cross-chain boundary:

1. an approved route locks or burns value on the source chain;
2. a miner quorum attests one exact operation;
3. the destination Treasury mints or releases the configured asset representation once; and
4. CoNET applications use the resulting canonical CoNET ERC-20.

This separates asset custody and supply conservation from relaying. A relayer can carry evidence, but it does not receive an unrestricted right to mint.

## Production anchors

There is **one** production Treasury: `TreasuryBridgeV3`. Older CREATE2 / `BaseTreasury` / `ConetTreasury` addresses are deprecated and must not be documented as a second Treasury.

| Component | Address | Role |
| --- | --- | --- |
| **TreasuryBridgeV3 proxy** | [`0xa208982212978550594A7FEEB70a61665d129003`](https://mainnet.conet.network/address/0xa208982212978550594A7FEEB70a61665d129003) | Sole Treasury: route policy, quorum, mint, burn, lock, and release on CoNET and Base |
| **ConetTreasuryPeer v4** | [`0x6093871d8a3EE6EaADc9869451D1693973cFBCC0`](https://mainnet.conet.network/address/0x6093871d8a3EE6EaADc9869451D1693973cFBCC0) | Peer module for registered burn/mint and configured swaps — **not** a second Treasury |
| **conet-USDC** | [`0x5209865D404aA5646eDe5B91CD4218909eA72eDA`](https://mainnet.conet.network/token/0x5209865D404aA5646eDe5B91CD4218909eA72eDA) | Treasury-canonical six-decimal settlement asset |
| **GBToken (`GB`)** | [`0xC3EF02DaE632b4C10abB66e07d92a387c10838D8`](https://mainnet.conet.network/token/0xC3EF02DaE632b4C10abB66e07d92a387c10838D8) | Active nine-decimal DePIN service asset |
| **Base USDC** | [`0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`](https://basescan.org/token/0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913) | Current source-chain USDC for LockMint and product top-up paths |

`TreasuryBridgeV3` is an ERC-1967/UUPS proxy. Its stable address does not imply immutable logic: upgrade authority, miner-roster administration, route configuration, and token roles remain part of the trust and governance boundary.

The current production counterpart chain is **Base (`chainId` 8453)**. That is a governed CoNET ↔ Base route on the **same** V3 Treasury, not a permissionless bridge and not a second Treasury contract. `ConetTreasuryPeer` bytecode is present on CoNET L1 at the address above; do not assume the same Peer address is deployed on Base without checking `eth_getCode`.

## Three explicit route modes

Every route binds the source chain, source Treasury, source asset, destination asset, mode, decimals, enabled state, and policy version.

| Mode | Source-side action | Destination-side action | Typical use |
| --- | --- | --- | --- |
| **BurnMint** | Burn an authorized source representation | Mint the configured destination representation | Canonical assets whose supply can be reduced on the source chain |
| **LockMint** | Lock the source asset in Treasury custody | Mint a representation on the destination chain | Foreign assets that cannot be burned by the bridge |
| **BurnRelease** | Burn the destination representation | Release previously locked source assets | Reverse leg of a lock-and-mint route |

A token address supplied by a caller does not create a route. The route must already be configured and enabled, and the Treasury must hold the required mint, burn, or custody authority.

## Miner-governed operation flow

```text
user-authorized source operation
        │
        ▼
configured Treasury route
        │  emits one operationId-bound payload
        ▼
independent source observation
        │
        ▼
destination miner votes / sorted attestations
        │  threshold = ceil(2N / 3)
        ▼
execute exactly once
        │
        ├── mint configured destination asset
        └── or release configured reserve
```

The operation identity commits to the source and destination chains, Treasuries and assets, route mode, beneficiaries, exact amounts, source transaction hash, nonce, fee, and optional callback. The destination contract:

- rejects a route that is not enabled;
- rejects conflicting payloads for the same operation;
- accepts at most one vote per miner;
- requires the configured quorum;
- verifies that beneficiary amounts sum to the gross amount; and
- consumes `operationExecuted[operationId]` before distribution, preventing replay.

These controls decentralize authorization across the configured miner set. They do not prove that every miner is operationally independent, that source-chain finality cannot reorganize, or that governance and upgrade keys cannot be compromised.

## AAC read-only production Shadow

[AAC proof-driven settlement](aac-cross-chain.md) is the proposed deterministic successor to per-operation miner votes. It separates source inclusion, source-header authenticity, finality, route constraints, and destination replay protection.

`bridge-aac-v0.16.0` now runs a production read-only Shadow on `.30`. It scans
two independent Base readers and two CONET reader paths, agrees block hash,
state root, and receipts root at the lower finalized height, verifies receipt
inclusion, persists its cursor, and pages on divergence. Both chains completed
the required 256-block lower-head stability hold.

This is operational evidence for the observer, not a custody cutover. The
Shadow reports `broadcast no`, `settled no`, `custody closed`, and
`light-client no`. It does not verify Base Ethereum-L1 output/fault-proof
finality or CONET consensus signatures. Therefore:

- a miner vote is not described as a Merkle or finality proof;
- `isReserved` does not replace source locking or burning;
- live `voteBridgeOperation` and GB validator voting remain active until an audited adapter and explicit cutover exist; and
- AAC additionally covers paid GB and unbound developer-token burn/mint routes, while free GB and GB-bound developer tokens remain non-bridgeable.

## Onboarding an ERC-20 from another chain

The architecture can admit ERC-20s from supported chains, but admission is **policy-driven, not automatic**, and **not permissionless**. A caller-supplied token address does not create a route. Current product paths use pre-registered assets such as Base USDC, conet-USDC, GB, and B-Unit. A route needs all of the following:

1. **Source identity** — exact source `chainId`, token contract, decimals, and finality policy.
2. **Custody mode** — `LockMint`, `BurnMint`, and any reverse `BurnRelease` path must conserve exact raw token units.
3. **Canonical CoNET representation** — a stable CoNET token address with bounded mint/burn roles and a documented upgrade policy.
4. **Treasury policy** — the exact route and version must be approved and enabled by the configured governance path.
5. **Replay domain** — operation IDs, nonces, source transaction hashes, and destination execution state must be unique.
6. **Relayer and miner availability** — enough independent observers must verify source finality and reach destination quorum.
7. **Exit capacity** — a lock route must retain reserves; a burn/mint route must preserve replacement authority and supply accounting.
8. **Application admission** — wallets, explorers, indexers, and applications must recognize the canonical CoNET address rather than the foreign address.

Until those conditions are met, “bridging any ERC-20 to CoNET” is not a safe or supported operation.

## From a bridged ERC-20 to CoNET-DLE

The intended user journey is:

```text
ERC-20 on a supported external chain
        │
        │ configured Treasury operation
        ▼
Treasury-canonical ERC-20 on CoNET L1
        │
        ├── usable by enabled CoNET L1 applications
        │
        └── optional DLE admission
                 │ exact proxy/version
                 │ approved pool + TWAP adapter
                 │ minimum liquidity + fresh quote
                 │ AssetAdmissionRegistry = ACTIVE
                 │ AssetBurnMintGateway safety gates
                 ▼
          parallel DLE asset tips
```

The first transition is a cross-chain Treasury operation. The second is a separate L1-to-L2 admission and burn/activation protocol. They use different operation IDs, fees, finality rules, and failure recovery.

Once a CoNET representation has passed the future DLE admission gates, the target architecture can give it access to:

- event-driven asset ledgers that progress independently;
- parallel capacity across archive shards rather than one global application queue;
- value-bounded asset tips with a frozen 100-USDC-equivalent per-tip safety ceiling;
- wallet-addressed L0 coordination for private order and notification traffic; and
- class-specific settlement, including future miner-assisted markets.

**This DLE transition is not live today.** Bridging into CoNET L1 does not by itself create an asset tip, activate L2 backing, or prove that the required pool, oracle, gateway, archive, and economic release gates have passed.

## Security boundary

| Risk | Required control |
| --- | --- |
| Unauthorized mint | Explicit route policy, bounded token roles, quorum verification, and single-use operation IDs |
| Double execution | Destination replay protection and payload-hash equality |
| Source-chain reorganization | Route-specific finality depth before miner attestation |
| Reserve shortfall | Verifiable locked reserves or replacement-capacity accounting |
| Decimal or asset mismatch | Exact raw-unit accounting and route-bound source/destination addresses |
| Miner collusion or censorship | Independent operators, transparent roster and quorum, monitoring, dispute and recovery procedures |
| Upgrade or owner compromise | Governed upgrades, delayed administration, key isolation, public verification, and emergency controls |
| Oracle or liquidity failure | No DLE admission without a versioned pool/TWAP adapter, minimum liquidity, and fresh observations |

No bridge can remove all cross-chain trust. CoNET's design makes route authority, operation data, quorum, and replay state explicit so they can be verified and constrained.

## DLE maturity boundary

The deployed Treasury primitives are necessary but not sufficient for production DLE asset ingress. The DLE specification additionally requires a dedicated `AssetBurnMintGateway`, replacement-capacity reservation, pending-burn activation or refund, normal and challenged exits, cumulative conservation accounting, and formal release gates.

See [Cross-chain assets in CoNET-DLE](../l2/cross-chain-assets.md) for that second boundary.

## Source anchors

- Explorer [`TreasuryBridgeV3`](https://mainnet.conet.network/address/0xa208982212978550594A7FEEB70a61665d129003) — sole upgradeable Treasury (`0xa208…`); older Treasury addresses are deprecated
- [beamio-APP/BeamioContract](https://github.com/beamio-APP/BeamioContract) snapshot — `src/b-unit/TreasuryBridgeV3.sol`, `src/b-unit/ConetTreasuryPeer.sol`; treat Explorer-verified bytecode as current
- [settleonbase/x402sdk](https://github.com/settleonbase/x402sdk) — `CONET_TREASURY` / `CONET_TREASURY_BRIDGE_V3` (`0xa208…`); `CONET_TREASURY_CREATE2` / `BASE_TREASURY` (`0xa311…`) are deprecated
- [CoNET-DLE whitepaper](https://github.com/CoNET-project/CoNET-DLE/blob/main/src/whitepaper/Decentralization%20Cluster%20multi-chain.md), §4.6 — external-chain to Treasury to DLE responsibility split
- [DLE-AssetBurnMintGateway-Invariant-Spec.md](https://github.com/CoNET-project/CoNET-DLE/blob/main/src/whitepaper/DLE-AssetBurnMintGateway-Invariant-Spec.md), §§1–3 — canonical-asset boundary and conservation rules

## Related

- [Bring an ERC-20 into CoNET](../developers/l1-erc20-bridge.md) — developer how-to
- [Core L1 assets](assets.md)
- [AAC proof-driven cross-chain settlement](aac-cross-chain.md)
- [Cross-chain assets in CoNET-DLE](../l2/cross-chain-assets.md)
- [Miner-matched order-book exchange](../applications/miner-orderbook-dex.md)
- [CoNET-DLE ledger classes](../l2/tip-classes.md)
- [Resources](../resources.md)
