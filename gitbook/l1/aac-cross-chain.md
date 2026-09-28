# AAC proof-driven cross-chain settlement

**Evidence level: mixed.** The `bridgeAAC` repository contains the AAC reference state machine and a production **read-only Shadow observer**. Shadow `v0.28.0` is deployed, but it is **not** a Base or CoNET light client, controls no custody, emits no settlement transaction, and has not replaced the live miner-vote bridge.

Source: [CoNET-project/bridgeAAC](https://github.com/CoNET-project/bridgeAAC)

## Purpose

Atomic Asset Container (AAC) is the proposed deterministic replacement for per-deposit miner voting. A source chain locks or burns an asset. A destination contract accepts that fact only after it verifies:

1. the deposit or burn is included under a source-state commitment;
2. the commitment belongs to the intended source chain and gateway;
3. the source header is final under that chain's consensus rules;
4. the asset, amount, recipient, route, nonce, and domain match; and
5. the source deposit has not already been consumed.

A relayer may submit a proof, but it cannot choose the amount or receive an unrestricted mint role.

## Deterministic state machine

```text
source lock or burn
        │
        ▼
submit inclusion + finality proof
        │
        ▼
VERIFIED → RESERVED → MINTED
                    └→ RELEASED
```

`isReserved(aacId)` is true only in `RESERVED`. It prevents two destination executions from consuming the same source deposit. It does not replace source custody, prove that a submitted header is real, or prove source-chain finality.

The AAC key commits to the source chain, source gateway, source deposit ID, and target domain. Its stored payload also binds the source and destination assets, amount, recipient, and asset class. Terminal states are irreversible.

## CoNET and Base responsibilities

The same contract address on two chains does not imply shared storage. Each source-side contract locks or burns locally; the destination-side contract verifies and consumes its own AAC.

| Asset route | Source action | Destination AAC action |
| --- | --- | --- |
| Base Circle USDC → CoNET | Base `TreasuryBridgeV3` locks Circle USDC | CoNET `TreasuryBridgeV3` mints canonical `conet-USDC` |
| CoNET USDC → Base | CoNET `TreasuryBridgeV3` burns canonical `conet-USDC` | Base `TreasuryBridgeV3` releases Circle USDC from its balance |
| Paid GB, either direction | Source GB contract burns paid GB | Destination GB contract mints the same amount into the paid pool |
| Unbound developer ERC-20, either direction | Source Peer v5 burns the token | Destination Peer v5 mints the same token address |

Free GB cannot cross. A developer token bound to a GB exchange rate cannot transfer or cross, so it has no AAC. GB/USDC rate voting and the CNET voter threshold are parameter governance on CoNET Peer v5, not remote-state proofs.

## Contract boundaries

The intended adapters are:

| Component | Address or status |
| --- | --- |
| TreasuryBridgeV3 on CoNET and Base | `0xa208982212978550594A7FEEB70a61665d129003` |
| Canonical CoNET USDC | `0x5209865D404aA5646eDe5B91CD4218909eA72eDA` |
| Base Circle USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| GB token | `0xC3EF02DaE632b4C10abB66e07d92a387c10838D8` |
| Peer v5 predicted CREATE2 address | `0x1DF0F1826e9085caDB2bDc927A117140FAb39066` — design / local implementation, not a verified production deployment |

The deprecated Treasury at `0xa311c8fBE7CafC611603Ee925465A62493B73B30` is not an AAC gateway.

## Proof boundary

A Merkle inclusion path proves only that a leaf belongs to a supplied root. It does not prove that the root belongs to a real, final source block.

- **Base → CoNET** needs an audited OP Stack finality adapter that validates the relevant Base output rather than trusting a relayer-supplied L2 header.
- **CoNET → Base** needs an audited CoNET consensus/finality adapter. Ethereum does not automatically publish CoNET headers for Base to consume.
- A message bus, event log, miner signature, or HTTP success response is not a substitute for either verifier.

The Rust project deliberately exposes a `FinalityVerifier` interface. Its execution-client adapters and `MockFinality` are explicitly not light clients. Execution tags, an Ethereum receipt proof, and agreement between two RPC readers do not by themselves verify an OP Stack output/fault-proof result or CONET consensus signatures.

## Production read-only Shadow

Release `bridge-aac-v0.28.0` runs the production read-only Shadow on
`38.102.126.30` as `bridge-aac-shadow-prod.service`. Its production readers are:

- Base: independent execution clients on `.30:8547` and `.58:8547`;
- CONET: the local `.30:8889` archive and the
  `publicrpc.conet.network` archive cluster.

For each scanned block, both readers must agree on the block hash, state root,
and receipts root. The scanner advances only to the lower finalized reader
height, starts at an immutable deployment floor, persists its cursor, and pages
on reader or cursor lag. It verifies real receipt inclusion and records legacy
bridge observations, but never reserves, mints, releases, or broadcasts.

Both chains completed the production gate: lower-head cursor lag stayed within
64 blocks for a 256-block hold and ended at `cursor-lag 0` / `stable yes`.
Reader divergence is not hidden: a final Base sample had `reader-lag 177` and
correctly kept `page open` / `alert reader-lag`.

Every production report keeps the following boundary:

```text
shadow yes
broadcast no
settled no
custody closed
light-client no
registry paused
consume denied
```

## Custody remains closed

Production Shadow approval is not approval of decentralized burn/mint custody.
The following gates remain:

1. verify Base finality from Ethereum L1 output/fault-proof evidence.
   `base-l1-output` only reads the OptimismPortal anchor and
   `isGameClaimValid`. While the Base execution `finalized` tag is ahead of
   that anchor, the report stays `covered no`. This command does not replay
   the fault proof and does not feed the production shadow decision;
2. verify CONET finality from consensus signatures against an independently
   trusted committee. `conet-consensus` compares the beacon finalized
   execution payload with the execution client's `finalized` tag and checks
   the sync-committee aggregate with FastAggregateVerify against the committee
   at the parent slot. A match prints `aggregate-verify yes`,
   `committee-state parent-slot`, and `signature-check yes`. `sync-quorum yes`
   requires two-thirds participation.    The report still prints
   `trusted-committee no` and `custody-gate no`,
   because the committee came from that same beacon and the beacon does not
   serve a light-client update. The checkpoint is read from the head state.
   The checkpoint stored in the already-finalized state lags fork choice by
   about two epochs. `beacon-agreed` compares geth `finalized` with the head
   checkpoint payload only. `alias-matches-geth yes` does not make
   `beacon-agreed yes`. `state-root-binding yes` means the parent slot's
   beacon state hashes to the signed header's `state_root` and its sync
   committee verifies the aggregate. That state still comes from the same
   beacon, so `trusted-committee` stays `no`. `committee-handoff yes` means one
   earlier period's aggregate authenticated a state whose `next_sync_committee`
   matches the current committee. That earlier committee is still served by
   the same beacon. Production Shadow is `bridge-aac-v0.28.0`. It does
   not feed the production shadow decision;
3. deploy and audit the destination consume-once AAC contracts.
   `destination-consumer` only records PUSH4 selector presence for
   `aacConsumeMint`, `aacConsumeRelease`, `aacConsumeMintPaid`, and
   `aacConsumeMintDeveloper`. `selector-observation present` still prints
   `semantic-proof no`, `consume-once no`, `consumer observation-only`,
   `audit no`, and `custody-gate no`. A 4-byte collision is not treated as
   an entrypoint. This command does not deploy or call a consumer and does
   not feed the production shadow decision;
4. close the unrestricted paid-GB admin-mint path and the upgrade authority
   that could restore it. `gb-mint-authority` only reads GBToken
   `0xC3EF02DaE632b4C10abB66e07d92a387c10838D8`. `mint`, `mintPaid`, and
   `voteBridgeMint` are on that token. While those selectors remain, the
   report stays `admin-mint open`. If they disappear, the report is
   `selectors-absent yes`, `upgrade-authority unread`, and `mint-closed no`.
   This command does not send a mint or a vote and does not feed the
   production shadow decision;
5. complete end-to-end adversarial tests and an independent security audit; and
6. perform a separately approved miner-vote cutover.

Until those gates pass, production USDC remains on `TreasuryBridgeV3.voteBridgeOperation`, GB remains on its validator-vote path, and no documentation or UI should label those votes as AAC or Merkle proof verification.

## Related

- [Decentralized cross-chain Treasury](cross-chain-treasury.md)
- [Core L1 assets](assets.md)
- [Bring an ERC-20 into CoNET](../developers/l1-erc20-bridge.md)
- [Cross-chain assets in CoNET-DLE](../l2/cross-chain-assets.md)
