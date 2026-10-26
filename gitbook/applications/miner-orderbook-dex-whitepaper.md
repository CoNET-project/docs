# Order-book Exchange Whitepaper: Miner Matching on CoNET-DLE

**Version:** v0.2 (discussion draft) | **Date:** 25 October 2026 | **Basis:** the [CoNET-DLE whitepaper](https://github.com/CoNET-project/CoNET-DLE/blob/main/src/whitepaper/Decentralization%20Cluster%20multi-chain.md) (revision 2026-09-23, "DLE whitepaper"), the [L2 — CoNET-DLE](../l2/README.md) section, the [Miner-matched order-book exchange](miner-orderbook-dex.md) design study ("design study"), and operator decisions of 25 October 2026 | **Status:** discussion draft. Not approved by the DAO. The DLE chain classes, events and contracts it needs are not implemented or deployed.

Order chains, miner splitting and matching, freeze authorization, and a liquidity-pool fast lane.

**How to read the labels**

- **[Decided]**: a rule the operator has decided, with the decision date. An operator decision is not DAO approval.
- **[DLE current]**: a rule frozen in the DLE whitepaper or its specifications, cited as "DLE §x.y".
- **[Needs DLE revision]**: a rule this paper needs DLE to add or change. It takes effect only after the DLE specification maintainers adopt it.
- **[Proposed]**: a design proposed by this paper and not yet decided by the operator.
- **[Pending]**: an open item, listed in Appendix B.
- In this paper, "chain" means one DLE tip (an independent ledger bound to an L1 NFT), not CoNET L1.
- Where this paper and the DLE whitepaper or its three specifications differ, the DLE documents prevail. Every change this paper needs from DLE is listed in Section 2.3.

---

## Summary

This paper proposes a decentralized order-book exchange that runs entirely on CoNET-DLE.

**Funds stay in DLE, held by the user.** A user's assets sit on DLE asset chains in the user's own name, each holding at most 100 USDC equivalent. To place an order, the user signs a freeze of some of those asset chains for that order. At fill, DLE moves value out of the frozen asset chains and into the counterparty's asset chains. Cancelling releases the freeze. The exchange has no vault, and nobody can move funds that the user has not frozen by signature [Decided] (2026-10-25).

**One order chain per order, with a 0.003% prepayment.** The order placer opens one DLE order chain for each order. At placement the placer prepays 0.003% of the full order amount. This prepayment is the chain-opening fee and goes to all validators of that order chain. Cancelling costs nothing more, and the prepayment is not refunded. The minimum order is 1 USDC equivalent [Decided] (2026-10-25). The order chain records the signed terms, the frozen funds and the fill progress, and closes when the order ends.

**Idle miners race to match; consensus miners keep it safe.** Each trading pair has one market chain. Order matching is done by every idle light miner (one that has staked the CNET threshold), competing for profit to be the first with a winning match: each one includes orders, splits them, computes the result and submits a proposal. The consensus committee DLE draws for the batch recomputes the proposals independently and makes the valid proposal with the largest fill volume the block, and the archive group replays and finalizes it. An invalid proposal costs its submitter [Decided] (2026-10-26). At fill, each order placer pays 0.007% of the filled amount as the matching fee, all of it to the winning matching miner; when two book orders fill each other, each side pays 0.007%. The 0.01% transfer fee is shared by the consensus miners [Decided] (2026-10-26). The 0.003% prepayment and the 0.007% at fill add up to 0.01%.

**DLE completes the transfers in parallel.** After a fill is final, miners split it into transfers on many asset chains and submit them in parallel. DLE executes them. Every outgoing transfer pays a 0.01% DLE transfer fee on its amount. However many chains a transfer is split across, the total fee equals 0.01% of the amount transferred [Decided] (2026-10-25). Transfers use two phases: first debit to in-flight, then credit. If either side's debit fails, the other side is refunded automatically.

**Liquidity pools and the fast lane.** Anyone may open a liquidity pool without permission and set its fee rate and price range. A pool is a registration on a DLE storage chain that lists the frozen asset chains of every LP in the pool. When an order turns on the fast lane, miners compare the pools and the book orders together and fill the order at whichever is better for the user. An order placer filled by a pool pays the matching fee, the transfer fee, and the LP fee set at pool opening. LPs also pay the 0.01% DLE transfer fee on what they send out, covered by the pool fee [Decided] (2026-10-25).

**Every fee is in the placer's outgoing token.** The prepayment, the DLE transfer fee, the matching fee and the LP fee are all computed and paid in the token the order placer sends out, not in the token the LP provides. LPs therefore receive the placer's token, which they can trade into any token on DLE's trading pools [Decided] (2026-10-25).

**Ordinary orders use frequent batch auctions.** Orders not on the fast lane fill at one uniform clearing price per batch. The order of arrival within a batch does not affect the price, which narrows the room for front-running [Proposed].

**Why DLE.** The core risk of centralized exchanges is custody: misuse, theft, freezes and opacity. Existing decentralized exchanges removed custody but brought curve pricing and front-running, small fixed validator sets, upgrade-key and bridge risk, and a capacity ceiling: every market shares one chain's block space and block time, or one validator set's block production. A DLE-based design answers with non-custodial freezes; open matching, where idle miners that stake CNET race to match while randomly drawn consensus committees and archive groups recompute and confirm; deterministic, recomputable matching; separate chains for each market, order and asset balance, so total capacity grows with miners and archive groups instead of one chain's block speed; and a 100 USDC loss cap per asset chain. The costs are latency above a centralized exchange's (one market's batches stay serial, and nothing is measured yet), more complex settlement, fragmented balances, a liquidity cold start, and dependence on DLE components that are not yet live (Sections 1.2–1.5, 6.6).

The DLE components this design depends on are not yet in production. The AssetBurnMintGateway that moves assets into and out of DLE is not live. Production archive signing is not enabled: the archive conformance specification forbids it until its production blockers close. The 30-day lab pilot's final assessment was "partial success, not qualified". This design also needs DLE revisions (Section 2.3): new market-chain and order-chain classes, freeze authorization, two-phase transfers between DLE chains, events that cite another chain's AC, liquidity-pool records on storage chains, transfer fees paid in the transferred token, the new fee allocation, and open matching proposals from staked light miners. This paper promises no launch date, fill speed, liquidity depth or return.

> **Audience.** DAO voters, miners, liquidity providers, DLE specification maintainers and auditors. Example parameters are for illustration only. They are not launch parameters.

---

## 1. Scope, landscape and motivation

### 1.1 Problem

The design study explains that an order book avoids several AMM problems: price comes from explicit quotes, a large trade consumes visible depth, and market makers control their own quotes, inventory and cancellation. Order books have their own problems: spreads widen when depth is thin, a matcher network brings ordering, censorship and front-running risks, and an order waits when no counterparty is present.

This paper's goal is a way to trade on CoNET that does not depend on a curve, does not take custody of funds, and is matched by the miner network, with user-provided liquidity pools to shorten the wait. It does not claim that an order book is better than an AMM in every case.

### 1.2 Centralized exchanges today

Centralized exchanges (CEXs) are still where most crypto trading happens. According to The Block, decentralized-exchange (DEX) spot volume in July 2026 equaled about 24% of CEX spot volume, the highest on record, up from about 17% a year earlier. The rise came mainly from falling CEX volume rather than growing DEX volume [1].

CEX strengths are real: deep order books, matching measured in milliseconds, fiat on- and off-ramps, customer support and compliance, and a full range of derivatives. Their problems all come from one fact: users must hand their assets to the exchange.

| Problem | Cases and notes |
| --- | --- |
| Custody and misuse | Mt. Gox lost about 850,000 BTC and went bankrupt in 2014; FTX misused customer assets and went bankrupt in 2022 |
| Theft | In February 2025 a Bybit cold-wallet transfer was manipulated and about $1.4–1.5 billion in Ethereum assets were stolen; the FBI attributed it to North Korean hackers [2]. About $2.7 billion in crypto was stolen across 2025 [3] |
| Insiders and data leaks | In May 2025 Coinbase disclosed that bribed outsourced support staff leaked some customer data, followed by an extortion demand [4] |
| Opacity | Proof of reserves shows at most the assets held at one moment; liabilities, internal matching order, proprietary trading and market making cannot be verified from outside |
| Unilateral control | Listings need the exchange's approval; accounts and withdrawals can be frozen unilaterally; one jurisdiction's regulatory action can stop the whole service |
| Fees | Base spot fees are commonly around 0.1% (Binance's base spot fee, for example, is 0.1%) |

### 1.3 Decentralized exchanges today

DEXs solve custody: assets stay in user wallets or public contracts, and trades can be checked on chain. But each existing type has a cost:

| Type | Examples | Strengths | Problems |
| --- | --- | --- | --- |
| AMM pools | Uniswap, Curve | Permissionless, non-custodial, composable with other contracts | Price set by a curve, with large price impact on big trades; LPs bear impermanent loss; sandwich attacks and other front-running (MEV) from the public mempool; fee tiers commonly 0.01%–1%, plus gas; contract risk (Cetus on Sui lost about $223 million in 2025 [4]) |
| On-chain order book on a shared chain | Serum / OpenBook (Solana) | Transparent order book | Bound by the whole chain's throughput and congestion; Serum's program upgrade key was held by an FTX-linked party, and after FTX's bankruptcy the community had to fork it as OpenBook |
| Appchain order book | dYdX v4, Hyperliquid | Speed close to a CEX | Ordering and matching are done by a fixed, fairly small validator set. In March 2025 Hyperliquid's validators voted within minutes to delist the JELLY perpetual and settle it at a set price, which drew criticism as a centralized decision [5] |
| Batch auctions and intents | CoW Protocol, UniswapX | Uniform clearing prices or solver competition reduce front-running | Depend on solver or filler networks; settlement still runs on a general-purpose chain with its fees and congestion |
| Cross-chain bridges | Various | Assets can move between chains | Bridges are a major attack surface: the Ronin bridge lost about $624 million in 2022 [6] |

In short, DEXs removed custody risk but brought curve pricing and MEV, congestion on a shared chain, small fixed validator sets, upgrade-key risk in upgradeable contracts, and bridge risk.

### 1.4 Why DLE: the problems it addresses

| Problem today | How this exchange handles it on DLE | Basis |
| --- | --- | --- |
| Throughput tied to one chain's block speed | DLE is an event-driven ledger system of many chains running concurrently. Each market, order and asset chain produces a block only when an event arrives and is served by its own committee drawn from the miner pool, so total capacity grows as miners and archive groups join, instead of being set by one chain's block interval (Section 1.4.1) | DLE §3.1–§3.4 |
| The exchange holds user assets | Funds stay on DLE asset chains in the user's own name; placing an order only freezes them; no vault, no admin | Section 4.2, Chapter 13 |
| A fixed sequencer or validator set | Matching is open to every idle miner that stakes CNET, competing to be first; confirmation is done by a consensus committee of 7 drawn at random each batch (5 signatures produce the block) and an archive group replaying it independently at 4/5; committees rotate every batch | DLE §6.5, §5.2.1; Section 6.6 |
| Matching cannot be verified | Matching rules live in the state machine and give deterministic results; full batches have data availability, so anyone can recompute them | Section 6.4; DLE §5.2.1 |
| Front-running and MEV | Ordinary orders use frequent batch auctions, where order within a batch does not affect price; marginal allocation uses an unpredictable random seed; orders travel encrypted over L0 to several miners, not through a public mempool | Sections 6.2, 6.4 |
| Congestion on a shared chain | One market chain per pair, one order chain per order, asset chains in parallel; no event, no block; a busy market does not slow others | DLE §3.1, §3.2 |
| One breach loses everything | Direct loss per asset chain is at most 100 USDC equivalent; committee cumulative exposure is bounded by E_C ≤ E_max | DLE §12.2, §12.3.2 |
| Matchers forging fills | The paying asset chain checks the order signature and freeze record itself, so a forged fill cannot take funds | Section 7.1 |
| An upgrade key held by one party | No admin; the L1 market registry is proposed to be non-upgradeable | Chapter 13 |
| High fees | A fully filled order pays about 0.02% in total (excluding any LP fee), computed on amounts and not increased by splitting | Section 9.2 |
| No lasting incentive for matchers | Matching miners race for the matching fee, consensus miners share the transfer fee, order-chain validators earn by order amount, LPs by pool share | Section 6.6, Chapters 9, 10 |
| Waiting when no counterparty is present | Permissionless liquidity pools and a fast lane, compared with book orders | Chapter 10 |
| Cross-chain asset risk | Only Treasury canonical assets are listed; an asset that depends on a cross-chain proof is listed only after that proof is shown to reject forged source-chain messages | Section 4.6 |
| Traders' network identity exposed | Wallet-address routing and encrypted forwarding reduce IP exposure (this is not anonymity) | DLE §4.5, §7 |

#### 1.4.1 Throughput: where DLE differs from today's order-book DEXs

This is the main architectural difference between this exchange and existing decentralized order books.

**Existing order-book DEXs are bounded by one chain.** An order book on a shared chain (such as Serum / OpenBook on Solana) shares that chain's block space and block time with every other application. An appchain order book (such as dYdX v4 or Hyperliquid) runs every market through one validator set that produces one sequence of blocks. In both cases total capacity is set by how fast one chain produces blocks and how much one block can carry. Adding validators does not add capacity; it usually adds coordination cost.

**DLE has no global block interval.** DLE is an event-driven, multi-chain concurrent ledger system [DLE current] (DLE §3.1–§3.2):

- Each ledger is its own chain. In this exchange, each trading pair has its own market chain, each order has its own order chain, and balances sit on many independent asset chains.
- A chain produces a block only when an event arrives ("no event, no block"). Nothing waits for a network-wide slot.
- Each block is produced by a committee of 7 drawn from the on-demand miner waiting queue and finalized by the archive group that hosts that chain. Different chains use different committees at the same time.
- Throughput is the sum of all active event streams across chains, not the speed of one chain.

**What this means for an order book.**

- **More markets in parallel**: every trading pair advances independently. A busy pair does not slow other pairs, and adding markets does not compete for one shared block space.
- **Many orders per block**: a matching batch is one event that can carry many orders, cancels and fills, so one market-chain block clears a whole batch auction at once.
- **Settlement in parallel**: each fill settles as transfers on different asset chains with different committees, so settlement capacity grows with the number of committees available.
- **Capacity grows with participation**: as more miners join the waiting queue and archive groups split (fission), more committees and more hosting capacity exist at the same time, so more markets, orders and settlements can run concurrently.

**Boundaries.** These are architectural properties, not measured results, and they do not mean each transaction gets faster as miners join [DLE current] (DLE §3.4):

- The batches of one trading pair still advance one after another on its market chain. The speed of a single market is bounded by the committee vote (window up to 30 seconds) and archive finality, and by the batch cap `B_max`.
- Capacity also depends on the number of archive groups and on the committee exposure bound E_C ≤ E_max.
- Fill latency and throughput have not been measured. The 30-day lab assessment was partial success, not qualified, and production signing is not enabled.

### 1.5 Advantages and disadvantages

**Advantages**

1. **Capacity that grows with miners**: an event-driven, multi-chain concurrent ledger, where markets, orders and settlements run on separate chains with separate committees; total capacity grows with miners and archive groups instead of being set by one chain's block speed (Section 1.4.1).
2. **Non-custodial**: assets always stay on the user's own DLE asset chains; only what the user freezes by signature can leave, and only per the order.
3. **Open matching, randomly drawn confirmation**: any idle miner that stakes CNET can race to match; a randomly drawn consensus committee and an archive group confirm the result, with no reliance on one company or a few fixed validators.
4. **Verifiable results**: matching and the reference price are deterministic computations on public data that anyone can recompute.
5. **Less front-running**: batch auctions clear at one uniform price, so order within a batch does not matter.
6. **Parallelism and failure isolation**: pairs, orders and assets are separate chains; congestion or a fault in one market does not affect others.
7. **Bounded loss**: if one asset chain is compromised, the direct loss is at most 100 USDC equivalent.
8. **Low, transparent fees**: about 0.02% for a full fill (excluding any LP fee), computed on amounts, regardless of how many chains carry it.
9. **Incentives tied to work**: miners, validators and LPs earn by fill volume, order amount and pool share respectively.
10. **Open liquidity**: anyone can open or join a pool without permission.
11. **No privileged address in governance**: listings and parameters are DAO votes; pools need no permission.

**Disadvantages**

| Disadvantage | Notes |
| --- | --- |
| Not usable today | It depends on AssetBurnMintGateway, which is not live; production archive signing is forbidden; the 30-day pilot did not qualify; DLE revisions R1–R9 are still needed (Chapter 2) |
| Slower than a CEX | Each batch needs a committee vote (window up to 30 seconds) and archive finality, and settlement needs several two-phase events; it cannot reach CEX millisecond speed; the fast lane fixes the price at once but does not speed up settlement; latency is not measured |
| Complex settlement, unknown execution cost | Each fill needs at least 4 asset-chain events, and each order needs an order chain and an L1 NFT; execution cost is not measured, and the 0.003% prepayment may not cover costs for small orders (B-18) |
| Fragmentation from the 100 USDC cap | Users with more funds hold many asset chains; receipts above the cap open new chains with a birth cost; wallets must merge and manage them |
| Liquidity cold start | An order book needs market makers; this design pays no maker rebates; LPs can lose money in one-way markets |
| Weak composability | DLE has no general-purpose VM, so other contracts cannot call the exchange the way they call an AMM; cross-chain settlement is eventually consistent in two phases, not atomic within one transaction |
| Security rests on DLE assumptions | It depends on committee sampling and an honest majority in 5-member archive groups; an attacker who controls several archive groups can cause losses on several asset chains; handling a forced exit of a frozen asset chain is still open (B-10) |
| Ordering and short-term censorship | A matching miner decides which orders its proposal includes and the order of fast-lane orders; leaving orders out loses to a more complete competitor, but the consensus committee's receive order (used only for ties) and short-term ordering advantage remain |
| The reference price can be pushed | In thin markets the reference price can be moved; protective parameters are not set |
| No fiat ramps or compliance services | No KYC, fiat on- or off-ramp, or customer support; the regulatory position is uncertain |
| Fees in many tokens | Miners, archive groups and LPs receive many tokens and must account for and convert them |
| The cost of transparency | The book and settlements are fully public, so trading strategies are visible; wash trading is cheap and volume figures need a caveat |
| Limited cross-chain assets | Until the cross-chain proof gate closes, assets whose supply depends on cross-chain proofs (such as conet-USDC) cannot be listed |

**Comparison**

| Dimension | CEX | AMM DEX | Appchain order-book DEX | This design (DLE) |
| --- | --- | --- | --- | --- |
| Custody | The exchange | User wallets and pool contracts | Exchange accounts on the appchain | The user's own DLE asset chains |
| Matching and ordering | Inside the exchange | No matching (curve); ordering by the block producer | A fixed validator set | Idle staked miners race to propose; a random consensus committee and the archive group recompute and confirm |
| Verifiability | Not verifiable from outside | On chain | On chain | Deterministic state machine plus data availability; recomputable |
| Front-running | Invisible internally | Sandwich attacks common | Depends on the sequencer | Uniform-price batch auction; fast-lane orders still have ordering room |
| Latency | Milliseconds | One block | Close to a CEX, depending on the implementation | A batch plus settlement; not measured |
| Trading fee | Around 0.1% | 0.01%–1% tiers, plus gas | Varies by platform | About 0.02% (excluding any LP fee) |
| Capacity scaling | The exchange's matching hardware | One shared chain's block space and block time | One validator set's block production | Grows with miners and archive groups across independent chains; one market is still serial |
| Failure isolation | One platform | One chain | One appchain | Separate per market, order and asset chain |
| Status | Live | Live | Live | Not implemented |

**References for this section**

1. The Block, 3 August 2026, "DEXs capture record 24% of spot crypto trading as CEX volumes sink": [theblock.co/post/410476](https://www.theblock.co/post/410476)
2. TechCrunch, 21 February 2025, "Crypto exchange Bybit says it was hacked and lost around $1.4 billion": [techcrunch.com](https://techcrunch.com/2025/02/21/crypto-exchange-bybit-says-it-was-hacked-and-lost-around-1-4-billion)
3. TechCrunch, 23 December 2025, "Hackers stole over $2.7 billion in crypto in 2025, data shows": [techcrunch.com](https://techcrunch.com/2025/12/23/hackers-stole-over-2-7-billion-in-crypto-in-2025-data-shows/)
4. Decrypt, "From Bybit to Coinbase: 2025's Biggest Crypto Hacks and Breaches": [decrypt.co](https://decrypt.co/351001/bybit-coinbase-2025-biggest-crypto-hacks-breaches)
5. Cointelegraph, "Bitget CEO slams Hyperliquid JELLY perps delisting": [cointelegraph.com](https://cointelegraph.com/news/bitget-ceo-slams-hyperliquid-jelly-perps-delisting)
6. Decrypt, "Biggest Crypto Hacks of All Time": [decrypt.co](https://decrypt.co/308292/biggest-crypto-hacks-of-all-time)

### 1.6 Related documents

| Document | Relationship |
| --- | --- |
| DLE whitepaper | This paper builds on its asset chains, storage chains, committees, archive finality, data availability, 100 USDC cap and committee cumulative-exposure rule. Needed revisions are listed in Section 2.3. |
| DLE trade-class chains (DLE §4.7, §10.2) | A trade chain coordinates the whole-ledger sale of one NFT-style subject. The order chain here keeps "one listing, one chain, opened by the lister" and extends it to fungible tokens. |
| [Design study](miner-orderbook-dex.md) | This paper expands it. Its release gates are mapped in Chapter 15. |
| [GB whitepaper](../l1/gb-whitepaper.md), [GB AMM whitepaper](../l1/gb-amm-whitepaper.md) | GB may be listed. The exchange does not change GB issuance, exit, official rate or AMO rules (Chapter 14). |

### 1.7 Not promised

Fill latency or throughput (neither is measured); depth or spread on any pair; miner or LP income (LPs can lose money); anonymity; launch before the DLE release gates close.

---

## 2. CoNET infrastructure used

### 2.1 Roles of each component

| Component | Role in the exchange |
| --- | --- |
| **CoNET L1** (chainId 224422) | Moving assets into and out of DLE (Treasury burn and remint through AssetBurnMintGateway); birth NFT and ownership of every DLE chain; archive membership checkpoints; market registry; anti-censorship inbox |
| **DLE asset chains** | User and LP balances, each ≤ 100 USDC equivalent [DLE current] (DLE §4.6). Freeze authorization and fill transfers run here |
| **DLE order chains** (one per order) | Signed terms, frozen-fund references, fill progress and lifecycle of one order [Decided: one chain per order] [Needs DLE revision] |
| **DLE market chain** (one per pair) | Order book, batch inputs, reference-price curve, clearing results, fill records [Needs DLE revision] |
| **DLE storage chain** | Liquidity-pool registration: pool parameters, frozen asset chains of each LP, shares [Decided] |
| **DLE trading pools** | Where LPs can trade received tokens into any token [Decided]. The markets and pools of this exchange are such pools |
| **DLE validator committee** (per event, N_V=7, Q_V=5) | On the market chain, the consensus committee: recomputes matching proposals, picks the winner and produces the block, without matching itself; on order and asset chains, it runs those chains' events [DLE current] (DLE §6.5) |
| **DLE archive group** (5 active + 2 standby, Q_A=4) | Replays every event, checks data availability, forms the Archive Certificate (AC) [DLE current] (DLE §5.2.1) |
| **Data availability `dle.rs.v1`** | Anyone can fetch the full batch and recompute it |
| **L1 Global Archive Routing Registry** (deployed) | Finds which archive group hosts each chain and whom to ask for its history and ACs |
| **L0 / Layer Minus** | Encrypted transport of orders, cancels and price broadcasts among miners |

### 2.2 Current status

| Component | Status |
| --- | --- |
| CoNET L1, Treasury V3, L1 Global Archive Routing Registry | Live / deployed |
| DLE lab network (0x44c45) and explorer | Lab environment, not production |
| AssetBurnMintGateway (moving assets into and out of DLE) | Not live; production asset ingress closed |
| DLE production archive signing | Forbidden by the specification; production blockers open |
| DLE 30-day pilot | Final assessment "partial success, not qualified" |
| Full runtime for asset and storage chains | Not running as production |
| Order chains, market chains, freeze authorization, two-phase transfer, pool registration | Proposed here; not implemented |

The path for assets into DLE is itself not open. Until the DLE production gates close, the exchange can only run on the lab network with test assets (Chapter 15).

### 2.3 DLE revisions needed [Needs DLE revision]

| ID | Revision | Reason |
| --- | --- | --- |
| R1 | New **market chain** class whose state machine includes deterministic matching and reference-price calculation | The three current classes do not support a fungible order book (DLE §4.2, §10) |
| R2 | New **order chain** class (or a versioned fungible-order state machine under the trade class) | The operator decided one chain per order; the current trade-class FSM serves one NFT subject and is frozen (DLE §10.2) |
| R3 | Asset chains gain a **freeze authorization** event: the owner signs to freeze balance for an order chain or a liquidity pool | Removes balance races at fill (Section 4.2) |
| R4 | Asset chains gain **two-phase cross-chain transfer**: debit to in-flight, credit against the counterparty's debit receipt, refund on timeout | DLE has no cross-chain calls (DLE §4.3), and one fill touches several chains |
| R5 | An event on one chain may cite **another chain's AC as a precondition** | The market chain cites order chains and pool registrations; asset chains cite market batches. Current rules only cite L1 views |
| R6 | Storage chains gain a **liquidity-pool registration** record type | The operator decided to register pools on storage infrastructure |
| R7 | **Transfer-fee asset**: from "oracle-valued, paid in conet-USDC" to "0.01% of the amount, paid in the transferred token" | The operator decided all fees are computed in the placer's outgoing token (Chapter 9). This differs from the current text of DLE §13.2 and must be revised there |
| R8 | **Matching and transfer fee allocation**: the 0.007% matching fee goes to the winning matching miner, not split 50/50; the transfer fee is shared by consensus miners | Section 9.4; DLE §13.4 |
| R9 | **Open matching proposals**: the market chain accepts matching proposals from staked light miners outside the committee, selects by fill volume, and defines penalties for invalid proposals | The operator decided that idle miners race to match (Section 6.6) |

---

## 3. System overview

### 3.1 Roles

| Role | Who | Does what | Pays / earns |
| --- | --- | --- | --- |
| Order placer | Any user holding DLE asset chains | Opens an order chain, signs the order and freezes funds; cancels to release | Prepays 0.003%; at fill pays 0.007% matching fee and 0.01% transfer fee; pays the LP fee when filled by a pool |
| Order-chain validators | Validators drawn by DLE for each event of an order chain | Produce the order chain's genesis, fill updates and closing blocks | Receive the 0.003% prepayment [Decided] |
| Pool creator | Anyone, no permission [Decided] | Opens a pool on a storage chain and sets pair, fee rate and price range | Shares as an LP when providing liquidity; no extra cut [Decided] |
| Liquidity provider (LP) | Anyone | Searches pools and freezes own asset chains into one | Receives the LP fee by share [Decided]; pays DLE transfer fee on own outgoing transfers |
| Matching miner (light miner) | A miner that has staked the CNET threshold and is currently idle [Decided] | Receives orders and cancels over L0; includes, splits, matches and computes the reference price; races to submit matching proposals | The winner earns the 0.007% matching fee [Decided] |
| Consensus committee | 7 miners plus 2 standbys drawn by DLE per market batch | Recomputes matching proposals, picks the valid one with the largest fill volume, signs the block; does not match | Shares the DLE transfer fee (Section 9.4) |
| Transfer committees | Drawn by DLE for each asset-chain and order-chain event | Run debit, credit, refund and order-status events | DLE transfer fee, allocated by DLE rules [DLE current] |
| Archive groups | The 5+2 group hosting each chain | Replay, data availability, AC | Archive share of the DLE transfer fee; availability budget |

### 3.2 Data flow

```text
1. Assets enter DLE (L1 burn → asset chain activated, each ≤ 100 USDC)   [needs AssetBurnMintGateway]
2. The placer opens an order chain (L1 birth NFT + DLE genesis) and prepays 0.003% of the order amount
   Genesis binds the signed order and the freeze authorizations (the placer's own asset chains)
   LPs sign pool entry + freeze authorization, registered on the pool's storage chain
        │ L0 encrypted transport
        ▼
3. One batch on the market chain
     Idle matching miners each include orders, compute the result and race to submit a proposal
     The consensus committee (5/7) recomputes every proposal and makes the valid one with the largest
     fill volume the block; the archive group finalizes it with a 4/5 AC
     A proposal contains: newly admitted order chains
     Fast-lane orders first: compare pools and book orders together, fill at once
     Ordinary orders next: frequent batch auction at one clearing price
     Output: fillsRoot, updated book, reference-price curve
        │
        ▼
4. Miners split each fill into transfers on many asset chains and submit them in parallel
     Phase 1: each paying asset chain debits to in-flight (fill amount + matching fee + transfer fee + LP fee)
     Phase 2: with every debit receipt in hand, credit the receiving asset chains; on a debit timeout, refund
        │
        ▼
5. Each order chain updates its fill progress from the market batch and settlement receipts,
   and closes when fully filled, cancelled or expired
6. A user leaving DLE exits normally through AssetBurnMintGateway (L1 remint)
```

### 3.3 Three confirmation levels

| Status | Meaning |
| --- | --- |
| **Received** | A matching miner verified the signature and acknowledged; no promise of inclusion or fill |
| **Matched** | The market batch has an AC; price and quantity are fixed and both sides' funds are frozen |
| **Settled** | Every debit and credit event has an AC; assets are on the recipient's asset chains |

An interface must never show a lower level as a higher one.

---

## 4. Funds: all in DLE, freeze authorization [Decided] (2026-10-25)

Operator decisions: the exchange does not take custody of funds; the user authorizes DLE, which moves funds out and in at fill. LPs must use funds already in DLE; staking moves those funds into a pool opened in DLE, and trades with the pool settle in DLE.

### 4.1 How funds enter DLE [DLE current]

An external-chain asset first becomes a CoNET L1 canonical token through a Treasury route. AssetBurnMintGateway then burns it on L1 and a DLE asset chain activates the same balance (DLE §4.6). At activation and at every later revaluation, an asset chain holds at most 100 USDC equivalent; any excess must move to new asset chains. A user with more funds therefore holds several asset chains. Leaving DLE uses normal or forced exit, which remints the canonical token on L1.

### 4.2 Freeze authorization

When opening an order chain, the placer also signs a freeze on each of their asset chains used for the order [Proposed, needs DLE revision R3]:

```text
FreezeForOrder {
    assetTipId,        // the frozen asset chain
    owner,
    amount,            // amount frozen for this order
    orderChainId,      // NFT id of the order chain
    freezeNonce
}
```

- Once frozen, that balance can only leave by a fill of that order, or be released when the order closes.
- Ownership does not change. The asset chain's owner is still the user (L1 `ownerOf`). The exchange, the miners, the order chain and the market chain do not hold these funds.
- The frozen amount must cover the order's maximum payment and every fee cap (Section 9.2).

Every matched fill is backed by frozen funds, so a user cannot move funds away after matching and make the fill fail.

### 4.3 Splitting under the 100 USDC cap

One order often needs several frozen asset chains. A 1,000 conet-USDC buy order needs at least 10. Transfers after a fill are split by a deterministic rule:

- Payment is debited from each asset chain in freeze-record order, one debit event per asset chain.
- When one asset chain takes part in several fills in the same batch, they merge into one event.
- Splitting only spreads a fill across asset chains. It does not change price, quantity or fees. The matching fee, the DLE transfer fee and the LP fee are computed on the total filled or transferred amount, however many chains are involved [Decided] (2026-10-25).

Operator rule: the DLE transfer fee is 0.01% of the amount, whatever the number of chains. For 1,000 USDC it is (100 × 0.01%) × 10 = 1,000 × 0.01%, not 1,000 × (10 × 0.01%).

### 4.4 Receiving asset chains

Received value must land on some asset chain, which still may not exceed 100 USDC equivalent after the credit. An order names how it receives [Proposed]:

1. Credit the receiving asset chains named in the order, up to their cap.
2. Open new asset chains for any remainder under the DLE spillover rule (DLE §4.6). Each new chain needs a new L1 NFT, which has a birth cost.

Wallets should merge balances from time to time, within each chain's cap. Who pays the birth cost of new receiving chains is pending (Appendix B, B-9).

### 4.5 Cancel, release and exit

- **Cancel**: the placer signs a cancel. Once a market batch includes it, the order chain moves to Cancelled under that batch's AC, and the asset chains release the freeze against the order chain's closing record.
- **Fill before cancel in the same batch**: when one batch holds both a fill and a cancel for the same order, the fill runs first [Decided] (2026-10-25; see Section 10.8; the same rule applies to ordinary orders).
- **Amend**: instead of cancelling, the placer may change price or quantity on the same order chain. The order rejoins the queue and pays 0.003% again on the new order total (Section 5.1a).
- **Release when the market stalls**: if the market chain produces no batch for `T_unfreeze`, the placer may close their own order chain and release the freeze without the market chain.
- **Forced exit**: DLE forbids any rule that blocks or reduces a forced exit (DLE §4.6). Once an asset chain requests a forced exit, the market stops using its frozen funds. How to handle a part that is matched but not yet debited is a question for the DLE gateway specification (Appendix B, B-10).

### 4.6 Listable assets

- Must be admitted to DLE: a Treasury V3 canonical token, `ACTIVE` in `AssetAdmissionRegistry`, with an approved L1 pool, TWAP oracle and minimum liquidity [DLE current] (DLE §4.6, §13.3).
- If its CoNET supply depends on cross-chain proofs (for example conet-USDC minted from Base USDC deposits), it may not be listed until that proof is shown to reject forged source-chain messages (the general gate in Chapter 17 of the [GB whitepaper](../l1/gb-whitepaper.md)).
- The DAO votes to approve each pair (Chapter 13).
- Free GB cannot be transferred or traded and cannot be listed (GB whitepaper 1.3, 8.2). Paid GB follows the new GB contract once deployed. The new GB and new conet-USDC contracts are not deployed.

---

## 5. Orders and order chains

### 5.1 One order chain per order [Decided] (2026-10-25)

The operator decided that the order placer pays the fee for opening a DLE chain, and that each order opens its own DLE chain.

An order chain:

- is opened by the placer and bound to a unique L1 NFT owned by the placer;
- binds the signed order and the ACs of the freeze authorizations at genesis;
- records remaining quantity, cumulative fills, settlement receipts and status;
- closes when fully filled, cancelled or expired, and produces no blocks after that (the same idea as a DLE trade chain closing after sale, DLE §4.7).

**Chain-opening fee: a 0.003% prepayment [Decided] (2026-10-25).** Operator decision: at placement, the placer prepays a 0.003% fee; cancelling costs nothing; at fill the placer pays 0.007% of the filled amount. The operator confirmed that the 0.003% prepayment is the chain-opening fee, received by all validators of that chain, and that the 0.007% matching fee goes to the matching miners.

| Rule | Content |
| --- | --- |
| Amount | Order total × 0.003%, rounded up. Order total: for a sell order, the order quantity; for a buy order, quantity × limit price (the maximum payment) |
| Token | The placer's outgoing token, as for every other fee |
| When | At order-chain opening, taken from the frozen funds |
| Use and recipient | Pays the order chain's costs; goes to all validators of that order chain |
| Cancel | No extra fee; the prepayment is not refunded [Decided] |
| Partial fill | The prepayment stays on the order total; filled parts also pay the 0.007% matching fee |
| Minimum order | The order total, at the token's market price, is at least 1 USDC [Decided] (2026-10-25) |

**How the prepayment reaches order-chain validators [Proposed].** The prepayment is recorded on the order chain. For each block the chain produces, one portion goes to the validators who voted to accept that block. When the chain closes, the remainder goes to the accepting validators of the closing block. Portion sizes are set in advance from the expected number of blocks (genesis, a number of fill updates, close), with rounding dust going to the closing block.

**Converting the minimum order [Proposed].** On a market quoted in conet-USDC, a buy order is checked on its quote amount and a sell order is converted at the reference price (Section 10.4). Other markets convert to USDC equivalent with the TWAP oracle used for DLE asset admission (DLE §13.3).

**Cost-coverage gap [Pending].** A 1 USDC order prepays only 0.00003 USDC equivalent. An order chain's real costs include the gas for minting its L1 birth NFT, the committee and AC for its genesis and later events, and the archive group's long-term storage of its history. With the whole prepayment going to validators, what pays the L1 mint gas and archive storage, and whether small orders cover validator costs, must be assessed after DLE measures costs (Appendix B, B-18).

**Effects.**

- The prepayment gives every order a cost. Cancelling is free, but repeated place-and-cancel loses the prepayment each time, so spam orders are costly.
- Price and quantity changes can be made on the same order chain without cancelling and opening a new one, but each amendment prepays 0.003% again on the full new order total (Section 5.1a).

### 5.1a Amending on the same chain [Decided] (2026-10-25)

The operator decided to allow amendment on the same order chain: the placer re-signs to change price or quantity, and the order rejoins the queue. Each amendment prepays 0.003% again on the full new order total.

| Rule | Content |
| --- | --- |
| How | The placer signs a new order for the same order chain: same `orderChainId`, higher `nonce`. The order chain emits `OrderAmended` |
| May change | Limit price, remaining quantity, validity, fast-lane settings, receiving chains [Proposed] |
| May not change | Market, side, base and quote assets, owner [Proposed]. Changing these needs a cancel and a new order chain |
| Filled part | Unaffected. The new order's quantity is the remaining quantity after the amendment |
| Prepayment | 0.003% of the new order total (new remaining quantity for a sell; new remaining quantity × new limit for a buy), paid in full again, not refunded, to order-chain validators [Decided] |
| Minimum order | The new order total must still be at least 1 USDC equivalent |
| Queue | Treated as newly admitted in the batch where the amendment takes effect; loses earlier time priority [Decided] |
| Frozen funds | If the new order needs more (including fee caps), freeze more first; if less, release the excess after the amendment takes effect |
| Fill and amendment in the same batch | Fill first, then amend [Proposed] (consistent with "the taker goes first"); the amendment applies only to the remainder |
| Takes effect | Once a market batch includes it. Until then the old terms still apply and may fill |

### 5.2 Order structure [Proposed]

```text
Order {
    version,
    marketId,          // market chain NFT id
    orderChainId,      // this order's order chain NFT id
    owner,
    side,              // BUY / SELL
    baseAsset,
    quoteAsset,
    quantityLots,
    limitPriceTicks,   // worst acceptable fill price (excluding fees)
    minFillLots,
    maxLotsPerBatch,   // per-batch cap (order splitting); 0 = market default
    timeInForce,       // GTC / GTD / IOC
    fastLane,          // fast lane on or off
    maxPoolFeeBps,     // highest acceptable LP fee rate on the fast lane
    validUntilBatch,   // last market-chain batch (nonce) in which a fast order is valid
    expiry,            // absolute unix seconds, judged on the cited L1 block time
    receiveTipIds,     // receiving asset chains (Section 4.4)
    feePolicyHash,
    nonce
}

domain = {
    name: "CoNET-DLE-Market",
    version: "1",
    chainId: 224422,
    verifyingContract: MarketRegistry   // market registry contract on L1
}
orderHash = EIP712Digest(domain, Order)
```

- A matcher cannot swap assets, raise quantity, loosen the price, extend validity, change receiving chains or replay a used nonce.
- There is no market order without a price limit. Immediate execution uses a fast-lane order or an IOC order with a worst price.
- Time is judged only from order fields and cited L1 block times, never from a miner's local clock [DLE current] (DLE §10.1).

### 5.3 Order-chain state machine [Proposed, needs DLE revision R2]

**States:** `None=0`, `Open=1`, `PartiallyFilled=2`, `Filled=3`, `Cancelled=4`, `Expired=5`, `Closed=6`.

| Current | Event | Preconditions | Next |
| --- | --- | --- | --- |
| `None` | `OrderOpened` | Valid order signature; freeze-authorization ACs sufficient and pointing to this chain; order total at least 1 USDC equivalent; 0.003% prepayment taken | `Open` |
| `Open` / `PartiallyFilled` | `FillApplied` | Cites this order's fills in a market batch AC | `PartiallyFilled` or `Filled` |
| `Open` / `PartiallyFilled` | `OrderAmended` | Valid new signature with the same `orderChainId` and a higher `nonce`; market, side, assets and owner unchanged; new order total at least 1 USDC equivalent; 0.003% of the new order total taken; frozen funds sufficient; cites the market batch AC that included the amendment | unchanged |
| `Open` / `PartiallyFilled` | `Cancelled` | Cites the market batch AC that included the cancel; or the market stalled for `T_unfreeze` | `Cancelled` |
| `Open` / `PartiallyFilled` | `Expired` | Cited L1 time past `expiry`, or market nonce past `validUntilBatch` | `Expired` |
| `Filled` / `Cancelled` / `Expired` | `Closed` | Settlement receipts for every matched fill are in (or the fill was voided and refunded) | `Closed` |
| `Closed` | * | — | reject |

The market chain is authoritative for remaining quantity. The order chain follows it, for public lookup, asset-chain checks and release.

### 5.4 Order types

| Type | Behavior |
| --- | --- |
| GTC / GTD limit order | The unfilled part rests on the book and joins every batch auction |
| IOC order | Joins only the auction of the batch that includes it |
| Fast-lane order (`fastLane = true`) | At the start of a batch, compared against pools and book orders and filled at once; does not join the auction; validity bounded by both batch count and L1 time [Decided] (Section 10.7) |

### 5.5 Integer prices and quantities

Each market fixes `lotSize`, `tickSize` and price limits. Fill amount = lots × priceTicks × tickSize, all integer arithmetic. Example: GB (9 decimals) against conet-USDC (6 decimals), `lotSize = 10^9` (1 GB), `tickSize = 1` (0.000001 conet-USDC); a price of 0.0102 is `priceTicks = 10200`. Every fee is rounded up in the token's smallest unit (Section 9.2).

---

## 6. Splitting and matching

### 6.1 Batches

DLE's rule is "no event, no block" [DLE current] (DLE §3.2). One block on the market chain is one matching batch. Processing order within a batch:

1. Admit newly opened order chains (citing their genesis ACs) and process the inbox. Record this batch's cancels and amendments; they apply only to orders that existed before this batch and run after this batch's fills (Sections 4.5 and 5.1a).
2. Compute the batch reference price (Section 10.4).
3. **Fast lane**: process fast-lane orders one by one, comparing pools and book orders together (Section 10.5).
4. **Batch auction**: run the uniform-price auction on the remaining ordinary orders (Section 6.4).
5. Output `fillsRoot`, `bookRoot`, the reference-price curve and the state root.

### 6.2 Inclusion and censorship resistance

Matching is deterministic. The only thing a matching miner controls is which orders to include, and selecting proposals by fill volume makes a proposal that leaves orders out lose (Section 6.6).

- **L1 inbox fallback**: a placer may submit an order chain's genesis reference or a cancel to an L1 inbox. The market chain must consume the inbox in order. An entry not consumed within `T_inbox` can go to DLE's archive censorship challenge (DLE §6.4 `ArchiveCensorshipChallenge`) [Proposed].
- **Many competing miners, rotating committees**: orders go over L0 to every idle matching miner, and each batch draws a new consensus committee. A matching miner that leaves out an order only lets a more complete competitor win.
- **Aligned incentives**: miners earn by fill amount, so leaving out a fillable order means losing its matching fee.

The matching miner decides the order of fast-lane orders in its proposal, which leaves room to reorder. Mitigations: a per-batch cap on fast-lane orders by count and amount, and ordering by order hash plus a batch random seed (Appendix B, B-4).

### 6.3 Order splitting

"Splitting" has four meanings here:

1. **Across batches**: each batch's total fill is at most `B_max`, and `maxLotsPerBatch` caps each order per batch; the rest carries over.
2. **Across counterparties**: a fast-lane order can take several pools and several book orders at once (Section 10.5).
3. **Across LPs in a pool**: a pool fill is spread over many frozen asset chains by LP share (Section 10.6).
4. **Across asset chains**: each fill's payments and receipts split into parallel transfers on many asset chains (Section 4.3, Chapter 7).

Splitting does not change the order signature or add fees. Cumulative fills of each order are recorded on the market chain and the order chain and never exceed `quantityLots`. All splitting rules are deterministic, so a matching miner cannot choose who gets the volume. `B_max` is also the market-chain counterpart of DLE's committee cumulative-exposure rule E_C ≤ E_max (DLE §12.3.2); how it counts is pending (Appendix B, B-8).

### 6.4 Ordinary orders: frequent batch auction [Proposed]

1. Candidate prices are the limit prices of all participating orders.
2. For each candidate price p: demand D(p) is the remaining quantity of buy orders with limit ≥ p; supply S(p) is the remaining quantity of sell orders with limit ≤ p; fillable volume V(p)=min(D,S), subject to `B_max` and `maxLotsPerBatch`.
3. The clearing price maximizes V(p). Ties go, in turn, to the smallest |D-S|, the price nearest the reference price, then the lower price.
4. If the clearing price is more than `priceBandBps` from the reference price, this batch fills only inside the band.
5. Orders better than the clearing price fill completely. At the marginal price, allocation goes to orders admitted in earlier batches first, then pro rata by remaining quantity within a batch, with leftover lots allocated by ascending `keccak(orderHash ‖ batchSeed)`, where `batchSeed` comes from L1 beacon randomness.
6. Every fill executes at the clearing price.

The order of arrival within a batch does not change the clearing price, so a matching miner cannot front-run by reordering. Switching to continuous matching within a batch is pending (Appendix B, B-3).

### 6.5 Self-trade prevention

When buy and sell orders of the same `owner` would both fill in one batch, the later-admitted one sits out that batch. The same applies between an owner's pool liquidity and their own fast-lane order (Section 10.6).

---

### 6.6 Racing to match: idle light miners compete, consensus miners keep it safe [Decided] (2026-10-26)

Operator decision: order matching is done by all idle miners, who race to match first for profit and so bring trades about, while consensus miners maintain security. The operator also decided that the matching miner receives the 0.007% and the consensus miners share the 0.01% transfer fee; that the proposal with the largest fill volume wins, with ties going to the first to arrive; and that becoming a light miner requires staking CNET, with a cost for invalid proposals.

| Role | Who | Does what | Earns |
| --- | --- | --- | --- |
| Matching miner (light miner) | A miner that has staked the CNET threshold and is not serving on this market's consensus committee for the batch | Collects orders, splits them, computes the result with the deterministic rules of Sections 6.4, 10.5 and 10.6, signs and submits a matching proposal | The whole 0.007% matching fee of the winning proposal [Decided] |
| Consensus miners | The market-chain consensus committee DLE draws for the batch (5 of 7) and the hosting archive group (4 of 5) | Recompute every proposal independently, pick the winner, produce and finalize the block; do not match | Share the 0.01% DLE transfer fee [Decided]; order-chain validators also receive the 0.003% prepayment |

**Matching proposal [Proposed]**

```text
MatchProposal {
    marketId, batchNonce, parentStateRoot, l1BlockNumber,
    includedOrderRefs[], cancels[], amendments[], poolRefs[],
    referencePriceTicks, clearingPriceTicks,
    fillsRoot, bookRoot,
    totalFillQuote,        // this proposal's fill volume, in the quote asset
    matcher, matcherStakeRef, signature
}
```

**Flow**

1. Orders, cancels and amendments are broadcast over L0 to every idle matching miner.
2. Each matching miner starts from the same parent state, chooses which orders to include, computes the result with the deterministic rules, and signs and submits its proposal.
3. The batch's consensus committee collects proposals until the cut-off and recomputes each one independently. A proposal whose result differs from its claims, cites an invalid order, or fails a precondition is invalid.
4. Among valid proposals, the one with the largest fill volume (`totalFillQuote`) wins [Decided]. Ties go to the one the consensus committee received first [Decided], then to the lower proposal hash.
5. The winning proposal becomes the batch's `Batch` event: 5 of 7 sign it under the normal DLE flow, and the archive group replays it and forms the AC.
6. When settlement completes, the 0.007% matching fee is credited to the winning matching miner; a voided fill pays nothing.

**Cost of an invalid proposal [Decided principle, proposed method].** Each proposal carries a stake reference. A proposal ruled invalid for a reason any third party can recheck (a recomputation mismatch, a missing or expired order, a bad signature) loses a DAO-set share of its submitter's stake, and the submitter may not propose for a number of batches. A valid proposal that loses only because its volume was smaller or it arrived later is not penalized.

**Why this design**

- Matching is deterministic: for a given set of included orders, there is exactly one result. Matching miners can only compete on how many fillable orders they include. "Largest fill volume wins" rewards the miner who includes more orders and brings about more trades.
- A proposal that leaves orders out loses to a more complete competitor, which makes censorship harder.
- Confirmation is separate from matching: consensus miners do not race for matches, and a matching miner cannot confirm its own result.
- The number of matching miners is not capped; the more idle miners, the stronger the competition.
- Fund safety does not depend on matching miners: a wrong or forged result fails consensus recomputation and the paying asset chain's check of signatures and freezes (Section 7.1).

**Boundaries and risks**

- "First to arrive" uses the consensus committee's own receive order, which outsiders cannot verify; it matters only for ties.
- A consensus committee could unfairly drop some proposals. Proposed mitigation: matching miners send each proposal to every committee member, and each member attaches to its signature the hash of the largest valid proposal it received, for later review (mechanism pending, Appendix B, B-23).
- One operator could control both a matching miner and consensus miners; role registration and conflict-of-interest rules are needed (DLE OperatorDomainRegistryV1).
- Many proposals consume the committee's recomputation capacity; the stake threshold, penalties and a per-miner per-batch proposal cap limit this.
- The matching miner decides the order of fast-lane orders in its proposal (Section 6.2).

## 7. Settlement: parallel DLE transfers [Decided] (2026-10-25)

Operator decision: at fill, miners submit many transactions in parallel, and DLE completes the transfers.

### 7.1 Two-phase transfer [Proposed, needs DLE revisions R4, R5]

One fill involves at least two paying asset chains and two receiving asset chains. DLE has no cross-chain calls, so this paper uses two phases to ensure that either both sides settle or neither does.

**Phase 1: debit to in-flight.** Miners submit a `LegDebit` event on each paying asset chain, citing the market batch AC, the fill's position in `fillsRoot`, and the order chain. The debit = this chain's share of the fill amount + this side's fees (Section 9.2). The asset chain's state machine checks on its own that:

- the debited balance is frozen for this order chain;
- the order signature is valid, the fill price is no worse than the limit, and cumulative fills do not exceed the order quantity;
- fees follow the fee-policy version the order committed to;
- this fill has not been debited on this chain before (the fill id is the replay guard).

If so, the amount moves from available balance to in-flight.

**Phase 2: credit or refund.**

- Once every `LegDebit` of a fill has an AC, miners submit `LegCredit` on each receiving asset chain. The matching fee is credited to the matching miners, the LP fee to the LPs' asset chains, and the DLE transfer fee is allocated by DLE rules. Each paying asset chain submits `LegFinalize` to clear its in-flight record.
- If a debit is not done within `T_leg`, the asset chains already debited submit `LegRefund` with timeout evidence and return the in-flight amount. The fill is void and no fee is charged.

The asset chain's checks do not rely on the market chain being honest. Even if the committee and archive group of a market batch are both captured, a forged fill fails the paying asset chain's own check of the order signature and freeze record. Stealing funds also requires capturing the archive group hosting the paying asset chain.

### 7.2 Parallelism and merging

- Events on different asset chains do not queue behind each other and can run in parallel.
- Several fills touching the same asset chain in one batch merge into one event.
- A credit may open new asset chains (Section 4.4).

### 7.3 Receipts and order-chain updates

After every phase-2 event completes, the market chain observes the receipts in a later batch and marks the fill Settled; the order chain updates its cumulative fills. When a fill is voided, the market chain restores the remaining quantity of the honest side and records a failure for the defaulting side (usually the owner of an asset chain that requested a forced exit).

### 7.4 Cap on unsettled depth

When matched-but-unsettled fill value on a market chain reaches `K_unsettled`, the state machine refuses new matches and handles only cancels and receipts.

### 7.5 Execution cost

Each fill produces at least four asset-chain events (two debits, two credits), plus order-chain updates. Each event needs a DLE committee draw and an AC. Merging same-chain events, raising minimum fill size and encouraging users to consolidate asset chains all lower costs. Real costs are not measured.

These are execution costs of committee draws, votes and ACs. Percentage fees are computed on amounts and do not grow with the number of events (Section 4.3).

---

## 8. Market-chain state machine [Proposed, needs DLE revision R1]

### 8.1 States

`None=0`, `Open=1`, `Halted=2` (circuit breaker: cancels and receipts only), `DrainOnly=3` (delisting transition), `Closed=4`.

### 8.2 Events

| Event | Description |
| --- | --- |
| `MarketOpened` | Genesis: pair, `lotSize`, `tickSize`, price limits, `B_max`, fee-policy version; must match the DAO-approved market record on L1 |
| `Batch` | One matching batch (Section 6.1) |
| `MarketHalted` / `MarketResumed` | Observes an L1 halt or resume record |
| `MarketDraining` / `MarketClosed` | Delisting |

The `Batch` payload, in order: `l1BlockNumber`, `l1BlockHash`, inbox range and accumulator, genesis AC references of newly admitted order chains, cancels and amendments, pool references (pool storage-chain AC and state root), settlement-receipt references, `batchSeed`, `referencePriceTicks`, `clearingPriceTicks`, `fillsRoot`, `bookRoot`, `priceCurveRoot`. Event ids and error codes are assigned by the DLE revision.

### 8.3 Transition rules (summary)

| Current | Event | Preconditions | Next |
| --- | --- | --- | --- |
| `None` | `MarketOpened` | A DAO-approved market record exists on L1 with matching parameters | `Open` |
| `Open` | `Batch` | Consecutive nonce; cited L1 block and chain ACs valid; order chains fillable with sufficient freezes; unsettled depth within cap; recomputed reference price, fast-lane fills, auction result, fees and roots match the candidate | `Open` |
| `Halted` | `Batch` | As above, but no fills | `Halted` |

If any precondition fails, the whole batch is rejected with no partial write [DLE current] (DLE §10.1).

### 8.4 State-root paths (minimum)

`/state`, `/nonce`, `/params`, `/referencePriceTicks`, `/priceCurve/<batchNonce>`, `/book/bids/<price>/<orderChainId>`, `/book/asks/<price>/<orderChainId>`, `/orders/<orderChainId>/remainingLots`, `/orders/<orderChainId>/status`, `/pools/<poolId>/stateRootRef`, `/fills/<batchNonce>`, `/unsettled`, `/failures/<owner>`.

---

## 9. Fees

### 9.1 Decided fee rules (2026-10-25)

| Rule | Operator decision |
| --- | --- |
| Matching fee (principle) | Miners do the splitting and matching, motivated by a 0.01% trading fee |
| 0.01% in two parts | Prepay 0.003% at placement; no fee to cancel; pay 0.007% of the filled amount at fill |
| Who gets each part | The 0.003% prepayment is the chain-opening fee and goes to all validators of that chain; the 0.007% matching fee goes to the matching miners. The prepayment is on the full order total and is not refunded on cancel |
| Minimum order | 1 USDC, at the token's market price against USDC |
| Two book orders filling each other | Both sides pay the matching fee: 0.007% of the filled amount each |
| Placer's full fee set | The chain-opening fee; at fill, the same 0.01% transfer fee as LPs (to transfer to the LP), 0.01% of the filled amount to miners (now split as above), and the LP fee. All are computed in the placer's token, not in the LP's token. LPs receive the placer's token and can trade it into any token on DLE's trading pools |
| LP transfer fee | LPs pay DLE's 0.01% fee, covered by the fee rate set at pool opening |
| Transfer fee by amount | DLE's transfer fee is 0.01% of the amount, whatever the number of chains |

### 9.2 Who pays what

Every percentage fee is computed and paid in the payer's **own outgoing token** [Decided]. The base is the **filled amount** in that token [Proposed]: for the seller, the filled quantity in the base asset; for the buyer, the filled quote amount. Each fee is rounded up in the smallest unit and computed once per fill (one order against one counterparty), regardless of how many asset chains carry it.

| Case | Order placer pays (in own outgoing token) | LP pays (in own outgoing token) |
| --- | --- | --- |
| Placing an order (opening an order chain) | Prepayment: order total × 0.003%, not refunded on cancel (Section 5.1) | — |
| Amending on the same chain | Prepayment: new order total × 0.003%, paid in full again, not refunded (Section 5.1a) | — |
| Two book orders filling each other (auction, or a fast-lane order taking a book order) | Each side: 0.007% matching fee + 0.01% DLE transfer fee | — |
| Fast-lane order filled by a pool | 0.007% matching fee + 0.01% DLE transfer fee + LP fee `feeBps` | 0.01% DLE transfer fee, covered by the LP fee |

Formulas, with Q the order total and A the payer's outgoing amount in this fill, both in the payer's outgoing token:

```text
prepayment       = ceil(3 × Q / 100,000)
matching fee     = ceil(7 × A / 100,000)
DLE transfer fee = ceil(A / 10,000)
LP fee           = ceil(A × feeBps / 10,000)
```

When an order fills completely, the placer pays about 0.003% + 0.007% + 0.01% = 0.02% in total, excluding any LP fee. On a partial fill or a cancel, the prepayment still applies to the full order total.

The frozen funds must cover: the maximum outgoing amount + prepayment + matching fee + DLE transfer fee + the highest LP fee (at `maxPoolFeeBps`).

Fee transfers themselves are not charged further fees [Proposed].

### 9.3 Effects of paying fees in the placer's token

- Miners, archive groups and LPs receive fees in several tokens: sellers pay in the base asset, buyers in the quote asset.
- LPs receive the placer's token (fill proceeds and the LP fee). They can trade it into other tokens on DLE's trading pools [Decided].
- Fees do not depend on conet-USDC and need no oracle conversion. Pools can open on any pair, and LPs need no conet-USDC fee reserve.
- This differs from the current DLE §13.2 rule ("asset transfer fees are oracle-valued and paid in conet-USDC"), and DLE must be revised to match (R7).

### 9.4 Fee allocation

| Fee | Recipient | Rule |
| --- | --- | --- |
| Matching fee 0.007% | The winning proposal's matching miner | All of it [Decided] (2026-10-26) |
| DLE transfer fee 0.01% | Consensus miners | Shared by consensus miners [Decided] (2026-10-26). Proposed: by DLE rules, 50% to the archive group and 50% to the accepting validators of the asset chain carrying the transfer (DLE §13.4); whether the market-chain consensus committee gets a share is pending (Appendix B, B-22) |
| Prepayment 0.003% | Order-chain validators | Section 5.1 |
| LP fee | LPs in the pool, by share | Chapter 10 |

Computed separately for each token. Dust among validators goes by ascending address (DLE §13.4). The matching fee is credited to the matching miner when settlement completes; a voided fill pays nothing.

DLE currently splits its 1 bp protocol fee 50/50 between the archive group and validators (DLE §13.4). Here the whole matching fee goes to the matching miner, the DLE transfer fee is shared by consensus miners, and the prepayment goes to order-chain validators. This needs confirmation in a DLE revision (R8).

### 9.5 Income illustration

**Matching miners (0.007% matching fee)**

| Daily volume on a pair | Two book orders filling each other (each side 0.007%) | All fast-lane fills against pools |
| --- | --- | --- |
| 100,000 | about 14 | 7 |
| 1,000,000 | about 140 | 70 |
| 10,000,000 | about 1,400 | 700 |
| 100,000,000 | about 14,000 | 7,000 |

Units are quote-asset equivalent. Sellers pay the matching fee in the base asset, converted here at the fill price. All of it goes to each batch's winning matching miner.

**Order-chain validators (0.003% prepayment)**: computed on the total amount of orders placed, not on volume. With 1,000,000 in daily order totals, about 30. Orders later cancelled or expired count too.

None of this is an income forecast.

### 9.6 Are incentives aligned?

- Matching miners compete on fill volume: only a proposal that includes more fillable orders wins, and leaving orders out loses to a competitor, so censorship has a cost.
- Invalid proposals lose stake, so spamming proposals has a cost.
- Matching and the reference price are deterministic, so miners cannot earn more by changing results.
- The matching fee is credited only after settlement, so miners have a reason to submit settlement events promptly.
- The prepayment is not refunded, so spam orders and repeated place-and-cancel have a cost. Order-chain validators earn from order flow and matching miners earn from volume, separately.
- Matching and transfer fees together are low, so wash trading is also cheap. Volume statistics should say so.

---

## 10. Liquidity pools and the fast-trade fee

### 10.1 Decided items (2026-10-25)

| Item | Operator decision / choice |
| --- | --- |
| Opening pools and fee rates | Anyone, without permission, may open a liquidity pool with its own fee rate and price range. Users can search pools and add liquidity to earn. When an order turns on the fast lane, miners search the liquidity pools first while matching and trade at the current market price |
| LP funds | LPs must use funds already in DLE. Staking moves the funds into a pool opened in DLE, and trades with it settle in DLE |
| Pool size and the 100 cap | Use DLE's storage infrastructure to record the chains of every LP in the pool, each already frozen and capped at 100. At fill, miners submit many transactions in parallel and DLE completes the transfers |
| Reference market price | DLE computes and broadcasts a trade-price curve; miners collect orders as evidence and update it in real time |
| Pools against book orders | Compared together; the better price for the user wins |
| LP fee | Goes entirely to LPs, by share |
| Fast-order validity | Bounded by both batch count and L1 time |
| Withdrawal against a taker in the same batch | The taker goes first |
| LP transfer fee | LPs pay DLE's 0.01%, covered by the pool's fee rate |
| Placer fees and token | See Section 9.1: in the placer's token, not in the LP's token |

An external discussion the operator referenced suggested "order book + LP auto-quoting vault + unified splitting + atomic settlement", with request-for-quote later. This chapter takes from it the idea of turning LP funds into executable quotes compared with ordinary orders. The "vault" here is made of LP asset chains frozen in DLE; the funds never leave the LP's own asset chains.

### 10.2 What a pool is

A liquidity pool is a registration record on a DLE storage chain [Decided]:

```text
PoolRecord {
    poolId,
    creator,
    marketId,                 // trading pair
    feeBps,                   // LP fee rate set by the creator; at least the 1 bp DLE transfer fee
    priceLow, priceHigh,      // price range: the pool quotes only while the reference price is inside it
    lpEntries[] {
        lp,
        assetTipId,           // asset chain the LP froze into the pool (each ≤ 100 USDC)
        asset,                // base or quote asset
        frozenAmount,
        freezeAcRef
    },
    sharesByLp,
    stateRoot
}
```

- The pool holds no funds. Funds stay on each LP's own asset chains, frozen for the pool.
- Storage chains pay storage and retention fees in conet-GB under DLE rules [DLE current] (DLE §4.2). Who pays the pool record's storage fee is pending (Appendix B, B-12).
- Pool parameters are set at opening. Whether they can change later is pending (Appendix B, B-13).

### 10.3 Opening, joining and leaving

- **Open**: anyone creates a `PoolRecord` on a storage chain, with no permission and no DAO approval [Decided]. The pair must be a listed market.
- **Search**: pool records are public on DLE. Wallets and miners can search by pair, fee rate, range, size and fill history.
- **Join**: the LP signs `FreezeForPool{poolId, amount}` on their own asset chain and, once it has an AC, is added to the pool record. Joining a pool does not open an order chain.
- **Leave**: the LP requests withdrawal. It takes effect after the next market batch finishes its fast-lane orders [Decided: the taker goes first], and the freeze is released against that batch's AC. If the market stalls for `T_unfreeze`, the LP may release directly.

### 10.4 Reference market price [Decided principle, proposed rule]

The operator decided that DLE computes and broadcasts a trade-price curve, and that miners collect orders as evidence and update it in real time. This paper writes that as `ReferencePriceV1`, computed deterministically in every batch:

1. **Trade-price curve**: the market chain records each batch's clearing price and fast-lane fill prices as a volume-weighted curve, written to the state root and broadcast over L0.
2. **Order evidence**: the best bid and best ask on the book at the start of the batch. Every book order has an order chain and frozen funds behind it, so these prices are evidence that someone is willing to trade with real money. Only orders of at least `minEvidenceLots` count.
3. **Calculation**:
   - If both best bid and best ask exist and the spread is at most `maxSpreadBps`, the reference price is their midpoint.
   - Otherwise, it is the volume-weighted average over the last `N_ref` batches.
   - The result is clamped to that volume-weighted average ± `refBandBps`.

The book is never crossed after a batch. Raising the midpoint requires opening an order chain and freezing real funds for a higher bid, which anyone may then fill. With the clamp in step 3, there is limited room to push the reference price and then extract value from pools. Parameter values are pending.

### 10.5 Matching a fast-lane order

At the start of a batch, fast-lane orders are processed one by one. For each fast-lane buy order:

1. **Candidate sellers**: book sell orders (at their limit prices) and every eligible pool. A pool is eligible if the reference price is inside `[priceLow, priceHigh]`, `feeBps ≤ maxPoolFeeBps`, and the pool has base asset available. A pool fills at the **reference price**, with the LP fee paid on top [Proposed].
2. **Unified comparison**: fill from the lowest real cost to the user upward, until the order is filled, the fill price would exceed the limit, or a per-batch cap is reached [Decided: the better price for the user wins]. A pool's real cost is reference price × (1 + `feeBps`). A book order's real cost is its limit price (the matching and transfer fees are the same on both sides and do not affect the ranking). On a tie, book orders fill before pools, and pools go by ascending `poolId`.
3. **Unfilled remainder**: an IOC order is void. A GTC order keeps being processed as a fast-lane order in later batches until `validUntilBatch` or `expiry`, and is then void.

A fast-lane sell order is symmetric: a pool's real proceeds are reference price × (1 − `feeBps`), and the LP fee is paid in the base asset the placer sends.

"Fast" means the order fills in the next batch at the best available price, without waiting for a counterparty to appear or for the auction to finish. Settlement still uses the two-phase transfer of Chapter 7 and completes in the same time as an ordinary fill.

### 10.6 Spreading a pool fill across LPs

A pool fill debits LPs' frozen asset chains and credits LPs' asset chains [Decided: miners submit many transactions in parallel and DLE completes the transfers]:

- **Share**: an LP's share in an asset = the LP's frozen amount of that asset / the pool total of that asset.
- **Allocation**: a pool sale of base asset is spread by base-asset share. The quote asset the placer pays, plus the LP fee, is credited to LPs in the same proportions. Leftover lots go by ascending LP address.
- **LP transfer fee**: each LP pays 0.01% DLE transfer fee on its total outgoing amount in this fill, in the token it sends (the base asset when the pool sells), taken from its frozen funds. An LP whose outgoing amount spans several asset chains pays once, on the total [Decided].
- **Minimum allocation**: an allocation below `minLegLots` goes to the next LP instead, to avoid many tiny transfers; leftovers rotate (Appendix B, B-14).
- **Inventory**: after a pool sells base asset, the LP's base asset falls and its quote asset rises. An asset chain holds one asset, so the quote asset is credited to the LP's quote-asset chain registered in the pool, or to a new asset chain if none is registered. Credited assets are frozen into the pool automatically and quote in the opposite direction.

### 10.7 Fast-order validity [Decided: double bound by batch count and L1 time]

A fast-lane order is bounded by both `validUntilBatch` (market-chain nonce) and `expiry` (L1 time), whichever comes first. A batch-only bound can last a long time in a quiet market; a time-only bound can span many batches in a busy one. The DAO sets both caps (Appendix A).

### 10.8 Withdrawal against a taker in the same batch [Decided: the taker goes first]

When an LP's withdrawal request, a creator's parameter change (if allowed) and a fast-lane order meet in one batch, the fast-lane order runs first and the withdrawal or change after it. LPs tend to withdraw exactly when the price moves against them; if withdrawals ran first, fast-lane orders would miss exactly when they matter most. LPs are compensated by the LP fee, the price range, and being able to leave in the next batch.

### 10.9 LP returns and the fee floor

| Item | Direction | Token |
| --- | --- | --- |
| Fill proceeds | Income | The placer's outgoing token |
| LP fee | Income, by share [Decided] | The placer's outgoing token [Decided] |
| 0.01% DLE transfer fee | Cost, covered by the LP fee [Decided] | The LP's own outgoing token |
| Market-making gain or loss | Either | — |

**Fee floor [Proposed].** The LP fee is `feeBps` of the filled amount; the LP's DLE transfer fee is 0.01% of its outgoing amount. The two amounts are close but in different tokens. To ensure coverage, `feeBps` may not be below 1 bp at pool opening, or the pool is rejected. At exactly 1 bp almost all of the LP fee goes to the transfer fee, so creators should leave a margin.

LP net result = fill and inventory gain or loss + LP fee − DLE transfer fee − other own costs. In a one-way market, a pool keeps selling the asset that is rising or buying the one that is falling, and LPs can lose money overall. The pool-entry interface must say so plainly.

### 10.10 Risks

| Risk | Description | Mitigation |
| --- | --- | --- |
| Reference-price manipulation | Push the reference price, then extract from pools | Order evidence backed by order chains and frozen funds, spread threshold, clamp to volume-weighted average; per-pool per-batch cap `poolBatchCap` |
| Adverse selection | Traders with faster information pick pools when quotes lag | LP fee, price range; reference price updated every batch |
| Matching-miner ordering | The matching miner orders fast-lane orders in its proposal | Per-batch cap; ordering by order hash and random seed (B-4) |
| Pool concentration | A few large pools dominate quotes | Pools are permissionless; LPs choose freely |
| Too many settlement events | One pool fill spread over many LP asset chains | Minimum allocation, merging per chain |
| LPs receive many tokens | LP fees and proceeds come in the placer's token | Trade them on DLE trading pools |
| LP forced exit | A frozen asset chain requests a forced exit | The market stops using that chain; matched parts await the DLE gateway specification (B-10) |

---

## 11. Performance and parallelism

- **Parallel across pairs and asset chains**: each chain advances with its own committee. More archive groups can host more chains.
- **Serial within a pair**: a market's batches advance in nonce order.
- **Number of order chains and settlement events**: one order chain per order, and at least four asset-chain events per fill, more for pool fills. Throughput of chain opening and settlement depends on L1 NFT minting, committee draws and AC speed.
- **New committee per event**: DLE currently draws a new committee for every block (DLE §6.1). Whether one committee may serve several events needs a DLE revision (Appendix B, B-15).
- **No throughput or latency claims**: the Received, Matched and Settled latencies must each be measured in a pilot.

---

## 12. Security and market integrity

With all funds in DLE, safety rests mainly on DLE itself: committee sampling, an honest majority in archive groups, data availability, and the 100 USDC direct-loss cap per asset chain [DLE current] (DLE §12.2). The safety of a fill's funds comes from the paying asset chain checking the order signature and freeze record itself (Section 7.1).

| Risk | Handling | Residual |
| --- | --- | --- |
| Consensus committee and market archive group both captured | A forged fill fails the paying asset chain's signature and freeze check | Censorship, delay, dropping competitors' proposals, unfavorable fills and ordering within limit prices |
| Matching miners submitting invalid or spam proposals | Stake threshold; rechecked invalid proposals lose stake and proposal rights for a time; a per-miner per-batch proposal cap | Penalty share and cap not set |
| An asset chain's committee and archive group captured | Direct loss at most that chain's balance (≤ 100 USDC); committee cumulative exposure E_C ≤ E_max | One attacker capturing several archive groups |
| An order chain captured | Order terms are bound to the signature at genesis and cannot change; asset chains check the signature | Delayed closing and release |
| Front-running | Batch auction for ordinary orders; caps on fast-lane ordering | The matching miner's ordering of fast-lane orders; the consensus committee's receive order (ties only) |
| Censorship | L1 inbox fallback, competing matching miners selected by fill volume, rotating committees | Short delays |
| Partial settlement | Two-phase transfer: if any debit fails, the rest is refunded and no fee is charged | Forced exit against in-flight amounts (B-10) |
| Reference-price manipulation | Section 10.4 | Parameters pending |
| Malicious tokens | Only DLE-admitted canonical assets are listed | A token changing behavior after an upgrade needs a circuit breaker |
| Cross-chain asset risk | A cross-chain proof must reject forged messages before listing | — |
| Wash trading | Same-address self-trade prevention; the prepayment | Wash trades between different addresses cannot be detected |
| Spam orders | Every order prepays 0.003% (not refunded on cancel), is at least 1 USDC equivalent, and freezes enough funds | The prepayment is proportional, so spam with small orders stays cheap |
| Privacy | L0 reduces IP exposure; DLE asset fragmentation raises the cost of address clustering (DLE §4.5) | The book and settlements are public; not anonymous |

Until the archive production blockers close (a second independent implementation, production networking, key custody and more), none of the AC-dependent conclusions above hold (DLE §5.2.1; archive conformance specification §11).

---

## 13. Governance

- **Listing and parameters**: listing, delisting, halting and resuming pairs, and `lotSize`, `tickSize`, `B_max`, `priceBandBps`, reference-price parameters, fast-order validity caps, `K_unsettled`, the light-miner stake threshold, the invalid-proposal penalty and similar, are decided by DAO proposal and vote. Parameter changes name a future effective batch and do not apply to order chains already opened.
- **Liquidity pools**: opening a pool needs no permission and no DAO approval [Decided]. The DAO sets only global limits (for example the per-pool per-batch cap, the minimum allocation and the `feeBps` floor).
- **No admin**: the market registry contract, market-chain parameters, order chains and pool records have no admin role and no privileged address that can move user or LP funds [Proposed, following the GB system's decision that admin roles do not exist and are folded into DAO management].
- **Upgrading the L1 market registry**: the proposal is no upgradeability; if upgradeability is kept, it requires a DAO vote with a code hash and a public timelock (Appendix B, B-16).

---

## 14. Relationship to GB economics

- The exchange only matches existing assets between users. It mints and burns no tokens, holds no reserves, and does not change GB's paid issuance, exit, official rate R or coverage rules.
- The liquidity pools here are made of user funds and have nothing to do with the treasury. The pool and AMO rules of the GB AMM whitepaper are unaffected; arbitrage closes price gaps between the two.
- A placer selling GB pays every fee in GB, so miners, archive groups and LPs receive GB. These are transfers between users and do not change GB supply.
- Whether the treasury or AMO may place orders or join pools here is outside this paper and would need its own proposal.
- Free GB cannot be listed.

---

## 15. Phased launch and release gates

| Phase | Content | Precondition |
| --- | --- | --- |
| 0 Specification | Turn this paper into an executable specification and test vectors; submit revisions R1–R9 to DLE | Operator confirms the key items in Appendix B |
| 1 Lab network | Run one market and a few pools on the DLE lab network (0x44c45) with test assets; differential replay with a second independent implementation | Phase 0 complete |
| 2 Limited pilot | Real assets, low caps, few markets; all data public | AssetBurnMintGateway live; DLE production gates closed; specification and contracts audited; listed assets meet Section 4.6 |
| 3 Open | The DAO approves pairs one by one | Pilot data public with no open high-severity issue |

Mapping to the design study's release gates:

| Design-study gate | This paper | Status |
| --- | --- | --- |
| Order, cancel, match and settlement specification | Chapters 5–8 and 10 | First draft |
| Deterministic test vectors and cross-implementation replay | Phases 0–1 | Not started |
| Matcher identity, stake, rotation, challenge and slashing | Section 3.1, following DLE committee rules | Needs more detail |
| Audited settlement and adapter contracts | Chapter 7 (settlement inside DLE), Chapter 13 (L1 market registry) | Not implemented |
| Admission rules for every listed asset | Section 4.6 | First draft |
| Failure tests for reorgs, partitions, stale books, partial fills, cancel races | Sections 4.5, 6, 7 | Not started |
| Three latencies measured separately | Sections 3.3, 11 | Not measured |
| Market surveillance and abuse handling | Sections 10.10, 12 | Needs more detail |
| Wallet authorization and key-recovery safeguards | Section 4.2; DLE layered key custody (DLE §4.5) | Needs wallet work |
| Public client and independently reproducible pilot | Phases 1–2 | Not started |

---

## Appendix A — Parameters

| Parameter | Meaning | Status | Example (illustration only) |
| --- | --- | --- | --- |
| Prepayment (chain-opening fee) | Order total, in the placer's token, not refunded on cancel, to order-chain validators | [Decided] 0.003% | — |
| Matching fee | Each placer, on the filled amount, in own outgoing token, to matching miners | [Decided] 0.007% | — |
| Minimum order | Converted at the token's market price | [Decided] 1 USDC equivalent | — |
| Amendment prepayment | New order total, paid in full again, not refunded | [Decided] 0.003% | — |
| DLE transfer fee | Each outgoing transfer, on the amount, in the transferred token | [Decided] 0.01% | — |
| LP fee `feeBps` | Per pool, paid by the placer in own outgoing token | [Decided] set by the creator; floor 1 bp [Proposed] | 0.05% |
| Light-miner stake threshold | CNET stake needed to be a matching miner | [Decided] stake required; amount [Pending] | — |
| Invalid-proposal penalty | Share of stake lost and batches suspended for a rechecked invalid proposal | [Decided] a cost is required; values [Pending] | — |
| Asset-chain cap | Balance per asset chain | [DLE current] 100 USDC equivalent | — |
| N_V / Q_V / standbys | Committee | [DLE current] 7 / 5 / 2 | — |
| N_A / Q_A | Archive group | [DLE current] 5 / 4 | — |
| `lotSize` / `tickSize` | Per market | [Pending] | 1 GB / 0.000001 conet-USDC |
| `B_max` | Per-batch fill cap | [Pending] | — |
| `priceBandBps` | Auction price band | [Pending] | — |
| `maxSpreadBps` / `N_ref` / `refBandBps` / `minEvidenceLots` | Reference price | [Pending] | 1% / — / — / — |
| Fast-order validity caps | Batch count and L1 time | [Decided form] values [Pending] | — |
| `poolBatchCap` | Per-pool per-batch fill cap | [Pending] | — |
| `minLegLots` | Minimum allocation inside a pool | [Pending] | — |
| `T_leg` / `T_unfreeze` / `T_inbox` | Timeouts | [Pending] | — |
| `K_unsettled` | Cap on matched-but-unsettled value | [Pending] | — |

## Appendix B — Open items

| ID | Item | Options | Proposal |
| --- | --- | --- | --- |
| B-1 | ~~Do settlement transfers also pay the DLE transfer fee?~~ | Decided: placers and LPs both pay 0.01% on their outgoing amount (2026-10-25) | — |
| B-2 | Matching fee against DLE's 50/50 rule | A: all to matching miners; archive groups paid by their share of the DLE transfer fee and the availability budget. B: keep 50/50 | A |
| B-3 | Matching algorithm for ordinary orders | A: frequent batch auction. B: continuous matching within a batch | A |
| B-4 | Ordering of fast-lane orders within a batch | Inclusion order; order hash with random seed; per-batch cap | Hash with random seed, plus a cap |
| B-5 | ~~Who pays the matching fee~~ | Decided: each placer pays; 0.003% prepaid at placement + 0.007% at fill (2026-10-25) | — |
| B-6 | ~~Assembler share α; whether intake miners get a share~~ | Decided: idle light miners race to match, and the 0.007% matching fee goes entirely to the winning matching miner; there is no assembler (2026-10-26) | — |
| B-7 | Implementation order | Wait for the DLE revisions; or prototype on the lab network first | Lab prototype first |
| B-8 | How market batches and settlement events count toward E_C | — | By fill value and settled value, separately |
| B-9 | Birth cost of new receiving asset chains | Paid by the recipient; subsidized from fees | Recipient pays; wallet warns |
| B-10 | Forced exit of a frozen asset chain with matched but undebited value | — | Needs an answer from the DLE gateway specification |
| B-11 | Rewards for ordinary book orders | None; from another source | None; no new token issuance |
| B-12 | Who pays the pool record's storage fee | Creator; LPs by share | Creator |
| B-13 | Can a pool change its fee rate and range after opening? | No; yes with advance notice | No; open a new pool instead |
| B-14 | Minimum allocation and leftover rotation inside pools | — | Set `minLegLots`; rotate leftovers by batch |
| B-15 | One committee serving several events | — | Research; needs a DLE revision |
| B-16 | Upgrading the L1 market registry | Not upgradeable; DAO vote + code hash + timelock | Not upgradeable |
| B-17 | ~~LP transfer fee on pairs not quoted in conet-USDC~~ | No longer applies, because fees are paid in the outgoing token | — |
| B-18 | Chain-opening fee | Decided: prepay 0.003% of the order total in the placer's token, to all order-chain validators, not refunded on cancel; minimum order 1 USDC equivalent (2026-10-25). Still open: what pays the L1 birth-NFT mint gas and archive history storage; whether small orders cover validator costs | Assess after DLE cost measurement |
| B-19 | ~~Can an order chain be amended or reused?~~ | Decided: amendment on the same chain is allowed (re-sign to change price or quantity, rejoin the queue), with 0.003% paid in full again on the new order total (2026-10-25). Still open: which fields may change (Section 5.1a is a proposal) | — |
| B-20 | Fee base | Filled amount; total outgoing including the LP fee | Filled amount; no fee on fees (the prepayment uses the order total, decided) |
| B-21 | How the prepayment is shared among order-chain validators | Per block (Section 5.1); all to the genesis committee; all at close | Per block |
| B-22 | How consensus miners share the transfer fee | All to the asset chain's archive group and validators by DLE rules; or a DAO-set share to the market-chain consensus committee | A DAO-set share for the market-chain committee, the rest by DLE rules |
| B-23 | How to stop a consensus committee from dropping proposals | Attach the hash of the largest proposal received to each signature; send proposals to every member; later challenge | The first two together; challenge rules defined separately |
| B-24 | Light-miner stake threshold, invalid-proposal penalty, per-miner per-batch proposal cap | — | Set by the DAO, calibrated after the pilot |

## Appendix C — Examples

Pair GB / conet-USDC with the parameters of Section 5.5. All figures are for illustration only.

### C.1 Two book orders filling each other (batch auction)

| Order | Side | Quantity (GB) | Limit | Source |
| --- | --- | --- | --- | --- |
| Carol | Sell | 1,000 | 0.0100 | Resting |
| Dave | Sell | 2,000 | 0.0102 | Resting |
| Erin | Buy | 1,500 | 0.0098 | Resting |
| Bob | Sell | 500 | 0.0097 | New in this batch |
| Alice | Buy | 2,500 | 0.0102 | New in this batch |

| Candidate price | D | S | V |
| --- | --- | --- | --- |
| 0.0097 | 4,000 | 500 | 500 |
| 0.0098 | 4,000 | 500 | 500 |
| 0.0100 | 2,500 | 1,500 | 1,500 |
| 0.0102 | 2,500 | 3,500 | 2,500 |

Clearing price 0.0102, 2,500 GB filled: Bob 500 and Carol 1,000 in full, Dave 1,000 (1,000 stays on the book), Erin unfilled.

**Prepayments** (paid when each order chain opened, in the placer's token, to its validators, not refunded on cancel):

| Placer | Order total | 0.003% prepayment |
| --- | --- | --- |
| Alice (buy 2,500 @0.0102) | 25.5 conet-USDC | 0.000765 conet-USDC |
| Erin (buy 1,500 @0.0098) | 14.7 conet-USDC | 0.000441 conet-USDC |
| Bob (sell) | 500 GB | 0.015 GB |
| Carol (sell) | 1,000 GB | 0.03 GB |
| Dave (sell) | 2,000 GB | 0.06 GB |

Erin does not fill in this batch and Dave fills half; their prepayments do not change.

**Fees at fill** (each placer pays the 0.007% matching fee and the 0.01% DLE transfer fee in their own outgoing token):

| Placer | Sends | Matching 0.007% | DLE transfer 0.01% | Total sent | Receives |
| --- | --- | --- | --- | --- | --- |
| Alice (buy) | 25.5 conet-USDC | 0.001785 conet-USDC | 0.00255 conet-USDC | 25.504335 conet-USDC | 2,500 GB |
| Bob (sell) | 500 GB | 0.035 GB | 0.05 GB | 500.085 GB | 5.1 conet-USDC |
| Carol (sell) | 1,000 GB | 0.07 GB | 0.1 GB | 1,000.17 GB | 10.2 conet-USDC |
| Dave (sell) | 1,000 GB | 0.07 GB | 0.1 GB | 1,000.17 GB | 10.2 conet-USDC |

Alice's matching fee is computed per fill: 0.000357 + 0.000714 + 0.000714 = 0.001785.

**Matching fees in this batch**: 0.001785 conet-USDC and 0.175 GB, all to the matching miner whose proposal won the batch. Converted at the fill price, that is about 0.014% of the 25.5 filled. The DLE transfer fees of this batch are shared by the consensus miners.

**Settlement**: Alice froze one asset chain holding 30 conet-USDC. Phase 1: Alice's asset chain debits 25.504335 to in-flight; Bob's, Carol's and Dave's GB asset chains debit 500.085, 1,000.17 and 1,000.17 GB. Phase 2: Bob, Carol and Dave's receiving asset chains are credited 5.1, 10.2 and 10.2 conet-USDC; Alice's receiving asset chain is credited 2,500 GB (about 25.5 USDC equivalent, within the 100 cap); fees are credited by the rules. If Carol's debit times out because of a forced exit, Carol's fill is void, Alice's 10.2 + 0.000714 + 0.00102 = 10.201734 conet-USDC for it is refunded, and the other two fills complete. Nobody's prepayment is refunded.

### C.2 Fast lane and a liquidity pool

After the batch, the best bid is 0.0098 (Erin) and the best ask 0.0102 (Dave's remaining 1,000 GB). The spread is about 4%, above the example `maxSpreadBps` of 1%, so the reference price falls back to the recent volume-weighted average, taken as 0.0102.

Pool P: LP fee 0.05%, price range 0.0095–0.0110. LPs: Ann froze 30,000 GB (about 306 USDC equivalent, across 4 asset chains), Ben froze 10,000 GB (about 102 USDC equivalent, across 2 asset chains). Each also registered one conet-USDC asset chain in the pool to receive proceeds.

In the next batch, Gina submits a fast-lane buy of 3,000 GB, limit 0.0104, `maxPoolFeeBps` 0.1%:

1. **Comparison**: Dave's ask costs 0.0102; pool P costs 0.0102 × 1.0005 = 0.010205. Dave's 1,000 GB fills first, for 10.2.
2. **Pool fill**: the remaining 2,000 GB fills from pool P at the reference price 0.0102, for 20.4.

**Gina's fees** (in conet-USDC). At placement she prepaid 0.003% of her order total 3,000 × 0.0104 = 31.2, that is 0.000936. At fill:

| Counterparty | Filled | Matching 0.007% | DLE transfer 0.01% | LP fee 0.05% | Subtotal |
| --- | --- | --- | --- | --- | --- |
| Dave | 10.2 | 0.000714 | 0.00102 | — | 10.201734 |
| Pool P | 20.4 | 0.001428 | 0.00204 | 0.0102 | 20.413668 |
| Total | 30.6 | 0.002142 | 0.00306 | 0.0102 | 30.615402 |

Gina pays 30.615402 conet-USDC at fill, 30.616338 including the prepayment, an all-in average price of about 0.0102054.

**Dave's fees** (in GB): matching fee 0.07 GB, DLE transfer fee 0.1 GB, total sent 1,000.17 GB; he receives 10.2 conet-USDC. His prepayment was paid at placement.

**Spreading the pool fill** (by GB share: Ann 75%, Ben 25%):

| LP | Sells | DLE transfer fee (GB, from frozen funds) | Fill proceeds | LP fee received |
| --- | --- | --- | --- | --- |
| Ann | 1,500 GB | 0.15 GB | 15.3 conet-USDC | 0.00765 conet-USDC |
| Ben | 500 GB | 0.05 GB | 5.1 conet-USDC | 0.00255 conet-USDC |

Ann's 0.15 GB transfer fee is about 0.00153 USDC at the reference price; after the 0.00765 conet-USDC LP fee covers it, about 0.00612 USDC equivalent remains. Ben keeps about 0.00204. With a 0.05% LP fee, five times the transfer-fee rate, about 80% of the LP fee stays with the LPs. Ann's and Ben's conet-USDC is frozen into the pool automatically for quotes in the opposite direction; they can trade it into other tokens on DLE trading pools.

**Matching fees in this batch**: Gina's 0.002142 conet-USDC and Dave's 0.07 GB. **Order-chain validators**: Gina's order chain received her 0.000936 conet-USDC prepayment. LPs do not open order chains and pay no prepayment.

## Appendix D — Glossary

| Term | Meaning |
| --- | --- |
| Asset chain | A DLE asset-class chain holding user balances, each ≤ 100 USDC equivalent |
| Order chain | A DLE chain opened for one order by its placer, recording the order terms and fill progress |
| Market chain | A DLE chain for one trading pair, recording the book and matching results |
| Freeze authorization | The user's signature freezing balance on their own asset chain for an order chain or a pool |
| Matching batch | One block of the market chain |
| Matching miner (light miner) | A miner that stakes CNET, is idle, and races to submit matching proposals |
| Consensus committee / consensus miners | The 7 miners DLE draws per batch to recompute and confirm, plus the hosting archive group |
| Two-phase transfer | Debit to in-flight, credit against every debit receipt, refund on timeout |
| Liquidity pool | A storage-chain record listing LPs' frozen asset chains; the pool itself holds no funds |
| Placer's token | The token an order placer sends in a fill; every fee is computed and paid in it |
| Reference price | The price computed each batch from the trade-price curve and funded book orders |
| Fast-lane order | An order filled at the start of a batch against pools and book orders together |
| AC | Archive Certificate, the sole basis for finality of a DLE chain event |

## Appendix E — Revision history

| Version | Changes |
| --- | --- |
| v0.1 (not published) | Funds in L1 wallets with ERC-20 approvals; L1 `settleBatch` with per-fill `transferFrom`; LP firm quotes for the fast lane |
| v0.2 (this version) | All funds in DLE with freeze authorization; parallel two-phase DLE settlement; permissionless liquidity pools on storage chains compared with book orders; reference price from the trade-price curve and funded orders; one order chain per order with a 0.003% prepayment and 0.007% matching fee; amendment on the same chain; DLE transfer fee 0.01% by amount, in the outgoing token; LP transfer fee covered by the pool fee; minimum order 1 USDC equivalent; Sections 1.2–1.5 on the state of centralized and decentralized exchanges, what DLE addresses, advantages and disadvantages; Section 1.4.1 on throughput; Section 6.6 on idle light miners racing to match, with consensus miners confirming |
