# Ledger classes

Every DLE chain in the target protocol is bound to a unique CoNET L1 NFT and exactly one immutable class: **asset**, **storage**, or **trade**.

Class selection fixes the allowed event schema and transition function. A tip cannot change class, host arbitrary bytecode, or become a general-purpose messaging bus.

## Asset class

An asset tip represents allocated backing from a Treasury-canonical ERC-20 on CoNET L1.

The intended ingress sequence is:

1. the asset is recognized by Treasury V3 and activated in the exact-version admission policy;
2. the gateway obtains its own fresh L1 pool/TWAP quote;
3. Treasury atomically burns principal and reserves an exclusive replacement entitlement;
4. the receipt remains `BURNED_PENDING` while genesis is unresolved; and
5. a valid genesis Archive Certificate activates the corresponding L2 backing.

Only exact raw token units participate in principal conservation. USDC-equivalent valuation is used for admission and tip sizing, not as a substitute accounting unit for principal.

The active-tip ceiling is **100 USDC-equivalent**. If an event would leave a tip above that ceiling, the excess must be assigned to one or more new asset tips. The current 10-USDC floor is provisional and is not a proven production parameter.

A foreign-chain token cannot be burned directly into DLE. It must first complete an independent Treasury route and become a recognized canonical CoNET L1 asset.

Refund, normal exit, and challenged force exit are mutually coordinated rights. Every successful remint must consume one valid replacement right through Treasury authority; the gateway must not have an unconstrained independent mint path.

## Storage class

A storage tip records deterministic state for encrypted content publication, purchase, delivery, lineage, social events, and sales accounting.

The intended content path keeps bulk plaintext outside public ledger state:

- the creator fragments and encrypts content;
- an encrypted assembly index is addressed by hash;
- authorized DePIN delivery nodes can reconstruct the content;
- buyer identity is bound to a PGP key or key hash;
- the delivered package is encrypted for that buyer; and
- ledger and L1 records retain commitments, status, and settlement references rather than plaintext.

Storage access and retention are metered in **GB** (9 decimals). The previous GBToken at [`0xC3EF02DaE632b4C10abB66e07d92a387c10838D8`](https://mainnet.conet.network/token/0xC3EF02DaE632b4C10abB66e07d92a387c10838D8) is no longer recognised; the [new GB design](../l1/gb-billing.md) is approved, not yet live. This does not refer to the deprecated `ConetGB1155` accounting track. Short-lived access authorization and storage-payment expiry remain application and node responsibilities constrained by the recorded state.

The whitepaper also defines parent lineage, Copyright ZERO version trees, and sales journals that can reference asset tips without giving the storage tip arbitrary cross-tip execution.

## Trade class

A trade tip is a short-lived order and state coordinator for selling an existing asset- or storage-class chain.

Before the trade tip opens:

- the seller authorizes exact terms using EIP-712 or EIP-1271;
- the order binds `quoteAsset`, `quoteAmount`, subject NFT, nonce, deadline, and any buyer constraint; and
- the order digest and subject NFT are anchored in the CoNET L1 Settlement Contract.

The seller chooses the quote. The 100-USDC asset-tip ceiling does **not** cap a trade quote because the protocol cannot assign an objective oracle value to the subject NFT.

The tip can record matching and readiness, but it cannot rewrite the seller’s terms. Final delivery is one L1 settlement action that transfers payment and subject ownership atomically. The trade tip then closes.

This class coordinates one NFT-style sale of an existing asset or storage ledger. It is not a fungible-token central limit order book and does not define pair-wide sequencing, partial fills across many orders, or ERC-20 batch netting. The proposed [miner-matched order-book exchange](../applications/miner-orderbook-dex.md) requires a separate application settlement protocol or a future DLE protocol revision.

## x402 v2 AI pay-per-use (target profile)

Whitepaper §4.7a is a **target interoperability profile**, not a fourth chain class and not a tip VM. x402 remains the HTTP payment edge (`402 Payment Required` and the v2 payment headers). DLE may later store immutable usage receipts or batch-settlement references on existing asset or storage surfaces.

The CoNET profile identifies L1 as `eip155:224422` and admits only version-pinned Treasury-canonical assets. Prompt and model output must not enter public tip state. “Running AI on DLE” never means deploying provider code into a general-purpose VM.

This GitBook does not treat the current Beamio API as already x402-v2-conformant.

## Maturity boundary

These class descriptions summarize the whitepaper’s target state machines. The Trade FSM and several class boundaries are product-frozen, but the complete Asset and Storage runtime, production gateway, economic admission, and end-to-end pilot are not established as live by this GitBook.

The public [DLE explorer](explorer.md) inspects an isolated Archive lab. It does not execute class state machines or expose a tip VM.

Asset safety requirements are further constrained by the normative gateway invariant specification. Production asset ingress remains disabled until its formal, implementation, Treasury-conformance, and economic release gates pass.

## Source anchors

- Whitepaper: §§4.2, 4.6–4.7a, and 4.8–4.10; §6.3; §10
- `DLE-AssetBurnMintGateway-Invariant-Spec.md`: §§1–10
- [Normative sources](specs-index.md) — controlling paths and status

## Next

[Cross-chain assets in CoNET-DLE →](cross-chain-assets.md)
