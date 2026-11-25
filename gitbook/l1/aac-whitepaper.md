# Atomic Asset Container (AAC): CoNET–Base USDC Bridge

**Whitepaper v1 draft — 25 November 2026**

**Evidence status: design and historical/local evidence; not a deployment notice.**

## 1. Executive summary

The Atomic Asset Container (AAC) is the proposed rule and contract system for moving assets between CoNET L1 and approved external chains. Version 1 centers on USDC between CoNET and Base. It defines deposits (Base to CoNET) and withdrawals (CoNET to Base), binds every operation to an order, recipient and amount, and makes replay prevention, limits, pause and recovery behavior explicit.

The design has two distinct paths. A Base deposit may be credited on CoNET after a sequencer pre-confirmation passes the AAC proof and policy checks; that credit is exposed until Base batches are included on Ethereum L1. A withdrawal burns the CoNET asset and releases Base USDC only after Base verifies the finalized CoNET burn and the matching order. The paths share governance and safety rules, but their proofs and source actions are not interchangeable.

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

The first official stablecoin route is the new conet-USDC ledger on CoNET paired with USDC on Base (chain ID 8453). The proposed v1 route has exactly one external chain. The existing CoNET conet-USDC contract is not upgraded; a new contract and a separately announced migration plan are required. No new AAC address is stated here.

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

Completion and refund are mutually exclusive terminal outcomes. A destination-side refund is allowed only after proof that the destination closed the order without delivery and the original deadline has expired. Once refunded, the order can never be delivered. If an unexpired order remains valid after a channel reopens, it may complete at most once. Closing a channel does not erase an in-flight order or reset its deadline.

The operator's acceptance rule for a withdrawal is stricter than observing a transaction or log: Base must verify CoNET's finalized burn proof and match the accepted order, recipient and amount, with replay protection. Historical scanning, archive downloads or reconstructing old state are not prerequisites for handling a newly accepted order. A query or proof failure is an unavailable/unknown result, never a successful zero or an empty business result.

### 4.1 Proof responsibilities

For a **deposit**, AAC verifies the authorized sequencer signature for its period, chain domain, signed-payload binding to the Base block header and `receiptsRoot`, the designated bridge's USDC lock receipt, order/recipient/amount, replay protection and limits. A sequencer signature establishes pre-confirmation, not Base finality.

For a **withdrawal**, the destination-side verifier must establish the finalized CoNET burn and bind it to the same order. The proof format, source finality policy, nonce scope, expiry and relay authorization remain open until frozen for the implementation.

Real CoNET headers and storage proofs have been exercised in local tests, but this does not prove the complete cross-chain path. The complete `AacResolutionExecutor.relayBridge` diagnostic recorded a local EDR transaction with status 0 and `NotFinal(bytes32)`; gas used was 16,178,615, balances and both replay states were unchanged, and the archived trace did not establish the inner cause. A separate local EDR Stage 2 test used synthetic consensus fields, a locally generated CoNET RLP header and slot-9 proof, a Base mock USDC and a test executor identity; it released once and rejected recipient substitution and replay. These are separate, limited observations. Neither is a real-chain end-to-end withdrawal acceptance.

## 5. Fast credit and L1 batch health

**Design decision:** a deposit may be credited against Base sequencer pre-confirmation without waiting for Ethereum L1 inclusion. This is fast credit, not proof that the Base batch is final. The system tracks the later inclusion of Base batches on Ethereum L1 and the exposure of deposits already credited.

A batch included within its expected window keeps the path healthy even if its proof or relay reaches CoNET late. Only trusted L1 evidence that no valid batch was included in **two consecutive expected windows** triggers a latched stop of both directions. RPC failure, missing relayer messages or silence alone is not evidence that no batch was included.

This rule depends on a trusted Ethereum L1 header source, specified as a sync-committee light client. Its checkpoint is installed by DAO vote; a checkpoint root is not upgraded in place. A defect requires a new deployment and a new DAO-approved checkpoint. Normal operation must verify/store finalized headers and committee handovers without periodic DAO renewal. Light-client liveness and trusted-header verification are not accepted production capabilities in the evidence cited here.

The time between the last confirmed L1 inclusion and a two-window stop is an exposure interval. About 30 minutes is an estimate in the historical design discussion, not a fixed maximum, hard limit or service-level commitment. The DAO-set windows determine the actual interval, and their values remain open.

## 6. Limits and circuit states

### 6.1 Per-asset limits

Each asset has separate limits and counters; assets do not share allowances. The recorded initial design values are **5,000 per transaction** and **50,000 per fixed 1,200-second window**, per asset. These are proposed initial values, not live on-chain limits. A separate per-asset cap applies between consecutive confirmed Base batch inclusions on Ethereum L1.

USDC is measured in USDC. GB and wCNET use a USDC-equivalent value; their price source is open. Third-party assets require an explicit unit and DAO-set limit. An asset with no configured limit starts at zero for cross-chain flow.

On the treasury bridge path, an admitted inflow with no configured limit or above its limit is held without minting. Release requires a fresh limit check. Release timing and conditions remain open. On the fast USDC deposit path, an over-limit or unconfigured deposit is refused, not held. Exhausting the between-batch allowance continues to block deposits across subsequent fixed 1,200-second windows until a new Base batch is confirmed on L1. The per-transaction, fixed-window and between-batch checks are cumulative, not substitutes for one another.

### 6.2 L, U and S

The proposed states constrain fast, unsafe-preconfirmation minting:

- **L — no positive inclusion proof:** limits new fast minting while there is no positive proof of Base batch inclusion. Withdrawals are not affected by L alone. Threshold K and the positive-batch proof format are open.
- **U — Base implementation unknown:** if the Base `SystemConfig` implementation changes, the verifier treats the state as unknown. A missed-window finding requires relevant Base key configuration to be known unchanged at both ends. Unknown state cannot prove a missed window and cannot trigger the breaker. If unknown lasts more than N windows of length W, state U applies; N and W are open. U alone does not trigger the breaker.
- **S — light client not live:** applies when the light client is absent, stopped or requires re-bootstrapping. New fast deposit confirmations are refused; earlier deferred deposits are not re-admitted or released. S alone does not trigger the breaker.

A confirmed two-consecutive-window miss is the distinct latched breaker condition and stops both directions. Once stopped, the bridge stays stopped until DAO reopening. Base recovery by itself does not reopen it. Reopening requires an executed DAO vote and Base recovery; there is no automatic grace period. Existing locks are reverified after reopening. A valid completion and a valid refund exclude one another.

### 6.3 DAO timing

The recorded design gives proposals a **600-second observation period** after voting opens, during which votes continue to be collected and no action executes early. The voting window remains **7 days**. These are operator-level design decisions and are not evidence of a live DAO configuration.

## 7. One-time factory binding and frozen authority

The intended deployment uses one fixed AAC factory and one initialization. It binds the exact addresses for the new conet-USDC ledger, deposit controller, withdrawal gateway, settlement contract, new GB and wCNET, treasury, route controllers and limit sources. Initialization seals the bindings: no administrator may replace them later, and the design has no proxy upgrade path. A later generation is a new deployment. Contract owner/admin roles, where present, belong to the governance contract rather than a personal wallet.

DAO route decisions may select only among addresses already bound by the factory; they cannot introduce a new controller or treasury. The DAO retains policy authority over asset admission, per-asset limits, channel switches, pause and reopening, but policy authority is not a power to replace sealed code or addresses.

**Implementation boundary:** local factory code and freeze checks have not all passed acceptance; the route binding is not yet wired into the factory. DAO candidate `7994b6a` has a static A–G review only and does not contain a compatible factory binder. Historical binder `af162402` calls `initIntervalLimit`, which is absent from the Candidate 4 Registry ABI. These versions must not be combined as if they formed one deployable candidate. Factory identity, constructor arguments, creation-code pins, and seal order remain unresolved. A separate recorded decision states that the Base lock fixes its route address at construction. The route binds the lock address once, and the lock address is part of the outflow domain. That equivalent one-time binding does not remove the other factory/candidate compatibility gaps. Therefore no factory or deployment is claimed by this paper.

Restoration of the legacy production oracle is a separate track; new AAC/DAO oracle features are deferred to the next version and are not a prerequisite for that restoration. V1 may leave the quote source open, but it must not enable routes that depend on an unfrozen quote source. This paper does not claim an oracle is live or restored.

## 8. GB, wCNET and third-party assets

The new GB and wCNET are intended to be CoNET-native assets with cross-chain representations controlled by AAC burn proofs. Their deployment parameters, metadata, price source, initial limits and final addresses remain unbound. The historical GB token at the legacy address is a separate asset and is not evidence of the new GB design being deployed.

A third-party token is admitted individually. The route must define its origin chain, source token, decimals, finality, custody mode, canonical CoNET representation, destination route, roles, limits, replay domain and application admission. A third-party stablecoin remains CoNET-only. Subscriptions and issuer payments are separate application rules and do not create cross-chain authority.

## 9. Fees

A CoNET-to-Base withdrawal has a DAO-set fee of **n%**, paid by the withdrawing user and accounted separately from the GB exchange fee. No default fee is set. The fee base, currency, rounding and refund treatment remain open. The local fee mechanism is reported as implemented pending acceptance; it is not a live charge.

## 10. Implementation and release gates

Before any route is opened, the release must bind one exact source commit, toolchain, dependency lock, generated artifacts, constructor arguments, initialization order and chain-specific addresses. Independent review must cover the same candidate and artifacts. The acceptance program must include:

1. positive and negative proof vectors for both directions, including wrong recipient/amount/chain, forged signatures or headers, invalid receipts, replay and conflicting completion/refund;
2. real source-finality evidence for the order being tested, with the destination receipt, balances and replay state captured at the same evidence boundary;
3. limits, pause, two-window breaker and DAO recovery tests, with RPC errors kept distinct from valid empty/zero results;
4. factory-to-DAO binding compatibility and sealed-address verification for one exact candidate; and
5. a separately approved deployment and operational runbook.

Historical integration suite `18ea56a` recorded 1,440 passed, 7 pending and 0 failed. Candidate `e6380ec` has limited local source/build and component receipts. Neither is a complete current acceptance, deployment freeze or production authorization. The full relay diagnostic failed as described above. No amount of a local pass changes the deployment gate.

## 11. History and current-state boundary

The older proof-driven AAC design, its October 2026 read-only Shadow observations, miner-vote shutdown records and the historical 0.01 Base USDC canary are retained in [the earlier AAC record](aac-cross-chain.md) and [the legacy Treasury history](cross-chain-treasury.md). They are dated historical evidence. They do not establish that the Shadow, old route, token role, bridge pause or any service is in the same state today. Current service, chain and contract status is **unknown unless re-read from an authorized, verifiable source**.

## 12. Open parameters and decisions

The following remain open or unverified and must not be filled by assumption:

- Withdrawal proof format, Base-side verifier and finality rule for CoNET burns.
- L1 batch window length and related thresholds; L's K; U's N and W; light-client checkpoint age, long-gap threshold and re-bootstrap point; positive batch proof.
- Price source and valuation units for GB, wCNET and third-party assets.
- Per-asset production limits, initial values, exact DAO configuration and held-deposit release conditions.
- Withdrawal fee base, currency, rounding and refund handling.
- Factory binder compatible with one frozen DAO candidate, exact constructor arguments and sealing order.
- New asset metadata, formal addresses, roles, balances, code hashes and same-address deployment proof.
- Current status of historical contracts, services, Shadow and legacy routes.

## Related pages

- [Two-way AAC bridge: detailed policy](aac-two-way-bridge.md)
- [Earlier proof-driven AAC design and dated records](aac-cross-chain.md)
- [Decentralized cross-chain Treasury: legacy production references](cross-chain-treasury.md)
- [DAO and the next-generation treasury](dao-treasury.md)
- [Third-party tokens and subscriptions](third-party-assets.md)
- [GB purchase, metering, fees and settlement](gb-billing.md)
