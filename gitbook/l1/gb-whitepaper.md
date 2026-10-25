# GB Whitepaper: CoNET DePIN Payment Token

**Version:** v0.3 (merged draft) | **Date:** 25 October 2026 | **Basis:** the v0.1.2 treasury-operations revision, the v0.2 working draft, and operator decisions of 22, 24 and 25 October 2026 | **Status:** DAO discussion draft. Not approved by the DAO; not on-chain.

Let real cloud services create payment demand, and let real protocol revenue build resilience against shocks.

**How to read the labels**

- **[Decided]**: a rule the operator has explicitly decided, with the decision date. An operator decision is not DAO approval.
- **[Pending]**: a parameter or rule not yet decided. Listed in Chapter 19.
- Content without a label follows the proposed rules of v0.1.2.
- This document describes proposed rules. It does not mean that the contracts, fees, treasury operations or recovery mechanisms described here have been deployed. Public project records and the deployment status of this proposal must be verified separately. [1][2][3]

---

## Summary

GB is the payment token of CoNET DePIN. It is used for network forwarding, cloud computing, SaaS, storage and related application services. GB has two classes:

- **Paid GB**: carries a right of exit, and can be transferred, traded and bridged across chains. New issuance may in principle come only from burning conet-USDC. The only exception is the new paid GB minted to a miner after the miner burns free GB; it is backed by the treasury risk reserve.
- **Free GB**: distributed by an airdrop contract within a voted budget. It can only be consumed, has no right of exit, cannot be transferred or traded, and is burned by the miner that provides the service.

Exiting paid GB means burning GB and minting conet-USDC. The only reserve asset of GB is Base USDC. The USDC locked on Base behind the conet-USDC burned when a user issues GB becomes GB base backing; when the user exits, that USDC returns to the reserve behind conet-USDC.

The protocol collects three fees: a 0.1% issuance fee and a 0.1% exit fee, both credited in full to the treasury risk reserve; and a miner settlement fee of 0.5% of the service price, borne by the miner and split according to a DAO-published ratio between DePIN network maintenance and redevelopment and the GB treasury.

Treasury open-market operations (AMO) may sell newly issued paid GB, but accept only conet-USDC, at a price not below the official rate, and burn the conet-USDC received in the same transaction. AMO may also buy back and cancel GB. Rebalancing, trades within AMO limits and circuit breakers are executed automatically by the contracts within parameters set by DAO vote. There is no privileged execution address.

GB's price is supported jointly by treasury reserves and the combined endorsement of the whole DePIN network, and is stabilised through market arbitrage and automatic market making by the issuer. This mechanism is not a redemption guarantee (Section 13.7).

GB has no execution multisig. Every matter that requires authorisation is a proposal, executed directly in the voting transaction by the voters whose yes votes reach two-thirds of the snapshot total weight.

The economic structure of GB has two separately measured parts: DePIN services that can be measured, verified and delivered, and the treasury assets that support exit. Service value creates demand for use; the backing and risk reserve support exit capacity. The two must not be double-counted.

---

## 1. Positioning and principles

### 1.1 Payment use

GB serves the CoNET DePIN resource market, including encrypted traffic forwarding, CPU/GPU tasks, application hosting, SaaS services and storage. Other applications, merchants and miner suppliers may voluntarily accept paid GB, so that the payment network can expand with real demand. [1]

A miner is a participant that provides the above resources or services. A miner's service revenue comes from actual user purchases and settlement, not from the mere existence of a node, capacity registration or price quotation. Any other node-reward mechanism should be disclosed separately from the GB user-payment system.

### 1.2 Four principles

| Principle | Protocol requirement |
| --- | --- |
| Real resources support use | Resource capacity, service terms, delivery evidence and dispute procedures can be verified |
| Real assets support exit | At issuance, the principal of each paid GB has matching Base USDC base backing; cross-chain liabilities are not backed twice. Any part of a rate increase beyond backing is bounded by the coverage constraint (C_min floor 10%, Section 2.3) and is not treated as fully backed (decided 25 October 2026) |
| Circulation and cancellation are separate | Payments transfer paid GB; user exits and treasury cancellations are recorded separately; consumption does not extinguish exit obligations |
| Revenue supports the network and a risk buffer | Issuance and exit fees go to the treasury; miner settlement fees support network maintenance, redevelopment and the treasury, recorded by use |

### 1.3 Token classes

| | Paid GB | Free GB |
| --- | --- | --- |
| Source | See Chapter 5 | Airdrop contract within a voted budget (Chapter 8) |
| Right of exit | Yes; burn to mint conet-USDC | No |
| Transfer and trading | Yes | No |
| Cross-chain | Yes | No |
| Use | Payment for services, transfer, trading, exit | Payment for services only; burned by the miner providing the service |
| Counted in exit obligation L | Yes | No |

- **[Decided]** New issuance of paid GB may come only from burning conet-USDC (22 October 2026). The miner-mint path is a risk-reserve-backed exception (24 October 2026, see Section 5.2).
- **[Decided]** Only paid GB may cross chains (scope v2 draft D7).
- **[Decided]** Free GB may only be consumed; it has no right of exit and cannot be transferred or traded, and is burned by the miner providing the service (24 October 2026).

GB does not confer on holders any automatic right to protocol profit, to the treasury's entire net assets, or to DAO governance. The source of governance rights and the voting mechanism are set out in Chapter 15.

---

## 2. Rate and price

### 2.1 Reference unit from standardised forwarding services

GB's resource reference is based on standardised cloud services. Initially, "the price of completing one GB of metered data forwarding" may serve as the base observation. The metering unit must be stated in the service catalogue; for example, 1 GB = 10^9 bytes, to avoid confusion with the token symbol GB.

A standard forwarding service must declare the region, payload definition, bandwidth and latency requirements, availability, redundancy, retransmission on failure and service taxes. Traffic of different service quality may not be treated as the same product, and internal forwarding at each hop may not be treated as a separate paid user service.

After the service definitions are unified, the DAO establishes a resource reference basket covering forwarding, computing, storage and SaaS. CPU/GPU, storage periods and application services need their own measurement units and delivery conditions, and are quoted in GB through a public conversion table.

**Standard price and provider pricing [Decided]** (25 October 2026): the standard price of a service is 1 GB paid for each 1 GB of billed traffic, or for one standard service unit defined in the conversion table. Providers have the right to set their own price: they may raise or lower it from the standard price by any percentage, with no upper or lower limit:

> GB paid by the user = standard quantity × (1 + provider's markup or discount)

For example, if a provider prices at the standard price +10%, a user who uses 1 GB of traffic pays that provider 1.1 GB; at −20%, the user pays 0.8 GB. The markup or discount must be published in the service catalogue and bound by the order signature, and cannot be changed during settlement. The same applies when paying with free GB (Section 8.2). **[Pending]** The standard units for non-traffic services such as CPU/GPU, storage and SaaS.

### 2.2 Three prices

| Price | How it is set | Use |
| --- | --- | --- |
| Resource service quote | The standard price (1 GB of traffic for 1 GB) plus the provider's own markup or discount (**[Decided]** 25 October 2026, Section 2.1) | Determines how many GB one service payment costs |
| Official rate R | Decided by DAO vote (**[Decided]** 22 October 2026) | Number of conet-USDC for each paid GB issued or exited |
| Secondary-market price | Free trading on swaps and other markets | Exchange of assets between holders |

Because issuance and exit use only conet-USDC, the official rate R is expressed directly as conet-USDC per GB and requires no price source for other assets. R is denominated in USDC; it does not mean that each GB is fixed at one US dollar, nor that USDC always equals one US dollar. Risks to USDC itself, such as de-pegging or freezing, are reserve-asset risks (Chapter 12).

### 2.3 Rate adjustments

**[Decided]** R is decided by DAO vote and executed by the yes-voters after passage (22 October 2026).

The DAO periodically reviews resource costs, effective volume, capacity and service quality, and publishes the data basis, parameter version and effective time.

Adjusting the rate changes the exit amount of every outstanding paid GB, so the following rules apply:

1. **Rate increases [Decided]** (24 October 2026): an increase raises the obligation L. The proposal must state coverage after the increase; if coverage after the increase falls below C_min, the contract refuses execution. The floor for C_min is 10% (operator decision of 25 October 2026), and this floor also applies to rate increases. Under Section 15.1, a vote whose execution fails is not counted, so such a proposal cannot pass. A rate increase may not be presented as creating a surplus for the treasury merely because the posted rate rose.
2. **Rate decreases [Decided]** (25 October 2026): decreases are allowed. A decrease reduces the exit proceeds of holders and is a change in holders' rights. A single change may not exceed 50% of the current rate, and there is no notice period. Decreases are also subject to a cumulative cap per period, the same as for increases (20%, calculated over 90-day periods).
3. **Front-running protection [Decided]** (24 October 2026): votes accumulate publicly, vote by vote. To prevent anyone from issuing or exiting at the old rate just before the vote approaches two-thirds, a proposal must state a future effective block. Execution upon passage records only the new rate and the effective block, and the contract switches automatically at that block. Between passage and the effective block, issuance and exit at the old rate are subject to a per-period cap. Each quote and authorisation is bound to a rate version.
4. **Single and cumulative limits [Decided]** (25 October 2026): each change to the official rate may move it by no more than 50% of the current rate (after a decrease, the rate is not below 50% of the current rate; after an increase, not above 150% of the current rate). Increases and decreases each have a cumulative cap: within each 90-day period, the cumulative change may not exceed 20% of the current rate.

---
## 3. Participants, asset layer and AAC

### 3.1 Participant roles

| Participant or module | Main responsibilities |
| --- | --- |
| User | Issues or buys paid GB, receives free GB, authorises payment, confirms service or raises a dispute, and exits under the rules |
| Miner | Provides deliverable resources, submits the necessary evidence, earns paid GB revenue, and burns the free GB of the users it serves |
| GB contract and settlement module | Records the two balances; executes payment, issuance, exit, burning of free GB and fee allocation |
| Airdrop contract | Distributes free GB within the budget and rules set by DAO vote |
| Treasury operations module (AMO) | Automatically executes sales, buybacks and cancellation of new GB within voted parameters |
| Risk control module | Automatically executes rebalancing constraints, limits and circuit breakers within voted parameters |
| AAC and cross-chain module | Verifies external lock or burn facts, confirms finality, and constrains one-time settlement; **[Decided]** tokens issued on CoNET are minted on external chains by the AAC secure construction (24 October 2026) |
| External treasury and asset ledger | Holds Base USDC and separates conet-USDC backing, GB base backing, risk reserve and pending-settlement occupancy; **[Decided]** cross-chain tokens are deployed at one address on external chains, and the treasury holds no minting right (24 October 2026) |
| DAO and voters | Propose and vote on proposals; once yes votes reach the threshold, the yes-voters execute |
| Swap and independent market makers | Provide exchange between existing paid GB and other assets, without thereby issuing GB |

**[Decided]** There is no execution multisig. Matters that require authorisation are all DAO proposals, executed by the yes-voters after passage (22 October 2026). **[Decided]** Daily risk control is executed automatically by the contracts within voted parameters, and there is no privileged execution address (24 October 2026).

CoNET L0 provides the resource plane; L1 carries assets, state and settlement. The AAC process is the settlement boundary this scheme requires. Its actual activation status, source-chain proof capability and custody rights must be verified against deployment evidence, and it must pass the safety gate in Chapter 17 before it opens. [1][2][3]

### 3.2 conet-USDC and Base USDC reserves

**[Decided]** conet-USDC has only two minting paths (22 October 2026):

1. Base USDC is deposited cross-chain into the external treasury and locked there, and conet-USDC is minted on CoNET;
2. paid GB is burned, and conet-USDC is minted.

There is no admin or owner minting, and no upgrade authority (operator decision, 25 October 2026). conet-USDC is deployed and used as a new contract (operator decision, 25 October 2026). How the existing conet-USDC supply migrates is pending.

**Outbound [Decided]** (25 October 2026): when conet-USDC leaves CoNET, it is burned on CoNET and the external treasury releases the locked Base USDC. Releases are capped by the locked balance, and nothing is minted on Base. This matches Chapter 4, point 5: external-native assets are released by the external treasury on exit. The release depends on the Base side verifying the CoNET burn. **[Decided]** (25 October 2026) This release path is also subject to the forged-message gate in Chapter 17: before it opens, it must be proven that the Base side rejects forged CoNET burn messages.

Base USDC locked in the external treasury is accounted for by use, and each unit may serve only one use:

| Account | Meaning |
| --- | --- |
| conet-USDC backing | Corresponds to circulating conet-USDC |
| GB base backing | Corresponds to circulating paid GB with a right of exit; the amount is L |
| Risk reserve | Net treasury assets with no matching liability, able to absorb losses |
| Pending-settlement occupancy | Cross-chain transfers in transit, and accepted exits not yet completed |

When a user burns conet-USDC to issue paid GB, the corresponding Base USDC moves from "conet-USDC backing" to "GB base backing" and the "risk reserve"; when the user exits, the movement is reversed. These transfers only change the accounting attribution and require no movement of funds on Base, but the on-chain records must correspond entry by entry to the burns and mints on the CoNET side.

### 3.3 One-time settlement and recovery

The same cross-chain event may be confirmed, retained and completed only once. Source-chain reorganisations, expired proofs, replays, retries and concurrent requests must not cause duplicate minting or duplicate release. In-transit assets, committed but unpaid assets and available assets are accounted for separately.

The cross-chain process cannot assume that two chains execute atomically. It must provide traceable pending states, timeouts and recovery rules. A claim arising from GB already burnt but not yet paid must not be lost through interface errors, retries or contract pauses.

---

## 4. Cross-chain GB

All of the following rules are **[Decided]**.

1. **Outbound** (22 October 2026): paid GB may be minted on an external chain only when the corresponding paid GB is burned on CoNET. No other minting route exists on external chains, including ERC-20 tokens issued by developers and bridged across. wCNET is the same: wCNET on an external chain may be minted only after wCNET is burned on CoNET, with no second method (operator decision, 24 October 2026).
2. **Inbound** (22 October 2026): there is only one case. An external chain burns a CoNET-issued asset, the user bridges back to CoNET, and CoNET mints the asset. Release from custody is not an inbound method.
3. **Deployment and minting right** (24 October 2026): a CoNET-issued token that can be bridged is deployed by the external treasury at the same address as on CoNET, on all external chains. The minting right is held by the AAC secure construction; the treasury holds no minting right.
4. **External total** (24 October 2026): the total GB on external chains equals the net outbound burn on the CoNET side; changes are determined on the CoNET side.
5. **External native assets** (24 October 2026): Base USDC, and external ERC-20 tokens that the DAO later votes to bridge, are locked in the external treasury on inbound, and CoNET mints the corresponding asset. On outbound, the external treasury releases them, and nothing is minted on external chains.
6. **One-to-one**: outbound burns and external minting, and external burns and inbound minting, must correspond one to one. Replays or duplicate submissions may not create additional supply.

A holder of GB on an external chain who wishes to exit must first bridge back to CoNET. The exit obligation is therefore calculated on global supply:

> L = R × (paid GB circulating on the CoNET side + GB circulating on each external chain)

Outbound burns and external minting only change location. They may not be counted as a supply contraction, nor as new capital.

---

## 5. Sources of paid GB

### 5.1 Overview of sources

| Source | Basis of issuance | Corresponding backing | Status |
| --- | --- | --- | --- |
| User issuance | Burning conet-USDC (Chapter 6) | Base USDC behind the burned conet-USDC | [Decided] 22 October 2026 |
| AMO sales | Conet-USDC received is burned in the same transaction (Chapter 13) | As above | [Decided] 24 October 2026 |
| Cross-chain inbound | External burn, verified through an AAC proof (Chapter 4) | Backing that already existed at outbound; crossing adds no new backing | [Decided] 22 October 2026 |
| Miner mint (exception) | Miner burns free GB; minted at a DAO-voted ratio (Section 5.2) | Base USDC transferred from the risk reserve | [Decided] 24 October 2026 |

**[Decided]** The new GB contract removes the following two existing entry points (24 October 2026):

1. direct minting of paid GB by an admin;
2. minting of paid GB after burning developer FX tokens.

Apart from the four sources in the table above, no address holds a minting right for paid GB.

### 5.2 Exception backed by the risk reserve: miner mint

**[Decided]** (24 October 2026): after a miner serves a user and burns that user's free GB, the contract mints paid GB to the miner at the ratio k set by DAO vote. For each mint, an equivalent amount of Base USDC is moved from the risk reserve into GB base backing. Minting is paused if the risk reserve is insufficient.

This is the only exception to the rule that paid GB may be issued only by burning conet-USDC. The newly minted GB is fully backed by Base USDC, but the backing comes from the risk reserve the treasury has already accumulated, not from conet-USDC burned at the time.

If a miner burns b units of free GB, then:

> New paid GB minted m = k × b
>
> Transfer from the risk reserve = R × m
>
> Assets after the operation A′ = A (the risk reserve is already counted in A, so moving it into base backing does not change A)
>
> Obligation after the operation L′ = L + R × m
>
> Change in surplus = −R × m

This path therefore does not take coverage below 100%, but it consumes surplus, reduces coverage, and competes directly with the 115% capital-accumulation target.

**Pause condition [Decided]** (24 October 2026): minting proceeds only if coverage A ÷ L′ after the mint is still not below the minimum C_min, and the single-period minting amount set by the DAO is not exceeded. If not, the miner's burn record enters a pending-reissue queue, and is reissued in order once the risk reserve recovers. The pending-reissue queue is a future commitment to miners. It is not counted in L, but it must be disclosed separately. **[Decided]** (25 October 2026): the initial value of k is 0.01, to be adjusted later by DAO vote; the single-period quota is 1% of the obligation L, calculated over 90-day periods; the pending-reissue queue is capped at 1% of L; transfers from the risk reserve are recorded entry by entry in the reserve-ledger contract.

Example: A = 1.15 million USDC, L = 1 million USDC (coverage 115%), R = 1, C_min = 110%. A miner burns 10,000 free GB, with k = 0.5 (an illustrative value, not the initial value), and mints 5,000 paid GB. After the operation L′ = 1.005 million, A is unchanged, coverage is about 114.43%, and the surplus falls from 150,000 to 145,000. Provided coverage stays at or above 110%, at most about 40,500 more GB could be minted after this mint.

In the early stage the risk reserve is small, so this path will be paused for most of the time. How much a miner who serves free users is compensated depends on the surplus the treasury has accumulated. The DAO should disclose this to miners accurately.

---
## 6. User issuance of GB and the 0.1% issuance fee

### 6.1 Charging basis

Let a user issue N paid GB, with the official rate R conet-USDC per GB and an issuance fee rate f = 0.001.

> Issuance principal Q = N × R
>
> Issuance fee F = Q × f
>
> conet-USDC burned by the user = Q × (1 + f)

A quote must state the exact conet-USDC amount, the rate version, the expiry time, the fees, and the net GB received.

### 6.2 Assets and liabilities

After the contract burns all the conet-USDC paid by the user, it mints N paid GB against the principal and does not mint GB for the fee. Of the corresponding Base USDC, Q moves to GB base backing and F moves to the risk reserve.

Example: a user burns 100.10 conet-USDC and receives paid GB corresponding to a principal of 100 USDC at rate R. On Base, 100 USDC moves to GB base backing and 0.10 USDC moves to the risk reserve.

If the user enters a payment budget B, the interface must back-calculate the net issuance quantity N = B ÷ (R × 1.001). It may not convert the whole budget into GB and then charge a fee implicitly. A failed operation does not create earned protocol fees.

### 6.3 Admission to issuance

Before execution, the following are checked together: the rate version is valid; the Base USDC backing for the conet-USDC is available; the source-chain and CoNET states are normal; and the resource capacity and transaction limits are met. If the reserve asset is restricted, issuance may not continue at the original rate, because that would pass the loss on to all holders.

---

## 7. Payment to miners and the 0.5% settlement fee

### 7.1 Users pay the price; miners bear the protocol fee

The fee basis is the gross service price of the service order. Let the service price be G paid GB:

> User payment = G
>
> Settlement fee borne by the miner = G × 0.5%
>
> Miner net revenue = G × 99.5%

For example, a service quoted at 100 GB: the user pays 100 GB, the miner receives 99.50 GB, and the protocol fee account receives 0.50 GB. Before payment, the gross price, the fee borne by the miner and the miner's net revenue are displayed. The signature binds the service order, the payee, the amount, the fee rate and the allocation-parameter version.

The protocol fee is charged once per user settlement event. Internal routing, order splitting and multi-hop delivery by a miner may not charge the same order twice. Where the proceeds are shared among several miners, the fee is charged once on the aggregate gross price of the order and the net revenue is then allocated.

The 0.5% settlement fee is allocated between the GB treasury and the DePIN network according to a ratio r published by the DAO: the treasury receives r, and DePIN network maintenance and redevelopment receive 1 − r. The allocation parameters are configured before execution, are fixed by the authorised order version, and may not be changed retroactively after authorisation or during settlement. The initial value of r is 50% (decided 25 October 2026), to be adjusted later by DAO vote. At settlement, the treasury's share is cancelled outright, and the network's share is transferred directly to the protocol fee address, which the DAO changes by a two-thirds vote (decided 25 October 2026). That address is a plain address; it is held by a holder designated by the DAO, who spends within approved purposes. The contract does not constrain the scope of its spending (decided 25 October 2026).

**Boundary on spending from the network-share address [pending confirmation]**: the address is a plain address, and its spending is not constrained on-chain. The principle of "no privileged execution address" (operator decision, 24 October 2026) concerns the daily risk-control operations that the contracts execute automatically within voted parameters; the budgeted spending of the network share does not fall within that scope. Spending must match the purposes approved by the DAO, but it is not enforced by the contract, and any change of holder requires a two-thirds DAO vote. How spending records are disclosed is pending. This boundary must be confirmed by the operator before it is finalised.

### 7.2 Consumption is a transfer of ownership

After a user pays with paid GB, the GB remains in circulation. A miner may then pay suppliers, buy other services, trade on a swap, or enter the official exit process. Consumption does not reduce the total GB supply, nor does it cancel the exit obligation attached to those GB.

**[Decided]** (24 October 2026): the new settlement module settles paid GB by transfer, and does not adopt the approach of "first burning the user's GB, then minting for the miner". The settlement module holds no minting right for paid GB; on-chain supply changes only with the sources in Chapter 5.

### 7.3 Fee boundary and delivery evidence

The 0.5% settlement fee is charged only in the designated settlement module. It is not extended into an automatic fee rule for ordinary ERC-20 transfers. Ordinary wallet transfers, independent DEX trades and internal protocol allocations do not trigger the fee. This reduces the compatibility burden on wallets, DEXs, bridges and applications, since tokens that deduct fees automatically on transfer face compatibility limits in routers such as Uniswap v3 [4].

Settlement depends on clear delivery conditions, for example a valid service receipt, a measurement agreed by both parties, verification of a task result, or the end of an agreed dispute period. A task cancelled before completion is not charged. Refund liability, evidence and deadlines are set in the service agreement, and the same refund is not charged twice.

Only the necessary settlement commitments or summaries of evidence are published; traffic and task content are protected by the relevant encryption protocols. If a transfer bypasses the settlement module, the protocol cannot recognise the nature of the service and cannot obtain that revenue.

---

## 8. Free GB

### 8.1 Distribution

**[Decided]** Free GB is distributed by the airdrop contract within the budget and rules set by DAO vote, and no admin is established (24 October 2026). The budget, the rules for recipients and the single-period total are set by proposal and published. Unused quota in a period does not carry over (operator decision, 25 October 2026).

### 8.2 Use and burning

**[Decided]** (24 October 2026)

1. Free GB may be used only to pay for DePIN services.
2. Free GB has no right of exit, cannot be transferred, cannot be traded, and cannot be bridged across chains.
3. Free GB is burned by the miner providing the service, when the service settlement is completed.

The settlement module must verify that each burn corresponds to a real service order and delivery evidence, under the same rules as Section 7.3. This prevents miners and users from colluding to burn free GB through fictitious services and thereby obtain newly minted paid GB.

**[Decided]** (25 October 2026) Free GB settlement also applies the provider's markup or discount (Section 2.1). Because markups have no upper limit, a miner could charge free-GB users a large markup to burn more free GB and receive more newly minted paid GB. The constraints are the free-GB distribution budget, the per-period quota and pending-reissue queue cap of the miner mint (Section 5.2), and the published markup. These constraints limit the total, but cannot stop a single miner from receiving more within the quota.

### 8.3 Accounting

Free GB has no right of exit, so it is not counted in the exit obligation L and does not take up any reserve. Distributing free GB does not change coverage.

Paid GB that a miner receives after burning free GB is backed by the risk reserve under Section 5.2 and is counted in L.

**[Decided]** (25 October 2026): when a user holds both classes of GB, service settlement deducts free GB first and then paid GB, consistent with the current contract. Free-GB settlement also charges the 0.5% settlement fee, borne by the miner. The fee basis is the value of the burned free GB at the official rate (decided 25 October 2026; basis pending confirmation).

---
## 9. Paid GB exit and the 0.1% exit fee

### 9.1 Gross and net

A user exits N paid GB:

> Gross redemption amount Q = N × R
>
> Exit fee F = Q × 0.001
>
> conet-USDC received by the user = Q × 0.999

**[Decided]** Burning paid GB mints conet-USDC (22 October 2026).

When a user authorises an exit, the user should see the number of GB to be burned, the gross redemption amount, the 0.1% protocol fee, the net conet-USDC received, the external withdrawal conditions, and any separately paid network costs.

### 9.2 Mint only the net amount

**[Decided]** (24 October 2026): the contract mints only the net conet-USDC for the user, and mints no conet-USDC for the exit fee. The Base USDC corresponding to the exit fee moves directly from GB base backing to the risk reserve. This avoids minting the fee portion first and then cancelling it.

| Exit of a gross 100 USDC | Treatment |
| --- | --- |
| Paid GB burned | Obligation L falls by 100 |
| User receives | 99.90 conet-USDC minted; the corresponding 99.90 Base USDC moves from GB base backing to conet-USDC backing |
| Exit fee | 0.10 Base USDC moves from GB base backing to the risk reserve; no token is minted |

### 9.3 Exit is separate from market trading

Selling paid GB to other market participants, or accepting a treasury buyback, is not an official exit. No 0.1% exit fee is charged on such sales, but the trading fees and network costs of the relevant market may apply.

An accepted exit request keeps its asset occupancy and processing record. Queuing, pausing, recovery and loss-bearing when assets are impaired follow rules that are published in advance and consistent with holders' rights (Chapter 14).

### 9.4 Separate from treasury buybacks

An official exit is a right that holders exercise under the published terms; a treasury buyback is a voluntary acceptance of the market price by a holder. The treasury may not use buybacks to replace committed exit obligations, nor may it restrict ordinary users' exits in order to create discounts that it can then buy back.

---

## 10. Fee allocation and risk reserve

### 10.1 Definition of the risk reserve

The risk reserve (also called the treasury asset surplus reserve) is the net Base USDC assets that have been allocated to the GB treasury, have no matching liability, and can absorb losses. It is not a premium on the GB market price.

| Fee or use | Allocation |
| --- | --- |
| 0.1% issuance fee | Credited in full to the risk reserve |
| 0.1% exit fee | Credited in full to the risk reserve |
| Treasury share r of the 0.5% settlement fee | Cancelled or realised, then credited to the risk reserve (Section 10.2) |
| Network share 1 − r of the 0.5% settlement fee | Used for network maintenance, security, software and protocol redevelopment according to approved budgets |

Network maintenance and redevelopment funds and the treasury risk reserve are kept in separate accounts or separately verifiable ledgers. Network budget that has not yet been spent does not constitute risk capital.

### 10.2 Capitalising the treasury share

The treasury share is received in the form of paid GB, and may be capitalised in one of two ways:

1. **Direct cancellation [Decided, default method]** (24 October 2026): the treasury cancels the q GB it has received. L falls by R × q, A is unchanged, and the surplus rises by R × q. The corresponding Base USDC moves from GB base backing to the risk reserve. There is no market sell pressure.
2. **Market sale (alternative)**: sell existing GB at the actual net price s, obtain s × q conet-USDC and burn it; the surplus rises by s × q. Selling existing GB is not new issuance.

Within the arbitrage band, s and R differ little, so the two methods have similar capital effects. Direct cancellation involves no market sell pressure, so it is the default. Treasury GB that has not yet been cancelled or sold is listed separately as "pending protocol revenue" and is not counted in the risk reserve.

GB from the network share may pay maintenance and development work directly according to budget, or may be sold to pay actual costs. Such GB remains counted in L and does not increase the risk reserve.

### 10.3 Fee status and execution constraints

Each fee is recorded entry by entry with a status such as: pending settlement, collected, allocated to the network budget, allocated to the treasury, cancelled, awaiting sale, capital received, or refunded. The same funds may be allocated only once, and the same revenue may enter capital only once. Sales follow public quotas, execution windows, slippage limits and failure-handling rules.

The risk reserve may also decrease through miner minting (Section 5.2) and through treasury trading gains and losses, and each such change must be recorded entry by entry.

---

## 11. Coverage and capital accumulation

### 11.1 Definitions

- A: net assets usable for GB exits, namely GB base backing plus the risk reserve, net of in-transit occupancy and restricted assets;
- L: the gross obligation of all paid GB with an exit right, valued at the rate in force (formula in Chapter 4); free GB is not counted;
- GB held by the treasury and not yet cancelled is not counted as an asset in A, nor is it deducted from L.

**[Decided]** (25 October 2026): A, L, the risk reserve and pending-settlement occupancy are recorded by a single reserve-ledger contract. Coverage, the C_min check and the rate check read only from that contract, and no figures from other sources are used.

> Surplus E = A − L
>
> Coverage C = A ÷ L
>
> Coverage of 115% means E = 0.15L

Calculating L on a gross basis avoids recognising in advance exit fees that will be collected only later.

### 11.2 Sources and consumption of surplus

Let M be the cumulative issuance principal of users, X the cumulative gross official exit amounts of users, and V the cumulative gross service price of paid GB, each converted into USDC at the rate at the time of the transaction; let r be the treasury share of the settlement fee, and F_m the cumulative value, at the rate, of paid GB minted to miners. Ignoring execution losses, and assuming all treasury shares are cancelled:

> Change in surplus = 0.001M + 0.001X + 0.005rV + AMO realised net gain or loss − F_m

The network share 0.005 × (1 − r) × V is used for network maintenance and redevelopment and is not counted in the surplus.

### 11.3 115% is a capital-accumulation target

115% is the DAO's interim target. It is neither capital already present at launch nor a safety guarantee.

- If L is fixed at 1 million USD, raising coverage from 100% to 115% requires a real increase of 150,000 USD in surplus.
- If only the settlement fee is relied on, the cumulative gross service price required is V = 30L ÷ r. Even if r = 1, all paid GB would have to turn over 30 times through paid services.
- If only the issuance fee is relied on, new issuance will push coverage only gradually toward 100.1%. Once coverage reaches 115%, every additional 100 USD of obligation needs a further 15 USD of surplus to maintain the ratio, and the 0.1% issuance fee contributes only about 0.10 USD.
- The miner-mint path directly consumes surplus.

Therefore, if 115% is to be reached within a predictable period, external capital injection or a longer accumulation period is needed. **[Pending]** Whether the interim target should instead be set at a lower value (115% is decided as an interim target and not a hard gate), and the specific value of C_min (the floor is decided at 10%, Section 2.3). The DAO should set issuance quotas on the basis of realised surplus, and must not assume that trading growth will close the capital gap on its own.

### 11.4 Resource capacity constraints

Net issuance should also be subject to resource-side constraints. Within a defined time window, the DAO should count verifiable, schedulable service capacity net of existing commitments, and convert it into GB service value. The capacity discount factor, utilisation and turnover assumptions must be published. Resource limits constrain the risk of service capacity, and financial backing constrains the risk of exit; both constraints apply at the same time. Resource registration on its own does not trigger issuance without backing.

---
## 12. Reserve assets

### 12.1 Base USDC only

**[Decided]** The only reserve asset of GB is Base USDC, namely the USDC locked behind the conet-USDC burned when users issue GB (24 October 2026).

This aligns the reserve asset with the exit asset: an exit mints conet-USDC, and what is ultimately released is this same Base USDC, so no portfolio switching is needed under stress.

### 12.2 Concentration risk

Using a single reserve asset means concentration risk. Under certain conditions the issuer of USDC keeps the ability to restrict or freeze addresses and to suspend the token; the protocol, the AAC and the DAO cannot remove these powers. [5] A stablecoin trading near one US dollar also does not mean that the treasury address can transfer out its balance.

The protocol should continuously monitor the freeze status of treasury addresses, the suspension status of the token, and the status of the Base chain. When reserves are restricted, they are handled under Chapter 14. The nominal amount of restricted assets, the amount currently available, and the potential recovery value are disclosed separately.

### 12.3 Longer-term discussion

The multi-asset allocations discussed in v0.1.2 (USDT, DAI/USDS, PYUSD, native BTC and ETH, and others) are moved to longer-term discussion and are not enabled in this version. [6][7][9] If they are introduced in future, two questions must be settled first: how to convert back to USDC on exit, and how to handle a failed conversion. Adding more currencies does not eliminate common-failure risk.

---

## 13. Treasury open-market operations (AMO)

The [GB AMM Whitepaper (draft)](gb-amm-whitepaper.md) expands this chapter: the arbitrage band, the trading pool, cross-chain arbitrage and worked AMO examples.

### 13.1 Two channels

GB supply is adjusted through two channels: users issuing and exiting at the official rate, and AMO. AMO is executed automatically by the contracts within the ranges and quotas set by DAO vote. Anyone may trigger it when the conditions are met, and there is no privileged execution address. **[Decided]** (confirmed 25 October 2026) When triggered, the contract itself checks the price deviation, quotas and coverage; if the conditions are not met, the transaction reverts. The trigger pays its own gas.

| Situation | Operation AMO may perform | Preconditions |
| --- | --- | --- |
| Market price above the official rate | Sell newly issued paid GB | All conditions in Section 13.2 are met |
| Market price below the official rate | Buy back paid GB on the market and cancel it | All conditions in Section 13.3 are met |
| Market within the normal range | No active intervention | Normal payments and independent trading continue as usual |
| Abnormal data, assets or capital | Stop the corresponding operation | Handled under Chapter 14; no quota is increased automatically |

AMO does not free USDC from the issuer's freezing, price or withdrawal risks.

### 13.2 Selling new GB

**[Decided]** (24 October 2026): AMO may sell newly issued paid GB, provided that all of the following are met:

1. only conet-USDC is accepted;
2. the net execution price s, after execution costs, is not below the official rate R;
3. the contract burns all the conet-USDC received in the same transaction.

In this way, GB sold by AMO is still issued against conet-USDC, under the same issuance rule as user issuance. If newly minted GB is not sold, the whole transaction is reverted, so no unbacked GB is left behind.

When q units are sold at net price s:

> Assets after the operation A′ = A + s × q
>
> Obligation after the operation L′ = L + R × q
>
> Change in surplus = (s − R) × q

Of the corresponding Base USDC, R × q moves to GB base backing and (s − R) × q moves to the risk reserve. Only the part of the sale price above the rate is surplus; the rest is backing, not profit.

Each sale must also keep coverage after the operation at or above C_min. A sale above the rate does not guarantee that coverage is not diluted: with A = 1.15 million and L = 1 million, selling 100,000 units at s = 1.0008 increases the surplus by 80 USDC, yet coverage falls from 115% to about 113.64%.

GB the treasury already holds (such as uncancelled settlement-fee shares) is accounted for separately from newly issued GB sold. GB in the network budget may not be converted into AMO funds without authorisation.

### 13.3 Buyback and cancellation

AMO may buy back paid GB and cancel it immediately. The buyback funds are a conet-USDC buffer that the treasury deposits in advance on CoNET, from Base USDC through path one in Section 3.2. In the merged view, these assets are counted only once.

**[Decided]** The buffer size is fixed at 100,000 conet-USDC (25 October 2026). When the buffer falls below 50,000 conet-USDC, the contract triggers automatically and replenishes it to 100,000 conet-USDC from the treasury's Base USDC through path one in Section 3.2 (decided 25 October 2026; the initial threshold is 50,000 conet-USDC, to be adjusted later by DAO vote). Replenishment has no separate cap; its size is indirectly limited by the single-transaction, daily and 90-day cumulative AMO quotas (decided 25 October 2026).

**[Pending]** The custody arrangement for the Base USDC used in automatic deposits, and the design of the contract. The operator has deferred this for discussion.

When q units are bought back and cancelled, at an average outlay b including execution costs:

> Assets after the operation A′ = A − b × q
>
> Obligation after the operation L′ = L − R × q
>
> Change in surplus = (R − b) × q

Example (R = 1): the treasury holds 1 million USDC against 1 million GB. It buys back and cancels 100,000 GB at 0.98, spending 98,000. After the outlay, assets are 902,000 and the obligation is 900,000, so coverage is about 100.22%.

Buying back below the rate does not necessarily improve coverage. With assets of 800,000 against 1 million GB, buying back 100,000 units at 0.90 lowers coverage from 80% to about 78.89%. A buyback improves coverage only if b is below the usable assets per GB, A ÷ N. When coverage is below 100%, the matter enters the overall recovery process in Chapter 14, and the daily rules may not continue to consume funds.

| Category of funds | May be used for buybacks? |
| --- | --- |
| GB base backing and risk reserve (through the conet-USDC buffer) | Yes; after the buyback, the remaining assets must satisfy all remaining obligations and liquidity constraints |
| conet-USDC backing | No |
| Assets pending payment, in transit or restricted | No |
| Network maintenance and redevelopment funds | No |

A GB bought back must be cancelled. Keeping it in a treasury wallet does not discharge the obligation.

---
### 13.4 Arbitrage band

Issuance and exit by users remain continuously open under normal conditions. The 0.1% issuance fee makes the cost of acquiring GB about 1.001 times the rate, and the 0.1% exit fee makes the net proceeds of an exit about 0.999 times the rate, before network and market costs. When the market price is clearly above the former, arbitrageurs issue and sell; when it is clearly below the latter, arbitrageurs buy and exit.

Therefore the room for AMO sales and buybacks is narrow, and the treasury cannot expect to earn large spreads over the long run. AMO's role is to supply liquidity and to deal with short-term imbalances. Trigger bands should be consistent with real arbitrage costs, and income from hypothetical premiums that are hard to trigger may not be written into the capital budget.

Persistent deep discounts should first be investigated for restricted reserves, blocked exits, data manipulation and service demand. They may not be used to create low-price buyback opportunities for the treasury by restricting ordinary holders' exits.

### 13.5 Price signals and execution constraints

Operating signals use multi-source, time-weighted observation, and check data freshness and effective depth. Execution uses explicit price limits, slippage tolerances, quantities and expiry conditions. An instantaneous price from a single thin pool may not trigger a large operation. Uniswap v3's historical price mechanism can support time-weighted observation, but data availability and manipulation costs must be verified independently. [15]

Trading quotas include at least single-transaction, daily and cumulative per-period limits, and are constrained by real-time available funds and pending-settlement occupancy. **[Decided]** (25 October 2026): quotas are based on the risk reserve. A single transaction may not exceed 1% of the risk reserve, a day may not exceed 10%, and the cumulative amount in each 90-day period may not exceed 20%. When a quota is exhausted, operations stop; resumption requires the capital and market conditions to be met again, and quotas may not be replenished indefinitely because prices keep falling. Failures, retries, partial fills and timeouts are recorded separately, and profits are not recognised in advance.

The treasury, its own liquidity pools and related accounts use a merged risk view. Internal rebalancing or self-trading creates no external net assets, and GB held in an own pool is not counted as an independent asset at the rate.

### 13.6 Mechanism references

Frax's AMO documentation provides a reference for constrained open-market operations. Its V3 design sets a target of at least 100% external collateral, while expressly not granting holders a right to redeem a specified asset at any time. [10][11] GB retains users' official exit right, so it cannot copy that rights structure.

Olympus's earlier RBS design bought at low reserve levels and sold at high levels, and set capacity and recovery conditions. Its official documentation now states that it has been replaced by a repurchase facility and an issuance manager. [12][13][14] GB draws on the budget, quota, sale-and-issuance and risk-control boundaries of such designs, and does not on that basis promise profit or a fixed price.

### 13.7 Price stability mechanism (operator description, 25 October 2026; specific parameters pending)

GB's price is supported by two parts together: the treasury's reserves, and the combined endorsement of the whole DePIN network. Price stability relies mainly on market arbitrage and automatic market making by the issuer. It does not constitute a redemption guarantee.

1. **Market arbitrage**: users' issuance and exit remain continuously open under normal conditions (Section 13.4). When the market price departs from the official rate, arbitrageurs' issuance and sales, or their buying and exits, pull the price back toward the official rate.
2. **Automatic market making**: the treasury module may, within the ranges and quotas set by DAO vote, provide liquidity automatically and regulate the market by controlling liquidity. Automatic market making has no privileged execution address, and all its parameters are set by vote.
3. **Reserve arbitrage**: the treasury may use part of the risk reserve and GB base backing in arbitrage. The rules in Section 13.3 apply equally: after the operation, the remaining assets must satisfy all remaining obligations and liquidity constraints, and coverage may not fall below C_min (value pending; see Chapter 19).
4. **Boundary**: the price stability mechanism does not change the official exit. Holders may still exit at the official rate R (Chapter 9), and exit proceeds are independent of the secondary-market price.

---

## 14. Risk monitoring, circuit breakers and recovery

### 14.1 Monitoring

| Risk signal | What is checked |
| --- | --- |
| Market deviation | Multi-source prices, effective depth, slippage and data freshness |
| Restricted reserves | Freeze status of treasury addresses, USDC suspension, Base withdrawal capability |
| Coverage shortfall | Balances of A, L and the risk reserve, and stress losses |
| AMO anomaly | Price manipulation, execution slippage, quotas, asset-occupancy conflicts and partial execution |
| Cross-chain and contract failure | Finality, reorganisation, replay, proof availability and upgrade events |
| Resource delivery anomaly | Effective capacity, service completion rate, concentration, failure and dispute rates |
| Free GB anomaly | Abnormally concentrated burns, burns inconsistent with service volume, and abnormal markups in free-GB settlement |

### 14.2 Automatic execution

**[Decided]** Circuit breakers, limits and suspensions are executed automatically by the contracts within voted parameters, and there is no privileged execution address (24 October 2026).

Contracts do not run on their own schedule. State updates are triggered by anyone submitting verifiable data, for example coverage and price data on CoNET, and Base-side facts certified by the AAC. Trigger conditions, durations, recovery hysteresis and corresponding actions must be set by vote before launch.

**[Decided]** (confirmed 25 October 2026) There is no manual emergency channel, including a guardian address that could only pause and could not move funds. Situations outside the voted parameters can therefore be handled only by proposal. Voting and execution involve delay, and this version makes no commitment to immediate handling under any market condition.

### 14.3 Tiered response

Response is divided into four stages: early warning and quotas; stopping intake or stopping exits; overall redemption protection; and recovery.

- AMO, miner minting and user channels use separate suspension scopes. Stopping AMO does not revoke accepted user exit requests.
- When coverage falls below C_min, AMO sales and miner minting stop automatically.
- Where restricted reserves cause coverage to fall below 100%, early exiters may not be allowed to withdraw all healthy assets without limit. Queuing, pro-rata payment or capital injection must be agreed before launch, and may not retroactively strip existing rights. **[Pending]** The specific rules.
- The 0.1% exit fee may not be temporarily raised to substitute for solvency management.

Ordinary transfers, independent DEXs and cloud services are not suspended globally because a single asset is abnormal, unless they have their own related security fault.

---

## 15. DAO governance

All of the following rules are **[Decided]**.

### 15.1 Voting and execution (22 October 2026)

1. **Locked passage**: when yes votes reach two-thirds of the snapshot total weight, the proposal is locked as passed and is executed by the voters in the transaction of that vote. There is no queue period and no grace period.
2. **Locked failure**: when votes against exceed one-third of the snapshot total weight, the proposal is locked as failed and ends immediately.
3. **End of the voting period**: a proposal that has not passed fails; votes cast after the voting period ends are invalid.
4. **Snapshot**: voting eligibility and weight are fixed at the proposal's snapshot time. A voter whose stake renews after the snapshot may not vote on that proposal. A voter whose stake expires after the snapshot and who exits may vote before exiting, and automatically loses the right to vote after exit. The snapshot total weight is the denominator for the two-thirds threshold.
5. **Execution cost**: executors pay their own gas, with no cap. If execution fails or gas is insufficient, the whole transaction reverts and that vote is not counted.

### 15.2 Voting eligibility (22 October 2026)

1. **Registration**: holding the CoNET threshold amount and staking for the current period (the first period is one year) completes DAO voting registration. **[Pending]** The threshold amount.
2. **First stake**: a voter may vote after one month of first staking, and may propose after six months. Renewal no longer applies these two restrictions.

### 15.3 Staking terms (22 October 2026; method of setting, 24 October 2026)

1. **Period length**: the first period is one year, with a minimum of one year and no maximum.
2. **Period-by-period adjustment**: the length of the next period is decided by an adjustment proposal approved by two-thirds during the current period. If it does not pass, the old length continues.
3. **Individual periods**: each voter's period runs from the moment of that voter's staking and applies the length then in force. There is no single global period.
4. **Renewal**: at expiry, a period with no cancel set renews automatically. A period with cancel set ends at expiry, and the voter no longer has voting rights. Cancel may be revoked within the current period.
5. **Withdrawal**: withdrawal is possible immediately after exit; there is no withdrawal hesitation period.
6. **Location of parameters**: staking-period parameters are stored in the registry, and are changed by GOVERNOR calling the registry's setter function after a two-thirds vote. GOVERNOR's own parameters are immutable.

### 15.4 Protocol parameters set by vote

The following matters require a proposal vote and are executed by the yes-voters: the official rate R; the settlement-fee allocation ratio r; the miner-mint ratio k and quota; the free-GB budget and distribution rules; C_min; AMO ranges and quotas; circuit-breaker parameters; the resource reference catalogue; cross-chain registration and external deployment; and fee rates.

The 0.1% issuance and exit fees and the 0.5% settlement fee are parameters of this version. **[Decided]** (24 October 2026): a proposal to change these fee rates must state the future effective block, and must explain how authorised orders and accepted exit requests transition. Authorised orders and accepted exits are completed at the old rates; new operations after the effective block use the new rates.

No vote may grant an unconstrained minting right, a right to misappropriate assets, or a hidden fee.

---
## 16. Continuous disclosure

At a minimum, the following data are published:

- **Supply**: paid GB issued by source (user issuance, AMO sales, cross-chain inbound, miner minting), burns and cancellations, and circulation on each chain; free GB distributed and burned.
- **Reserves**: L, GB base backing, risk reserve, protocol revenue awaiting consolidation, restricted assets, in-transit occupancy, coverage, and executable exit capacity.
- **Fees**: the original-currency amounts of the three fee types, the miner's gross and net revenue, the two-way allocation of the settlement fee, cancellation and sale records, refunds, and actual capital received.
- **Miner minting**: k, the amount minted, the amount transferred from the risk reserve, pause periods, and pending-reissue records.
- **AMO**: quantities bought and sold, net execution price, corresponding rate, trading costs, realised net gains and losses, coverage before and after each operation, remaining quota, and in-transit occupancy.
- **Network budget**: budgets, disbursement records and verifiable outputs. Unspent budget is not counted in the risk reserve.
- **Resources**: verified capacity, time windows, measurement basis, utilisation and service completion. Settlement volume must distinguish real services, ordinary asset trading and internal consolidation. Self-transfers, order splitting or circular trades may not be counted as new demand.

---

## 17. Phased implementation and verification

| Stage | Work to be completed |
| --- | --- |
| Rule freeze | Settle the pending items in Chapter 19; freeze fee rates, rate rules, k, C_min and quotas |
| Contract implementation | New GB contract (two balances, burnable, old minting entry points removed), settlement module, airdrop contract, AMO, risk-control module, cross-chain representation tokens |
| Verification and limited operation | Independent audit, asset conservation, market manipulation and bank-run testing, cross-chain forged-message testing, small-scale limited operation |
| Capital accumulation | Establish the risk reserve through actual receipts; account for development funds separately; disclose real coverage and liquidity |
| Expansion | Open new services and quotas item by item once capital, liquidity and operating conditions are met |

**Deployment gate [Decided]** (25 October 2026): deployment of the new contracts takes place only after discussion and independent audit are complete. Nothing is deployed before the audit is complete.

**Security gate [Decided]** (24 October 2026): before any path that mints paid GB or conet-USDC opens, it must be proven that cross-chain verification rejects forged source-chain messages, including forged block headers and receipts. Positive tests with real data alone are not sufficient. Forged conet-USDC could continue to issue GB, so this gate is a precondition for every coverage target.

**[Decided]** (25 October 2026) The conet-USDC outbound release path is also subject to this gate: before it opens, it must be proven that the Base side rejects forged CoNET burn messages. The path mints no token, but a forged burn message would directly withdraw the Base USDC locked in the external treasury.

Core verification should also cover: repeated execution, precision and rounding, order splitting, refunds, pausing, reorganisation, price invalidation, concurrent occupancy and partial cross-chain completion; for AMO, same-transaction burning, capital constraints after net execution, buybacks not cancelled, quote manipulation and circular trading in own pools; for miner minting, the pause conditions and false-service burns; and deduplication of cross-chain mirrored supply. Where a function works but these constraints are unverified, the economic loop may not be declared safe to operate.

A token name does not replace legal judgement on services, asset exchange and fees. Tokens redeemable at a fixed rate may in some jurisdictions be classed as regulated payment or e-money tokens; for example, the EU's MiCA imposes specific restrictions on redemption fees for applicable tokens. [8] The deployment scope of the three fee types and of the exit mechanism must be subject to a legal assessment of the actual functions.

---

## 18. Change comparison

| Location | v0.1.2 | v0.2 working draft | This draft | Basis |
| --- | --- | --- | --- | --- |
| Token classes | Not differentiated | Paid/free; free pending | Full free-GB rules (Chapter 8) | Operator, 24 October 2026 |
| Sources of paid GB | Issuance by users plus treasury minting | Only by burning conet-USDC | New Chapter 5; four sources; miner mint as the exception; admin and developer FX minting removed | Operator, 22 and 24 October 2026 |
| Issuance and exit assets | Any eligible asset i, requiring a price source | v0.1 formula retained | Only conet-USDC; formula Q = N × R | Operator, 22 October 2026 |
| Exit-fee treatment | Gross minted first, then cancelled | As v0.1 | Only the net is minted | Operator, 24 October 2026 |
| Treasury share of the settlement fee | Must be sold for cash | As v0.1 | Cancelled by default; sale as the alternative | Operator, 24 October 2026 |
| Settlement method | Not specified | Not specified | Settled by transfer; the settlement module holds no minting right | Operator, 24 October 2026 |
| Pause of miner minting | None | None | Paused below C_min or above quota; records enter the pending-reissue queue | Operator, 24 October 2026 |
| Reserve assets | Multi-asset, BTC/ETH staged allocation | As v0.1 | Base USDC only; multi-asset moved to longer-term discussion | Operator, 24 October 2026 |
| AMO | Issuance and sale for external assets | No separate chapter | Sales accept only conet-USDC, burned in the same transaction, at not below the rate | Operator, 24 October 2026 |
| Daily risk control | DAO or risk-execution module | Both require a proposal | Contracts execute automatically within voted parameters; no privileged address | Operator, 24 October 2026 |
| Cross-chain GB | None | New | As v0.2; L calculated on global supply | Operator, 22 and 24 October 2026 |
| Governance | Delayed execution; multisig and emergency powers mentioned | No multisig; voters execute | As v0.2; decision dates corrected | Operator, 22 and 24 October 2026 |
| Rate adjustment | Advance notice; quote validity | Decided by vote | A rise must pass the coverage check; effective block stated; limit during lock-up until the effective date | Operator, 24 October 2026 |
| Fee-rate change | Notice and delayed execution | None | Effective block stated; authorised orders and accepted exits completed at the old rates | Operator, 24 October 2026 |
| Rounding | Excessive rounding up not allowed | Public rounding direction | Always in favour of the reserve | Operator, 24 October 2026 |
| Implementation | Five stages | None | Cross-chain forged-message gate added; no legacy migration stage | Operator, 24 October 2026 |
| Service pricing | Service catalogue quotes | Not specified | Standard price of 1 GB for 1 GB of traffic; providers set their own markup or discount; also applies to free GB | Operator, 25 October 2026 |
| conet-USDC outbound | Not specified | Not specified | Burn on CoNET, release by the external treasury; must pass the forged-message gate before opening | Operator, 25 October 2026 |
| AMO trigger and emergency channel | Risk-execution module, emergency powers | Both require a proposal | Anyone may trigger AMO; no manual emergency channel | Operator, 25 October 2026 |

v0.2 labelled the decisions "no multisig" and "cross-chain entry rules" as dated 24 October 2026. This draft corrects them to 22 October 2026, as stated by the operator.

---

## 19. Pending items

1. **Old contract balances (decided, 25 October 2026)**: free and paid balances in the old GB contracts are void. New contracts issue from zero, with no legacy migration stage (the legacy migration stage was rejected on 24 October 2026).
2. **Miner-mint parameters**: decided in Section 5.2 (25 October 2026).
3. **Free GB details**: the deduction order between the two balances is decided as free GB first, and settlement of free GB charges the 0.5% settlement fee (both decided 25 October 2026; the basis of the fee is pending confirmation).
4. **Settlement-fee allocation ratio r**: the initial value is decided as 50% (25 October 2026), to be adjusted later by DAO vote. The network share is transferred directly to a protocol fee address that a two-thirds DAO vote can change. The address is a plain address, and a holder designated by the DAO spends within approved purposes (decided 25 October 2026).
5. **C_min and the interim coverage target**: the floor for C_min is decided at 10% (25 October 2026), with the number set by DAO vote. 115% is not a hard gate and is only an interim target (decided 25 October 2026).
6. **AMO parameters**: the price source (multi-source, time-weighted observation), the trigger band (market price deviating 1% from the official rate) and the trading quotas (1% per transaction, 10% per day and 20% per 90 days, of the risk reserve) are decided (25 October 2026; Section 13.5). The buyback buffer size is decided at 100,000 conet-USDC. When it falls below 50,000 conet-USDC, the contract replenishes it to 100,000 conet-USDC through path one, with no separate cap (Section 13.3). The custody arrangement for the Base USDC used in automatic deposits, and the contract design, are pending discussion.
7. **Rate adjustment**: the minimum interval between the proposal and the effective block, and the quota during lock-up until the effective date. Whether decreases are allowed, and the single and cumulative limits, are decided in Section 2.3 (25 October 2026).
8. **Exit rules when coverage is insufficient**: decided as queuing, with payment at the official rate once assets recover (25 October 2026). Queuing follows order of arrival. The details of the queue (whether partial payment is allowed, and disclosure during the queue) are pending.
9. **Developer application settlement**: after the developer FX minting entry is removed, how pay-per-use and subscription models will settle in paid GB.
10. **Same-address deployment of tokens**: deployer, initialisation code and salt.
11. **Form of the AAC secure construction**: whether the verification contract directly holds the minting right, or a dedicated representation token grants the minting right only to the AAC secure construction; and, where the token has no admin, how the minter is replaced.
12. **Outbound release of conet-USDC (decided, 25 October 2026)**: burning on the CoNET side and release of the locked Base USDC by the external treasury (Section 3.2); the path must pass the forged-message gate in Chapter 17 before it opens (decided 25 October 2026).
13. **DAO voting threshold for registration**, and whether the threshold for adjusting the staking period is likewise two-thirds of the snapshot total weight.
14. **Quorum**: the operator leans towards no quorum, as two-thirds of the snapshot total weight is sufficient; to be confirmed before it is written in.
15. **Validation in registry setter functions**: minimum period length of one year, taking effect only after expiry.
16. **Legal assessment**: applicability of the exit mechanism and of the three fee types in the target jurisdictions.

---
## Appendix A: Parameter summary

| Item | Rule | Status |
| --- | --- | --- |
| Issuance fee | 0.1% of principal, charged in addition to the principal | Parameter of this version |
| Exit fee | 0.1% of the gross redemption amount, deducted from the gross | Parameter of this version |
| Settlement fee | 0.5% of the service price, borne by the miner | Parameter of this version |
| Service pricing | Standard price of 1 GB for 1 GB of traffic or one standard service unit; providers set their own markup or discount by percentage, with no limit; also applies to free GB | Decided (25 October 2026); standard units for non-traffic services pending |
| Allocation of issuance and exit fees | Credited in full to the risk reserve | Parameter of this version |
| Allocation of the settlement fee | Treasury share r cancelled at settlement; network share 1 − r transferred directly to a plain address that a two-thirds DAO vote can change, whose holder designated by the DAO spends within approved purposes | Initial r of 50%, to be adjusted later by DAO vote; decided (25 October 2026) |
| Official rate R | conet-USDC per GB, decided by DAO vote | Decided (22 October 2026) |
| Sources of paid GB | User issuance, AMO sales, cross-chain inbound, miner minting (exception) | Decided (22 and 24 October 2026) |
| Removed minting entry points | Direct minting by admin; minting after developer FX burn | Decided (24 October 2026) |
| Miner minting | Minted at ratio k (initial 0.01, adjusted later by DAO vote), backed from the risk reserve; single-period quota 1% of L (90-day periods); pending-reissue queue capped at 1% of L; minting paused and records queued if coverage falls below C_min or the period quota is exceeded | Decided (24 and 25 October 2026) |
| Settlement of paid GB | By transfer; the settlement module holds no minting right | Decided (24 October 2026) |
| Exit minting | Only the net conet-USDC is minted; no tokens minted for the exit fee | Decided (24 October 2026) |
| Treasury share of the settlement fee | Cancelled by default; sale as the alternative | Decided (24 October 2026) |
| Rate increase | Contract refuses execution if coverage after the increase falls below C_min; C_min floor 10% | Decided (24 and 25 October 2026) |
| Limits on rate changes | A single change no more than 50% of the current rate; increases and decreases each capped at 20% per 90-day period; no notice period for decreases | Decided (25 October 2026) |
| Rate and fee effectiveness | Proposals state a future effective block; the rate is locked, with a quota, during the effective period | Decided (24 October 2026) |
| Opening of minting paths and the conet-USDC release path | Must first pass reverse testing against forged cross-chain messages | Decided (minting paths 24 October 2026; release path 25 October 2026) |
| Old contract balances | Void; new contracts issue from zero, with no legacy migration stage | Decided (25 October 2026) |
| Free GB | Airdrop contract distributes within budget; consumption only; no right of exit; no transfer, trading or cross-chain; burned by miners | Decided (24 October 2026) |
| Deduction order | When both classes are held, service settlement deducts free GB first, then paid GB | Decided (25 October 2026) |
| Free-GB settlement fee | 0.5% of the service price, borne by the miner, consistent with paid settlement; the fee basis is the burned amount valued at the official rate | Decided (25 October 2026; basis pending confirmation) |
| Exit when coverage is insufficient | Queued in order; paid at the official rate once assets recover | Decided (25 October 2026); queue details pending |
| conet-USDC minting | Base USDC deposit, or burning of paid GB | Decided (22 October 2026) |
| conet-USDC outbound | Burn on CoNET; the external treasury releases the locked Base USDC, capped by the locked balance | Decided (25 October 2026); must pass the forged-message gate |
| Reserve assets | Base USDC only | Decided (24 October 2026) |
| Reserve ledger | A, L, risk reserve and pending-settlement occupancy recorded by the reserve-ledger contract; coverage, C_min and rate checks read only that contract | Decided (25 October 2026) |
| AMO sales | Accept only conet-USDC; s ≥ R; burned in the same transaction; coverage at or above C_min after the operation | Decided (24 October 2026) |
| AMO buybacks | Bought back and cancelled using a conet-USDC buffer fixed at 100,000; below 50,000 the contract replenishes it automatically through path one, with no separate cap | Decided (25 October 2026); custody arrangement pending discussion |
| AMO trading quotas | Based on the risk reserve: 1% per transaction, 10% per day, 20% cumulative per 90-day period | Decided (25 October 2026) |
| AMO price signal | Multi-source, time-weighted observation; trigger when the market price deviates 1% from the official rate | Decided (25 October 2026) |
| Daily risk control | Contracts execute automatically within voted parameters; no privileged address | Decided (24 October 2026) |
| AMO trigger | Anyone may trigger when the conditions are met; the transaction reverts otherwise | Decided (confirmed 25 October 2026) |
| Emergency channel | None, including a pause-only guardian address | Decided (confirmed 25 October 2026) |
| Outbound | Burn on CoNET; minted on external chains by the AAC secure construction | Decided (22 and 24 October 2026) |
| Inbound | External burn; minted on CoNET; this is the only method | Decided (22 October 2026) |
| External total | Equals the net outbound burn on CoNET | Decided (24 October 2026) |
| Vote passes | Yes votes reach two-thirds of the snapshot total weight; executed in that vote | Decided (22 October 2026) |
| Vote fails | No votes exceed one-third of the snapshot total weight, or the period ends without passage | Decided (22 October 2026) |
| Voting eligibility | Hold the threshold and stake; vote after one month of first staking, propose after six months | Decided (22 October 2026); threshold amount pending |
| Staking period | First period one year; minimum one year; no maximum; adjusted period by period; individual periods | Decided (22 October 2026) |
| 115% coverage | Interim target, not a guarantee; not a hard gate | Decided (25 October 2026) |
| C_min | Set by DAO vote; floor 10% (operator decision, 25 October 2026) | Floor decided; number pending |

**Precision and rounding [Decided]** (24 October 2026): fees are measured on a common denominator of 1,000. The issuance fee and exit fee are 1/1,000, and the settlement fee is 5/1,000. The implementation uses fixed-point numbers of sufficient precision and publishes the minimum settleable amount. Rounding always favours the reserve: amounts paid by users are rounded up, amounts received by users are rounded down, and the rounding difference per operation does not exceed one minimal unit. The precision of GB and conet-USDC is as registered in the contracts (the current GB contract uses 9 decimals and USDC usually 6), and conversions must be calculated at the higher precision before rounding. Micro-payments may use cumulative remainders or batch net settlement, so that the long-run effective rate approaches the prescribed rate.

Splitting and multi-hop services charge the settlement fee once, on the gross order price. Quotes, authorisations and execution are bound to the same fee rate and rate version. Consolidation, cancellation and sale do not recursively trigger the settlement fee. A failed execution or a retry is not charged again.

---

## Appendix B: References and evidence boundaries

The economic rules of this proposal are defined by this whitepaper. The following materials are used to confirm infrastructure boundaries, token integration or external-asset risks. They do not indicate endorsement of GB by any outside institution, and they do not replace review of the final contracts and deployments. The verification date of the materials is carried over from v0.1.2 (24 October 2026). This draft has not re-verified the links, and deployment status must be checked item by item.

[1] CoNET Documentation, L0 - Decentralized Cloud: resource plane, service metering and deployment boundaries.
https://gitbook.conet.network/l0/

[2] CoNET Documentation, L1 - CoNET Blockchain: responsibilities for assets, settlement and the cross-chain treasury.
https://gitbook.conet.network/l1/

[3] CoNET-project, bridgeAAC: cross-chain fact proofs, one-time settlement, and public records of deployment status.
https://github.com/CoNET-project/bridgeAAC

[4] Uniswap Developers, Token Integration Issues, Uniswap v3: integration limits for tokens that deduct fees on transfer.
https://developers.uniswap.org/docs/protocols/v3/concepts/unsupported-tokens

[5] Circle, USDC Terms: boundaries of redemption, restrictions, freezing and related rights for the external asset.
https://www.circle.com/legal/usdc-terms

[6] Tether, Legal: terms on issuance, redemption and service restrictions.
https://tether.to/en/legal/

[7] Ethereum.org, Financial freedom and open access: the difference between native ETH and tokens controlled by an issuer.
https://ethereum.org/open-access/

[8] European Union, Regulation (EU) 2023/1114 (MiCA), Articles 39 and 49: redemption rules for applicable tokens.
https://eur-lex.europa.eu/eli/reg/2023/1114/oj/eng

[9] Paxos, US Dollar-Backed Stablecoin Terms and Conditions: PYUSD, USDG and the related issuing entities and administrative rights.
https://www.paxos.com/terms-and-conditions/stablecoin-terms-conditions

[10] Frax Finance, AMO Overview: a framework for constrained open-market operations.
https://docs.frax.finance/amo/overview

[11] Frax Finance, FRAX V3 Overview: the external collateral target and the boundary of holders' redemption rights.
https://docs.frax.finance/frax-v3-100-cr-and-more/overview

[12] Olympus Docs, Range Bound Stability: the former mechanism, capacity rules and replacement status.
https://docs.olympusdao.finance/main/overview/range-bound

[13] Olympus Docs, Yield Repurchase Facility: yield, backing recovery and the repurchase mechanism.
https://docs.olympusdao.finance/main/overview/yield-repurchase-facility

[14] Olympus Docs, Emissions Manager: rule-bound issuance and sale mechanism.
https://docs.olympusdao.finance/main/overview/emissions-manager

[15] Uniswap Developers, Price Oracles: historical prices, time-weighted observation and data constraints.
https://developers.uniswap.org/docs/protocols/v3/concepts/price-oracles

---

**GB's usage demand comes from actual services. GB's treasury resilience comes from available assets, realisable revenue and constrained governance.**
