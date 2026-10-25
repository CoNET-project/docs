# GB AMM Whitepaper: Automatic Market Making, Treasury Operations and Market Risk

**Version:** v0.2 (review revision) | **Date:** 25 October 2026 | **Basis:** the [GB Whitepaper v0.3](gb-whitepaper.md) (the "GB Whitepaper") and operator decisions of 22 to 25 October 2026 | **Status:** DAO discussion draft. Not approved by the DAO. The contracts described here are not deployed.

A companion paper on GB market structure within the CoNET economy.

**How to read the labels**

- **[Decided]**: a rule the operator has decided. Rules taken from the GB Whitepaper cite its section; rules added in this paper give the decision date. An operator decision is not DAO approval.
- **[To confirm]**: text already in the GB Whitepaper that the operator has not finally confirmed.
- **[Pending]**: a matter not yet decided. Listed in Appendix B.
- **[Proposed here]**: a design proposed by this paper and not yet decided by the operator.
- A reference such as "(WP 13.2)" or "(WP Chapter 4)" points to the GB Whitepaper. This paper's own sections are written as "Section 4.2" or "Chapter 5".
- This paper expands GB Whitepaper Chapter 13 (AMO) and Section 13.7 (price stability mechanism). Where the two differ, the [Decided] rules of the GB Whitepaper prevail.

---

## Summary

GB is the payment token of CoNET DePIN. Its long-term demand comes from deliverable services: network forwarding, storage, hosting and computing. This paper explains how GB is priced on secondary markets, how the treasury takes part in the market through AMO and automatic market making within parameters set by DAO vote, and how these operations affect reserves and coverage.

GB has three layers of price. The service price sets how many GB one service costs. The official rate R, decided by DAO vote, sets how much conet-USDC corresponds to issuing or exiting one paid GB. The secondary-market price is set by trading. Users can burn conet-USDC to issue paid GB at R (plus a 0.1% issuance fee), and can burn paid GB to exit at R (less a 0.1% exit fee). While these two channels are open and reserves are available, arbitrage keeps the market price within a narrow band around R.

The treasury has no discretionary minting power. AMO sells new GB only for conet-USDC, at a net price not below R, and burns the conet-USDC received in the same transaction. GB bought back is cancelled at once. Of the sale proceeds, the part equal to R becomes GB base backing; only the part above R enters the risk reserve. Treasury income therefore comes from narrow spreads and protocol fees, and its scale is limited by the risk reserve and trading quotas.

Crossing chains is not a treasury privilege. GB leaves CoNET by being burned on CoNET and minted on the external chain by the AAC secure construction; it returns by being burned on the external chain and minted on CoNET. Any holder can arbitrage price differences between the chains. The treasury holds no minting right on external chains.

The perpetual-short strategy proposed in v0.1 conflicts with these rules in several ways. This version keeps it as a [Pending] research module (Chapter 8), not part of any implementation (operator decision, 25 October 2026).

This paper does not promise that GB equals one US dollar, and does not promise rising prices, holder numbers or treasury profit. It is neither a return forecast nor a contract audit.

> Intended readers: DAO voters, service users, liquidity providers and researchers. Example parameters are for illustration only and are not launch parameters.

---

## 1. Positioning and price structure

**GB's holding value comes first from its ability to keep buying services. GB's exit capacity comes from separately accounted Base USDC reserves. The two are measured separately and must not be double-counted.**

### 1.1 Two classes of GB

| | Paid GB | Free GB |
| --- | --- | --- |
| Source | User issuance, AMO sale, cross-chain inbound, miner mint (exception) | Airdrop contract, within a voted budget |
| Right of exit | Yes: burn, then mint conet-USDC at R | No |
| Transfer, trade, cross-chain | Yes | No |
| Enters the AMM pool | Yes | No |
| Counted in exit obligation L | Yes | No |

[Decided] (WP 1.3, 5.1, 8.2). The markets, pools, arbitrage and buybacks in this paper concern paid GB only.

### 1.2 Three prices

| Price | How it is set | Use |
| --- | --- | --- |
| Service price | Standard price plus the provider's own markup or discount (Section 2.1) | How many GB one service costs |
| Official rate R | DAO vote [Decided] (WP 2.3) | conet-USDC per paid GB at issuance or exit |
| Secondary-market price P | Free trading in pools and other markets | Exchange between holders |

R is expressed in conet-USDC per GB and does not mean that one GB is fixed at one US dollar. Changes to R are bound by these rules [Decided] (WP 2.3): each change is at most 50% of the current rate; rises and falls are each capped at 20% cumulatively per 90-day period; a rise that would leave coverage below C_min is refused by the contract; proposals state a future effective block, and issuance and exit at the old rate are capped between lock and effect.

**[Decided]** (25 October 2026) The standard price of a service is 1 GB paid for each 1 GB of billed traffic, or for one standard service unit defined in the service catalogue. Providers may raise or lower their price from the standard price by any percentage, with no upper or lower limit (Section 2.1). The billed data unit (for example 1 GB = 10^9 bytes) must be stated in the service catalogue, so that it is not confused with the token symbol GB.

### 1.3 Arbitrage band

Issuing one paid GB costs about R × 1.001; exiting one returns about R × 0.999 net. Let c be the network, trading and capital cost of one arbitrage round, per GB. Then:

> R × (1 − 0.001) − c ≤ P ≤ R × (1 + 0.001) + c

When P is above the upper bound, arbitrageurs issue and sell. When P is below the lower bound, they buy and exit. While issuance and exit are open and reserves are available, this band is the main constraint on the GB price.

AMO is triggered when the market price deviates from R by 1% [Decided] (WP 13.5), clearly wider than the 0.1% fee band. In normal conditions, arbitrageurs act before AMO does. AMO matters mainly in three cases: cross-chain or execution costs make c large; issuance or exit is restricted; or market depth is too thin for arbitrage to complete in time.

### 1.4 Three kinds of price deviation

1. **Cross-chain spread**: paid GB trades at different prices on CoNET and Base. Repaired by cross-chain arbitrage (Chapter 5).
2. **Market price outside the arbitrage band**: first check the issuance and exit channels, cross-chain costs and market depth; AMO supplements within its quotas (Chapter 7).
3. **Reserves or exits impaired**: Base USDC is frozen, coverage is below 100%, or exits are queued. The lower bound no longer holds, and the market price may fall to a deep discount. This case is handled under WP Chapter 14. AMO and buybacks are not used as a price floor.

Each case is handled separately. A fixed dollar value is not used as a target for unlimited intervention.

### 1.5 Reasons to hold, and limits

Keeping GB lets users avoid repeated conversion costs, keep a balance ready for services, and plan purchases within clear price windows. Long-term retention should rest on service quality, fee transparency and enforceable exit rules.

GB gives holders no right to protocol profit, treasury net assets or DAO governance power [Decided] (WP 1.3). Cancellation reduces supply, but lower supply does not mean a higher price: within the arbitrage band, the price is set mainly by R and by exit capacity.

---

## 2. Application demand and service delivery

**Applications support GB demand only when they turn into deliverable services that people pay for.**

| Application | Intended GB use | Public status and limits |
| --- | --- | --- |
| SilentPass | Private access, network forwarding and the related resource settlement | Public product and implementation exist; GB pricing and operating metrics still need verification |
| web3:// C/S | Wallet-addressed web, API and persistent application streams | Protocol and part of the runtime implemented; still under development overall |
| Wallet-addressed BT and DCDN | Valid piece delivery, seeding and content distribution | Development direction; not to be counted as realised revenue in advance |
| Other cloud-resource applications | Storage, hosting and compute services with verification rules | Included application by application, on delivery and billing evidence |

Public documentation lists SilentPass as an application with a production reference, and lists the overall product capability of web3:// and BT/DCDN as in development. The existence of a base protocol does not mean that new applications already have paying users or commercial scale. [4](../applications/silentpass-vpn.md) [5](../applications/web3-url.md) [6](../applications/bt-dcdn.md)

Wallet addressing reduces an application's dependence on a fixed public IP address. The network underneath still uses TCP/IP, and participants such as entry nodes may still observe connection metadata. The commercial value of GB should rest on verified functions and privacy limits, and revenue forecasts must not assume "no IP at all" or absolute anonymity. [1](../README.md) [5](../applications/web3-url.md)

### 2.1 Standard price and provider pricing [Decided] (25 October 2026)

Services are priced in GB. The standard price is 1 GB paid for each 1 GB of billed traffic, or for one standard service unit. Providers have the right to set their own price: they may raise or lower it from the standard price by any percentage, with no upper or lower limit:

> GB paid by the user = standard quantity × (1 + provider's markup or discount)

For example, if a provider prices at the standard price +10%, a user who uses 1 GB of traffic pays that provider 1.1 GB; at −20%, the user pays 0.8 GB. The markup or discount must be published in the service catalogue, is bound by the order signature, and cannot be changed during settlement.

Payment with free GB is settled at the provider's markup or discount in the same way (decided 25 October 2026). The farming risk this creates is covered in Chapter 11.

Because services are priced in GB, the user's USDC cost moves with R and with the market price, and so does the value of the GB the provider receives. Providers can respond by adjusting their markup or discount.

When GB trades below R (case 3 in Section 1.4), a user pays the same number of GB, so the USDC cost of the service falls. This can attract demand from real users. The GB the provider receives is discounted at market value in the same way, and the provider can raise its price. The USDC cost here is only a reference; it is not a redemption promise for GB.

### 2.2 Terms each service must publish

Each service must publish its resource unit, markup or discount, available capacity, responsible provider, acceptance criteria, and refund and dispute rules. Bandwidth, storage and compute are metered separately. When a service is interrupted, confirmed delivery or refund obligations still follow the original rules; the existence of other applications does not substitute for the specific service a user bought.

---

## 3. Protocol fees, cancellation and retention

**The treasury's recurring income comes from protocol fees. The GB Whitepaper has decided how they are booked; this chapter covers only their effect on the market.**

### 3.1 Three protocol fees [Decided]

| Fee | Basis | Allocation |
| --- | --- | --- |
| Issuance fee 0.1% | Charged on top of the issuance principal (WP Chapter 6) | In full to the risk reserve |
| Exit fee 0.1% | Deducted from the gross redemption; only the net amount is minted (WP Chapter 9) | In full to the risk reserve |
| Settlement fee 0.5% | 0.5% of the service price, borne by the miner (WP Chapter 7) | Treasury share r (initially 50%) is cancelled at settlement; network share 1 − r goes to the protocol fee address, which a DAO 2/3 vote can change |

Example: a service is priced at 100 GB and the user pays 100 GB. The miner nets 99.5 GB; the 0.25 GB treasury share is cancelled at settlement, and 0.25 GB goes to the protocol fee address.

The 0.5% settlement fee is charged only in the settlement module; ordinary transfers and DEX trades are not charged (WP 7.3). The AMM pool's swap fee τ is set separately from these protocol fees; neither replaces the other.

### 3.2 Accounting effect of cancellation

When q GB of the settlement-fee treasury share is cancelled, L falls by R × q, A is unchanged, surplus rises by R × q, and the matching Base USDC moves from GB base backing into the risk reserve [Decided] (WP 10.2). Cancellation needs no USDC first, and creates no selling pressure.

v0.1 proposed selling fees for USDC to use as derivatives margin. That conflicts with default cancellation and is removed in this version. Market sale is only the fallback in WP 10.2; its proceeds also go to the risk reserve, with no other use.

### 3.3 Retention driven by use

Balances held for service purchases, continued use, spending across applications and reasonable conversion costs all reduce unnecessary repeated cash-outs. The exit fee is fixed at 0.1%, and must not be raised temporarily as a substitute for solvency management (WP 14.3). More long-term holders is an operating result that needs verification, not something fees guarantee.

Retention metrics should track paying users' 7-day and 30-day balances, repeat purchase rate, service consumption rate, exit ratio and balance concentration. Free GB distribution, transfers between addresses under common control, and short-lived wash activity should be flagged separately. Growth in holder addresses is not, by itself, real user growth.

---

## 4. AMM and execution architecture

**Pools exchange assets by rule. AMO and automatic market making adjust supply and liquidity within voted parameters. Every check reads only the reserve-ledger contract.**

### 4.1 Modules

| Module | Main role | Constraints |
| --- | --- | --- |
| Trading pool | Exchanges paid GB and conet-USDC; records actual reserves | [Decided] Concentrated liquidity, τ = 0.05% (Section 4.2); free GB cannot enter |
| Price observation | Aggregates multi-source time-weighted prices, depth and freshness | [Decided] Multi-source time-weighted observation (WP 13.5); a single thin pool cannot trigger large operations |
| AMO module | Sells new GB; buys back and cancels | [Decided] conet-USDC only, s ≥ R, burn in the same transaction; quotas based on the risk reserve (WP 13.2, 13.5) |
| Automatic market making | Adds or withdraws liquidity within voted ranges and quotas | [Decided] Not enabled at first (Section 4.4) |
| Risk-control module | Limits, circuit breakers and pauses | [Decided] Contracts execute automatically within voted parameters (WP 14.2) |
| Reserve-ledger contract | Records A, L, the risk reserve and pending-settlement occupancy | [Decided] Sole source for coverage, C_min and rate checks (WP 11.1) |
| AAC and cross-chain module | Verifies burn facts and mints on external chains | [Decided] The treasury holds no external minting right (WP Chapter 4) |

[Decided] Daily risk control and AMO are executed automatically by the contracts within DAO-voted parameters, with no privileged execution address (WP 3.1, 14.2). The contracts do not run on a schedule; state updates are triggered by transactions that submit verifiable data. **[Decided]** (25 October 2026) Anyone may trigger AMO sales and buybacks when the conditions are met. The contract itself checks the price deviation, quotas and coverage; if the conditions are not met, the transaction reverts. The trigger pays its own gas.

Automation constrains execution. It does not by itself produce positive returns.

### 4.2 Base trading pool

**[Decided]** (25 October 2026) The GB/conet-USDC pool uses a concentrated-liquidity design (with Uniswap v3 as the reference), with a swap fee τ = 0.05%. Because the GB price moves in a narrow band around R most of the time, liquidity providers can concentrate funds in that band, so the same capital gives more depth. A fee of 0.05% is below the 0.1% issuance and exit fees, so it does not noticeably widen the arbitrage band.

Within a single price range, a concentrated-liquidity pool performs a constant-product swap on that range's virtual reserves. Let x and y be the virtual paid-GB and conet-USDC reserves in the range. Selling a GB into the pool returns b conet-USDC: [13](https://developers.uniswap.org/docs/protocols/v2/concepts/swapping)

> b = y × (1 − τ) × a ÷ (x + (1 − τ) × a)

A trade that crosses a range boundary is computed piecewise, using the liquidity of each adjacent range. The actual execution price depends on trade size, fees and how liquidity is distributed in the pool. Orders from users and from contracts must carry a limit price, an expiry and an acceptable price impact.

The swap fee τ goes to liquidity providers. The treasury does not make markets at first (Section 4.4), so it earns no swap fees; how such fees would be booked is decided together with the evaluation of option B.

### 4.3 The only way new GB enters the market

Newly issued paid GB can enter the market only through an AMO sale [Decided] (WP 13.2). The contract mints q GB and trades them at once, and burns all the conet-USDC received in the same transaction. If the trade does not complete, the whole transaction reverts, leaving no unbacked GB.

For a sale of q GB at net price s:

> A′ = A + s × q; L′ = L + R × q; change in surplus ΔE = (s − R) × q

R × q becomes GB base backing, and (s − R) × q goes to the risk reserve. Most of the sale proceeds back the new obligation. They are not profit and cannot be used for anything else.

v0.1 said new GB could enter the market through "auctions or liquidity additions". An auction that does not settle at once, or adding newly minted GB to a pool on one side only, does not meet the same-transaction burn rule. Both are removed in this version.

### 4.4 Inventory source for automatic market making

WP 13.7 allows a treasury module to provide liquidity automatically within voted ranges and quotas, but does not say where the GB side of that inventory comes from. Under the current rules, the treasury has no usable GB inventory: the settlement-fee treasury share is cancelled at settlement; GB bought back must be cancelled at once (WP 13.3); and GB newly minted by AMO can only be sold on the spot. The options and their consequences are:

| Option | Method | Consequence |
| --- | --- | --- |
| A: treasury issues GB into the pool | Issue GB at R from the conet-USDC buffer, and pair it with conet-USDC as liquidity | This GB is counted in L, and treasury-held GB is not counted in A (WP 11.1), so coverage falls; the 0.1% issuance fee is also paid |
| B: one-sided conet-USDC liquidity only | Place conet-USDC in price ranges below R, which works as tiered limit buybacks | GB acquired must be cancelled under the buyback rules and counted against buyback quotas; the contract must cancel it automatically after each fill |
| C: no treasury market making | Rely on independent liquidity providers, user issuance and exit, and AMO | Lowest treasury risk; depth depends on outside participants |

**[Decided]** (25 October 2026) Option C at first: the treasury does not make markets. Option B is evaluated after AMO buybacks have run stably.

### 4.5 Front-running and execution loss

AMO and market-making parameters are set by vote and are therefore public; front-running cannot be prevented by hiding parameters. Protection comes from per-trade quotas, limit prices, trigger persistence and split execution, which limit the spread a front-runner can capture each time.

**[Decided]** (25 October 2026) Batch auctions and encrypted orders are not used at first. Front-running profit is limited by per-trade quotas, limit prices and trigger persistence. A single trade is at most 1% of the risk reserve, so the room for front-running is small, and the contracts stay simpler. The two methods below are kept for later evaluation.

Short batch auctions: orders in the same batch and direction clear at one price, and buy and sell interest is matched directly. CoW Protocol's batch settlement is a reference. [7](https://docs.cow.fi/cow-protocol/concepts/benefits/mev-protection)

Encrypted orders: private routing protects who talks to whom, but not on-chain transaction ordering. Encrypted orders would need the ordering commitment to come before decryption, and rules for reorganisations, timeouts and orders that cannot be executed. Ordinary private RPC endpoints also carry an operator trust boundary.

---

## 5. Cross-chain transfers and arbitrage between CoNET and Base

**Market participants repair cross-chain spreads through cross-chain arbitrage. The treasury has no cheaper migration path than an ordinary holder.**

### 5.1 Rules [Decided] (WP Chapter 4)

1. **Outbound**: an external chain may mint GB only after paid GB is burned on CoNET. There is no other mint route.
2. **Inbound**: an external chain burns the CoNET-issued asset, and after AAC proof it is minted on CoNET. This is the only route.
3. **Minting right**: on external chains, the minting right is held by the AAC secure construction. The external treasury deploys the token at the same address, but holds no minting right.
4. **External supply**: the GB supply on external chains equals the net outbound burns on CoNET.
5. **One time only**: each burn matches one mint; replays and duplicate submissions must not create extra supply.

### 5.2 Arbitrage path

Exit is possible only on CoNET, so the GB price on Base is anchored to "inbound cost + net exit proceeds on CoNET".

| Step | Base discount example (R = 1) |
| --- | --- |
| Buy on Base | Buy 100,000 GB at an average of 0.97, paying 97,000 Base USDC |
| Inbound | Burn on Base; after AAC proof, 100,000 GB is minted on CoNET |
| Exit on CoNET | Exit at R, receiving 99,900 conet-USDC net |
| Gross spread | 2,900, before gas, cross-chain confirmation time and capital cost |

When Base trades at a premium, the direction is reversed: issue or buy on CoNET, burn to go outbound, mint on Base and sell. While issuance and exit on CoNET are open, the CoNET price rarely stays outside the arbitrage band for long, so cross-chain spreads show up mainly as a discount or premium on Base. The width of that band depends on cross-chain confirmation time and cost.

Prices in the example are executable averages, not the best order-book level or the instantaneous pool price. Arbitrage compresses spreads to the range set by cost and risk; it cannot push them to zero.

The treasury can take part in arbitrage only through the reserve arbitrage of WP 13.7, executed by the contracts within voted parameters. The specific parameters are [Pending].

### 5.3 Supply conservation and in-transit supply

> S_eff = S_CoNET + S_ext + U

S_CoNET and S_ext are the paid GB circulating on CoNET and on each external chain. U is the amount already burned on one side but not yet minted on the other. When migration completes, U falls and the destination chain's supply rises by the same amount.

The exit obligation in the GB Whitepaper is L = R × (S_CoNET + S_ext). **[Decided]** (25 October 2026) U is not counted in L; it is disclosed separately. Holders' claims on in-transit burns are not lost (WP 3.3). During cross-chain peaks, coverage computed this way reads temporarily high, so U should be read together with coverage.

### 5.4 Where settlement assets sit

Trading on Base uses Base USDC; trading on CoNET uses conet-USDC. conet-USDC can be minted only from Base USDC deposits or by burning paid GB [Decided] (WP 3.2). It is not USDC issued natively by Circle on CoNET. [2](assets.md) [12](https://developers.circle.com/stablecoins/usdc-contract-addresses)

Arbitrage that repairs a Base discount accumulates its capital on CoNET as conet-USDC. **[Decided]** (25 October 2026) When conet-USDC leaves CoNET, it is burned on CoNET and the external treasury releases the locked Base USDC. Releases are capped by the locked balance, and nothing is minted on Base. **[Decided]** (25 October 2026) This release path is also subject to the forged-message gate in WP Chapter 17: before it opens, it must be proven that the Base side rejects forged CoNET burn messages. Until this path opens, the capacity to repair a Base discount is limited by arbitrageurs' own Base USDC.

---

## 6. Treasury accounts

**The treasury measures its results by coverage and realised surplus, and accounts for the use of every unit of Base USDC.**

### 6.1 Definitions [Decided] (WP 11.1)

- A: net assets available for GB exits, that is, GB base backing plus the risk reserve, less in-transit occupancy and restricted assets;
- L: the gross obligation of all paid GB with a right of exit, at the current rate;
- surplus E = A − L; coverage C = A ÷ L;
- GB held by the treasury and not yet cancelled is not counted in A, and is not deducted from L.

A, L, the risk reserve and pending-settlement occupancy are recorded by the reserve-ledger contract. Coverage, C_min and rate checks read only this contract.

### 6.2 Effect of each operation on the accounts

| Operation | Change in A | Change in L | Change in surplus E |
| --- | --- | --- | --- |
| User issuance (principal Q) | +1.001Q | +Q | +0.001Q |
| User exit (gross Q) | −0.999Q | −Q | +0.001Q |
| Cancel q GB of settlement-fee treasury share | 0 | −Rq | +Rq |
| AMO sells q GB at net price s | +sq | +Rq | +(s − R)q |
| AMO buys back and cancels q GB at average price b | −bq | −Rq | +(R − b)q |
| Miner mint of m GB | 0 | +Rm | −Rm |
| Cross-chain outbound or inbound | 0 | 0 | 0 |

The settlement fee's network share keeps circulating as GB and stays in L, but does not add to surplus. This table is consistent with the surplus formula in WP 11.2.

### 6.3 Fund categories [Decided] (WP 13.3)

| Fund category | Usable for buybacks or market making? |
| --- | --- |
| GB base backing and risk reserve (through the conet-USDC buffer) | Yes, provided the remaining assets still meet all remaining obligations and liquidity constraints |
| conet-USDC backing | No |
| Payable, in-transit or restricted assets | No |
| Network maintenance and redevelopment funds | No |

Each unit of Base USDC may serve only one purpose.

### 6.4 Two accounting errors corrected in this version

1. **New issuance is not free money.** Of AMO sale proceeds, R × q is base backing for the new obligation, and cannot cover trading losses or top up margin; only (s − R) × q enters the risk reserve. v0.1's example of "selling about 166,667 new GB at 1.2 to raise USD 200,000 against short losses" yields only about 33,333 USDC of risk reserve when R = 1; the other 166,667 USDC is backing. In addition, while issuance is open, the market price is unlikely to reach 1.2.
2. **The treasury has no "own unissued newly minted GB".** v0.1 distinguished burning the treasury's own newly minted GB from market buybacks. Under the current rules, new GB is minted only on the spot during an AMO sale, and the treasury never holds newly minted GB in advance. That distinction is removed.

### 6.5 Service economics

Node income should cover service costs and a reasonable return. After serving free users, miners receive newly minted paid GB at ratio k (initially 0.01), backed by the risk reserve [Decided] (WP 5.2). This path consumes surplus directly. Its per-period quota is 1% of L, and it pauses when coverage is below C_min. The risk reserve is small early on, so this path will be paused most of the time; miners should be told this plainly.

---

## 7. Handling volatility and price deviations

**The treasury chooses tools by the cause of the deviation and the capital available. There is no unbudgeted fixed-price floor.**

| Market state | Response | Execution limits |
| --- | --- | --- |
| Market price within the arbitrage band | No active intervention | Payments and independent trading continue as normal |
| Market price more than 1% above R | AMO sells new GB | s ≥ R, burn in the same transaction, C ≥ C_min after the trade, per-trade, daily and 90-day quotas |
| Market price more than 1% below R | AMO buys back from the conet-USDC buffer and cancels | Buffer of 100,000 conet-USDC, topped up automatically below 50,000; quota shared with sales; remaining assets must meet obligations after the buyback |
| Cross-chain spread | Market participants arbitrage across chains | AAC proof time and cross-chain cost |
| Coverage below C_min | AMO sales and miner mint stop | WP 14.3 |
| Reserves restricted, coverage below 100% | Overall recovery process; exits queue and are paid at R once assets recover | No further spending under daily rules; queue details [Pending] |
| Conflicting price sources or abnormal service volume | Stop the affected operation and investigate | Do not freeze a distorted price; do not erase losses already incurred |

AMO quotas are based on the risk reserve: at most 1% per trade, 10% per day and 20% per 90-day period [Decided] (WP 13.5). **[Decided]** (25 October 2026) Quotas are measured in conet-USDC traded: the amount received for sales and the amount spent for buybacks. Sales and buybacks share one quota. When a quota is used up, operations stop; quotas are not refilled without limit because the price keeps deviating.

### 7.1 When the price rises

The main force against hoarding and squeezes is the open issuance channel: anyone can obtain new GB at about R × 1.001, so a hoarder can hardly control circulating supply for long. AMO sales are a supplement, limited by quotas based on the risk reserve.

Selling above R can still dilute coverage: whenever s ÷ R is below current coverage, coverage falls after the sale (Section 10.1). Each sale must check that coverage after the trade is not below C_min.

### 7.2 When the price falls

The main force against dumping is the open exit channel: when the market price is below R × 0.999 − c, arbitrageurs buy and exit. AMO buybacks are a supplement, funded from a fixed-size conet-USDC buffer.

A buyback raises coverage only when its average price b is below the available assets per GB, A ÷ N (WP 13.3). When coverage is below 100%, buying below R can still lower coverage, so the overall recovery process applies instead.

Service demand is a channel of support independent of financial markets. Because services are priced in GB, the USDC cost of services falls when GB is at a discount, which may attract real users to buy more (Section 2.1). Service demand should be verified by actual new purchases, not by historical turnover.

---

## 8. Derivatives risk module [Pending research module]

**v0.1 proposed that the treasury hold perpetual short positions on GB and use gains in a falling market to fund buybacks. Under the current rules, this design does not work on funding, execution or returns.**

**[Decided]** (operator, 25 October 2026) This chapter stays as a [Pending] research module and is not part of any implementation. Its design and parameters are not launch rules.

### 8.1 Conflicts with decided rules

1. **Funding source**: the settlement-fee treasury share is cancelled at settlement and is not converted into USDC. Margin could come only from the risk reserve, and every unit allocated lowers A and coverage directly.
2. **Covering losses**: R × q of AMO sale proceeds is base backing and cannot top up margin (Section 6.4).
3. **Execution identity**: there is no privileged execution address. A centralised exchange or OTC account needs a private-key holder, which conflicts with this. An on-chain perpetual would need a GB perpetual market to exist, with the contract holding the position directly.
4. **Return conditions**: within the arbitrage band, GB moves in small steps around R, so a short earns close to nothing while paying funding and execution costs continuously. A short earns meaningful returns mainly when reserves are restricted, exits are queued and the lower bound fails, which is exactly when counterparty and venue risk is highest.
5. **Conflict of interest**: the DAO votes on R and on AMO parameters. If the treasury also holds a directional position, there is an incentive to influence settlement prices through parameters.

### 8.2 If studied in future

The profit and loss of a directional short is:

> Π = Q × (F₀ − F₁) + Fund − Cost

Q is the GB quantity under the contract; F₀ and F₁ are the average opening and closing prices; Fund is the net funding actually paid or received; Cost is execution cost. Shorts may pay funding; the direction depends on the spread between the perpetual price and the spot index. [9](https://docs.dydx.xyz/concepts/trading/funding)

Stress constraint: let C_d be the USDC available to the module, u the stress price rise within the response window, m the maintenance margin rate, and c_d a cost buffer as a share of notional. The opening notional N must satisfy:

> N ≤ C_d ÷ (u + m × (1 + u) + c_d)

This requires the account to still meet maintenance margin after absorbing the loss from the rise. It is a simplified constraint and does not cover price jumps, unlimited rises or venue failure. Liquidation happens before any supply response, and pushing the price back afterwards does not undo it. [8](https://docs.dydx.xyz/concepts/trading/margin) BIS research on crypto carry trades also documents funding constraints, margin and liquidation risk. [10](https://www.bis.org/publications/working-paper-1087-crypto-carry)

[Proposed here] If the module is studied again, it should at least meet these conditions: C_d comes only from risk reserve above a buffer over C_min; positions are held by contract in an on-chain market, with no account holder; positions are used only to hedge the tail risk of restricted reserves, not for directional profit; and all positions, margin and realised profit and loss are recorded in the reserve-ledger contract and published.

---

## 9. Business volume and capital accumulation

**10 TB and 1,000 TB are business-volume indicators. They must first be converted into realised surplus before they can be used to judge the risk reserve and operating quotas.**

The figures below use daily completed, billable traffic. Storage should use a separate unit such as TB-months; the same content forwarded through several nodes does not create several independent paid demands. The example assumes 10 USDC of service revenue per TB, a 0.5% settlement fee, a treasury share r = 50% that is fully cancelled, and an unchanged R. All parameters are illustrative assumptions.

| TB per day | Service value | 0.5% settlement fee | Treasury share (cancelled) | Network share | Annual surplus increase (365 days) |
| --- | --- | --- | --- | --- | --- |
| 10 | 100 | 0.50 | 0.25 | 0.25 | 91.25 |
| 100 | 1,000 | 5 | 2.50 | 2.50 | 912.50 |
| 1,000 | 10,000 | 50 | 25 | 25 | 9,125 |

> All amounts are in USDC equivalent.

### 9.1 Sensitivity to price per TB

| 1,000 TB per day | 1 USDC/TB | 10 USDC/TB | 50 USDC/TB |
| --- | --- | --- | --- |
| Daily service revenue | 1,000 | 10,000 | 50,000 |
| Daily treasury share (cancelled) | 2.50 | 25 | 125 |
| Annual surplus increase | 912.50 | 9,125 | 45,625 |
| Years from 100% to 115% coverage with L = 1,000,000 | about 164 | about 16.4 | about 3.3 |

Raising coverage from 100% to 115% needs a surplus of 0.15L. From settlement fees alone, the cumulative service value required is 0.15L ÷ (0.005r), which is 60L when r = 50%, consistent with WP 11.3.

Issuance and exit fees add surplus separately: with combined daily issuance and exit of 100,000 USDC gross, they add about 36,500 USDC a year. This depends on fund flows and cannot be derived from service volume.

### 9.2 Conclusions

1. At low fee rates, service fees alone build the risk reserve slowly. AMO quotas are based on the risk reserve, so business growth does not translate directly into larger operating quotas.
2. Scaling up AMO, market making or any risk module first needs risk reserve actually on hand, or separately disclosed outside capital and loss capacity.
3. Resource registration and TB forecasts are not reserves and do not trigger issuance (WP 11.4).

---

## 10. Worked fund-flow examples

**The same rules must explain profitable, loss-making and restricted scenarios.**

All examples assume: R = 1, GB base backing 1,000,000, risk reserve 150,000, A = 1,150,000, L = 1,000,000 (coverage 115%), C_min at an example value of 110%, and a conet-USDC buffer of 100,000. Quotas are measured in conet-USDC traded and are shared by sales and buybacks (Chapter 7).

### 10.1 Market price above R: AMO sale

The market price is 1.015, above the 1% trigger. The per-trade quota is 1% of the risk reserve, that is, 1,500 conet-USDC.

| Item | Result |
| --- | --- |
| Sale | 1,400 new GB at a net price of 1.012, receiving 1,416.80 conet-USDC, burned in the same transaction |
| Accounts | A = 1,151,416.80; L = 1,001,400; coverage about 114.98% |
| Surplus | +16.80 (base backing +1,400; risk reserve +16.80) |

Even if the whole daily quota (10% of the risk reserve, that is, 15,000) were used for sales, surplus would rise by only about 178 USDC. AMO is a liquidity supplement, not a main source of income.

### 10.2 Market price below R: AMO buyback

The market price is 0.985, below the 1% trigger.

| Item | Result |
| --- | --- |
| Buyback | 1,500 GB bought at an average of 0.985 and cancelled at once, spending 1,477.50 conet-USDC |
| Accounts | A = 1,148,522.50; L = 998,500; coverage about 115.02% |
| Surplus | +22.50; buffer balance 98,522.50, above the 50,000 top-up threshold |
| Quota | 1,477.50 used, from the daily quota of 15,000 shared with sales |

### 10.3 Restricted reserves

Suppose the issuer freezes 200,000 USDC on Base. A, net of restricted assets, falls to 950,000, and coverage to 95%:

1. coverage is below C_min, so AMO sales and the miner mint stop automatically;
2. coverage is below 100%, so buybacks no longer follow daily rules and the overall recovery process applies;
3. exits queue and are paid at R once assets recover (WP 19.8);
4. the lower bound of the arbitrage band fails, and the market price may fall below R × 0.999.

This is GB's main tail risk. The concentration risk of a single reserve asset is covered in WP 12.2.

### 10.4 The rules do not guarantee a profit every round

AMO earns narrow spreads, and its quotas are based on the risk reserve, so each round earns little. If the price rises and then falls, the obligations added by AMO sales must still be carried by backing. If the price keeps falling after a buyback, there is no book loss (the GB was cancelled), but the buffer has been spent. Strategies must be judged over the whole path, not over a favourable window.

---

## 11. Anti-manipulation and execution

**The aim is to reduce the ability to push the price artificially and extract profit, while still allowing normal purchases, sales and spread-repairing arbitrage.**

| Risk path | Control | What to verify |
| --- | --- | --- |
| Hoard GB, then squeeze | Open user issuance; AMO sales | Availability of issuance; actual traded volume |
| Dump, then collect cheaply | Open user exit | Availability of exit; queue status |
| Front-run AMO orders | Per-trade quota, limit price, trigger persistence (no batch auctions at first) | Worst execution, ordering rights, reorganisation handling |
| Front-run a rate vote | Future effective block; quota between lock and effect [Decided] (WP 2.3) | Issuance and exit volume before the effective block |
| Trigger AMO repeatedly to drain funds | Per-trade, daily and 90-day quotas | Whether the buffer can be drained cheaply |
| Fabricate service transactions | Delivery evidence, deduplication, subsidies shown separately | Wash trading, replay, common control |
| Burn free GB through fictitious services to farm the miner mint | Delivery evidence (WP 8.2); per-period quota of 1% of L | Whether burns match service volume |
| Charge free-GB users a large markup to burn more free GB and farm the miner mint | Free-GB distribution budget, with unused quota not carried over (WP 8.1); miner-mint per-period quota of 1% of L and pending-reissue queue cap; published markups | Markup distribution in free-GB settlement; concentration of miner mint by miner |
| Forge cross-chain messages | Before minting paths and the conet-USDC release path open, prove that forged block headers and receipts are rejected [Decided] (WP Chapter 17) | Negative testing, not only positive testing |
| Duplicate minting | One-time event identity, finality confirmation, per-chain reconciliation | Supply differences and recovery of incomplete operations |

Large trades are not evidence of bad intent in themselves. Miners may need to pay real costs, and businesses may buy in bulk. Controls should centre on market depth, price impact, quotas and real delivery, and the economic rules should not depend on identifying or penalising particular wallets.

### 11.1 Independence of price data

Several data points taken from the same shallow pool are not economically independent. Time-weighted prices raise the cost of short-term manipulation, but they lag, and longer-term manipulation still needs assessment. [14](https://developers.uniswap.org/docs/protocols/v2/concepts/oracles) When sources conflict, new operations should stop; a distorted price must not be frozen to hide actual losses.

### 11.2 Service evidence and privacy

Valid service evidence should confirm completed volume, payment and service quality, so that the same bytes are not billed or rewarded twice. A BT piece hash proves only content integrity; on its own, it does not prove that an independent user paid. Audits should use the minimum aggregated data needed, and avoid publishing logs that link user wallets, destinations and plaintext content. [6](../applications/bt-dcdn.md)

### 11.3 Stress-test target

The target of stress testing is that the full gain of the cheapest feasible manipulation does not cover its cost. The calculation must include spot markets, cross-chain transfers, issuance and exit, the AMO response and external derivatives markets. Trading principal cannot all be counted as attack cost, because part of it can be recovered in the reverse trade. Unknown positions in external markets should be listed as a model limit.

---

## 12. Governance and disclosure

**The treasury's operating powers should turn into holder confidence through public parameters and verifiable accounts.**

### 12.1 Governance [Decided] (WP Chapter 15)

- There is no execution multisig and no admin. Every matter that needs authorisation is a proposal. When yes votes reach two-thirds of the snapshot total weight, the voter executes it within that vote's transaction.
- Voted parameters relevant to this paper: R, C_min, the AMO trigger band and quotas, the conet-USDC buffer size and top-up threshold, circuit-breaker parameters, the miner-mint ratio k and its quota, and the settlement-fee split r.
- No vote can grant unbounded minting rights, rights to divert assets, or hidden fees.

### 12.2 Emergencies

**[Decided]** (confirmed 25 October 2026) There is no manual emergency channel, including a guardian address that could only pause (WP 14.2). Chain reorganisations, price-source failures, account mismatches and similar cases can be handled only by the contracts under circuit-breaker parameters voted in advance. Anything outside those parameters needs a proposal, with the delay that involves. v0.1's statement that "new high-risk trading and issuance can be paused" is implemented here through circuit-breaker parameters and does not correspond to any manual power.

Pauses are scoped separately: AMO, the miner mint and user channels pause independently, and stopping AMO does not cancel accepted exit requests. Treasury losses are not a reason to selectively erase counterparties' gains, or to stop them settling under existing rules.

### 12.3 Disclosure

| Item | Content | Purpose |
| --- | --- | --- |
| Supply | Issuance by source, burns and cancellations, circulation per chain, in-transit amount U | Verify conservation |
| Reserves | A, L, GB base backing, risk reserve, restricted assets, in-transit occupancy, coverage | Verify exit capacity |
| Fees | The three fees, the two-way split of the settlement fee, cancellation records | Identify income sources |
| AMO | Volumes bought and sold, net prices, R at the time, costs, realised profit and loss, coverage before and after, remaining quota | Judge the effect of treasury operations |
| Buyback buffer | Balance, top-up records, trigger threshold | Verify fund consumption |
| Trading pool | Pool reserves, treasury liquidity positions (if any), swap-fee income | Identify liquidity sources |
| Miner mint | k, volume minted, risk-reserve transfers, pause periods and pending-reissue records | Judge surplus consumption |
| Real services | Completed volume per application, refunds, external net payments | Tell business from wash activity |

Parameters and operations are on-chain, so on-chain data is the reference for disclosure, and summary reports must be reproducible from it. Showing only total USDC balances, cumulative mint volume or gross trading volume does not prove that the treasury is profitable.

---

## 13. Public status and staged verification

**Confidence must match the level of evidence. Each new module must pass its own launch gate.**

| Item | Current status | Role in this paper |
| --- | --- | --- |
| New GB contract | Design stage, not deployed; old contract balances are void and issuance starts from zero [Decided] (WP 19.1) | Asset base |
| New conet-USDC contract | Design stage, not deployed; no admin minting, no upgrade authority [Decided] (WP 3.2) | Settlement asset |
| AAC cross-chain | Minting paths and the conet-USDC release path must pass forged-message negative testing before opening [Decided] (WP Chapter 17) | Precondition for cross-chain use |
| SilentPass | Public product and implementation | GB revenue counted on measurement |
| web3:// and BT/DCDN | Still in development overall | Demand roadmap; no revenue booked in advance |
| AMO | Rules set in the GB Whitepaper; not implemented | Needs implementation, audit and small-scale validation |
| Automatic market making | Not enabled at first [Decided] (25 October 2026) | Option B evaluated after AMO buybacks run stably |
| Derivatives module | [Decided] Kept as a pending research module, not implemented (25 October 2026) | Research topic |

**Deployment gate [Decided]** (WP Chapter 17): new contracts are deployed only after discussion and independent audit are complete. Settlement-path status and issuance capability described in CoNET public documentation cannot be taken to mean that the AMM in this paper can already execute automatically. [2](assets.md) [3](cross-chain-treasury.md)

### 13.1 Staged verification

1. **Rule freeze**: settle the pending items in Appendix B and in WP Chapter 19.
2. **Contract implementation and audit**: new GB, conet-USDC, settlement module, reserve ledger, AMO and risk-control module; complete forged cross-chain message negative testing.
3. **Limited operation**: open issuance, exit and settlement with low quotas; run AMO with quotas below the decided values, disclosing all costs.
4. **Expansion**: once risk reserve is actually on hand and AMO buybacks run stably, evaluate option B for market making and its quotas.

### 13.2 Controlled experiments

Under the same business and market shocks, compare four configurations: user issuance and exit only; adding AMO; then adding market making; then adding cross-chain transfers. Measure the worst asset loss, the largest price deviation, recovery time, service delivery and exit completion rate. A new module's quotas grow only if it improves the overall result.

Scenarios should cover sustained rises, a rise followed by a fall, sustained falls, falling service demand, a USDC freeze, queued exits, a rate-adjustment vote, a single-chain outage, conflicting price sources and a sudden loss of market depth. Researchers should be able to reproduce the parameters and results. One successful buyback, or a single profitable stretch, is not a substitute for full validation.

> The mechanism analysis in this paper is not a contract audit, a return forecast or a fixed redemption promise. Holder confidence should grow with delivered services and operating evidence, not rest on claims of unlimited defence that cannot be tested.

---

## Appendix A: Parameter reference

| Parameter | Meaning | Status |
| --- | --- | --- |
| R | Official rate, conet-USDC per GB | [Decided] DAO vote; ±50% per change; rises and falls each capped at 20% cumulatively per 90 days |
| Issuance fee, exit fee | 0.1% each, in full to the risk reserve | Parameter of this version (GB Whitepaper) |
| Settlement fee | 0.5% of the service price, borne by the miner | Parameter of this version (GB Whitepaper) |
| r | Settlement-fee treasury share, cancelled at settlement | [Decided] Initially 50% |
| C_min | Minimum coverage | [Decided] Floor of 10%; value pending |
| AMO trigger | Market price 1% away from R; multi-source time-weighted observation | [Decided] |
| AMO quotas | 1% of the risk reserve per trade, 10% per day, 20% per 90 days; measured in conet-USDC traded; shared by sales and buybacks | [Decided] (measurement added 25 October 2026) |
| AMO trigger party | Anyone; the transaction reverts if conditions are not met | [Decided] (25 October 2026) |
| Service pricing | Standard price of 1 GB for 1 GB of traffic or one standard service unit; providers set their own markup or discount, with no limit; also applies to free GB | [Decided] (25 October 2026) |
| Buyback buffer | 100,000 conet-USDC, topped up automatically below 50,000 | [Decided]; custody method under discussion |
| k | Miner-mint ratio | [Decided] Initially 0.01; per-period quota of 1% of L |
| τ | Swap fee of the concentrated-liquidity pool | [Decided] 0.05% (25 October 2026) |
| D, p | Billed TB per day, service revenue per TB | Examples only |
| U | In-transit cross-chain amount | [Decided] Not counted in L; disclosed separately (25 October 2026) |
| N, C_d, u, m, c_d | Derivatives stress constraint | Research module, not implemented [Decided] (25 October 2026) |

---

## Appendix B: Pending items

All nine items listed in the first v0.2 draft were answered by the operator on 25 October 2026:

1. **Inventory source for market making (decided)**: option C at first, with no treasury market making; option B is evaluated after AMO buybacks run stably (Section 4.4).
2. **How AMO quotas are measured (decided)**: in conet-USDC traded; sales and buybacks share one quota (Chapter 7).
3. **In-transit amount U (decided)**: not counted in L; disclosed separately (Section 5.3).
4. **Derivatives module (decided)**: kept as a [Pending] research module, not implemented (Chapter 8).
5. **Service pricing (decided)**: standard price of 1 GB for 1 GB of traffic or one standard service unit; providers set their own markup or discount by percentage, with no limit; also applies to free GB (Section 2.1).
6. **conet-USDC outbound (decided)**: burn on the CoNET side, and the external treasury releases the locked Base USDC; must pass the forged-message gate in WP Chapter 17 before opening (Section 5.4).
7. **Pool curve and swap fee (decided)**: concentrated liquidity, τ = 0.05% (Section 4.2).
8. **Batch auctions or encrypted orders (decided)**: not used at first (Section 4.5).
9. **AMO trigger and emergency channel (decided)**: anyone may trigger AMO when the conditions are met; no manual emergency channel (Sections 4.1 and 12.2).

Still pending:

- The conditions for evaluating option B, and how swap-fee income on treasury liquidity positions would be booked.
- Standard service units: which unit of CPU/GPU, storage, SaaS and other non-traffic services corresponds to 1 GB.
- The specific parameters of treasury reserve arbitrage (WP 13.7; Section 5.2).
- Details of queued exits when coverage is below 100% (WP 19.8; Chapter 7).

Items 5, 6 and 9 were written into the GB Whitepaper on 25 October 2026 (WP 2.1, 3.2, 8.2, 13.1, 14.2, Chapter 17, Chapter 19 item 12, Appendix A).

---

## Appendix C: Main changes from v0.1

| Area | v0.1 | This version | Basis |
| --- | --- | --- | --- |
| Pricing | Market pricing only; no conversion | Issuance and exit at the official rate R form an arbitrage band | WP 2.2, 2.3, Chapter 9 |
| USDC conversion fee | To be priced separately | 0.1% each for issuance and exit | WP Chapters 6 and 9 |
| Settlement fee | Treasury takes 0.5% and may sell it for margin | Borne by the miner; treasury share r cancelled at settlement; network share to the protocol fee address | WP 7.1, 10.2 |
| New GB issuance | Treasury may sell, auction or add liquidity; proceeds treated as financing | Only by on-the-spot AMO sale with a same-transaction burn; R × q is backing | WP 13.2 |
| Cross-chain | Treasury burns and mints equal amounts as issuer | Anyone crosses chains; external minting right held by the AAC secure construction | WP Chapter 4 |
| Buybacks | Funded from net profit and free USDC | Fixed conet-USDC buffer; quotas based on the risk reserve; immediate cancellation | WP 13.3, 13.5 |
| Execution | Treasury executor with an operating identity | Contracts execute automatically within voted parameters; no privileged address | WP 3.1, 14.2 |
| Emergencies | New trading and issuance can be paused | Contract circuit breakers only; no manual channel | WP 14.2 |
| Derivatives | Perpetual shorts and buyback rules | Kept as a [Pending] research module, not implemented; conflicts explained | Operator, 25 October 2026 |
| Volume estimates | 20% of fees converted to futures capital | Surplus accumulation after cancelling the treasury share | WP 11.2, 11.3 |
| Fund-flow examples | Short-position gains and losses; new-GB financing | AMO sale, buyback and restricted reserves | This review |
| In-transit amount | Supply conservation formula | Not counted in L; disclosed separately | Operator, 25 October 2026 |
| Service quotes | Fixed resource quotes or conversion at the live rate | Standard price of 1 GB for 1 GB; providers set their own markup or discount, with no limit | Operator, 25 October 2026 |
| Trading pool | Constant-product baseline | Concentrated liquidity, τ = 0.05% | Operator, 25 October 2026 |
| Market making | Inventory source not discussed | Not enabled at first; one-sided orders evaluated later | Operator, 25 October 2026 |
| Front-running | Batch auctions and encrypted orders under study | Not used at first | Operator, 25 October 2026 |

---

## Appendix D: References

These sources establish protocol background and risk mechanisms. They do not mean that any of these organisations endorses or has verified the GB economic design. Links are carried over from v0.1 (accessed 25 October 2026) and were not re-verified in this version. Addresses and activation status change over time and should be re-verified before deployment.

0. [GB Whitepaper v0.3](gb-whitepaper.md): the decided rules this paper relies on.
1. [CoNET Documentation](../README.md): infrastructure and levels of evidence.
2. [CoNET Core L1 assets](assets.md): the asset identity of GB and conet-USDC.
3. [CoNET Decentralized cross-chain Treasury](cross-chain-treasury.md): routes, authorisation, reconciliation and current operating limits.
4. [CoNET SilentPass](../applications/silentpass-vpn.md): application implementation and privacy limits.
5. [CoNET web3 application protocol](../applications/web3-url.md): wallet addressing and development status.
6. [CoNET BT over DePIN DCDN](../applications/bt-dcdn.md): product roadmap, service evidence and development status.
7. [CoW Protocol MEV protection](https://docs.cow.fi/cow-protocol/concepts/benefits/mev-protection): reference for batch settlement and execution design.
8. [dYdX Margining](https://docs.dydx.xyz/concepts/trading/margin): margin and open-interest constraints.
9. [dYdX Funding](https://docs.dydx.xyz/concepts/trading/funding): perpetual funding-rate mechanism.
10. [BIS Crypto carry](https://www.bis.org/publications/working-paper-1087-crypto-carry): capital and liquidation limits on carry trades.
11. [Circle CCTP technical guide](https://developers.circle.com/cctp/references/technical-guide): burn, mint, messaging and finality.
12. [Circle USDC contract addresses](https://developers.circle.com/stablecoins/usdc-contract-addresses): networks where native USDC is issued.
13. [Uniswap v2 Swaps](https://developers.uniswap.org/docs/protocols/v2/concepts/swapping): constant-product swap mechanics.
14. [Uniswap v2 Oracles](https://developers.uniswap.org/docs/protocols/v2/concepts/oracles): time-weighted prices and manipulation cost.

> Version management: later versions should list parameter changes, application status changes and verification reports, and be updated together with the GB Whitepaper.
