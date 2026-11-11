# Node registry V2

**Status as of 10 November 2026.** NodeRegistryV2 is the next node registry for CoNET Guardian nodes. Its rules were decided by the operator and the user in November 2026. It is implemented and tested locally; it is not audited and not deployed. The deployment date will be announced after audit and acceptance.

**How to read the labels**

- **[Live]**: running on the network today.
- **[Implemented, pending acceptance]**: implemented and tested locally. Not deployed. Acceptance, an independent audit and a separate deployment approval are still needed.
- **[Approved, not yet live]**: a rule the operator has decided and published. It is not deployed.
- **[Open]**: not decided.

Unless marked otherwise, every rule from Section 2 on is **[Approved, not yet live]**, and the registry contract that enforces it is **[Implemented, pending acceptance]**. Some parameters are still to be decided; see [Open items](#7-open-items-open).

## 1. The registry in production today [Live]

- [`GuardianNodesInfoV6`](https://mainnet.conet.network/address/0xBC6b53065b5647261396d002bDBA0d3396E0722f) at `0xBC6b53065b5647261396d002bDBA0d3396E0722f` on CoNET L1 is the only node registry in production. It lists **472** nodes (snapshot at CoNET block 2,059,640).
- It is an administrator-maintained node table: `addNode` and `removeNode` require the admin list. It has **no staking rules**: no stake threshold, no service-quality suspension, no offline charges and no slashing.
- [`ValidatorDepositRedeem`](https://mainnet.conet.network/address/0xc71e246DD78B37C2fABc905D340932F28F503433) still reads node records from V6.

None of the rules below applies to V6.

## 2. Nodes and identities

- **The existing 472 nodes** form a fixed trusted set, initialised by the project from the V6 snapshot. They skip the admission vote and the voting cool-down for their first registration only. The trusted set never grows beyond 472, and an unclaimed place does not pass to a new node.
- **Node numbers** are assigned by the contract. Numbers below 100 are never valid. The 472 existing nodes keep numbers 100–571; new nodes start at 572.
- **Migration** starts with a first batch of at least 40 nodes from at least 5 operators, with no operator above 20 nodes. This is arranged in the deployment seed: the contract lets reserved places be claimed in batches, limited per operator wallet per 24 hours.
- **Wallets.** The operator wallet is separate from the node wallet. A node's main wallet can register a probe wallet on chain. The probe wallet shares the node's one vote and can vote on reports, admissions and recoveries. It cannot report, propose, apply for recovery, manage the node or become the main wallet. An execution reward earned through it goes to the node's beneficiary. The contract side is implemented; the node software side is in progress.

## 3. Stake and terms

- The initial stake is **5 CNET**. It is a deployment parameter that the DAO can change.
- A term lasts at least **six months** and at most **three years**. If the DAO raises the stake threshold, a node keeps its current threshold until its term ends.
- **Renewal.** At the end of a term, the contract checks the node's locked stake against the full threshold in force at that moment and renews the node if it is enough. The contract does not add funds: a shortfall must be topped up beforehand, from any wallet through the management web page (the payer gets no control over the node) or from the node's prepaid wallet. If renewal fails, the old threshold is not carried over, and topping up afterwards does not bring the node back by itself; it needs a recovery vote.
- **Suspension.** A node is suspended when its stake falls below **80%** of the threshold for its current term. A fine is checked against this line in the same transaction.
- **Rewards first fill the node's own stake shortfall**; only the rest is paid out.

## 4. Going online and coming back

- **New nodes** go online by admission vote. The applicant signs an application with its main wallet and asks a proposer node to propose it. Voting nodes each send their own encrypted challenge, which the applicant answers. The application and challenges travel off chain; the contract records the proposal and the votes.
- **Coming back after being offline** always needs a recovery vote that checks the node is actually reachable. This includes the 472 trusted nodes, nodes that topped up their stake, and browser nodes whose address did not change.
- **Going offline voluntarily** needs no vote. Coming back still needs one.
- After a node actually goes offline, it cannot come back online for **12 hours** (43,200 seconds). Changing address, wallet or entry does not reset this.
- **Online fee.** Each time a node goes online (first admission and each recovery), the applicant pays **0.01 CNET**. It is locked when the case opens, collected on success and refunded on failure or expiry. Where the collected fee goes is **[Open]**.
- **Admission and recovery cases:**

| Role | Outcome |
| --- | --- |
| Proposer node | Proposing counts as one yes vote; it cannot vote again. +0.01 CNET if the case passes; −0.001 CNET if it is rejected |
| Voters on the winning side | +0.001 CNET each |
| Voters on the losing side | −0.001 CNET each |
| Node whose vote decides the case and executes it | +0.005 CNET |

A node receives at most one reward per case, the highest that applies.

## 5. Reports of node violations

- Nodes probe each other with signed HTTP requests. Under the node software rules, a node opens a report only after **three** failed probes; the contract does not check this. A report goes to a vote, and a report alone never takes a node offline or fines it.
- The contract sets no daily limit on reports or votes. The node software votes even when gas is expensive.
- Every node can check a report and vote for or against under the same eligibility rules. The reporter's report counts as its yes vote.
- A new node, or a node that changed its controlling wallet, cannot vote for **7 days**. The 472 trusted nodes are exempt after their first registration.
- Fines are calculated on the fined node's term threshold. A node is fined at most once for the same kind of fine in one case, and never below zero.

Settlement of a decided report:

| Outcome | Reporter | Winning voters | Caller who completes settlement | Reserve |
| --- | --- | --- | --- | --- |
| Upheld | 7% | 56% | 7% | 30% plus rounding remainders |
| Rejected | none (the reporter bears the fine) | 63% | 7% | 30% plus rounding remainders |

- The winning share goes in equal parts to the first **18** valid votes in on-chain order, or to all winning voters if there are fewer.
- The reserve is kept separately in the registry and is spent only by DAO vote.
- A node under an open report is still paid when users pay it in third-party tokens ([Third-party tokens and subscriptions](third-party-assets.md)).

## 6. Voting time for every case

- Each node casts at most one vote per case.
- Every case has an observation period of **600 seconds** after it opens, during which votes are collected and nothing is decided. Voting ends **7,200 seconds** after it opens.
- A case is decided when its threshold is met and the 600 seconds have passed. It can also be decided earlier once the nodes that voted are strictly more than half of the nodes registered when the case opened, provided the vote margin is also met. Which nodes this count should include is **[Open]**.
- The vote that decides a case closes voting and settles the first batch in the same transaction. After the 600 seconds, anyone can also close a case whose threshold is met and receives that case's execution reward. Repeated calls never fine or reward twice.
- After 7,200 seconds the votes are frozen. Anyone can then close the case: if the frozen votes meet the threshold it is decided; otherwise it lapses. A lapsed case fines and rewards nobody, and locked amounts are released.
- If the stake pool is short, entitlements are recorded and paid after the pool is topped up, never twice.

## 7. Open items [Open]

- The minimum vote margin for reports (two values are under review).
- The pass threshold for admission and recovery votes.
- The fine standard for each kind of violation.
- Which nodes count for early closing by participation, and whether a minimum number is needed.
- Where the online fee goes.
- Which changes of controlling wallet start the voting cool-down.
- How a node's stake is handled when renewal fails.
- How GB earned from third-party token payments tops up a node's stake, which is in CNET.
- Batch sizes for continuing a settlement, and what the reserve is used for.

## Related

- [Guardian Nodes](guardian-staking.md)
- [Node and client roles](../l0/node-roles.md)
- [DAO and the next-generation treasury](dao-treasury.md)
- [GB purchase, metering, fees and settlement](gb-billing.md)
- [Third-party tokens and subscriptions](third-party-assets.md)
