# CoNET Privacy and Asset Fragmentation Whitepaper

**Version:** Revised discussion draft v0.3 | **Revision date:** 26 October 2026 | **Scope:** permissionless privacy infrastructure, DLE asset-right fragmentation, and isolation of external reserve units | **Status:** DAO discussion draft. Not approved by the DAO; not deployed; not on-chain.

*Translation note: this English page translates the Chinese draft (v0.3). If the two texts differ, the Chinese text governs.*

**Governance position:** CoNET is permissionless, open-source and decentralised. Protocol governance is decided by the DAO, and CoNET Labs carries out technical development. This draft grants neither CoNET Labs, the DAO nor any other party a network-wide decryption capability, traceability through to individuals, arbitrary seizure of user assets, or freezing of user assets by identity.

**Evidence scope:** This draft is based on the v0.1 document provided, the v0.2 revision and the discussion of 26 October 2026. On that date the repository documents on Layer Minus, web3://, the order-book exchange and CoNET-DLE were read, and the interfaces of `FreezeRegistry`, `ExternalTreasuryImmutable` and `ConetLightClient` were checked. `ConetLightClient` verifies the CoNET beacon chain itself and does not cover Base. The commit hashes, deployed bytecode and audit reports for those files have not been verified, so maturity statements are not taken as evidence of the current network state. The text distinguishes project statements, proposed specifications and points still to be verified. New designs are not described as deployed capabilities, and existing CoNET components are not discredited on the basis of this draft.

**Normative terms:** "must" and "must not" express security constraints of this design; "should" marks a proposal; "pending" marks matters without a complete implementation or governance decision. This document is not deployable code, a cryptographic security proof, or legal advice for any jurisdiction.

---

## Summary

CoNET treats privacy as a property of the base protocol. Through the design of communication routing and asset state, it aims to reduce the chance that a user's network location, application access and asset-transfer relationships can be continuously linked by outside observers. Lawful use of privacy technology and the possibility of misuse must be assessed separately; the latter cannot by itself justify a requirement that the protocol contain a regulatory backdoor.

This draft distinguishes three capabilities:

1. **Communication-relationship protection**: Layer Minus and web3:// use role separation, wallet addressing and end-to-end encryption to reduce the chance that a destination service or an intermediate routing node obtains a client's IP address and the complete application relationship directly.
2. **DLE asset-right fragmentation**: asset rights are split, transferred and combined under defined rules, producing privacy-oriented state transitions. Fragmentation must preserve conservation, ownership verification, double-spend prevention and transaction-relationship protection at the same time. Increasing the number of fragments is not in itself proof of privacy.
3. **External reserve-unit isolation**: for external assets such as USDC whose issuer retains restriction powers, reserves are held in separate deposit units. This avoids routine inflows into a shared holding address and structurally reduces the direct impact when a single address is restricted. Deposit units are derived deterministically by a CREATE2 factory, and single-deposit risk is limited through pre-flight checks before execution, atomic redemption and the risk-control checklist (Section 3.9).

Internal DLE fragments and external deposit units are different objects. The former represent transferable rights; the latter actually hold external tokens. One deposit unit can back several internal fragments, and splitting or trading internal fragments does not mean that external tokens move at the same time.

CoNET's technical position is that of an **asset-right fragmentation privacy protocol**. It cannot be treated, without analysis, as equivalent to a traditional pooled mixing mechanism merely because transactions are harder to trace. Technical classification, third-party issuers' usage policies and legal liability are three separate questions that must be argued separately.

Independent addresses can reduce the risk of a common freeze at address level, but they do not prevent an issuer from restricting several addresses, suspending the token or taking other lawful measures. If internal rights are redeemed uniformly, restriction of part of the reserves can still create a shared coverage shortfall. This draft discloses these boundaries and sets out conditions for safe accounting and settlement.

## 1. Problem, goals and threat model

### 1.1 Problems to solve

Public transaction graphs, RPC access records and application network connections can be combined into long-term behavioural profiles. Hiding a client's IP address alone does not hide transaction relationships on the public ledger, and splitting assets alone does not automatically remove the links between amounts, timing and ownership.

On the other hand, concentrating a large number of users' external reserves in a single USDC address places a disputed deposit and unrelated users' funds within one address-level restriction scope. The protocol therefore needs to study relationship privacy and reserve isolation together, and cannot use one in place of the other.

### 1.2 Privacy and security objectives

| ID | Objective | What must be shown |
|---|---|---|
| P1 | Network-location protection | Under the stated routing and non-collusion assumptions, a destination service and specified intermediate roles cannot directly obtain the client's IP address |
| P2 | Internal transaction-relationship protection | A specified observer cannot practically reconstruct the full graph linking internal rights' inputs, outputs, counterparties or subsequent holders |
| P3 | Transaction correctness | Privacy does not impair authorisation checks, value conservation or double-spend prevention |
| P4 | External reserve isolation | Unit reserves do not flow into a shared transit holding address through routine deposits and withdrawals |
| P5 | Settlement integrity | Each paid amount corresponds to exactly one reduction of rights; unpaid amounts are not treated as redeemed |
| P6 | Verifiable permissions | The actual permissions of code, governance and dependencies match the statement that there are no backdoors |

P2 must define the observer, the public fields, the information that may leak and the criteria for a successful attack. "Complicated routing" or "high tracing cost" cannot by themselves serve as evidence that the objective is met.

### 1.3 Attackers and dependency assumptions

The analysis considers a single malicious node, colluding routing nodes, a malicious matcher, observers of external chains, a malicious submitter, source-chain reorganisations, and the existing administrative powers of an external token issuer. Global traffic observation, compromise of clients, theft of wallet keys and failure of consensus security require separate analysis.

Deposits and withdrawals on external chains, unit addresses, amounts, times, deployment relationships and the actual withdrawal transactions may remain public. The visibility of source-chain reserve flows and the linkability of DLE internal beneficial rights must be assessed separately. This draft does not promise to hide all cross-chain deposit and withdrawal traces.

### 1.4 No network-wide regulatory backdoor

This design must not include a network-wide master decryption key, an asset-seizure interface that a regulatory identity can call directly, or an interface through which CoNET Labs, the DAO or the validator committee can arbitrarily recover all users' transaction relationships.

A user may use records the user holds to prove particular transactions to a counterparty, an auditor, or an institution that lawfully requests them. Voluntary or lawfully required individual disclosure does not create a protocol-wide disclosure capability, and does not mean that any third party can read the full history.

Verification of security proofs, public accounting and the restriction status of external tokens exists to verify system state. It does not give a submitter the power to read users' plaintext or to decide whether a user's identity may transact.

## 2. System layers and terminology

### 2.1 Layered structure

| Layer | Object | Responsibility | Not to be confused with |
|---|---|---|---|
| External asset layer | Native token of the source chain | Records real balances and executes the token's own transfer rules | CoNET cannot revoke the issuer's existing powers |
| External reserve layer | Deposit unit (DU) | Holds registered reserves independently and executes verified redemptions | A DU is not an internal freely tradable asset fragment |
| Cross-chain verification layer | Finality and state verifiers | Verifies deposit, redemption, cancellation and reserve-state facts | A relay signature or RPC response does not automatically equal a source-chain fact |
| DLE asset layer | Rights fragments and their states | Splitting, combination, authorised transfer, double-spend prevention | The number of fragments is not the amount of reserves or any increase in value |
| Application and trading layer | Order book, matching and settlement | Exchange of rights under user authorisation | A matcher does not acquire custody merely by participating in matching |
| Communication layer | Layer Minus, web3:// | Encrypted communication and wallet addressing | Hiding the network origin does not automatically hide the ledger's transaction graph |

### 2.2 Key terms

- **Deposit unit (DU)**: a source-chain contract account that holds a specific external token and is linked to a unique deposit record.
- **Rights fragment (Fragment)**: an internal logical unit representing a certain amount of asset rights. Its state representation and proof system must be specified in the DLE implementation specification. This draft does not presuppose any particular zero-knowledge, FHE or UTXO scheme.
- **Bridged representation asset**: an asset representation formed on the CoNET side according to verified external reserves. To avoid ambiguity, this draft uses the example name CoNET-USDC. It does not imply native issuance or endorsement by Circle.
- **Reserve control contract**: a code module that executes payments only according to fixed verification rules. Holding tokens does not by itself prove the absence of custody; one must still check who can change the verification rules or the calling conditions.
- **Unit restriction**: a verified external token or source-chain state that currently prevents the unit from executing a transfer that satisfies the published rules.
- **Public rights pool**: deposits that give rise to one fungible, uniformly redeemable right. It may sit at the liability or equity level even when the source-chain reserves are held in separate units.

### 2.3 Two kinds of isolation

This draft uses two terms: "reserve-address isolation" and "redemption-risk isolation". The former is determined by the external holding structure. The latter also depends on whether internal rights keep an independent settlement boundary. Having achieved the former, one may not claim that the latter has been achieved automatically.

---
## 3. External deposit units: structure and permissions

### 3.1 Unit boundary

It is proposed that each accepted deposit correspond to one DU, one token and one unique registration record. A unit must not accept arbitrary withdrawal instructions from a common template controller. Every transfer of assets out must satisfy an explicit cross-chain settlement condition or a lawful refund proof condition.

The DU, the factory, the verifiers and the reserve-control module together form the complete permission boundary. Proving that the DU has no owner field is not sufficient: if its sole caller can be upgraded by an administrator, that administrator may still indirectly obtain control over all units.

### 3.2 CREATE2 and contract implementation

CREATE2 can be used for deterministic deployment and address precomputation. The address depends on the deployer, the salt and the hash of the initialisation code, and it provides no anonymity.[1]

ERC-1167 minimal proxies can serve as a candidate for lowering deployment cost. They delegate to a fixed implementation through `delegatecall`, so one may not simultaneously claim "uses ERC-1167" and "there is entirely no delegatecall". The security constraints should be stated as: the target implementation is fixed; there is no delegated execution to arbitrary targets; and there is no replaceable implementation address or administrative channel that changes payment authority.[2]

One must verify that the implementation address really holds code, that the implementation itself cannot be replaced by arbitrary logic, and that initialisation cannot be called first by someone else. Deployment and initialisation should be atomic. The token, the verification rules, the registration identity and the necessary domain-separation fields must all be bound before a formal deposit is accepted. Dependency libraries and the compiler must be pinned to specific versions.[3]

The salt must bind at least the source chain, the protocol domain, the control-rule version, the token and a unique deposit identifier. This is a domain-separation requirement. It does not mean that this document specifies the final deployment bytecode. The user's deposit intent must also bind the amount, the commitment to the beneficial rights and anti-replay information, so that a predicted address cannot be registered first as another person's asset.

### 3.3 Deposits go directly into units

The baseline process is as follows:

1. The user authorises a deposit intent that binds the source chain, the token, the amount, a unique identifier and the commitment to beneficial rights on the CoNET side.
2. The factory creates and initialises the DU within the same transaction.
3. The entry point makes the token transfer and sends the user's assets directly into the DU. The principal is not first transferred to a public treasury and then redistributed.
4. The actual receipt is confirmed according to the token semantics that have been explicitly supported. The deposit record is registered and a verifiable event is emitted.
5. Only after CoNET has verified the source-chain facts and their finality may the corresponding rights enter a transferable state. The same deposit must not be issued twice.

If a compatible entry point does genuinely need to hold tokens briefly, its permissions and public dependencies must be disclosed separately. A zero balance at the end of the transaction may not be presented as having eliminated all common points of failure.

The initial implementation should accept only tokens whose behaviour has been fully modelled. Fee-on-transfer tokens, rebasing tokens, tokens with callbacks and tokens with abnormal return values cannot directly reuse the accounting assumptions for ordinary USDC.

**Pre-flight checks and bounded retries.** Before a withdrawal, the most recent finalised state of each selected unit must be read, and the freshness of its proof must be checked. If a batch is rolled back because one unit is restricted, that rollback does not change the recorded state of any unit. The system should re-plan on the basis of updated proofs and set a bounded number of retries. When retries are exhausted, the withdrawal request enters the queue, and the user is told that it is "awaiting re-planning", not "completed". This design trades some liveness for atomicity: an occasional unknown restriction delays payment, but it does not cause partial payment.

### 3.4 Unrequested transfers and dust

An ordinary ERC-20 transfer generally cannot be refused one by one by the receiving contract. A DU may receive unrequested or unregistered additional tokens. Receipt does not mean that the protocol has accepted those tokens as issuable collateral.[4]

Unregistered inbound transfers must be recorded separately. They do not increase issuance authority, do not automatically become treasury income, and are not consolidated through a public address. Their disposition must be specified in advance and must not give anyone an arbitrary withdrawal right.

Non-registration does not cancel the receipt facts on the external chain. If the issuer actually restricts the DU, both the registered principal and the unregistered inbound transfers may be affected. The separation of accounts therefore cannot be presented as a mechanism that prevents all contamination or all collateral restrictions.

The recommended baseline does not pool small deposits from several people into a shared bucket. A minimum accepted deposit can control cost, but this threshold cannot prevent others from transferring dust directly, nor prove that every accepted source of funds is lawful. If bucket units are introduced in future, the shared freeze scope within each bucket must be disclosed explicitly, and the arrangement must not be described as per-deposit isolation.

### 3.5 Withdrawals do not pass through a public holding point

Normal redemption is paid directly by the selected DU to the payee address authorised by the user. Several DUs may make one redemption payment to the same payee address; this does not violate the prohibition on a shared public reserve transit point.

The protocol must limit the number of units used by a single withdrawal and the cost of scanning. The baseline may use first-in-first-out. It is verifiable, fair and simple to implement, but it may not be regarded as privacy protection, because a fixed selection order may strengthen the link between timing and amount. Any selection rule must be evaluated together for verifiable fairness, resistance to manipulation, cost and linkage leakage.

A payee may not designate reserves that belong exclusively to another person. If a public rights pool is used, the scheduling rule may not be described as a guarantee that all risk transfer has been eliminated.

### 3.6 Restriction facts and unit states

| State | Meaning | Accounting treatment |
|---|---|---|
| Registered | Registered, but the full finality conditions required for issuance are not yet met | Does not support issuance of tradable rights |
| Active | Verified as usable; the balance matches the registered rights | Counted in usable reserves, with redemptions already reserved shown separately |
| ExternallyRestricted | An external token or chain state actually restricts payments from this unit | The restricted amount is not counted in current usable reserves |
| ReconciliationPending | An inconsistency or evidence gap whose cause cannot yet be determined | The unverified amount is reported explicitly; it is not automatically treated as a permanent loss |
| Spent | Registered principal exhausted by valid payment records | Not counted in remaining reserves |
| LossConfirmed | Sufficient evidence that the relevant registered assets have actually been lost | The loss is recorded and rights coverage is updated |

A single failed transfer must not automatically classify a DU as frozen, still less as criminal funds. The failure may stem from a restriction on the payee's address, insufficient balance, calling permissions, gas, a global pause or an implementation issue.

An external freeze fact on chain may be submitted with proof by anyone. Successful verification only updates the asset's availability; it does not grant the submitter or the DAO any new protocol freezing power. A dispute notice may be recorded as information, but it cannot replace a definitive state-verification rule.

### 3.7 Source-chain state proofs

A proof must specify the chain and the token address, the proxy implementation version, the block height or hash, the state root, the storage layout and finality. Reading a source-chain RPC and having a single observer sign the result is not equivalent to trustless state verification.

For Base, one must distinguish sequencer pre-confirmation, L2 block confirmation, L1 batches and finality. One must also distinguish the finality of ordinary L2 transactions from the proofs and waiting conditions used for cross-domain withdrawals. A single fixed number of seconds or days may not be stated as the general answer.[5]

Verifying the authenticity of a source-chain state root and proving its finality are two necessary steps. If an existing light client only verifies CoNET's own consensus, it does not automatically acquire the ability to verify Base. The specific adapter, proof freshness and failure behaviour are all pending implementation.

A USDC implementation upgrade may change the state layout or the verification assumptions. An adapter must not silently read old storage slots and continue to claim that the proof is valid. A public version-compatibility rule is required. Where verification is not possible, only the affected cross-chain security operations are restricted; no identity-based review interface is added.

### 3.8 Common dependencies and batch restrictions

Identical factories, templates and deployment events are easy to identify. Factory rotation can serve version management and capacity partitioning, but it cannot be a security guarantee against clustering or against batch freezes.

A shared implementation flaw, an upgradeable control module, the failure of a single verifier, or caller-level restrictions can each affect several units at once. USDC's EVM implementation contains permissions such as address restrictions and pausing, and transfer paths must also check the actual rules applied to the caller, the payer and the payee.[4]

The verifiable commitment of unit isolation is a reduction in shared holding exposure. It is not a claim that a fault at the external issuer, on the source chain or in common software can affect only one unit.

### 3.9 Risk-control checklist (maximal risk control)

The measures below are the proposed baseline. Together they reduce risk, but none of them can by itself be claimed to eliminate risk.

| ID | Control | Risk addressed | Residual risk (may not be claimed as eliminated) |
|---|---|---|---|
| C1 | One unit per accepted deposit; no aggregation; no shared buckets by default | Scope of a single dispute or freeze | Batch freezes, common code defects, clustering by the same factory |
| C2 | Units are not upgradeable, have no administrator and accept no arbitrary calls; derivation parameters can be precomputed from public data | Concentration of control; replacement of the implementation | The implementation defects themselves; changes in dependency libraries |
| C3 | Withdrawals select only units that pass pre-flight checks as Active; the withdrawing party may not choose units; a cap on the number of units per withdrawal | Payment from restricted or suspicious units; selection attacks | State changes between the pre-flight check and execution |
| C4 | Atomic batch execution: if any unit fails, the whole batch reverts, and no proof is partially consumed | Loss from settling a whole request after partial payment | Reduced liveness; requires bounded retries and queuing |
| C5 | Unit states change only through verifiable facts; a single transfer failure does not constitute a freeze | Mistaken contamination findings; wrongful freezes | Proof delay; source-chain reorganisation |
| C6 | The protocol does not suspend all assets because one unit is restricted; asset-level suspension is used only for chain-level security events | A single restriction escalated into a network-wide halt | A global pause remains determined by the token issuer |
| C7 | Unregistered inbound transfers do not increase issuance authority, are not consolidated and are not counted as usable reserves | Dust attacks and the mixing-in of funds of unknown origin | The actual receipts on the external chain still exist |
| C8 | Accounting reports R, D, U, A, W, L, P and F separately; freezes and losses are recorded separately | Concealment of restricted amounts; double counting; wrong coverage ratio | Reconciliation depends on the quality of proofs and snapshots |
| C9 | Losses are borne first by the risk reserve, subject to a cap; the excess enters coverage | A single freeze creating a shortfall for all holders | When the risk reserve is insufficient, coverage is still shared |
| C10 | Factories are rotated by period; buckets are subject to amount and count caps | On-chain clustering and large single-period dependence | Rotation cannot prevent clustering; it provides only partitioning and version management |
| C11 | Invariant tests, a fault matrix and simulated drills | Implementation and permission errors | Test coverage is not a security proof |
| C12 | Nominal, usable, frozen and loss data disclosed by unit | Misjudgement under panic caused by opacity | The accuracy of disclosure depends on proof quality |

---
## 4. DLE asset-right fragmentation and privacy

### 4.1 Fragment representation and conservation of value

A fragment represents asset rights. It does not create native external tokens out of nothing. Splitting, combination and exchange must distinguish the asset class, the amount precision and the authorisation of beneficial rights.

For a given asset, a lawful transformation must satisfy: total input rights = total output rights + any fee expressly accrued + any rights expressly destroyed. Rights received by a fee recipient must also be counted in the ledger's total. The same amount may not be recorded both as destroyed and as treasury income.

For example, 100 units of rights may be split into 60 and 40, and the beneficial ownership of the 40 units may then be transferred through a trade. The 100 USDC locked in the external DU does not move automatically as a result. External reserves change only upon deposit, upon a proven redemption, or upon another pre-specified valid state transition.

### 4.2 Privacy and validity must hold at the same time

An implementation specification must explain:

1. how a user proves the right to use input rights without disclosing identities or transaction relationships beyond the design scope;
2. how nodes verify that inputs are valid and have not been reused;
3. how conservation, range and precision are proved, so as to rule out negative amounts, overflow and hidden issuance;
4. how output beneficiaries obtain and recover their rights;
5. how proofs, messages and transaction identifiers are domain-separated, to prevent replay across chains, assets or versions;
6. which information is public, which is visible only to the transacting parties, which is visible to nodes, and which linkages must be hidden.

Input-output commitments, consumption identifiers and other cryptographic constructions may serve as candidates. This draft does not present these candidates as an implementation deployed on DLE. Whether a consumption identifier can be linked to its historical source must also be included in the proof targets.

### 4.3 The number of fragments is not a measure of privacy strength

If the stable identifiers, amounts and correspondences of inputs and outputs are all public, splitting one transaction into many small transactions can still be fully reassembled. If every node must read complete plaintext to verify, communication encryption cannot remove those nodes' ability to observe the transaction graph.

Privacy therefore depends on an explicit state representation, a verification method and an observer model. It does not depend merely on transactions being broken up, on complicated paths or on a large volume of data. A paper or test should report linkability, timing and amount leakage, the view of matchers, and the conditions for collusion.

### 4.4 Technical difference from pooled mixing mechanisms

Under this design, external principal is held independently in DUs. Privacy is achieved internally through fragmentation of rights states and authorised transformations. It does not require depositing native USDC in one shared mixing pool and redistributing it afterwards.

The structure should be described by its actual asset flows, state transitions and permission graph. The fact that an implementation has privacy effects does not erase its difference from other mechanisms. Likewise, using a different name does not automatically exclude a broad third-party classification of "hidden-source" functions. Chapter 10 discusses technical classification, service policy and legal liability separately.

### 4.5 Auditability is not the same as publishing every relationship

Verifying total issuance, reserve balances and conservation is a different requirement from publishing the complete source path of every internal fragment. This draft keeps the former and does not require the latter.

If an implementation can verify conservation only by full plaintext tracing, it cannot also claim to hide transaction relationships from those verifiers. If it relies on cryptographic proofs, encrypted aggregation or other constructions, it must submit the corresponding verification algorithm, security assumptions and failure model.

### 4.6 Boundaries of information leakage

External DU deposits and payments may still be public. Address reuse by users, similar amounts, concentrated withdrawals, order timing, fee patterns and communication behaviour can each strengthen linkage. Public reserve flows do not automatically prove that internal beneficial rights remain held by the same user, but neither can they be treated as carrying no linkage information at all.

This draft does not claim absolute untraceability against a global observer. A complete privacy assessment must cover normal user behaviour, malicious matchers, malicious deposit and withdrawal requests, and collusion among several observer roles. Verifying only the local correctness of cryptographic components is not enough.

## 5. Cross-chain redemption: integrity first, rather than "continue after failure"

### 5.1 Baseline settlement principle

It is proposed that the first implementation adopt atomic redemption in bounded batches. Within one source-chain transaction, the payments from the selected DUs must either all succeed or all be rolled back. A unit that does not apply may be dropped after re-planning before execution, but a request in which "part has been paid and the whole proof has been consumed" may not be treated as a success.

Interfaces such as `trySafeTransfer` can return a transfer-failure result, but they do not by themselves complete partial-payment accounting, cross-chain proof consumption, refunds or retries.[6] Using such an interface does not mean that cross-chain settlement safety has been solved.

### 5.2 Redemption identifiers and authorisation

Each redemption request must have a unique `redemptionId`, bound to the source chain, the CoNET domain, the asset, the amount, the payee address authorised by the user, the lock status of the rights and the version. Any relayer may submit only proof with identical content and may not change the beneficiary.

The same request must be prevented from being paid twice across different source chains, different DUs, different versions or concurrent batches. The external payment state and the replay-protection state must be updated consistently within the same atomic transaction, and must cover reentrancy and abnormal token behaviour.

### 5.3 Locking, payment and final write-off

1. The CoNET side locks the rights to be redeemed. Once locked, they cannot be traded further or used for another redemption.
2. The source chain verifies the valid lock and the content of the request, and executes payment under the authorisation rules.
3. Once the payment reaches the required finality, CoNET verifies the completion proof.
4. The paid amount and the corresponding locked rights are written off in one consistent settlement update, producing a verifiable completion record.

This is a design constraint. It does not mean that the cross-chain state machine above has been implemented. A secure implementation must also prove that the steps cannot produce double spends or unjustified destruction of rights under delay, reorganisation, relay interruption and concurrency.

### 5.4 Cancellation may not rely on local timeouts alone

If the source chain might still accept an old payment proof, CoNET unlocking rights merely because of a timeout could produce the outcome "rights are restored, and then the source chain pays anyway".

Cancellation must place the corresponding request on the source chain into a final state in which it can no longer be paid, and the fact of that cancellation must be proven to CoNET before the remaining lock can be released. Amounts already paid cannot be recovered through cancellation. A purely local CoNET timer, or the absence of any observed payment, is not enough to prove that the source chain will never pay.

### 5.5 Future extension to instalment or partial payment

If multi-transaction instalment payments are needed in future, each payment segment must have a unique index, a cumulative amount paid, the remaining liability, completion conditions and cancellation rules defined separately. The cumulative payments must be proven not to exceed the authorised amount.

Until this extension has been audited, "continue trying other units after a failure without rolling back the whole batch" may not be adopted as the default implementation.

---
## 6. Reserve coverage, freezes and rights risk

### 6.1 Accounting quantities reported separately

For each external asset, the following quantities are reported separately, from one verified and reproducible settlement snapshot:

| Symbol | Definition | Treatment |
|---|---|---|
| R | Total external tokens actually held by the units | Report the corresponding block and the verification basis at the same time |
| D | Registered reserve principal not yet redeemed, refunded or confirmed as lost | A restriction on an asset does not by itself reduce D |
| U | Identifiable unregistered inbound transfers | Do not support new issuance; not counted as redeemable reserves |
| A | Registered reserves currently usable | Excludes restricted, lost and unreliably verifiable amounts; includes amounts reserved but not yet paid |
| W | The part of A already reserved for pending redemptions | Scheduling is limited separately; the same amount may not be reserved twice |
| L | Liquidity not currently reserved, L = A − W | Used to decide whether a new execution arrangement can be accepted |
| P | Total unperformed redemption rights | Includes rights already locked but not yet paid |
| F | Registered reserves temporarily unavailable because of external restrictions | Separates restriction from permanent loss; not treated directly as legal forfeiture |

In a snapshot where no abnormal asset behaviour exists and reconciliation has been completed, R = D + U must hold. If it does not, the gap and its cause must be reported. The entire gap may not be recorded as a permanent loss of funds.

The usable coverage ratio is defined as C = A / P. In a reconciled snapshot, D = A + F should hold: A includes the reserved part, and F is the restricted part. Any amounts in ReconciliationPending or LossConfirmed must be shown separately between D and A and F, with an explanation. The correspondence with the GB whitepaper is as follows: P is the L of the GB whitepaper; C is its coverage ratio A ÷ L; F corresponds to its "restricted assets"; and W is a reservation sub-item introduced in this draft. The currency and valuation rules must be consistent across the two documents. When P is zero, this must be stated separately, and a division by zero may not be used as an economic judgement. Different currencies and different legal rights may not be added directly without valuation and risk adjustment.

### 6.2 Preventing double deduction and cross-chain timing mismatches

W is only a purpose-specific reservation within A. If P still includes the redemption right concerned, W should not also be deducted from the numerator A of the coverage ratio. Otherwise the same in-transit settlement would be counted twice as a shortfall. Liquidity L and the coverage ratio C must be reported separately.

A request that has been paid on the source chain but not yet written off on CoNET must be shown separately as a cross-chain settlement in transit. Only on the basis of a trusted final payment proof may the corresponding assets and the unperformed rights be reduced in one consistent accounting update. One side may not use the post-payment balance while the other still uses the un-updated liability, and then book the brief timing difference entirely as a loss.

Rights may not be treated as redeemed at the moment they are locked. A request that is frozen, queued or awaiting cancellation but not paid still carries the corresponding rights.

### 6.3 A numerical example of address isolation

Suppose external reserves are 1 million USDC, split into 100 DUs with 10,000 USDC each, and the unperformed internal rights P are 1 million.

- Under normal conditions, A is 1 million and the usable coverage ratio is 100%.
- If one DU's 10,000 USDC is temporarily restricted externally, the directly restricted reserve is 10,000 USDC. The other units are not automatically frozen at the token-contract layer as a result.
- With no other supplementary assets, A is 990,000 and the coverage ratio is 99%. The nominal balance R and the unperformed rights P are not automatically reduced by the restriction.
- If the restricted funds are later released, A is restored on the basis of verified facts. If a final loss occurs, the actual loss and its allocation are recorded separately.

It is therefore incorrect to describe the situation as "the remaining 990,000 USDC can still be transferred, so all other holders keep riskless full redemption". For a public rights pool, the shortfall may still affect the economic value of all rights.

Suppose also that under normal conditions W is 200,000 USDC. Then the liquidity L available for new arrangements is 800,000 USDC, while the coverage ratio remains 100%. Reserved amounts do not on their own create a 200,000 USDC payment shortfall.

### 6.4 Two rights structures and their trade-offs

| Structure | Internal circulation | Economic effect of restriction on one DU | Trade-off that must be disclosed |
|---|---|---|---|
| Public rights pool | The same asset's rights are uniform, fungible and redeemed uniformly | Usable coverage bears the change jointly | Address isolation is not the same as isolation of holders' risk |
| Independent redemption units or risk groups | Rights keep the redemption boundary of their reserve group | The effect can be confined to the corresponding group, but this requires real and enforceable rights constraints | Liquidity, pricing and state proofs are more complex; one may not assume that these rights are interchangeable with all others by default |

This draft analyses the homogeneous circulation case as a public rights pool. If an independent redemption structure is adopted later, it needs a separate specification. Keeping an economic redemption boundary does not require publishing every user's transaction history automatically, and it may not be described as an interface through which a regulator can trace the whole network.

If any rights can be withdrawn in the same amount from any reserve, and no effective independent risk-bearing boundary exists, the arrangement must be disclosed as bearing common redemption risk.

### 6.5 Risk reserve and exit arrangements

The risk reserve may be used to cover a shortfall only when it actually exists, can be verified, has not been counted twice, and has been explicitly designated to bear the relevant risk. A book name, a future fee not yet realised, or the duplicate classification of the same asset may not increase coverage.

If coverage is insufficient and the first to arrive is allowed to withdraw all usable reserves at face value, the remaining shortfall may be left to later arrivals. A first implementation must therefore determine in advance how new requests are handled when coverage is insufficient, how locked requests are treated, and the rules for fair allocation and recovery. These must be disclosed publicly. Temporary votes may not give preference to particular addresses.

Queuing only adjusts the timing of payment. It cannot create reserves or eliminate losses. The loss-allocation scheme, the cap on bearing losses and the applicable asset version are all pending matters. Until these rules are completed, bridged representation assets may not be described as having an unconditional right to immediate redemption at face value.

## 7. Communication privacy, application protocols and RPC

### 7.1 Layer Minus

As described in v0.1, Layer Minus uses role separation between entry points and mailboxes, wallet addressing and OpenPGP encryption. Its aim is to reduce the chance that any single routing role learns at the same time the client's network location, the destination and the content.

Entry points can still observe the client's connection. Each communicating party knows the information it is authorised to obtain. Collusion between roles, one entity controlling several routing positions, global timing analysis or a compromised client would each weaken the relevant protection.

The carrier form, such as `POST /post` or an encrypted body, does not by itself prove that traffic is unrecognisable. Packet size, connection patterns, visible headers and request timing must all be included in measurement. Maturity is described in Chapter 11. This draft does not extend the production-capability claims without basis.

### 7.2 web3://

It continues the interface direction of v0.1: addressing by wallet or exact tag, caller signatures, encrypted correlated responses, and checks of request identifiers, nonces and expiry times. A prefix search result may not be automatically treated as an exact target, and a successful HTTP response at the routing layer is not the same as success at the application layer.

A signature proves that a call is authorised; it does not automatically hide the relationship between the signer and the service. Application host security, origin verification and the boundary of local service access must be verified separately.

### 7.3 RPC through Layer Minus

Submitting signed transactions through a privacy route can reduce the chance that an RPC service directly sees the client's IP address. It does not, however, change the visibility of the public fields once the transaction is executed. Queries may also expose the addresses or applications in which the user is interested.

An untrusted exit may refuse, delay or falsify query results. A client should rely on the corresponding state proofs or another explicit verification method. That several exits return consistent results is only auxiliary information and cannot replace proof of authenticity.

RPC routing is a separate work item. It cannot be used as a substitute for the protection of internal transaction relationships in DLE.

---
## 8. Interface between the order-book DEX and fragmentation

### 8.1 Matching and custody

The aim of the DEX is that users authorise orders, matchers discover matches, and the protocol completes asset exchange according to fixed rules. Matching authority must not include the power to transfer user assets arbitrarily, to change the payee or to spend an order twice.

Limit orders, partial fills, the order of cancellations, nonces, expiry, fees and batch replay protection must each be defined separately. A matcher's or verifier's revenue arrangement does not prove that it holds user assets. Whether actual control exists must be verified against the code and the permission graph.

### 8.2 Public settlement and DLE privacy settlement

| Settlement mode | Visible information | Privacy commitments that may not be made directly |
|---|---|---|
| Ordinary public EVM orders and transfers | Addresses, amounts, trades and call relationships are usually observable | Splitting orders alone does not justify a claim that the transaction chain is hidden |
| Matching mechanisms for hidden orders | Depends on the view of matchers and execution nodes | Commit-reveal alone does not guarantee confidentiality of the final trade graph |
| DLE rights-fragment settlement | Depends on the fragment representation, authorisation and validity proofs | Until end-to-end verification is complete, one may not claim that matching, settlement and withdrawal are unlinkable |

User-initiated order splitting, automatic order splitting by miners and private asset-state transitions must each be described separately. Order splitting is an execution strategy; it is not a substitute for cryptographic privacy mechanisms.

### 8.3 Compatibility of DLE types

An earlier draft stated that some existing DLE transaction types adopt NFT-style semantics. That statement has not been confirmed by the code review carried out for this revision. It cannot be used to conclude that the existing types support all transactions for fungible-asset fragments, nor to conclude directly that the whole underlying protocol must be modified.

An implementer must provide a mapping between asset types, fragment states, matching commitments and settlement proofs, and must choose either a justified application interface or a justified version extension. Different types must be domain-separated, so that a tip or event with the same name is not mistaken for another consumable asset.

## 9. Security invariants and verification scenarios

### 9.1 Invariants that must hold

1. **Issuance correspondence**: one valid deposit supports at most one corresponding rights issuance. The issued amount does not exceed the real receipt accepted under the rules.
2. **Fragment conservation**: for each asset class, inputs, outputs, fees and expressly destroyed amounts satisfy conservation and range constraints.
3. **Complete authorisation**: fragment transfers, order settlements, withdrawals and cancellations are each authorised by the relevant rights holder or satisfy publicly fixed verification rules.
4. **No double spending**: fragments, orders, deposit proofs and redemption requests all have replay protection within the correct domain.
5. **Complete redemption**: cumulative valid payments do not exceed the authorised request amount; confirmed payment and rights write-off correspond strictly.
6. **Mutually exclusive cancellation**: a source-chain request cannot be paid after final cancellation. Rights may not be restored merely because of a timeout unless the cancellation has been proven.
7. **No consolidation of reserves**: registered principal is not redeemed or reallocated in routine operation through a shared transit holding address.
8. **Distinguishing failure causes**: a failure at the payee side, for gas reasons or for permission reasons does not automatically become an external freeze fact for the paying DU.
9. **No expansion of permissions**: there is no hidden path through an upgrader, a verifier replacement, arbitrary calls or proxy configuration that bypasses authorisation.
10. **Accounting consistency**: W is not deducted twice from coverage; locking is not redemption; restriction is not loss; in-transit states can be reconciled.
11. **Bounded execution**: the cost of a single scheduling operation, of DU access and of state updates has an upper bound, and does not depend on iterating over all historical units without limit.
12. **Verifiable evidence**: important state changes are bound to trusted sources, versions and finality, and are not made effective by the declaration of any identity.

### 9.2 Audit and fault-testing matrix

| Scenario | Result that must be verified |
|---|---|
| The same deposit proof is submitted twice, or replayed across versions | No duplicate issuance |
| Front-running of deployment or initialisation, or theft of a depositId | Beneficial rights and payment rules cannot be altered |
| Forced transfer of dust into a DU, whether or not it is deployed | No new issuance authority is created and no registered rights are taken over |
| A cloned template has no code, or initialisation is incomplete | A formal deposit may not be registered as valid |
| In a multi-DU batch, a later transfer fails | The baseline atomic batch rolls back entirely; no partial payment followed by a whole-request write-off |
| The payee is restricted, the balance is insufficient, or gas is insufficient | The causes are distinguished and the state of other DUs is not contaminated |
| The same request is executed concurrently, re-entered or submitted from several source chains | Cumulative payments do not exceed the authorised amount |
| Source-chain payment and cancellation race, or messages arrive out of order | The request has only mutually exclusive final states, and paid rights are not restored |
| Source-chain reorganisation, forged state root, or stale freeze proof | Invalid or expired evidence cannot trigger issuance or restore availability |
| The token implementation or storage layout changes | Old parsing results are not silently used |
| A single DU is restricted externally | Its availability and the public rights-pool coverage are updated truthfully, and usable reserves are not overstated |
| Global token pause, a common-template flaw or a source-chain outage | Multi-unit or global impact is reported; the design does not claim that per-unit isolation is immune |
| Timing of trades, combinations of amounts and address reuse attacks | Privacy leakage is measured and compared with the P2 indicators defined in advance |
| DAO parameter votes and upgrade attempts | No arbitrary disposition of existing users' assets, and no decryption right, can be obtained through ordinary governance processes |

The table states testing requirements that should be implemented. It does not mean that the contracts or the cryptographic tests have been run for this revision.

---
## 10. Governance, developer roles and legal boundaries

### 10.1 Protocol, DAO, developers and users

| Party | Role boundary adopted in this draft |
|---|---|
| CoNET protocol | Open-source, permissionless base rules and execution system |
| DAO | Decides development direction, parameters and new-version matters under published governance rules; does not thereby automatically hold users' private keys or historical plaintext |
| CoNET Labs | Open-source technical developer; is not presumed to be a fiduciary operator of all transactions merely because it develops software |
| Nodes and matchers | Verify, relay or match under the published protocol; whether any additional custody or operating role exists is a question of fact to be judged separately |
| Users and third-party service providers | Bear responsibility for their own transactions and for the services they actually operate |

"Open source", "DAO" and "non-custodial" must each correspond to the real permissions. If a party can unilaterally change verification logic, co-sign payments or seize assets, this must be disclosed accurately. The absence of control may not be claimed merely by pointing to a name.

### 10.2 Boundary of governance powers

This design does not give the DAO the power to freeze units arbitrarily by name list, to read transaction plaintext, or to transfer reserves. Recording an external restriction state is a verification of fact; it is not an asset-management power newly granted to the DAO.

The DAO may decide research directions, parameter proposals and the direction of new versions under published rules. Upgrades, migrations and consensus changes that affect existing users' rights must state clearly their original authorisation, the conditions under which users may exit, and their trust assumptions. No claim may be made that any governance system is inherently immune to majority attacks or to all chain-fork disputes.

A deterministic rejection caused by failed cross-chain security verification is a way of handling invalid or unverifiable operations. It does not confer on an administrator a power to freeze valid user transactions arbitrarily.

### 10.3 Software development and money-transmission services

FinCEN's 2019 guidance distinguishes anonymising software providers from anonymising services that accept and transmit customer value. It states that merely creating a DApp does not automatically make one a money transmitter.[7]

Matthew Galeotti, then acting head of the Criminal Division of the U.S. Department of Justice, made remarks on 21 August 2025 (reported secondhand; the original text is to be verified). He stated that for software that is genuinely decentralised, executes peer-to-peer transactions automatically only, and involves no third-party custody or control of user funds, prosecutors would not bring new charges under 18 U.S.C. § 1960(b)(1)(C) against its developers. Other laws may still apply where criminal intent is shown. The remarks are not binding and cannot serve as a legal exemption.[8]

Legal assessment must therefore examine the actual conduct of a specific party, its control capabilities, its state of mind and its jurisdictional connections. It may not treat all developers and ordinary nodes as the same financial intermediary merely because the protocol offers privacy or because someone misuses it. Neither the above guidance nor enforcement policy constitutes a global or permanent statutory exemption.

### 10.4 Asset fragmentation and issuer policies

Whether the issuer's published acceptable-use policy (Circle Acceptable Use Policy) prohibits or restricts uses such as mixing or concealing the source of funds could not be verified against the original text in this draft's review. The "Section 3(g)" reference in the earlier draft is likewise unverified. Before this provision is cited, the current version of the text must be read and its version date recorded.[9] This draft keeps the technical classification of CoNET asset-right fragmentation. It does not treat that classification as a guarantee that every third-party term necessarily does not apply.

Third-party commercial policies on a service, technical descriptions of the protocol and court determinations about specific conduct must each be stated separately. There is no inference that "it is hard to trace, so the protocol is automatically unlawful", and no inference that "it uses fragmentation terminology, so all terms are automatically excluded".

Publication of this protocol does not depend, as a technical precondition, on an issuer's endorsement of the whole privacy network. When a particular third-party asset or regulated service is used, its specific permissions, contractual relationships and applicable law must be handled separately.

### 10.5 External asset permissions and legal measures

For assets whose issuer retains the ability to block or suspend addresses, CoNET cannot remove those external powers merely through an internal privacy protocol. Circle's public Stablecoin Access Denial Policy states that a blocked address loses the ability to send and receive, and its balance is locked on chain. It states that blocks are used for security threats (such as a compromised minting key) or for legal obligations from a competent authority.[10] Third-party reporting indicates that other agreements, such as Circle Mint's user agreement, may allow the issuer to suspend accounts at its own discretion, and that a batch of blocks in March 2026 was disputed. These reports are third-party accounts and have not been verified. It therefore cannot be assumed that every block is limited to the two categories above.

Derived addresses can provide a clearer locus for reserves and support analysis of the scope of a dispute. They are not a substitute for separation of ownership or for judicial immunity. Independent addresses, independent beneficial rights, general redemption claims and specific legal property rights may not be conflated.

On 26 November 2024, in *Van Loon v. Department of the Treasury*, the U.S. Court of Appeals for the Fifth Circuit held that OFAC exceeded its authority under IEEPA by placing immutable smart contracts on its blocking list, because those contracts are not "property" within the meaning of the statute, which can be owned. The decision concerns the designation of particular immutable contracts. It does not grant an exemption for all operational activity or for external token reserves. Subsequent proceedings and any later OFAC measures must be checked separately.[11]

### 10.6 Disclosure, audit and minimisation of permissions

The protocol may publish its code, its permission graph, aggregated issuance data and verifiable reserves. A user may disclose specific credentials or records that the user holds. Parties subject to applicable law must discharge their obligations in respect of the information they actually hold or control.

This draft does not require the creation of a network-wide decryption capability that does not otherwise exist. It does not interpret selective disclosure as meaning that an issuer can unilaterally penetrate all users' relationships, and it does not assume that any developer naturally holds every user's records.

## 11. Implementation status and evidence requirements

### 11.1 Current evidence grades

| Grade | Meaning |
|---|---|
| Project statement | Architecture, governance and role descriptions provided in the discussion |
| Earlier-draft reference | Repository paths or maturity descriptions from v0.1, not independently verified in this review |
| Proposed specification | Design constraints, processes and security objectives proposed in this draft |
| Verified implementation | A label that may be used only after evidence has been submitted, such as code version, build, deployment and test evidence |

This review confirms the document's logic and the external specifications it lists. It is not a security audit of the repository code referred to in the draft.

### 11.2 Component evidence matrix

| Component | Status adopted in this draft | Evidence required before a release conclusion |
|---|---|---|
| Layer Minus | The earlier draft describes it as implemented; not independently verified in this review | Code commits, role deployments, end-to-end and collusion tests |
| web3:// | The earlier draft describes a draft with v1 components; not independently verified in this review | Protocol version, client and host verification vectors |
| RPC through routing | Listed as a design direction in the earlier draft | Specification, implementation, state verification and performance results |
| Order-book DEX | Listed as a design study in the earlier draft | Matching and settlement specification, code, fault tests and audit |
| DLE asset-right fragmentation | Abstract model supplied in this draft; the concrete construction is to be confirmed | State transitions, verification algorithms, privacy model, conservation and double-spend proofs |
| CREATE2 deposit units | Proposed specification | Factory, templates, full dependency permission graph and audit |
| Source-chain proofs and cross-chain redemption | Proposed specification | Bidirectional verifiers, finality, mutually exclusive cancellation and replay tests |
| Coverage and loss allocation | Proposed accounting framework; governance parameters pending | Synchronised snapshots, risk-fund sources, and implemented allocation rules |

### 11.3 Migration of new and historical assets

If the existing external treasury cannot be upgraded, this scheme may not be described as adding a feature to the old contract directly. The migration methods actually permitted by the old contract, the users' rights, and the binding of proofs must be verified.

It is proposed that new deposits be carried by a new version that is publicly verifiable. Migration of historical reserves may not depend on withdrawals by an administrator without authorisation. The issuance and redemption proofs of the old and new versions must be kept distinct, so that the same reserves cannot support rights in both versions at once.

## 12. Pending decisions and release conditions

### 12.1 Pending decisions

| ID | Pending decision | Decider or submitter |
|---|---|---|
| Q1 | Concrete state representation, authorisation and privacy-proof method for DLE fragments | Developers submit a specification for review under the DAO process |
| Q2 | Public rights pool or independent redemption groups, and the corresponding risk disclosure | Determined by the DAO under published rules |
| Q3 | Allocation of shortfalls, sources of risk reserves, queuing and fair allocation | Determined by the DAO under published rules and implemented as verifiable code |
| Q4 | Conditions for source chains, token adapters, verifiers and finality | Developers submit a reproducible implementation and an independent audit |
| Q5 | Selection of withdrawal units, batch caps and privacy metrics | Developers submit a proposal and comparative tests |
| Q6 | Minimum accepted deposit and treatment of unregistered transfers | Proposed by developers; determined by the DAO under published rules |
| Q7 | Cancellation state machine, coexistence of old and new versions, and migration | Developers submit; holders' rights are handled under existing rules |
| Q8 | Real permissions of the DAO, Labs, nodes and verification dependencies | Public permission graph and code evidence |
| Q9 | Implementation maturity of each component and repository references | Maintainers complete commit hashes, specification versions and test results |
| Q10 | Verification of the original texts of external law and issuer policies (the Circle AUP use provisions, the DOJ remarks and the Van Loon judgment) | Legal assessors verify and record the version dates |
| Q11 | Freshness thresholds for pre-flight checks, the number of bounded retries, and queuing rules | Developers submit a specification for review under the DAO process |
| Q12 | Unified naming of the bridged representation asset, and its relationship to conet-USDC in the GB whitepaper | Operators and developers define jointly |

Core security mechanisms may not be left undetermined by pointing to pending parameters. In particular, Q1, Q3, Q4 and Q7 may not be regarded as complete merely because a numerical value has been supplied.

### 12.2 Production release conditions for the new components in this scheme

1. Complete the specification of the state, correctness and privacy boundaries of DLE fragments, with reproducible test vectors.
2. Publish the factory, the DUs, the verifiers, the control contracts and all administrative and upgrade paths, and demonstrate that the permissions match this draft.
3. Complete the implementation of deposit, issuance, cross-chain redemption, cancellation and exception states, and pass the key tests in Chapter 9.
4. Subject the code, the cryptographic constructions and the cross-chain trust assumptions to independent review proportionate to their risk.
5. Determine the rules for coverage shortfalls, risk funding, exit and recovery, and disclose them clearly to users.
6. Publish the source chain, the token implementations, the deployed bytecode, the build parameters and the source commit hashes.
7. Have the DAO decide the corresponding release matters under its existing powers, without granting any additional arbitrary disposition right over existing assets.

Written permission from a third-party issuer is not a single release gate for the development of the whole CoNET protocol. A specific party that connects to a commercial or financial service requiring a licence must separately satisfy that service's requirements and those of the applicable jurisdiction.

---

## Appendix C: External specifications and primary sources

The following materials were consulted as of 26 October 2026. They support the descriptions of the relevant technical mechanisms or legal boundaries. They do not constitute an endorsement of CoNET.

1. [EIP-1014: CREATE2](https://eips.ethereum.org/EIPS/eip-1014): the calculation of deterministic addresses.
2. [ERC-1167: Minimal Proxy Contract](https://eips.ethereum.org/EIPS/eip-1167): a minimal proxy that delegates to a fixed target.
3. [OpenZeppelin Contracts 5.x: Proxy / Clones](https://docs.openzeppelin.com/contracts/5.x/api/proxy): clone deployment, initialisation and implementation-code checks. A real project must pin a specific release.
4. [Circle stablecoin-evm official source code](https://github.com/circlefin/stablecoin-evm): restriction, pausing and transfer implementation for external tokens. A formal integration must be bound to a specific deployment and source commit, and must not rely only on the repository's master branch.
5. [Base: Transaction Finality](https://docs.base.org/specifications/transactions/transaction-finality) and [Base: Withdrawals](https://docs.base.org/specifications/base-protocol/bridging/withdrawals): the difference between transaction finality and the conditions for cross-domain withdrawals. These links have not been checked in this review.
6. [OpenZeppelin Contracts 5.x: SafeERC20](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20#SafeERC20): safe transfer wrappers and the interface for returning failure results. They do not replace a business settlement state machine.
7. [FinCEN FIN-2019-G001](https://www.fincen.gov/system/files/2019-05/FinCEN%20Guidance%20CVC%20FINAL%20508.pdf): the distinction between anonymising software providers and anonymising service providers. The specific section numbers have not been checked in this review.
8. [U.S. Department of Justice: remarks of 21 August 2025 by Acting Assistant Attorney General Matthew R. Galeotti](https://www.justice.gov/opa/speech/acting-assistant-attorney-general-matthew-r-galeotti-delivers-remarks-american): the link to the original remarks is to be verified. A secondary analysis is available in [WilmerHale's September 2025 client alert](https://www.wilmerhale.com/en/insights/client-alerts/20250910-doj-signals-approach-to-digital-assets-what-it-means-for-developers-and-platforms). The remarks are not binding.
9. [Circle Acceptable Use Policy](https://www.circle.com/legal/acceptable-use-policy): the use-restriction provisions. The "Section 3(g)" provision has not been verified; the current version must be read and its date recorded.
10. [Circle Stablecoin Access Denial Policy](https://www.circle.com/hubfs/Blog%20Posts/Circle%20Stablecoin%20Access%20Denial%20Policy_pdf.pdf): address-level restrictions and the circumstances in which the policy applies. The circle.com link shown here is the official site and differs from the link listed in the earlier draft.
11. [*Van Loon v. Department of the Treasury*, U.S. Court of Appeals for the Fifth Circuit, 26 November 2024](https://www.ca5.uscourts.gov/opinions/pub/23/23-50669-CV0.pdf): the limits of IEEPA sanctions authority over the relevant immutable contracts. The link has not been checked in this review. A secondary analysis is available in [Jones Day's December 2024 commentary](https://www.jonesday.com/en/insights/2024/12/fifth-circuit-reverses-tornado-cash-sanctions-ruling).

## Appendix D: Version record

| Version | Date | Content |
|---|---|---|
| v0.1 | Original discussion draft | Proposed the communication layer, the order-book DEX and the CREATE2 deposit-unit scheme |
| v0.2 | 26 October 2026 | Set out the roles of a permissionless protocol, DAO governance, Labs development and the absence of a regulatory backdoor; added the DLE fragmentation model; corrected reserve isolation, cross-chain redemption and coverage accounting; organised the evidence and release conditions |
| v0.3 | 26 October 2026 | Revised the v0.2 text: corrected coverage terminology and the relationship between D, A and F; added pre-flight checks and bounded retries; added a risk-control checklist; downgraded legal references to items requiring verification |

---
