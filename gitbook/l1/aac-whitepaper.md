# Atomic Asset Container (AAC): CoNET–Base USDC Bridge

**Whitepaper v1 — normative specification, 25 November 2026**

**Evidence status: design and historical/local evidence; not a deployment notice.**

## 1. Executive summary

The Atomic Asset Container (AAC) is the normative rule specification for the intended system moving assets between CoNET L1 and approved external chains. Version 1 centers on USDC between CoNET and Base. It defines deposits (Base to CoNET) and withdrawals (CoNET to Base), binds every operation to an order, recipient and amount, and makes replay prevention, limits, pause and recovery behavior explicit. The normative status records the adopted design decisions; it does not establish implementation acceptance, a deployment, or an enabled route.

The design has two distinct paths. Fast credit on a Base deposit is **disabled by default**. It may be enabled only after real sequencer signatures, positive and negative proof tests, a hard exposure cap, named risk ownership and independent acceptance are recorded for one candidate. A withdrawal burns the CoNET asset and releases Base USDC only after Base verifies the finalized CoNET burn and the matching order. The paths share governance and safety rules, but their proofs and source actions are not interchangeable. Neither path is enabled by this specification.

V1 deployment and custody opening are pending complete evidence, independent acceptance and separate release approval. Engineering remains paused until this whitepaper is signed off; implementation, acceptance and deployment are separate later gates. This paper specifies the intended v1 system; it does not claim a current deployment, operational service, custody opening or production end-to-end success. Current chain and service state was not independently re-read for this paper.

## 2. Status and evidence legend

Use these labels throughout:

- **Design decision** — an operator-level rule recorded for the proposed system. It is not a DAO vote, implementation proof or deployment approval.
- **Implemented locally; acceptance pending** — code or tests exist for a stated local candidate. This does not establish production behavior.
- **Tested locally (scope stated)** — a named local test path passed. The claim is limited to its exact candidate, fixtures and components.
- **Open / unknown** — no decision or sufficient evidence is available. Unknown must not be interpreted as zero, false, absent or safe.
- **Deployed** — reserved for a verified chain, address, code hash and same-block state read. This paper makes no new deployed claim.

Historical records and local test receipts are dated. They do not establish the current state of a service or chain. A successful component test is not an end-to-end bridge acceptance.

## 3. Scope, assets and authority

### 3.1 CoNET and Base USDC v1

The first official stablecoin route is the new conet-USDC ledger on CoNET paired with USDC on Base (chain ID 8453). The proposed v1 route has exactly one external chain. The existing CoNET conet-USDC contract is not upgraded; a new contract and a separately announced migration plan are required. No new AAC address is stated here. All asset-admission and treasury rules in this paper are normative specifications. This specification does not authorize enabling an AAC route or treasury capability; no implementation acceptance is claimed, and current live state is not asserted.

Base-side release for a withdrawal remains unavailable under v1 policy until a real finalized CoNET burn, its accepted order, recipient, amount and replay protection are verified on the same accepted candidate. The specification does not claim current live configuration.

The two directions are:

| Direction | User-facing name | Source action | Destination action |
|---|---|---|---|
| Base → CoNET | Deposit | Lock Base USDC in the designated AAC bridge and prove the lock receipt | Mint the same order's conet-USDC on CoNET after AAC checks |
| CoNET → Base | Withdrawal | Burn conet-USDC on CoNET and prove the finalized burn | Release the matching amount of Base USDC to the bound recipient |

“Deposit” and “withdrawal” are named from the CoNET user's perspective. A valid proof is bound to chain domains, asset addresses, order ID, recipient and exact amount. A proof for one direction cannot authorize the other.

### 3.2 Other asset classes

- **Other official stablecoins:** each admitted stablecoin has one external chain and its own fixed-template exchange entry. A stablecoin cannot enter from one external chain and leave through another.
- **GB and wCNET:** the proposed new assets originate on CoNET. An external mint requires a verified CoNET burn; a return mint on CoNET requires a verified burn on that external chain. Moving between two external chains therefore takes two steps through CoNET. Same-address deployment is a design requirement, not an established deployment fact.
- **Third-party cross-chain tokens:** admitted individually by DAO decision, with route-specific limits and proof requirements. Automatic deployment at the same address on a first transfer is design only and is not implemented.
- **Third-party stablecoins:** remain on CoNET; they have no external-chain route.

Asset admission does not grant an unlimited mint authority. The exact token, chain, decimals, route, roles, proof verifier and limits must be bound before a route can operate.

## 4. Orders, proof checks and replay safety

Every accepted transfer is an order with a unique identifier and a domain that includes source and destination chains, source and destination assets, amount, recipient and route. The destination must reject a mismatched order, wrong recipient, wrong amount, wrong asset, wrong chain, expired or invalid proof, and an order already completed or refunded.

Completion and refund are mutually exclusive terminal outcomes. A refund is allowed only after proof that the destination closed the order without delivery and the original deadline has expired. Once refunded, the order can never be delivered. If an unexpired order remains valid after a channel reopens, it may complete at most once. Closing a channel does not erase an in-flight order or reset its deadline.

The operator's acceptance rule for a withdrawal is stricter than observing a transaction or log: Base must verify CoNET's finalized burn proof and match the accepted order, recipient and amount, with replay protection. Historical scanning, archive downloads or reconstructing old state are not prerequisites for handling a newly accepted order. A query or proof failure is an unavailable/unknown result, never a successful zero or an empty business result.

### 4.1 Proof responsibilities

For a **deposit**, AAC verifies the authorized sequencer signature for its period, chain domain, signed-payload binding to the Base block header and `receiptsRoot`, the designated bridge's USDC lock receipt, order/recipient/amount, replay protection and limits. A sequencer signature establishes pre-confirmation, not Base finality.

For a **withdrawal**, the destination-side verifier must establish the finalized CoNET burn and bind it to the same order. The proof format, source finality policy, nonce scope, expiry and relay authorization remain open until frozen for the implementation.

Real CoNET headers and storage proofs have been exercised in local tests, but this does not prove the complete cross-chain path. The complete `AacResolutionExecutor.relayBridge` diagnostic recorded a local EDR transaction with status 0 and `NotFinal(bytes32)`; gas used was 16,178,615, balances and both replay states were unchanged, and the archived trace did not establish the inner cause. A separate local EDR Stage 2 test used synthetic consensus fields, a locally generated CoNET RLP header and slot-9 proof, a Base mock USDC and a test executor identity; it released once and rejected recipient substitution and replay. These are separate, limited observations. Neither is a real-chain end-to-end withdrawal acceptance.

## 5. Fast credit and L1 batch health

**Design decision:** fast credit is disabled by default. It is a conditional future path in which a deposit may be credited against Base sequencer pre-confirmation before Ethereum L1 inclusion; it is not proof that the Base batch is final. No fast credit may open until the candidate has real sequencer-signature evidence, positive and negative proof tests, a hard exposure cap, an identified risk owner and independent acceptance. The cap and allocation of risk remain open. The normative v1 rule is to refuse new fast deposits until all gates and a separate release decision are complete; this does not assert current live behavior. If L1 or RPC evidence is unavailable or unknown, that uncertainty blocks new unsafe minting; it is not evidence of a missed batch window.

A batch included within its expected window keeps the path healthy even if its proof or relay reaches CoNET late. Only trusted L1 evidence that no valid batch was included in **two consecutive expected windows** triggers a latched stop of both directions. RPC failure, missing relayer messages or silence alone is not evidence that no batch was included.

This rule depends on a trusted Ethereum L1 header source, specified as a sync-committee light client. Its checkpoint is installed by DAO vote; a checkpoint root is not upgraded in place. A defect requires a new deployment and a new DAO-approved checkpoint. Normal operation must verify/store finalized headers and committee handovers without periodic DAO renewal. Light-client liveness and trusted-header verification are not accepted production capabilities in the evidence cited here.

The time between the last confirmed L1 inclusion and a two-window stop is an exposure interval. About 30 minutes is an estimate in the historical design discussion, not a fixed maximum, hard limit or service-level commitment. The DAO-set windows determine the actual interval, and their values remain open.

## 6. Limits and circuit states

### 6.1 Per-asset limits

Each asset has separate limits and counters; assets do not share allowances. **5,000 per transaction** and **50,000 per fixed 1,200-second window** are design values only, not approved production parameters or live on-chain limits. Per-asset production values, units, between-batch caps and DAO configuration remain to be frozen. For one asset, inbound deposits and outbound withdrawals share that asset’s fixed-window allowance. This specification does not authorize a dependent path to open before its production parameters and acceptance are complete; current live state is not asserted. A separate per-asset cap is intended between consecutive confirmed Base batch inclusions on Ethereum L1; its production value remains open.

USDC is measured in USDC. GB and wCNET use a USDC-equivalent value; their price source is open. Third-party assets require an explicit unit and DAO-set limit. An asset with no configured limit starts at zero for cross-chain flow.

As normative behavior after a route is separately enabled, only an order for an admitted asset may enter the treasury hold path: an admitted inflow with no configured limit or above its limit is held without minting, and release requires a fresh limit check; release timing and conditions remain open. An order for a non-admitted asset is refused, not held. A fast USDC deposit above a limit or without a configured limit is refused, not held. Exhausting the between-batch allowance continues to block deposits across subsequent fixed 1,200-second windows until a new Base batch is confirmed on L1. The per-transaction, fixed-window and between-batch checks are cumulative, and deposits and withdrawals of the same asset share the fixed-window allowance. This specification does not authorize opening these paths before production values and route-specific acceptance are complete; current live state is not asserted.

### 6.2 L, U and S

The proposed states constrain fast, unsafe-preconfirmation minting. Any RPC, light-client or implementation status that cannot be verified is unknown and blocks new unsafe minting; it cannot be converted into a valid zero or a missed-window finding:

- **L — no positive inclusion proof:** limits new fast minting while there is no positive proof of Base batch inclusion. Withdrawals are not affected by L alone. Threshold K and the positive-batch proof format are open.
- **U — Base implementation unknown:** if the Base `SystemConfig` implementation changes, the verifier treats the state as unknown. A missed-window finding requires relevant Base key configuration to be known unchanged at both ends. Unknown state cannot prove a missed window and cannot trigger the breaker. If unknown lasts more than N windows of length W, state U applies; N and W are open. U alone does not trigger the breaker.
- **S — light client not live:** applies when the light client is absent, stopped or requires re-bootstrapping. New fast deposit confirmations are refused; earlier deferred deposits are not re-admitted or released. S alone does not trigger the breaker.

A confirmed two-consecutive-window miss is the distinct latched breaker condition and stops both directions. Once stopped, the bridge stays stopped until DAO reopening. Base recovery by itself does not reopen it. Reopening requires an executed DAO vote and Base recovery; there is no automatic grace period. Existing locks are reverified after reopening. A valid completion and a valid refund exclude one another.

### 6.3 DAO timing

The recorded design gives proposals a **600-second observation period** after voting opens, during which votes continue to be collected and no action executes early. The voting window remains **7 days**. These are operator-level design decisions and are not evidence of a live DAO configuration.

## 7. One-time factory binding and frozen authority

**Factory Option 2 is the normative v1 choice.** One fixed AAC factory performs one-time binding. The approved official template must be valid and bound; the Router must be installed and bound before the factory seals. The factory can no longer write to the Registry after sealing. The DAO retains the approved governance permissions over policy and route decisions among bound addresses; it cannot replace sealed code or addresses. The intended initialization binds the new conet-USDC ledger, deposit controller, withdrawal gateway, settlement contract, new GB and wCNET, treasury, route controllers and limit sources. The design has no proxy upgrade path; a later generation is a new deployment. Contract owner/admin roles, where present, belong to the governance contract rather than a personal wallet.

DAO route decisions may select only among addresses already bound by the factory; they cannot introduce a new controller or treasury. The DAO retains policy authority over asset admission, per-asset limits, channel switches, pause and reopening, but policy authority is not a power to replace sealed code or addresses.

**Implementation boundary:** Factory Option 2 is a normative design, not an accepted implementation. The exact ABI, constructor arguments, implementation, roles, template hash (`H`) and seal order remain open. Same-candidate positive and negative tests must prove that the template and Router are present before sealing, the factory cannot write the Registry after sealing, and governance retains only the intended permissions. DAO candidate `7994b6a` has a static A–G review only and does not contain a compatible factory binder. Historical binder `af162402` calls `initIntervalLimit`, which is absent from the Candidate 4 Registry ABI and is incompatible; these versions must not be combined as one deployable candidate. No factory or deployment is claimed by this paper. A separate recorded decision states that the Base lock fixes its route address at construction. The route binds the lock address once, and the lock address is part of the outflow domain.

Restoration of the legacy production oracle is a separate track; new AAC/DAO oracle features are deferred to the next version and are not a prerequisite for that restoration. V1 may leave the quote source open, but it must not enable routes that depend on an unfrozen quote source. This paper does not claim an oracle is live or restored.

## 8. GB, wCNET and third-party assets

The new GB and wCNET are intended to be CoNET-native assets with cross-chain representations controlled by AAC burn proofs. Their deployment parameters, metadata, price source, initial limits and final addresses remain unbound. Third-party asset admission and treasury behavior are normative design rules only. This paper does not authorize route enablement; implementation acceptance is pending and current live status is not asserted. The historical GB token at the legacy address is a separate asset and is not evidence of the new GB design being deployed.

A third-party token is admitted individually. The route must define its origin chain, source token, decimals, finality, custody mode, canonical CoNET representation, destination route, roles, limits, replay domain and application admission. A third-party stablecoin remains CoNET-only. Subscriptions and issuer payments are separate application rules and do not create cross-chain authority.

## 9. Fees

A CoNET-to-Base withdrawal is specified to have a DAO-set fee of **n%**, paid by the withdrawing user and accounted separately from the GB exchange fee. This specification sets no live fee or default. The fee base, currency, rounding and any refund fee remain open. Under the normative v1 policy, the withdrawal path cannot open until these parameters are frozen and the same candidate passes independent acceptance; current live behavior is not asserted. A local fee mechanism is not a live charge.

## 10. Implementation and release gates

Before any route is opened, the release must bind one exact source commit, toolchain, dependency lock, generated artifacts, constructor arguments, initialization order and chain-specific addresses. Independent review must cover the same candidate and artifacts. The acceptance program must include:

1. positive and negative proof vectors for both directions, including wrong recipient/amount/chain, forged signatures or headers, invalid receipts, replay and conflicting completion/refund;
2. for any fast-credit candidate, real sequencer-signature evidence, hard exposure-cap enforcement, named risk owner, and tests showing unknown RPC/L1 state blocks credit;
3. real source-finality evidence for the order being tested, with the destination receipt, balances and replay state captured at the same evidence boundary;
4. per-asset production limits, pause, two-window breaker and DAO recovery tests, with RPC errors kept distinct from valid empty/zero results;
5. Factory Option 2 ABI/constructor/role/template-hash compatibility and sealed-address verification for one exact candidate; and
6. a separately approved deployment and operational runbook.

Historical integration suite `18ea56a` recorded 1,440 passed, 7 pending and 0 failed. Candidate `e6380ec` has limited local source/build and component receipts. Neither is a complete current acceptance, deployment freeze or production authorization. The full relay diagnostic failed as described above. No amount of a local pass changes the deployment gate.

## 11. History and current-state boundary

The older proof-driven AAC design, its October 2026 read-only Shadow observations, miner-vote shutdown records and the historical 0.01 Base USDC canary are retained in [the earlier AAC record](aac-cross-chain.md) and [the legacy Treasury history](cross-chain-treasury.md). They are dated historical evidence. They do not establish that the Shadow, old route, token role, bridge pause or any service is in the same state today. Current service, chain and contract status is **unknown unless re-read from an authorized, verifiable source**.

## 12. Open parameters and decisions

The following remain open or unverified and must not be filled by assumption:

- Withdrawal proof format, Base-side verifier and finality rule for CoNET burns.
- L1 batch window length and related thresholds; L's K; U's N and W; light-client checkpoint age, long-gap threshold and re-bootstrap point; positive batch proof.
- Price source and valuation units for GB, wCNET and third-party assets.
- Per-asset production limits, values/units, hard exposure cap and risk owner; exact DAO configuration and held-deposit release conditions.
- Withdrawal fee base, currency, rounding and any refund fee; under v1 policy the withdrawal path cannot open until these are frozen and accepted.
- Factory Option 2 exact ABI, constructor arguments, implementation, roles, template hash (`H`), Router binding and seal order; same-candidate positive/negative acceptance. This specification does not authorize route enablement before this is resolved and accepted; current live status is not asserted.
- New asset metadata, formal addresses, roles, balances, code hashes and same-address deployment proof.
- Current status of historical contracts, services, Shadow and legacy routes.

## Related pages

- [Two-way AAC bridge: detailed policy](aac-two-way-bridge.md)
- [Earlier proof-driven AAC design and dated records](aac-cross-chain.md)
- [Decentralized cross-chain Treasury: legacy production references](cross-chain-treasury.md)
- [DAO and the next-generation treasury](dao-treasury.md)
- [Third-party tokens and subscriptions](third-party-assets.md)
- [GB purchase, metering, fees and settlement](gb-billing.md)
