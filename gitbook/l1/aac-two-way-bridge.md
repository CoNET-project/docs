# Two-way AAC bridge (CoNET ↔ Base)

**Status and evidence, 25 November 2026.** This page records operator design decisions from 7–12 November 2026. AAC implementation is paused; this page is not deployment approval. No current AAC deployment or address is claimed. Current chain and service state was not re-read for this update. See the [AAC whitepaper v1](aac-whitepaper.md) for the consolidated design, evidence labels and current acceptance boundary. The earlier proof-driven design and its dated records are on [AAC proof-driven cross-chain settlement](aac-cross-chain.md). The legacy Treasury cross-chain bridge was recorded as paused; its current status is not re-verified here.

**How to read the labels**

- **[Implemented, pending acceptance]**: implemented and tested locally. Not deployed. Acceptance, an independent audit and a separate deployment approval are still needed.
- **[Approved, not yet live]**: a rule the operator has decided and published. It is not deployed. Deployment still needs an independent audit and a separate approval.
- **[Open]**: not decided.

An operator decision is not a DAO vote.

conet-USDC on this page means the new conet-USDC contract (not yet deployed) that will replace the current one (decided, not yet live); the switch-over plan will be announced. The current contract will not be upgraded. The status of the current contract is to be verified. Support for new inflows through the previous Treasury bridge will stop (decided, not yet live).



**[Approved, not yet live]** AAC is a two-way USDC bridge between CoNET and Base. Seen from CoNET, Base → CoNET is a **deposit** and CoNET → Base is a **withdrawal**. Withdrawals exist from the first version; this replaces the earlier rule that version 1 has no withdrawal.

## Assets and chains [Approved, not yet live]

| Asset | Chains | Rule |
| --- | --- | --- |
| conet-USDC | CoNET ↔ Base | The first official stablecoin. Deposits and withdrawals use Base only |
| Other official stablecoins | CoNET ↔ one external chain each | The DAO may admit more at any time, each from a fixed template with its own exchange entry. Each has exactly one external chain; it cannot flow in from one chain and out to another. The one-channel rule is **[Implemented, pending acceptance]** |
| New GB and wCNET | CoNET ↔ chains the DAO approves | Issued originally on CoNET only. Another chain mints only against a burn on CoNET verified by AAC; moving back mints on CoNET only against a verified burn on that chain. A move from one external chain to another goes through CoNET in two steps. Same address on every chain |
| Third-party cross-chain tokens | CoNET ↔ chains the DAO approves | Admitted one by one by DAO decision. Deployed automatically at the same address on the first move to a chain (design; not implemented). See [Third-party tokens and subscriptions](third-party-assets.md) |
| Third-party stablecoins | CoNET only | No route to other chains |

Multi-chain same-address deployment is a design requirement and is not yet complete.

## Confirmation by direction

The v1 order invariant is **one terminal outcome**: a matching completion or a proven refund after expiry, never both. Errors, missing RPC responses and malformed proofs are unknown/unavailable, not a valid empty result.


| | Base → CoNET (deposit) | CoNET → Base (withdrawal) |
| --- | --- | --- |
| Source action | USDC is locked in the AAC bridge on Base | conet-USDC is burned on CoNET |
| First confirmation | **AAC deposit confirmation (design).** The Base block is still unsafe (pre-confirmed by the sequencer). AAC is intended to check the authorised sequencer's signature for that period, chain domain, signed-payload binding to the block header and `receiptsRoot`, designated bridge lock receipt, order/recipient/amount, replay protection and limits. A valid check would credit conet-USDC once; it is not finality or collateral. Acceptance has not passed. | **Withdrawal (design).** Base may release USDC only after verifying a finalized CoNET burn bound to the same order, recipient and amount, with replay protection. The destination verifier and complete withdrawal path remain unaccepted; no end-to-end withdrawal is proven. |
| Later check | **Ethereum L1 health check.** Base's health is judged by the time at which each Base batch is actually included on Ethereum L1. The same L1 evidence is used to track the exposure of deposits already minted. It mints nothing | — |

**[Approved, not yet live]** Fast crediting depends on the Base sequencer's pre-confirmation. A sequencer signature proves pre-confirmation only; Base's health is judged by when its batches are actually included on Ethereum L1. A batch that is included on time keeps the path healthy, even if its proof or its relay to CoNET arrives late. Only trusted L1 evidence that no valid batch was included in **two consecutive expected windows** stops both directions (see [Circuit breaker and reopening](#circuit-breaker-and-reopening)); silence from an RPC endpoint or a relayer is not such evidence. The windows and the other parameters are set by the DAO. These rules are decided; their implementation is pending. The term "early mint" describes when minting happens; it is not a stage name. Between the last batch confirmed as included on L1 and the moment the circuit breaker stops the bridge there is a period of exposure; its length depends on the window parameters the DAO sets and is currently estimated at about 30 minutes, an estimate rather than a fixed limit or a service level, and any loss in that period is handled by the project case by case.

## Deployment and upgrades [Approved, not yet live]

- **One factory, one initialisation.** A fixed AAC factory deploys the bridge contracts during initialisation: the new conet-USDC ledger, the deposit controller and withdrawal gateway, the settlement contract, the new GB and wCNET contracts, and the new treasury. Each contract's exact address is bound once to a predefined role.
- **No upgrades.** These contracts will be deployed at fixed addresses with no proxy and no upgrade function. This includes GB and wCNET. A later generation is a new deployment, moved to by DAO decision.
- **Frozen authorisations.** When initialisation completes, the key authorisations are frozen: the gateways, the controllers, the settlement contract and the source of limits. Nobody can add or replace them afterwards, and no administrator can reopen them. Releasing or clearing exposure is possible only through the bound settlement path, against a verified order.
- **Owner and administrator roles.** Where a new contract has an owner or administrator role, that role is held by the governance contract. No personal wallet or multisig holds it.
- **Route versions.** A new route version may use only controller and treasury addresses that the factory bound at initialisation. A DAO route decision chooses among those bound addresses; it cannot introduce a new address.
- What is frozen is the deployed code and the key authorisation addresses. The DAO keeps the governance rules already decided: per-asset limits, asset admission, the circuit breaker and reopening.

The factory stack is **[Implemented, pending acceptance]** locally. Its freeze checks have not all passed, the per-stablecoin channel switch and mint and burn pause are implemented locally but not accepted, and no contract has been frozen at an address. The binding of route addresses is implemented on the governance side but is not yet wired into the factory.

No address exists yet. Addresses will be published after audit and a separate deployment approval.

## Limits [Approved, not yet live]

USDC, GB and wCNET each have their own limits. Each asset has its own allowance and its own counter; there is no shared allowance between assets.

- **Per transaction:** 5,000 initially, for each asset. The per-asset limits are **[Implemented, pending acceptance]** for the USDC stack.
- **Per 20-minute window:** 50,000 initially, for each asset. The window is a fixed 1,200-second window, measured by the on-chain time at which CoNET accepts the order. Deposits and withdrawals of the same asset share that asset's allowance.
- **Unit.** USDC is counted in USDC. GB and wCNET are counted at their USDC-equivalent value, not as raw token amounts. The price source for that conversion is **[Open]**.
- **DAO adjustment.** The DAO can change each asset's two limits separately: one decision may change one limit of one asset, or both limits of that asset. Other assets' limits and counters are not affected. Changes made other than by DAO decision are refused. The per-transaction and per-window limits are enforced separately.
- **Limit between L1 confirmations.** It caps how much of an asset can flow into CoNET between two consecutive confirmations of Base submissions to Ethereum L1. It applies alongside the per-transaction and 20-minute limits above; neither replaces the other. The DAO sets this limit for each asset separately, and it is counted on CoNET only.
- **Starting values.** The new conet-USDC is deployed by the factory with this limit preset to 50,000 USDC; the DAO can change it later. An asset with no configured limit starts at 0, for example GB, wCNET and third-party tokens. For each other cross-chain token the DAO admits for flows into CoNET, the DAO sets a limit for the same interval.
- **Bridge path: inflows are held.** On the bridge path into the treasury, an inflow of an asset with no limit set is held instead of minted, and so is an inflow that would exceed the limit. Held inflows do not count against the limit until they are released, and on release they are checked against the limit again. When and on what conditions held inflows are released is **[Open]**.
- **Fast USDC deposit path: deposits are refused.** On the fast deposit path for USDC, a deposit that would exceed the limit between L1 confirmations or the 20-minute limit is refused, not held. Once the limit between L1 confirmations is used up, deposits stay refused even in a new 20-minute window; the allowance returns only after the next batch is newly confirmed on L1. A deposit of an asset with no limit set is also refused on this path.
- These are design rules; their implementation is not accepted.

## DAO decisions [Approved, not yet live]

Every proposal, including AAC reopening and limit changes, has an observation period of **600 seconds** from when voting opens. During that period votes are still collected and nothing is executed early. A DAO proposal that has reached its threshold is executed only after the 600 seconds have passed; the DAO voting window stays **7 days**.

## Proofs and evidence

This page is a design specification. Local receipts cover limited components, not a live bridge. Real CoNET header/storage-proof verification has local test evidence. The e638 Stage 2 receipt exercised synthetic consensus fields and locally generated CoNET RLP/slot-9 proof with Base mock USDC and a test executor; one release succeeded and recipient substitution/replay were rejected. Separately, the complete local `AacResolutionExecutor.relayBridge` diagnostic reverted with `NotFinal(bytes32)` (status 0; gas 16,178,615); balances and replay state did not change, and the trace did not prove the inner cause. No real-chain end-to-end withdrawal acceptance is established.


- **[Implemented, pending acceptance]** Verification of real CoNET block headers and real CoNET storage proofs, which proves CoNET chain state to another chain. Tested locally; not accepted.
- **[Open]** Carrying a final CoNET DAO decision to an external chain with a real proof has not yet been shown to work end to end.
- Return transfers of GB and wCNET, and settlement of third-party assets, are tested only with stand-in proofs. They are **not verified**.
- The proof parameters are still open: format, nonce scope, finality of the source chain, expiry, who may relay, and route gating.

## Fees [Approved, not yet live]

A withdrawal from CoNET to Base pays a DAO-set fee of **n%**, paid by the withdrawing user. It is accounted separately from the GB exchange fee. No default value is set; the fee base, currency and refund handling are **[Open]**. The fee mechanism is **[Implemented, pending acceptance]**.

## Per-stablecoin switches [Implemented, pending acceptance]

Each official stablecoin, including conet-USDC, has a cross-chain channel switch and a mint and burn pause. Both are implemented locally in the AAC contracts and in DAO candidate 4 (not locked); they are not accepted and not deployed. They are set separately by DAO decision and apply only to that stablecoin. Closing the channel stops both directions while in-flight messages keep their original deadlines: an unexpired message is delivered at most once after reopening, and an expired one can be refunded once the destination chain is proven to have closed it without delivery, after which it can never be delivered; the pause blocks every mint and burn of that stablecoin inside CoNET L1, but not ordinary transfers. While the conet-USDC pause is on, paid GB issuance that burns conet-USDC and exchanges of GB back to conet-USDC pause too. The current conet-USDC contract will not be upgraded and does not have these switches. Details: [Third-party tokens and subscriptions, Section 5.1](third-party-assets.md#51-two-switches-per-official-stablecoin-implemented-pending-acceptance); decision rules: [DAO and the next-generation treasury, Section 6](dao-treasury.md#6-stablecoin-channel-and-pause-decisions-implemented-pending-acceptance).

## Circuit breaker and reopening

The trigger, the trusted-header rule, the evidence rule, the latch, the unknown-implementation rule and states L, U and S below are **[Approved, not yet live]**: design rules, with implementation pending. The DAO-only reopening is **[Implemented, pending acceptance]**.

- **Trigger.** Windows are measured by the time at which a Base batch is actually included on Ethereum L1. When trusted L1 evidence confirms that no valid batch was included in two consecutive expected windows, AAC treats the Base cross-chain path as failed and immediately stops **both directions** between Base and CoNET. A batch that was included on time does not trigger the breaker because its proof or relay is late. Silence from an RPC endpoint or a relayer alone does not trigger it. Trusted L1 block headers come from an Ethereum sync-committee light client (see the next item). The window and the other parameters are set by the DAO; their values are **[Open]**.
- **Trusted L1 headers.** An Ethereum sync-committee light client supplies the trusted L1 headers (decided, not yet implemented). Its initial checkpoint is confirmed by a CoNET DAO vote. The checkpoint root cannot be upgraded: if a defect is found, a new contract is deployed and a new checkpoint root is installed by DAO vote. The checkpoint's maximum age applies only to the first start and to re-bootstrapping after a long period without updates. In normal operation the light client keeps verifying and storing finalized Ethereum L1 headers and sync-committee handovers itself, and needs no periodic renewal by the DAO. The checkpoint's maximum age, the threshold for a long period without updates and the point at which re-bootstrapping is required are **[Open]**.
- **Evidence is kept.** A later batch cannot overwrite, erase or skip the evidence of an earlier missed window.
- **Latched stop.** Once the breaker has stopped the bridge, it stays stopped until the DAO reopens it. Base producing blocks again, or submitting batches again, never reopens AAC by itself.
- **State L (no positive proof).** While there is no positive proof that Base batches are being included on L1, AAC enters state L: new minting on unsafe pre-confirmation is limited, and withdrawals are not affected. The threshold K that starts state L is **[Open]**, and so is the form of the positive batch proof.
- **Unknown Base implementation.** The verifier reads only the implementation slot of Base's SystemConfig contract. If that implementation changes, for example because Base upgrades the contract, the verifier treats Base's state as unknown. A missed-window finding requires Base's key configuration (batcher, owner, administrator and settings) to be known to be unchanged at both ends of the evidence. An unknown state is not treated as Base's configuration being unchanged, so it cannot support a missed-window finding and cannot trigger the circuit breaker. It lasts until a new verifier is deployed by DAO decision.
- **State U (implementation unknown).** If Base's implementation stays unknown for longer than N windows of length W, AAC enters state U. N and W are **[Open]**. State U itself never triggers the circuit breaker. The breaker rule stays as decided: trusted L1 evidence that no valid batch was included in two consecutive expected windows. N and W do not change or replace that rule.
- **State S (light client not live).** AAC is in state S whenever the light client is not live: it has stopped updating, it needs re-bootstrapping, or it has not been installed. This check fails closed: only a live light client lets minting on unsafe pre-confirmation go ahead. Before the DAO vote installs the light client's checkpoint, the light client counts as not installed, so state S applies.
- **What states U and S limit.** In state U or S, only new minting on unsafe pre-confirmation is blocked: new deposit confirmations are refused, and deposits deferred earlier are neither re-admitted nor released. Withdrawals are not affected, and neither state triggers the circuit breaker.
- While stopped, AAC accepts no new deposits or withdrawals and mints nothing. Approved refunds stay available; they do not mint or open ordinary withdrawals.
- Reopening needs a **DAO vote**. When the approved reopening is executed, Base must have recovered; otherwise that vote has no effect. There is no grace period. Chain recovery alone never reopens AAC.
- After reopening, AAC re-verifies existing locks and completes them automatically; users do not resubmit. A refund stays available against a proof that the order is closed and was not minted. A refund and a completion exclude each other. The same rule applies during a long stop.

## Buying GB with bridged conet-USDC

conet-USDC received through AAC deposit confirmation can buy GB under the normal rule: the GB contract burns conet-USDC at the DAO-set price per GB. There is no separate burn cap. The burn does not change the original deposit order. How GB purchases and GB exits behave while AAC is stopped is **[Open]**.

## Gate before the fast path opens

**[Approved, not yet live]** The fast path opens only after complete verification passes and negative tests show that forged signatures, forged block headers, forged receipts and replays are rejected. Production opening and operational acceptance are recorded separately.

Status on 7 November 2026: in the local implementation the negative tests pass, the chain-ID byte order matches a public test vector, and block-header recomputation matches real Base blocks. Positive tests use test keys only; real sequencer signature samples are still missing. **The gate has not passed.**

## Implementation status — historical snapshot (12 November 2026)

The table below records the page state on 12 November 2026. It is not a current implementation inventory. Later local evidence is summarized in the [AAC whitepaper v1](aac-whitepaper.md).

| Item | Status |
| --- | --- |
| Factory stack | **[Implemented, pending acceptance]**: the factory-deployed conet-USDC ledger with its gateways and freeze, new GB, wCNET and treasury, local tests. GB, wCNET and the treasury are not yet part of the same initialisation. Same-address deployment on CoNET, Base and Ethereum is not complete; predicted addresses were checked only in local simulation |
| Deposit confirmation | Local code: block authenticator, signer epochs, lock log, window ledger, inbound controller, bridge breaker and CoNET cover. The local code also contains a Base guarantee contract from the earlier design; the current rule does not use a guarantee |
| Circuit breaker on L1 inclusion, kept evidence, latched stop, unknown-implementation rule and states L, U and S | Design rules decided; implementation and review in progress, not accepted. The state U implementation has known defects that are not yet fixed, and the production path that judges Base's health by L1 inclusion time is not implemented. Trusted L1 headers come from an Ethereum sync-committee light client (decided, not yet implemented), with its initial checkpoint confirmed by DAO vote and no periodic DAO renewal in normal operation. The checkpoint's maximum age, the long-gap threshold and the re-bootstrap point, the positive batch proof, the state L threshold K, the state U parameters N and W and the other numeric parameters are **[Open]** |
| Tests | The full local test suite passes, including a real Base lock receipt, real Base header offsets, real CoNET block headers and storage proofs, and the official-stablecoin channel. Some proof paths still use stand-ins (see Proofs). Nothing has been accepted |
| Withdrawal | On 12 November 2026, the page recorded the CoNET → Base contract as not implemented. Later local evidence includes a synthetic Stage 2 component release, but no complete `relayBridge` success or real-chain end-to-end withdrawal acceptance; see [AAC whitepaper v1](aac-whitepaper.md) |
| Deployment | None. No contract deployed and no transaction sent |
| Known limits | When two valid proofs conflict, the effect of the one applied first is not rolled back; ordering two related events inside the same canonical block by transaction and log order is not implemented |

## Open items (12 November 2026)

1. Freeze the v1 withdrawal proof and finality integration: Base must verify the finalized CoNET burn and match its order, recipient and amount with replay protection. A synthetic component test is not full relay acceptance.
2. The price source for counting GB and wCNET at USDC-equivalent value.
3. For the Ethereum sync-committee light client: the checkpoint's maximum age, the threshold for a long period without updates, and the point at which re-bootstrapping is required.
4. The form of the positive batch proof.
5. The threshold K for state L and how far new unsafe minting is limited in state L; the parameters N and W for state U.
6. The numeric circuit-breaker parameters, including the expected window, which the DAO sets.
7. Real sequencer signature samples for positive acceptance.
8. How GB purchases and GB exits behave while AAC is stopped.
9. Which components of the earlier bridge still run; this needs a read-only on-chain check.
10. The cross-chain proof format and its parameters.
11. The withdrawal fee details.
12. The limit unit for third-party cross-chain tokens and the initial limits of newly admitted official stablecoins.

## Related

- [AAC whitepaper v1](aac-whitepaper.md) — consolidated design and dated evidence boundary

- [GB purchase, metering, fees and settlement](gb-billing.md)
- [Third-party tokens and subscriptions](third-party-assets.md)
- [DAO and the next-generation treasury](dao-treasury.md)
- [AAC proof-driven cross-chain settlement (earlier design)](aac-cross-chain.md)
- [Decentralized cross-chain Treasury](cross-chain-treasury.md)
- [Core L1 assets](assets.md)
