# Miner-matched order-book exchange

**Maturity: Design study.** This non-normative page proposes a non-custodial
exchange with signed limit orders and miner-assisted high-speed matching. No
public exchange client, production matcher network, fungible order-book DLE
specification, or audited settlement contract is identified as live by this
GitBook.

Public site: [https://gitbook.conet.network/applications/miner-orderbook-dex.html](https://gitbook.conet.network/applications/miner-orderbook-dex.html)

**Whitepaper.** The [order-book exchange whitepaper](miner-orderbook-dex-whitepaper.md) (v0.2 discussion draft, 25 October 2026) expands this study. It keeps funds inside CoNET-DLE instead of L1 wallets: users freeze their own DLE asset chains, one DLE order chain is opened per order, miners split and match in batches, and DLE settles fills as parallel two-phase transfers. It also adds permissionless liquidity pools for a fast lane, and the operator's fee decisions. Where the two pages differ, the whitepaper reflects the later decisions. Neither is deployed.

## Product thesis

A decentralized exchange does not have to use an automated market-maker curve.

The proposed CoNET exchange uses a **central limit order book**:

- users place signed bids and asks at explicit prices;
- registered miner matchers maintain and replay market books;
- matching can run concurrently across trading pairs;
- the user interface exposes depth, spread, partial fills, and cancellation like a centralized exchange; and
- final asset movement remains non-custodial and contract-verified.

The design separates **matching** from **custody**. A miner can suggest that two orders match, but cannot change their signed limits or withdraw user assets. Settlement succeeds only when the destination contract verifies both intents, balances, authorization, nonce, expiry, fees, and the exact match.

## Why an order book instead of an AMM

An order book can avoid several AMM-specific trade-offs:

| AMM-specific behavior | Miner-matched order book |
| --- | --- |
| Price follows a pool curve | Price comes from explicit signed bids and asks |
| Large trades move along the curve and create price impact | A trade consumes visible depth at accepted order prices |
| Passive liquidity providers bear pool inventory and impermanent-loss risk | Market makers choose orders, inventory, spreads, and cancellation policy directly |
| Capital must sit in each liquidity pool | Assets can remain in user custody until bounded settlement authorization or escrow |
| Every pair needs an appropriate pool and curve | A market can open when canonical assets, settlement support, and real bid/ask liquidity exist |

This is not a claim that order books are universally better. Thin books can have wider spreads and worse execution than deep AMMs. Professional market makers can concentrate liquidity. A matcher network introduces ordering, censorship, availability, and front-running risks that an AMM expresses differently.

The goal is to remove **mandatory curve-based execution**, not to remove algorithms. Matching, priority, risk checks, and settlement still require precise, publicly reproducible algorithms.

## User experience target

The intended interface resembles a modern centralized exchange:

- market selector and searchable asset list;
- bid/ask depth and recent trades;
- limit orders;
- immediate-or-cancel orders with an explicit worst acceptable price;
- partial fills and remaining quantity;
- open orders, fills, and cancellation history;
- fast order acknowledgement; and
- clear separation between **matched**, **submitted for settlement**, and **finalized**.

Fast acknowledgement or matching is not finality. The interface must not display a match as settled until the relevant L1 transaction or future DLE settlement certificate is final.

## Asset path: external ERC-20 to a CoNET market

```text
ERC-20 on a supported chain
        │
        │ approved Treasury route
        ▼
Treasury-canonical ERC-20 on CoNET L1
        │
        ├── order-book market admission
        │     exact token proxy + decimals
        │     settlement adapter + fee policy
        │     liquidity and risk controls
        │
        └── optional future DLE asset admission
              pool/TWAP + AssetAdmissionRegistry
              AssetBurnMintGateway + release gates
```

An ERC-20 does not become tradable merely because its metadata can be read on CoNET. The market must recognize the exact canonical proxy, its Treasury route, decimals, transfer behavior, upgrade policy, settlement permissions, and exit capacity.

See [Decentralized cross-chain Treasury](../l1/cross-chain-treasury.md) and [Cross-chain assets in CoNET-DLE](../l2/cross-chain-assets.md).

## Proposed order lifecycle

### 1. User signs a bounded order

The wallet signs versioned EIP-712 data that binds at least:

```text
Order {
  version,
  marketId,
  owner,
  side,
  baseAsset,
  quoteAsset,
  quantity,
  limitPrice,
  minimumFill,
  timeInForce,
  feePolicyHash,
  nonce,
  deadline,
  settlementContract
}
```

The signature is the source of trading authority. A matcher cannot replace an asset, increase quantity, worsen the limit price, extend the deadline, redirect proceeds, or replay a consumed nonce.

A “market order” should be encoded as a short-lived, immediate-or-cancel limit order with a worst acceptable price. An unbounded market authorization is unsafe.

### 2. Submit through the CoNET communication plane

The client can send the signed order through [Layer Minus](../l0/README.md) to several eligible matcher miners instead of depending on one public exchange API.

L0 can reduce direct IP exposure and carry encrypted order traffic, but it does not make trading activity anonymous. A public book exposes price and quantity, and settlement still links addresses and assets on-chain.

### 3. Deterministic miner matching

Matcher miners maintain a replicated book for a bounded market shard. A production rule must define:

- market and shard assignment;
- order admission and signature verification;
- canonical sequence cut-off;
- price-time or another explicit priority rule;
- partial-fill arithmetic and integer rounding;
- cancellation ordering;
- self-trade prevention;
- matcher fees and bonds;
- duplicate candidate handling; and
- deterministic state roots that another miner can replay.

Miners can calculate matches quickly and in parallel across independent pairs. That does not justify an unqualified latency claim: observed speed still depends on routing, book replication, quorum, retries, and final settlement.

### 4. Produce a match commitment

A candidate match binds the consumed portions of both signed orders, the execution price, fees, sequence position, settlement nonce, and resulting book root.

Competing matchers should be able to derive the same result from the same canonical input. A production design needs a proof or challenge mechanism for omitted better-priced orders, priority violations, invalid fills, or equivocation.

### 5. Settle without matcher custody

The settlement boundary verifies the signed orders and atomically moves the exact assets:

```text
valid bid + valid ask + valid match commitment
        │
        ▼
atomic settlement
        ├── debit buyer quote asset
        ├── credit seller quote asset
        ├── debit seller base asset
        ├── credit buyer base asset
        ├── charge bounded disclosed fees
        └── consume fill quantities and nonces
```

If any required transfer or check fails, that match must not partially settle.

User funds should remain either:

- in the user's wallet under a single-use or tightly bounded authorization; or
- in a settlement escrow whose withdrawal rules are fixed by the signed order.

Matcher miners must never hold a general withdrawal key or an omnibus customer balance.

## What miners do — and do not do

| Miner responsibility | Not miner authority |
| --- | --- |
| Receive and verify signed orders | Change the user's limit or asset |
| Replicate a market shard | Mint a bridged token without Treasury policy |
| Apply the deterministic priority rule | Spend from a wallet without bounded authorization |
| Propose fills and book roots | Declare a match final by itself |
| Participate in challenge, quorum, or availability duties | Bypass the settlement contract |

The Treasury bridge miner set, L0 service nodes, DLE validators, archive members, and exchange matchers are different roles unless an explicit registry and conflict-of-interest policy says otherwise. The design must not silently treat every CoNET miner as authorized for every role.

## Relationship to CoNET-DLE

Current DLE documents define:

- **asset-class tips** for Treasury-backed value; and
- a **trade-class tip** for one NFT-style sale of an existing asset or storage ledger, with final atomic delivery on CoNET L1.

That trade class is a **single-subject NFT-style sale coordinator**, not a general fungible-token order book. It does not yet define pair-wide sequencing, partial fills across many orders, cancellation races, or atomic ERC-20 batch netting. More miners in a validator committee also does not, by itself, create a high-frequency matching engine.

A production miner-matched exchange therefore needs one of two explicitly specified paths:

1. **Application matcher + CoNET L1 settlement.** Miners coordinate and prove matches off-chain; an audited L1 contract verifies every signed fill and moves canonical ERC-20s atomically.
2. **Future DLE protocol revision.** A new or revised class-fixed state machine defines order-book events, deterministic matching, data availability, archive certification, and a safe L1 settlement bridge.

The current class set has no general-purpose VM or free-form cross-tip calls. Documentation alone cannot reinterpret the existing NFT-style trade tip as a fungible exchange.

## How the design targets CEX-like speed without CEX custody

| User expectation | Proposed mechanism | Boundary |
| --- | --- | --- |
| Fast order acknowledgement | Route to several matcher miners and validate locally before queueing | Acknowledged is not matched or settled |
| Fast matching | Deterministic in-memory books sharded by market | Requires measured replication and failover benchmarks |
| Visible depth | Signed open-order commitments and replayable book roots | Private or hidden orders need a separate commit-reveal design |
| Reliable cancellation | Signed nonce cancellation ordered before a published batch cut-off | A fill already finalized before cancellation remains valid |
| Asset safety | Wallet custody, bounded authorization, atomic settlement | Client-key compromise or malicious unlimited approval can still lose funds |
| Service continuity | Multiple matchers and deterministic replay | Correlated operators or network partition can still censor or halt a market |

## Market-integrity requirements

A release must address:

- **front-running and information leakage** — commit-reveal, sealed batches, frequent batch auctions, or another explicit policy;
- **fair ordering** — a publicly reproducible sequence source rather than a matcher-local clock;
- **censorship** — multi-matcher submission, inclusion deadlines, and challenge evidence;
- **equivocation** — signed book roots, conflicting-root evidence, bonds, and penalties;
- **cancellation races** — one deterministic cut-off and nonce state;
- **partial-fill conservation** — exact integer accounting across every fill;
- **toxic tokens** — reject fee-on-transfer, rebasing, callback, blacklist, or upgrade behavior unless a versioned adapter proves safe settlement;
- **cross-chain risk** — pause a market when its Treasury route, reserves, source finality, oracle, or canonical-token status becomes unsafe;
- **MEV and matcher concentration** — transparent fees, role separation, rotation, and measurable inclusion quality; and
- **recovery** — deterministic replay from signed orders and published commitments after a matcher failure.

## What exists and what remains

| Capability | Evidence |
| --- | --- |
| CoNET L1, EVM signatures, canonical assets, and deployed Treasury V3 | Production reference |
| Layer Minus wallet-addressed encrypted routing over L0 resources | Implemented capability |
| DLE asset-tip conservation and NFT-style trade coordinator | Normative design |
| Fungible order schema and deterministic pair-wide matching | Still to specify |
| Matcher registry, bonds, fair sequencing, and challenge proofs | Still to specify and implement |
| Atomic ERC-20 batch-settlement contract | Still to implement and audit |
| Public exchange client, market makers, and live liquidity | Not available |
| Throughput, latency, spread, uptime, and adversarial benchmarks | Not measured |

## Release gates

Before describing the exchange as available, the project must publish:

1. a versioned order, cancellation, match, and settlement specification;
2. deterministic test vectors and cross-implementation replay tests;
3. a matcher identity, stake, rotation, challenge, and slashing policy;
4. audited settlement and token-adapter contracts;
5. Treasury and DLE admission rules for every listed asset;
6. failure tests for reorgs, matcher partitions, stale books, partial fills, and cancellation races;
7. measured acknowledgement, match, and finality latency as separate metrics;
8. market-surveillance and abuse procedures;
9. wallet approval and key-recovery safeguards; and
10. a public client and independently reproducible pilot.

## Related

- [Order-book exchange whitepaper](miner-orderbook-dex-whitepaper.md)
- [Applications](README.md)
- [Decentralized cross-chain Treasury](../l1/cross-chain-treasury.md)
- [Cross-chain assets in CoNET-DLE](../l2/cross-chain-assets.md)
- [DLE ledger classes](../l2/tip-classes.md)
- [DLE economics](../l2/economics.md)
- [Layer Minus](../l0/README.md)
