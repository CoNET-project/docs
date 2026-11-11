# GB purchase, metering, fees and settlement (new GB design)

**Status as of 11 November 2026.** This page summarises the new GB design and its fee rules. Nothing on it is deployed, and no address exists. The earlier [GB token whitepaper (v0.3)](gb-whitepaper.md) and [GB AMM whitepaper (v0.2)](gb-amm-whitepaper.md) are superseded by this design and kept for reference.

**How to read the labels**

- **[Live]**: running on the network today.
- **[Implemented, pending acceptance]**: implemented and tested locally or on a public testnet. Not deployed to CoNET or Base. Acceptance, an independent audit and a separate deployment approval are still needed.
- **[Approved, not yet live]**: a rule the operator has decided and published. Not deployed. Deployment still needs an independent audit and a separate approval.
- **[Open]**: not decided. Listed without candidate values.

An operator decision is not a DAO vote. Prices, ratios and fees described as DAO-set are set by DAO vote.

## 1. Previous assets and where they stop

| Asset | Status |
| --- | --- |
| The current GBToken listed on [Core L1 assets](assets.md) | No longer recognised; its services have stopped. Balances do not carry over to the new GB. The new GB is not deployed |
| The current wCNET contracts | Their cross-chain service has stopped, because the Treasury cross-chain bridge is paused. A new wCNET is part of the next-generation contracts |
| The current conet-USDC | Will be replaced by a newly deployed contract (decided, not yet live); the switch-over plan will be announced. The current contract will not be upgraded. The status of the current contract is to be verified |

The Treasury cross-chain bridge is paused.

## 2. Two kinds of GB

| | Paid GB | Free GB |
| --- | --- | --- |
| How it is obtained | Issued by the paths in Section 4 | Claimed by a user (Section 5) |
| Transfer | Transferable | Not transferable and cannot be approved |
| Use | Pays for services; can be approved to an execution node | Pays for the same services as paid GB (Section 5) |
| Exit | Keeps an exit right | No exit right; cannot be bridged |

GB uses **9 decimals**.

## 3. Contracts and governance [Approved, not yet live]

- The new GB and wCNET contracts are deployed by the fixed AAC factory during initialisation, together with the new conet-USDC ledger and the new treasury. They have fixed addresses, no proxy, no upgrade function and no administrator. Their key authorisations are frozen when initialisation completes. Details: [Two-way AAC bridge, Deployment and upgrades](aac-two-way-bridge.md#deployment-and-upgrades-approved-not-yet-live).
- Original issuance of GB and wCNET happens only on CoNET. Minting on another chain happens only against a burn on CoNET verified by AAC.
- wCNET has no governance burn. A cross-chain burn of wCNET is started only by its holder.
- The compiler settings of the new GB and wCNET contracts are fixed, so that each contract has the same address on every supported chain.
- Local code for the new GB exists but is not complete: for example, free GB claims and spending are not yet implemented as decided. Nothing is accepted or deployed, and same-address deployment on CoNET, Base and Ethereum is not complete.
- Every proposal has a 600-second observation period after voting opens. DAO votes keep a 7-day window. See [DAO and the next-generation treasury](dao-treasury.md).

## 4. Issuance of paid GB [Approved, not yet live]

Paid GB is issued only on CoNET, by these paths:

1. **Node reward.** A node burns free GB that users have spent with it and receives paid GB at a DAO-set ratio. Per-node and network-wide caps apply; rewards above the caps are dropped while the free GB is still burned. Node rewards issued in each fixed 90-day period may not exceed **1%** of the exit obligation, and queued rewards are capped at the same 1%.
2. **Purchase.** A user buys GB on CoNET: the GB contract burns conet-USDC at the DAO-set price per GB and issues the GB. conet-USDC here means the new conet-USDC contract (not yet deployed). While the DAO has the conet-USDC mint and burn pause on, both purchases and exchanges of GB back to conet-USDC pause, because each mints or burns conet-USDC ([Third-party tokens and subscriptions, Section 5.1](third-party-assets.md#51-two-switches-per-official-stablecoin-implemented-pending-acceptance)).
3. **Market operations.** One DAO-designated market-operations contract may issue and burn GB to keep the GB price at the DAO-set price.
   - It may issue GB without burning conet-USDC. Its **net issuance** (GB issued minus GB it burned) is limited by a DAO-set amount of GB. The limit starts at **0** and is not reset by period.
   - It may burn only GB it holds itself. It cannot burn a user's or anyone else's balance. A sale of GB back to it is started by the holder.
   - Parts of it are **[Implemented, pending acceptance]**.
   - Its issuance and burning are counted separately from cross-chain mints and burns.
   - **It is not enabled at launch.** Turning it on needs a separate DAO decision.

Rules across the paths:

- Exchanges between GB and conet-USDC, in both directions, pay a DAO-set fee of **n%**, paid by the person exchanging. It is separate from the third-party issuance fee in CNET. No default value is set. The fee mechanism is **[Implemented, pending acceptance]**; its value is **[Open]**.
- No paid GB is issued, and no free GB can be claimed, until external capital has been registered on chain behind a cross-chain proof that rejects forged source-chain messages.
- Every minting and burning slot is set once at deployment and cannot be replaced. Parameters are adjusted by DAO vote within hard limits.

## 5. Free GB [Approved, not yet live]

- Any ordinary wallet (an externally owned account) can claim free GB **once per rolling 24 hours**, counted from its last claim. The amount per claim and the network-wide rolling 24-hour budget are set by the DAO.
- Free GB cannot be transferred or approved, and it has no exit right.
- **Free GB pays for the same services as paid GB**, including mailbox fees, with the user's authorisation (decided 10 November 2026).
- The claim and the consent to spend are signed by the wallet itself (ECDSA).

## 6. The GB price [Approved, not yet live]

The DAO sets the benchmark price of GB in conet-USDC. Each change:

- moves the price by at most **50%** in one step;
- keeps the total of all price moves within the last rolling **90 days** at or below **20%** of the price in effect at the start of that window. Rises and falls both count and do not offset each other. The window rolls with every check; it is not a fixed quarter;
- is timed by the block in which the DAO decision is executed;
- moves the price by at least one smallest unit of that stablecoin.

There is no longer-period cap: at 20% per rolling 90 days, the price can change by about 2.07 times in a year. The price does not expire; settlement checks only that the price version is valid and matches the order.

The rolling-cap logic is **[Implemented, pending acceptance]** in the DAO contracts for conet-USDC. The limits for other official stablecoins are **[Open]**.

## 7. Reserve [Approved, not yet live]

- The reserve asset is Base USDC. The project funds it from outside and discloses the funding publicly.
- Funding goes into a reserve contract with no administrator and no withdrawal function. It cannot be taken back.
- conet-USDC is minted only through bound paths: a verified Base deposit, burning GB, and the fixed exchange entry that pays out conet-USDC when a third-party stablecoin backed by it is redeemed or spent ([Third-party tokens and subscriptions](third-party-assets.md)).

Bridging is described in [Two-way AAC bridge](aac-two-way-bridge.md).

## 8. Metering

- **[Live]** On a signed command path, the last hop adds verified prior-hop byte counts to a per-wallet counter, and every node reports the totals each epoch. SOCKS proxy traffic is counted the same way. No balance is checked and nothing is charged. GB issuance from these counts is paused.
- **[Live]** SilentPass exit traffic is admitted by a valid Passport NFT and is not charged by volume.
- **[Approved, not yet live]** The charging unit is **1 MB**. A request is split into shares equal to the number of hops plus one, so each hop is paid for its part.

## 9. Service fees in GB [Approved, not yet live]

For services that involve CoNET nodes:

- The user approves the execution node's wallet for at least **0.5 GB** of paid GB.
- The execution node keeps an off-chain tally and collects with `transferFrom` each time the tally reaches **0.1 GB**. The user receives a breakdown of each charge.
- Available credit is the smaller of the allowance and the user's paid balance, minus charges not yet collected.
- A request declares at most **2** relays between the entry and the execution node.
- The new GB token supports EIP-2612 `permit` and EIP-3009 `transferWithAuthorization`, so a user without CNET can approve and others can submit transfers. Both accept ordinary wallet (ECDSA) signatures only; contract-wallet signatures (ERC-1271) are not accepted for GB.

Every 12 hours (UTC), each execution node pays the previous hop against a hash-based statement, and each hop writes off what it received. There is no settlement contract: hop payments are plain transfers of paid GB.

Visible on chain: the user's approval of and payments to the execution node are public, and payments between nodes reveal route edges over time. No single transfer shows both the user and the entry.

Payment for node services in a third-party stablecoin runs separately from these GB fees; each has its own funds. See [Third-party tokens and subscriptions](third-party-assets.md).

Offline mailbox storage has its own rule: [Mailbox storage billing](../l0/mailbox-storage-billing.md).

## 10. Open items [Open]

- How free GB is collected for services, given that it cannot be transferred or approved, including how it is settled hop by hop, and which existing fee rules change because free GB pays for all services.
- Whether the paid GB a node receives for burned free GB first tops up the node's stake shortfall.
- Whether an issuance fee applies in addition to the n% exchange fee, the value of n and the other details of the exchange fee.
- The market-operations contract: the meaning of its price band, the observed price source and the values. These are decided before it is enabled.
- Rounding of small requests and unit prices per service type.
- Fee details: the share count for a direct connection to the execution node, whether a browser execution node's anchor counts as a hop, per-request usage vouchers, allowance limits in clients, a starting limit for new wallets, how bad debt is shared between hops, statement contents, overdue payers, reconciliation tolerance and minimum amounts.
- The fee for registering or changing a Beamio tag.
- The format and verifier of delivery receipts.
- The release order of queued node rewards.
- Whether each minting module gets a DAO-controlled off switch.

## Related

- [Core L1 assets](assets.md)
- [Two-way AAC bridge](aac-two-way-bridge.md)
- [Third-party tokens and subscriptions](third-party-assets.md)
- [DAO and the next-generation treasury](dao-treasury.md)
- [Mailbox storage billing](../l0/mailbox-storage-billing.md)
- [Node registry V2](node-registry-v2.md)
- [CoNET Chat whitepaper, Section 16](../applications/depin-chat-whitepaper.md#16-metering-charging-and-settlement)
- [GB token whitepaper v0.3 (superseded)](gb-whitepaper.md)
- [GB AMM whitepaper v0.2 (superseded)](gb-amm-whitepaper.md)
