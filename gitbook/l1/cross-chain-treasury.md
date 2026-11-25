# Decentralized cross-chain Treasury

**Evidence level: historical and mixed.** This page preserves production references and dated operating records for the legacy `TreasuryBridgeV3` system. The current chain, bridge, asset and Shadow status was not re-read for this document. AAC custody and the hand-off from a bridged asset into CoNET-DLE are not authorized by this historical page. Read the [AAC whitepaper v1](aac-whitepaper.md) for the proposed successor design and its evidence boundary.

Public site: [https://gitbook.conet.network/l1/cross-chain-treasury.html](https://gitbook.conet.network/l1/cross-chain-treasury.html)

## Purpose

An ERC-20 issued on another chain is not automatically a CoNET asset. Its source-chain contract, supply, decimals, finality, and custody model all belong to a different trust domain.

The CoNET Treasury provides an explicit cross-chain boundary:

1. an approved route locks or burns value on the source chain;
2. a miner quorum attests one exact operation;
3. the destination Treasury mints or releases the configured asset representation once; and
4. CoNET applications use the resulting canonical CoNET ERC-20.

This separates asset custody and supply conservation from relaying. A relayer can carry evidence, but it does not receive an unrestricted right to mint.

## Historical production anchors

The cited deployment records identify **one** production Treasury at that evidence point: `TreasuryBridgeV3`. Older CREATE2 / `BaseTreasury` / `ConetTreasury` addresses were marked deprecated in those records. This paragraph is historical, not a current chain read.

| Component | Address | Role |
| --- | --- | --- |
| **TreasuryBridgeV3 proxy** | [`0xa208982212978550594A7FEEB70a61665d129003`](https://mainnet.conet.network/address/0xa208982212978550594A7FEEB70a61665d129003) | Sole Treasury in the cited deployment snapshot: route policy, quorum, mint, burn, lock, and release on CoNET and Base. The same historical record described cross-chain operation as paused; current status is unknown |
| **ConetTreasuryPeer v4** | [`0x6093871d8a3EE6EaADc9869451D1693973cFBCC0`](https://mainnet.conet.network/address/0x6093871d8a3EE6EaADc9869451D1693973cFBCC0) | Peer module for registered burn/mint and configured swaps — **not** a second Treasury |
| **conet-USDC** | [`0x5209865D404aA5646eDe5B91CD4218909eA72eDA`](https://mainnet.conet.network/token/0x5209865D404aA5646eDe5B91CD4218909eA72eDA) | Treasury-canonical six-decimal settlement asset. Status to be verified. It will be replaced by a newly deployed contract (decided, not yet live); the switch-over plan will be announced |
| **GBToken (`GB`)** | [`0xC3EF02DaE632b4C10abB66e07d92a387c10838D8`](https://mainnet.conet.network/token/0xC3EF02DaE632b4C10abB66e07d92a387c10838D8) | Nine-decimal DePIN service asset. The cited historical record said it was no longer recognised and services had stopped; current status is unknown |
| **Base USDC** | [`0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`](https://basescan.org/token/0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913) | Source-chain USDC identified in the cited LockMint and product top-up records; verify any current route before use |

The cited deployment/source records described `TreasuryBridgeV3` as an ERC-1967/UUPS proxy. Its stable address did not establish immutable logic: upgrade authority, miner-roster administration, route configuration, and token roles formed part of the historical trust and governance boundary.

The cited deployment records identify **Base (`chainId` 8453)** as the counterpart chain for a governed CoNET ↔ Base route on the same V3 Treasury, not a permissionless bridge or a second Treasury contract. Those records reported `ConetTreasuryPeer` bytecode at the CoNET address above; they did not establish a matching Base deployment. Re-read code on the target chain before relying on either statement.

**Historical status recorded in October 2026:** the Treasury cross-chain bridge was recorded as paused and GBToken as no longer recognised. Those states have not been re-read. The planned conet-USDC replacement is a design decision, not a deployed migration. The remainder of this page records historical route descriptions.

**Next-generation treasury (decided, not yet live).** The next treasury will be deployed by the fixed AAC factory during initialisation, at a fixed address with no proxy and no upgrade function. Its key authorisations are frozen when initialisation completes. A later generation will be a new deployment, moved to by DAO decision. No address exists yet, and deployment still needs an independent audit and a separate approval. The previous CoNET and Base treasuries will not be used by the new system, and support for new inflows through this bridge will stop (decided, not yet live). See [DAO and the next-generation treasury](dao-treasury.md) and [Two-way AAC bridge](aac-two-way-bridge.md#deployment-and-upgrades-approved-not-yet-live).

**GB and conet-USDC design status.** The contracts in the table above were recorded as deployed at the cited evidence point; their current code and status have not been re-read. The [GB token whitepaper (draft)](gb-whitepaper.md) proposes a replacement design for paid GB and for conet-USDC. That design was not deployed in the cited records, and it did not change the historical routes described on this page.

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

## Historical AAC read-only Shadow record

[AAC proof-driven settlement](aac-cross-chain.md) is the proposed deterministic successor to per-operation miner votes. It separates source inclusion, source-header authenticity, finality, route constraints, and destination replay protection.

Historical records dated October 2026 describe `bridge-aac-v0.33.13` as a read-only Shadow and record its reader and stability checks. Those records are retained in [AAC proof-driven settlement](aac-cross-chain.md); they are not a current service readback. Current process, reader, route and custody state are **unknown** unless verified from a fresh authorized source.

The historical receipt described an observer-only path, not a custody cutover. Its status fields must not be read as current. No new AAC mint, release, or miner-vote state is asserted here. The following bullets summarize the dated evidence:

- a miner vote is not described as a Merkle or finality proof;
- `isReserved` does not replace source locking or burning;
- A 2026-10-15 readback recorded `voteBridgeOperation`, `executeMint`, and `executeRelease` reverting `VoteBridgeClosed`; it also recorded paid-GB `voteBridgeMint` as paused, `sourceInitiateOpen` as true on Base and CoNET, and the listed Base route switches as open. These are dated historical values, not current state. An October 2026 receipt recorded a 0.01 Base USDC canary covered by [patch-geth](https://github.com/CoNET-project/patch-geth) and settled as canonical CoNET-USDC;
- The historical route description additionally covered paid GB and unbound developer-token burn/mint routes, while excluding free GB and GB-bound developer tokens; current route configuration is unknown.

## Onboarding an ERC-20 from another chain

The architecture can admit ERC-20s from supported chains, but admission is **policy-driven, not automatic**, and **not permissionless**. A caller-supplied token address does not create a route. The historical product-path records named pre-registered assets such as Base USDC, conet-USDC, GB, and B-Unit. A route needs all of the following:

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

**At the evidence date of this page, this DLE transition had not been verified live; current status is unknown.** Bridging into CoNET L1 does not by itself create an asset tip, activate L2 backing, or prove that the required pool, oracle, gateway, archive, and economic release gates have passed.

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

Treasury primitives identified in historical deployment records were necessary but not sufficient for production DLE asset ingress. The DLE specification additionally requires a dedicated `AssetBurnMintGateway`, replacement-capacity reservation, pending-burn activation or refund, normal and challenged exits, cumulative conservation accounting, and formal release gates.

See [Cross-chain assets in CoNET-DLE](../l2/cross-chain-assets.md) for that second boundary.

## Source anchors

- Explorer [`TreasuryBridgeV3`](https://mainnet.conet.network/address/0xa208982212978550594A7FEEB70a61665d129003) — sole upgradeable Treasury (`0xa208…`); older Treasury addresses are deprecated
- [beamio-APP/BeamioContract](https://github.com/beamio-APP/BeamioContract) snapshot — `src/b-unit/TreasuryBridgeV3.sol`, `src/b-unit/ConetTreasuryPeer.sol`; re-read code and proxy implementation at the target block before reporting the current deployment
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
