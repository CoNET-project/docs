# Third-party tokens and subscriptions

**Design status, 25 November 2026.** This page records proposed third-party asset and subscription rules. AAC implementation is paused. Nothing here establishes a deployed route or current chain state; local implementation claims remain limited to their named candidate and tests. V1 specifies third-party asset admission and treasury routes. Those routes may open only after per-asset production parameters, the exact factory candidate and independent acceptance are complete.

**How to read the labels**

- **[Implemented, pending acceptance]**: implemented and tested locally. Not deployed. Acceptance, an independent audit and a separate deployment approval are still needed.
- **[Approved, not yet live]**: a rule the operator has decided and published. Not deployed.
- **[Open]**: not decided. Listed without candidate values.

In the examples, **T** is a third-party stablecoin and **S** is the official CoNET stablecoin it is backed by, for example conet-USDC.

## 1. Issuing a token [Approved, not yet live]

- Anyone can issue a token on CoNET through the AAC factory after paying a DAO-set issuance fee in CNET. No administrator approval is needed. The fee amount is set by DAO vote.
- There are two kinds:

| | Stablecoin | Cross-chain token (not a stablecoin) |
| --- | --- | --- |
| Where it exists | CoNET only; no route to other chains | CoNET, and other chains the DAO has approved |
| Supply | Issued only by burning the chosen official stablecoin at a fixed ratio; redeemed by burning it back | The issuer sets the initial supply once, at issuance on CoNET. No later minting by the issuer or any administrator |
| On other chains | — | Minted only against a burn verified by AAC. The token moves in both directions |

- A token can name an icon by a link on CoNET's IPFS.
- Third-party tokens accept offline signatures. A user signs an authorisation (EIP-712) that a connected party submits. Each authorisation is bound to the chain, the token, the action, the user, the target, the amount, a nonce and a deadline. A service order is also bound to the serving node, the order, the balance type and the price version. Contract wallets are checked through their own ERC-1271 interface. This differs from GB, which accepts ordinary wallet signatures only.

## 2. Cross-chain tokens on other chains [Approved, not yet live]

- The design calls for first-use deployment on an approved chain through a fixed factory at the same address as CoNET. This is not implemented or verified; no same-address deployment is claimed.
- Later transfers reuse that deployment.
- Before deploying or minting, the chain's executor verifies a final CoNET DAO admission decision for that token and direction, and an AAC transfer proof. Route closures, circuit breakers and limits still apply.

## 3. Third-party stablecoins [Approved, not yet live]

### 3.1 Backing and ratio

- At creation the issuer chooses one official stablecoin S that the DAO has approved and registered on CoNET. **The choice is permanent.** T is issued by burning S and redeemed for S. Nothing else can stand in as a reserve.
- The ratio between T and S is fixed at creation and may be a fraction (for example 1 T = 0.5 S, or 3 : 7). T takes the decimals of S, read by the contract at creation.
- Each official stablecoin keeps its own exchange obligation and supply record; nothing is moved across currencies.
- **Exchange in.** The user receives T rounded down, and only the S actually needed is burned; the user keeps the remainder. A request that would mint zero T is rejected.

### 3.2 Two balances

Like GB, T has a **paid** balance and an optional **free** balance.

- The issuer chooses at creation whether the free pool is on, and can switch it later.
- While the free pool is on, the issuer sets how much each wallet can claim per rolling 24 hours (86,400 seconds from the wallet's last successful claim; not reset at UTC midnight or by any setting change), whether free balances can be transferred, and whether free balances can be spent on node services.
- **Free balances have no redemption right** and cannot be turned into paid balances. They keep their type when transferred.
- A transfer takes the free part first, then the paid part. The receiver gets each part in its own type.
- When the free pool is switched off, new claims stop. The issuer chooses whether existing free balances are frozen or stay usable. Switching it on again resets no balance, claim time or used allowance.

### 3.3 Redemption

- Redemption means burning a **paid** T balance to receive S.
- The base amount is converted at the fixed ratio and rounded down. A remainder below one smallest unit of S is not minted to anyone.
- The issuer may set a redemption fee **p** between **0% and 5%** at creation. **p cannot be changed afterwards.** The fee is taken from the face value: burning 100 T at 1 : 1 with p = 5% gives the user 95 S and the issuer 5 S.
- The user's S and the issuer's fee are minted directly, in the same transaction, through the fixed exchange entry. The issuer's wallet is the creator's address, fixed at creation. There is no accrued balance to withdraw.

### 3.4 Paying DePIN nodes

- A user can pay mailbox and other DePIN services with T. The node submits the user's signed authorisation to the token contract.
- **Price.** The DAO sets the benchmark price of GB in S. The issuer sets a GB profit rate **m** between **0% and 500%**: the price is the benchmark times (1 + m). For example, with a benchmark of 0.01 S per GB, a ratio of 1 T = 1 S and m = 200%, the user burns 0.03 T and the node receives 1 GB.
- **m can be changed** by the issuer at any time, up or down, effective immediately. Each change starts a new price version, and an order signed under an older version is rejected. m is separate from the redemption fee p.
- **Funding.** The node is paid in GB from GB the issuer has deposited in advance. If the deposit is short, the whole order is rejected and no T is burned. The project treasury does not subsidise these orders.
- When a paid balance is spent, the matching S is minted to the issuer's wallet in the same transaction. Spending a free balance mints nothing.
- Free balances can pay for services only if the issuer allows it, at the same price as paid balances.
- A node under an open violation report is still paid. Settlement checks only that the node is registered and active.
- GB a node earns this way **first tops up the node's stake shortfall**; only the rest goes to its beneficiary.
- These payments run separately from CoNET's own GB service fees ([GB billing](gb-billing.md#9-service-fees-in-gb-approved-not-yet-live)); each has its own funds.

## 4. Subscriptions (ERC-1155) [Approved, not yet live]

The requirement is decided. A local implementation exists; some details, such as how terms are counted, are still open.

- An issuer can turn on and off its own subscription products, with a starting token ID of its choice. Each product has a name, a description, an icon link, a price and a term: **day, week, month, quarter or year**.
- Each subscription is a unique ERC-1155 receipt held by the buyer.
- A product can include an allowance of free T for the whole term, or an unlimited allowance. The allowance is counted per receipt over the whole term, is not reset daily or weekly, and is not reset when the receipt is transferred. An unlimited allowance is still limited by the issuer's GB deposit.
- A user pays for a subscription with a paid T balance or with the underlying S, at the product's price in T (S at the fixed ratio). Free balances cannot buy subscriptions. Payment in T burns it and mints the matching S to the issuer; payment in S goes directly to the issuer.
- A node presents the receipt to settle a service. The token checks that the receipt is valid and that the node is qualified, then pays the node in GB from the issuer's deposit.
- Switching off the ordinary free pool does not affect subscription allowances, which are accounted separately.
- Contract wallets must be able to receive the ERC-1155 receipt; a purchase that cannot deliver the receipt is reverted in full.

## 5. Official stablecoins [Approved, not yet live]

- conet-USDC, backed by Base USDC, is the first official stablecoin.
- The DAO may admit a new official stablecoin through a separately accepted route decision. Each uses the fixed approved template with its own exchange entry; the design does not itself enable the route or authorize deployment.
- **Each official stablecoin has exactly one external chain** for deposits and withdrawals. The same stablecoin cannot flow in from one chain and out to another.

### 5.1 Two switches per official stablecoin [Implemented, pending acceptance]

Each official stablecoin has two switches. They are independent: either can be set without the other. Both are set only by DAO decision and are carried out on CoNET by the AAC contracts. Each applies only to the stablecoin it names; other stablecoins are not affected.

Both switches apply to conet-USDC, meaning the new conet-USDC contract (not yet deployed). The current conet-USDC contract listed on [Core L1 assets](assets.md) will not be upgraded and does not have these switches.

1. **Cross-chain channel switch.** When the channel is closed, both directions close for that stablecoin: no transfers into CoNET and no transfers out of CoNET. Messages already in flight, whose value was already burned or locked on one side, are kept safely. While the channel is closed, these messages still expire at their original deadline. After its deadline, a message can be refunded, but only once it is proven that the destination chain has closed it without delivering it; a refunded message can never be delivered afterwards. A message that has not expired is delivered at most once after the channel reopens. This applies in both directions. Closing a channel never leaves a one-sided burn and never causes a double delivery.
2. **Mint and burn pause.** While it is on, every path that mints or burns that stablecoin inside CoNET L1 is blocked. This includes direct calls and calls made indirectly through third-party stablecoins backed by it: exchange in, redemption, issuer earnings, subscriptions and DePIN settlement. A pause cannot block only payouts while still accepting exchange in. Third-party stablecoin entry points backed by it are covered through the mint and burn calls they make. Ordinary transfers are not paused.

Paid GB bought on CoNET is issued by burning conet-USDC ([GB billing, Section 4](gb-billing.md#4-issuance-of-paid-gb-approved-not-yet-live)). Exchanging GB back to conet-USDC mints conet-USDC. While the conet-USDC mint and burn pause is on, both that paid GB issuance and exchanges of GB back to conet-USDC pause.

Both switches are set by DAO decision: the governor executes the decision through the AAC execution contract on CoNET, which applies it to the stablecoin's contracts. How the DAO stops, reopens and pauses (two-direction pairing, refund conditions and the cross-chain message identifier) is described in [DAO and the next-generation treasury, Section 6](dao-treasury.md#6-stablecoin-channel-and-pause-decisions-implemented-pending-acceptance).

The two switches replace any earlier description in which one switch stopped only exchange in and the other stopped only redemption. The design is decided. Both switches, for the official stablecoins and conet-USDC, are implemented locally in the AAC contracts, and the DAO side (including the mint and burn pause decision) is implemented locally in DAO candidate 4, which is not locked. Acceptance is pending, and nothing is deployed.

## 6. Implementation status

| Item | Status |
| --- | --- |
| Stablecoin factory, dual balances, redemption fee p, profit rate m, issuer minting at burn, mixed transfers, fractional ratios | In local candidate `e6380ec33bf9fb40bf1d4c958073b47fe06355f7`, `ThirdPartyStableToken.sol` sets `MAX_PROFIT_RATE_BPS = 50000` and constructor/setter reject values above it; `third-party-decimals-reentrancy.test.ts` covers the 50,000 bps boundary. This is source and test evidence for that candidate, not a fresh test run or production state |
| Settlement of third-party asset payments across chains | Tested only with stand-in proofs; not verified |
| Per-stablecoin channel switch and mint and burn pause (Section 5.1) | **[Implemented, pending acceptance]**, local tests in the AAC contracts and in DAO candidate 4 (not locked; candidate 3 remains the locked candidate). Not deployed |
| Subscriptions (ERC-1155) | **[Implemented, pending acceptance]**, local tests; payments go to the issuer. Term counting details pending |
| Node-submitted orders | Design; local prototype on the node side only. Not enabled on production nodes; needs separate approval |
| Automatic same-address deployment on other chains | Design decided; not implemented |

## 7. Open items [Open]

- The amount of the CNET issuance fee.
- The unit of cross-chain limits for third-party cross-chain tokens, and initial limits for newly admitted official stablecoins. A token without a DAO limit cannot move.
- How a node earning GB tops up its stake (stake is in CNET), and the price used.
- How orders signed before a setting change are handled, beyond price version checks.
- Subscriptions: how month, quarter and year terms are counted and when they start.
- Batch submission, credit limits and who bears failure costs for node-submitted orders.

## Related

- [GB purchase, metering, fees and settlement](gb-billing.md)
- [Two-way AAC bridge](aac-two-way-bridge.md)
- [DAO and the next-generation treasury](dao-treasury.md)
- [Mailbox storage billing](../l0/mailbox-storage-billing.md)
