# DAO and the next-generation treasury

**Status as of 11 November 2026.** This page describes how the CoNET DAO decides and how the next-generation treasury carries out its decisions on CoNET and on other chains. The rules were decided by the operator and the user in October and November 2026. Nothing on this page is deployed, and no address exists. The DAO and treasury contracts are implemented and tested locally; acceptance on CoNET, Base and Ethereum is not complete.

**How to read the labels**

- **[Implemented, pending acceptance]**: implemented and tested locally. Not deployed. Acceptance, an independent audit and a separate deployment approval are still needed.
- **[Approved, not yet live]**: a rule the operator has decided and published. Not deployed.
- **[Open]**: not decided.

## 1. Previous treasury

The current `TreasuryBridgeV3` on CoNET and Base is described on [Decentralized cross-chain Treasury](cross-chain-treasury.md). Its cross-chain bridge is paused, and support for new inflows through it will stop (decided, not yet live). The new system is a new deployment and does not reuse the previous CoNET and Base treasuries (decided).

## 2. How the DAO votes [Approved, not yet live]

- Voting weight is fixed at a snapshot when the proposal opens. Each unit of weight votes once.
- A proposal passes with **two thirds** of the snapshot weight voting yes. Once yes votes reach two thirds, no votes can no longer reach the one third needed to block it.
- **Observation period.** For **600 seconds** after voting opens, votes are collected and nothing is executed. This applies to every proposal, including node cases.
- **Voting window.** DAO proposals stay open for **7 days**. (Node cases in the node registry end after 7,200 seconds; see [Node registry V2](node-registry-v2.md).)
- **Execution.** Once the 600 seconds have passed and yes votes have reached two thirds, the proposal is closed and executed in the same transaction, by the next vote (yes or no) or by anyone who calls the closing function. This works before or after the deadline. There is no timelock, queue or execution multisig.
- **Rejection.** As soon as no votes exceed one third of the snapshot weight, the proposal is defeated, without waiting for the deadline.
- **After the deadline.** A proposal that reached neither two thirds yes nor one third no closes as expired.

## 3. Who can vote and propose [Approved, not yet live]

- A member registers by staking at least the minimum stake for a term of **one year** (365 days). The term length is fixed and cannot be changed by vote. The minimum stake starts at **500 CNET** and can be changed only by DAO vote.
- A first-time member can vote after **30 days** and propose after **180 days**. These waits are fixed. Renewals do not restart them.
- **Founder seats.** The first five registrants, starting with the deployer, are exempt from these waits. A seat is kept on renewal and lost on exit or cancellation; it is not reassigned. **Risk:** the deployer's wallets could hold all five seats, and until other members join, the five founder seats can pass any proposal on their own, including general calls to other contracts. The operator accepted this risk on 6 November 2026.
- A member who cancels stops renewal and can undo the cancellation within the term. A member who exits can withdraw at once.

## 4. What the DAO cannot change [Approved, not yet live]

The key addresses of the bridge and treasury are frozen at initialisation:

- Among the cross-chain decision types, none adds, replaces or upgrades a gateway, controller or contract.
- A route decision can choose only among controller and treasury addresses that the fixed AAC factory bound at initialisation. There is no function that sets a route to any other address.
- This limit applies to the cross-chain decision layer. The governor can still make general calls to other contracts that pass a vote.
- conet-USDC's backing asset on Base is bound to one fixed slot at initialisation.

**From decision to execution.** A DAO decision does not act on the bridge or token contracts directly. Once a proposal passes, the governor executes it by calling the AAC execution contract on CoNET, and that contract applies the decision to the bridge and token contracts, such as a channel stop or the mint and burn pause. On an external chain, the executor there acts only on a final CoNET decision (Section 5).

The DAO keeps the decided governance rules: per-asset limits, asset admission, circuit breakers, reopening, prices and fees. For each official stablecoin it can also close or reopen the cross-chain channel and turn the mint and burn pause on or off, separately; both are carried out on CoNET by the AAC contracts ([details](third-party-assets.md#51-two-switches-per-official-stablecoin-implemented-pending-acceptance)). How these decisions are made is in Section 6.

## 5. Next-generation treasury [Approved, not yet live]

- **One address on every chain.** The next treasury is to be deployed at the same address on CoNET and on each external chain the DAO supports. This is a design requirement; the address is not fixed yet, and same-address deployment is not complete.
- **No upgrades.** It has no proxy and no upgrade function. A later generation is a new deployment, moved to by DAO decision.
- **Deployment.** The fixed AAC factory deploys the treasury, GB, wCNET and the conet-USDC ledger at initialisation. GB and wCNET have no administrator; cross-chain minting, burning and route activation belong to the treasury.
- **Routes start closed.** New assets are registered as candidates in the deployment transaction. Their routes in both directions stay closed until a final CoNET DAO decision to enable them, verified by AAC.
- **External executors.** On each external chain, an executor at the same address acts only on a CoNET DAO decision that has been executed and is final. It checks the target chain, the treasury or executor, the action and replay protection before it acts. How CoNET finality is judged, and whether the treasury accepts calls only from the executor, are **[Open]**.

## 6. Stablecoin channel and pause decisions [Implemented, pending acceptance]

Candidates are versions of the DAO contracts under review; only a locked candidate can be deployed. These rules govern how the DAO stops and reopens a stablecoin channel and sets the mint and burn pause described in [Third-party tokens and subscriptions, Section 5.1](third-party-assets.md#51-two-switches-per-official-stablecoin-implemented-pending-acceptance).

**[Implemented, pending acceptance]** in candidate 4, with local tests. Candidate 4 is not locked; candidate 3 remains the locked candidate. Nothing is deployed, and independent acceptance is not complete.

> **Status: design settled; implemented locally in candidate 4; not deployed.** The locked candidate is still candidate 3. Candidate 4 has not been pushed, deployed, or released.

### 6.1 Two-direction pairing for channel stops

A stop or a reopening of a stablecoin channel is one DAO decision that names both directions. Both records must be in the same proposal, with the same action, epoch, token standard, and channel. A record that names one direction alone is refused.

### 6.2 Commitment to the proposal's calls

Each channel resolution commits to the other calls of its proposal. The contract checks that commitment against those calls, leaving out the resolution records themselves, so a decision cannot be attached to a different set of calls.

### 6.3 Mint and burn pause for stablecoins

A DAO decision can pause or resume minting and burning on CoNET for an official stablecoin or for conet-USDC, under one switch. Only the DAO decision path can set the switch. Third-party stablecoins are not in this class.

### 6.4 A fixed template for official stablecoins

Each official stablecoin is deployed from one fixed template. The template is pinned at initialization, before the factory is sealed, and an admission decision must name that template. The external address of the channel is set by the admission decision.

### 6.5 Admission of the external copy

An official stablecoin is admitted only by its admission decision. Its external copy is then activated on its channel. It is not registered again through any other path.

### 6.6 Direct reads of the registry

CoNET-side contracts read the channel-stop state and the mint and burn pause directly from the registry's read-only views. No contract keeps its own settable copy of these switches.

### 6.7 Cross-chain message identifier

Each transfer message has one cross-chain identifier, the messageId. It is a hash of the message fields under a fixed domain tag, "BeamioBridgeProof:v1", so both sides derive the same identifier from the message, and a changed field names a different message. The exact field layout is being finalized.

### 6.8 In-transit messages during a channel stop

- A stop does not change the deadline of any message.
- A stop refuses new transfers and deliveries in the stopped direction. It does not stop the close of an expired message, and it does not stop a refund.
- A message can be delivered at most once, up to its deadline. After the deadline the destination can close it, and a closed message can never be delivered.
- A refund requires proof that the destination closed the same message. Delivery and refund are mutually exclusive, and the destination chain's state decides which one happens.
- A refunded message is void for good. A replacement needs a new nonce and the same fields, and it can only follow the refund.

### 6.9 A stopped direction is reopened before it is stopped again

A channel direction that is already stopped cannot be stopped again. It must be reopened first, and a reopening of a running direction is refused.

## 7. Implementation status

| Item | Status |
| --- | --- |
| DAO voting and membership rules (Sections 2 and 3) | **[Implemented, pending acceptance]**, local tests |
| 90-day GB price cap | **[Implemented, pending acceptance]** for conet-USDC, local tests |
| Cross-chain decision types and route binding | **[Implemented, pending acceptance]** on the governance side; not yet wired into the factory |
| Next-generation treasury | **[Implemented, pending acceptance]**, local tests; freeze checks not all passed; same-address deployment on CoNET, Base and Ethereum not complete |
| Channel stop pairing, call commitment, mint and burn pause, official stablecoin template and admission, registry reads, message identifier, in-transit messages (Section 6) | **[Implemented, pending acceptance]** in candidate 4, local tests ("Design settled; implemented locally in candidate 4; not deployed."). Candidate 4 is not locked; candidate 3 remains the locked candidate. Not deployed |
| External executors | Implemented locally; acting on a final CoNET decision with a real proof is **[Open]** |
| Deployment | None. Addresses will be published after audit and a separate deployment approval |

## 8. Open items [Open]

- Rules for how often voting thresholds may be changed.
- Whether voting weight follows the locked amount.
- How CoNET finality is judged for external execution.
- The fixed address of the next-generation treasury.

## Related

- [Two-way AAC bridge](aac-two-way-bridge.md)
- [GB purchase, metering, fees and settlement](gb-billing.md)
- [Third-party tokens and subscriptions](third-party-assets.md)
- [Node registry V2](node-registry-v2.md)
- [Decentralized cross-chain Treasury](cross-chain-treasury.md)
