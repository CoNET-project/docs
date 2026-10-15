# AAC proof-driven cross-chain settlement

**Evidence level: mixed.** The `bridgeAAC` repository contains the AAC reference state machine and a production **read-only Shadow observer**. Shadow `v0.31.0` is deployed, but it is **not** a Base or CoNET light client, controls no custody, emits no settlement transaction, and has not replaced the live miner-vote bridge.

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

## Ethereum sync committee root for Base

**Evidence level: installed checkpoint.** Base proxy `0xcEE3D699df3df07a573f1aFf642888B97B7aA961` stores the period-`1883` committee for finalized beacon slot `15427520`. One two-thirds aggregate in that period verified under those keys. The proxy `headerFinal()` view stays false. This installation does not open custody.

New AAC proofs of Base finality use one Ethereum sync committee stored on Base. The first keys are the `current_sync_committee` of a finalized beacon block chosen at installation. They are not the committee initialized at the Altair fork. The historical 0.01 USDC lock is not a sample for this root. Altair handoff contracts already deployed from `bridgeAAC` stay historical records.

A sync-committee period is `8192` beacon slots, about `27.3` hours. On 2026-10-12 the signing period was `1882`, covering slots `15417344` through `15425535`. An installation after that date uses the period that is current at installation.

Installing the root requires all of the following:

1. A finalized beacon block. The stored keys are the sync committee that signs slots in that block's period, proven by a Merkle branch into its beacon `state_root`. The stored digest is `keccak256` of the compressed keys.
2. The same beacon block root present in the Ethereum EIP-4788 beacon-roots contract `0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02`, with an account proof for that execution header. This shows the execution layer recorded the root. It does not by itself prove beacon finality.
3. More than one CoNET observer recomputes that digest from the state proof. The installation record names the observers. One beacon endpoint is not an observer set. Observers agree only on this first root.
4. After the digest is stored, one sync aggregate from a block in the same period verifies under those keys with at least two-thirds participation. If it fails, the root is rejected.

A Base output root is a commitment to Base execution state, the message-passer storage root, and a Base block hash. It does not contain the 512 committee keys. Base follows Ethereum, so a matching L1 origin does not choose the Ethereum committee.

After installation, Base accepts a committee update only when the stored committee signs the next period, at least two thirds participate, and the update advances exactly one period. An aggregate below two thirds does not rotate the keys. Pairing runs on Base through EIP-2537 precompiles `0x0b` through `0x11`. CoNET execution of those addresses returns an empty result, so CoNET does not host this pairing.

A new lock is eligible only when its beacon slot is in a period the stored committee signs, and only after a finalized beacon header is at least that late. Finality lags by about two epochs. Receipts under one finalized header share that one BLS verification. Each receipt still needs its own inclusion proof and can be consumed once. `headerFinal` in that combined proof means final relative to the installed checkpoint, not final by a chain of signatures back to Altair.

At the gas price measured on Base on 2026-10-12, one rotation cost about `0.000069` ETH (`11,481,348` gas at `0.006` gwei). About `321` rotations fit in a year, about `0.022` ETH at that price. One Base transaction cannot hold two such pairings: the transaction gas cap is `16,777,216`, and one rotation already uses about `11.5` million gas. Skipping the Altair replay removes the historical rotations. It does not remove rotations after the checkpoint.

The checkpoint aggregate has succeeded. Obstacles **1–5 are Accepted** (2026-10-14). Production settlement still stays on miner votes: custody, mint, release, and miner-vote cutover remain closed until independent audit and a separate cutover. Engineering assurance after those gates (Rust tests + fail-closed smoke **PASS**; independent audit **PENDING**): [`PRODUCTION-ASSURANCE.md`](https://github.com/CoNET-project/bridgeAAC/blob/main/docs/PRODUCTION-ASSURANCE.md). Cutover Phase A read-only preflight is **recorded** (2026-10-15; AAC proxy still closed; GB `admins(proxy)` false on CoNET and Base); Phases B–D remain **not executed**: [`CUTOVER-CUSTODY.md`](https://github.com/CoNET-project/bridgeAAC/blob/main/docs/CUTOVER-CUSTODY.md). Shadow remains read-only.

## Production read-only Shadow

Release `bridge-aac-v0.31.0` runs the production read-only Shadow on
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

## Production deployment acceptance

**Status (2026-10-14): Obstacles 1–5 are Accepted.** Custody stays closed:
`custodyOpen()` / `headerFinal()` remain false; no-arg `settle()` still
reverts `CustodyClosed`. Role grants, independent audit, and the miner-vote
cutover are later transactions. The historical Altair committee store and the
0.01 USDC lock in Base block `52497860` do not pass any of these obstacles.
Full gate evidence: [`bridgeAAC` PRODUCTION-CUSTODY-GATES](https://github.com/CoNET-project/bridgeAAC/blob/main/docs/PRODUCTION-CUSTODY-GATES.md).
Assurance package: [`PRODUCTION-ASSURANCE`](https://github.com/CoNET-project/bridgeAAC/blob/main/docs/PRODUCTION-ASSURANCE.md).
Cutover Phase A preflight **recorded** (2026-10-15); Phases B–D **not executed**: [`CUTOVER-CUSTODY`](https://github.com/CoNET-project/bridgeAAC/blob/main/docs/CUTOVER-CUSTODY.md).

| Order | Deployment | Accepted address / evidence |
| --- | --- | --- |
| 1 | New Base checkpoint-root store | Proxy `0xcEE3D699df3df07a573f1aFf642888B97B7aA961` — period-`1883` keys; one two-thirds aggregate verified |
| 2 | One new AAC message | Cover `0x01506527a4Dab14141038Db15f5341dcF4729233` — new 0.01 USDC lock in Base block `52583500`; finalized beacon slot `15427680` + receipt in one call |
| 3 | CoNET-source finality, on the destination | Proxy `0xE4f6c834eb63f726cbE65b4F864620e4a6F7a6c9` — `proveAggregate` on Base |
| 4 | New consume-once consumer | Proxy `0xC6CBcC0c629ac1A80DB95e8b80927e713E82Cf4F` — second consume reverts; not the paused canary / `0xA13843C75f68F726e1DC4dbA75d07597EE18d999` |
| 5 | Upgrade Base proxy `0x9051e08aBA3EC1A1323f36f0F5c3745C81912aAd` | Impl `0x3085216E8329eF7d10c914cB1C43Cd8168f53442` — cover overloads accept Obstacle 2 sample; no-arg `settle()` still `CustodyClosed` |

A Base-origin message uses obstacles 1, 2, 4, and 5. A CoNET-origin message uses obstacles 3, 4, and 5. An execution `finalized` tag, a parent-hash walk, an output root, a same-block bootstrap, a beacon API `finalized` flag, and `isGameClaimValid` by `eth_call` do not pass obstacle 1 or 2.

## Custody remains closed

Obstacles 1–5 Accepted does **not** open decentralized burn/mint custody.
Production Shadow approval is not a cutover. The Shadow commands below are
observers. Mint, release, settlement broadcasting, Treasury / GB role grants,
and miner-vote cutover stay closed until an independent audit and a separate
cutover (see [`CUTOVER-CUSTODY`](https://github.com/CoNET-project/bridgeAAC/blob/main/docs/CUTOVER-CUSTODY.md);
engineering assurance in [`PRODUCTION-ASSURANCE`](https://github.com/CoNET-project/bridgeAAC/blob/main/docs/PRODUCTION-ASSURANCE.md)).

1. `base-l1-output` only reads the OptimismPortal anchor and
   `isGameClaimValid`. While the Base execution `finalized` tag is ahead of
   that anchor, the report stays `covered no`. This command does not replay
   the fault proof, does not install the checkpoint root, and does not feed
   the production shadow decision;
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
   beacon, so `trusted-committee` stays `no`. `committee-handoff yes` and
   `handoff-periods` count how many earlier periods authenticate the next
   committee. A read that linked four periods, back to epoch 47358, still
   used this same beacon. `genesis-pin yes` means the genesis beacon state
   hashes to its header and its validators root is the published CoNET pin.
   The handoff chain has not reached that genesis committee, so
   `trusted-committee` stays `no`. `forward-committee` starts at that same
   genesis pin and accepts the next period only from a supermajority signature
   by the committee already trusted for the current period.    A period without a two-thirds aggregate still advances by its best valid
   signature after the period timeout. Eight such steps were required. The
   chain then reached beacon head period 189, and the stored committee's
   finalized execution hash matched geth. `trusted-committee` stays `no`
   because those eight steps were not a supermajority. `0.33.0`
   `weak-subjectivity` does not invent those missing supermajorities. It froze
   a period-18 candidate at slot 155646 and checked the next-sync-committee
   branch and the finalized-root branch against that state root. A second
   beacon returned the same state root. Three other full nodes, at
   `216.225.202.22`, `216.225.197.3`, and `216.225.202.82`, recomputed that
   same header from their own beacons. The checkpoint now has three
   confirmations and `safety weak-subjectivity-trusted`. Those nodes share
   one operator and one consensus client, so `trusted-committee` stays `no`.
   Stock Lighthouse v5.3.0 and v8.2.2 hash a CoNET checkpoint with the mainnet
   eth1 vote limit and stop on a different block root. On `70.35.205.77`, a
   Lighthouse v5.3.0 build with a 4-epoch eth1 voting period recomputed slot
   155646 from hub SSZ: block root `0x442a5f8c…91336` and state root
   `0x70001a2f…1410`. That host runs its own geth and does not use a production
   Engine API. The operator is still the same, and periods 18 through 189 are
   not replayed into the weak-subjectivity store, so `trusted-committee` stays
   `no`. This check does not feed the production shadow decision. Production
   Shadow remains `bridge-aac-v0.31.0`. An operator who does not administer
   these hosts follows
   [Confirm the period-18 checkpoint](../developers/l1-independent-confirmation.md).
3. deploy and audit the destination consume-once AAC contracts.
   `destination-consumer` only records PUSH4 selector presence for
   `aacConsumeMint`, `aacConsumeRelease`, `aacConsumeMintPaid`, and
   `aacConsumeMintDeveloper`. `selector-observation present` still prints
   `semantic-proof no`, `consume-once no`, `consumer observation-only`,
   `audit no`, and `custody-gate no`. A 4-byte collision is not treated as
   an entrypoint. This command does not deploy or call a consumer and does
   not feed the production shadow decision. A separate specification
   consumer, proxy `0xA13843C75f68F726e1DC4dbA75d07597EE18d999` on CoNET,
   records consume ids only. It is compiled with `bytecodeHash: ipfs`, and
   Blockscout reports `is_fully_verified` for the proxy, both implementations,
   the rejected reorder implementation, the gateway, and the revert effect.
   An earlier `bytecodeHash: none` deployment stayed partial and is superseded.
   Mainnet transactions rejected a second consume, a reentrant consume, a
   failed effect, and a reordered upgrade, and an append-only upgrade kept
   the consumed id. It does not mint or release.
   Independent audit is still absent, so `consume-once` and custody gate 3
   stay closed;
4. close the unrestricted paid-GB admin-mint path and the upgrade authority
   that could restore it. `gb-mint-authority` only reads GBToken
   `0xC3EF02DaE632b4C10abB66e07d92a387c10838D8`. `mint`, `mintPaid`, and
   `voteBridgeMint` are on that token. While those selectors remain, the
   report stays `admin-mint open`. If they disappear, the report is
   `selectors-absent yes`, `upgrade-authority unread`, and `mint-closed no`.
   This command does not send a mint or a vote and does not feed the
   production shadow decision;
5. complete end-to-end adversarial tests and an independent security audit
   ([`PRODUCTION-ASSURANCE`](https://github.com/CoNET-project/bridgeAAC/blob/main/docs/PRODUCTION-ASSURANCE.md):
   local tests and Base fail-closed smoke **PASS**; independent audit **PENDING**); and
6. perform a separately approved miner-vote cutover
   ([`CUTOVER-CUSTODY`](https://github.com/CoNET-project/bridgeAAC/blob/main/docs/CUTOVER-CUSTODY.md):
   Phase A **recorded**; Phases B–D **not executed**).

Until those gates pass, production USDC remains on `TreasuryBridgeV3.voteBridgeOperation`, GB remains on its validator-vote path, and no documentation or UI should label those votes as AAC or Merkle proof verification.

## Related

- [Decentralized cross-chain Treasury](cross-chain-treasury.md)
- [Core L1 assets](assets.md)
- [Bring an ERC-20 into CoNET](../developers/l1-erc20-bridge.md)
- [Cross-chain assets in CoNET-DLE](../l2/cross-chain-assets.md)
