# Economics

The DLE design maintains three separate economic ledgers. They represent different liabilities and must not be collapsed into one fee balance.

## 1. Protocol value fee

The target variable protocol fee is **1 basis point** on applicable value movement:

\[
1\ \mathrm{bp} = 0.01\% = 0.0001
\]

- Asset transfers pay the fee in canonical conet-USDC after the required L1 pool/TWAP valuation.
- Trade settlement pays the fee in the seller’s selected `quoteAsset`.
- The fee is split 50% to the hosting archive group and 50% to the validator quorum credited for the finalized event.

This is protocol revenue. It is not an execution-gas deposit and is not assumed to fund fixed availability capacity.

This 1 bp figure is **not** a universal all-in fee for every AI task. It applies to specified classes of applicable value movement: asset transfers and successful trade settlement. Official DLE economic text states that AI/API use does **not** automatically inherit the NFT-trade 1 bp rule; a dedicated, timelocked fee policy would be required before any percentage protocol fee applies to that class. Inference execution, data access, proof verification, L1 settlement, retries, storage, and availability may carry separate measured costs under future class-specific fee schedules. Candidate AI-market events in the Privacy-first AI paper are **not** presently frozen DLE tip classes.

## 2. Execution reserve

The execution reserve is a payer-capped canonical conet-USDC balance for objectively attributable work, including:

- L1 gas;
- oracle and proof verification;
- data-availability ingress;
- cross-domain settlement legs; and
- bounded retries allowed by `FeeScheduleV1`.

The reserve limits payer exposure before execution. Charges must be tied to the versioned schedule and measured work. Unused reserve is not silently converted into protocol revenue or archive funding.

## 3. Availability budget

The availability budget funds capacity that must be ready even when a tip has little transaction volume:

- five active archive voters;
- two ready standbys;
- validator capacity;
- retained history and availability service; and
- rotation, takeover, and re-home readiness.

The proposed sources are chain rent or creation reserves, with an explicit capped bootstrap subsidy if required. The availability budget is evaluated per epoch and separately from the 1 bp fee.

## Storage metering

Storage content, access, and retention use **GB** metering, not the deprecated `ConetGB1155` accounting track. The previous GBToken at [`0xC3EF02DaE632b4C10abB66e07d92a387c10838D8`](https://mainnet.conet.network/token/0xC3EF02DaE632b4C10abB66e07d92a387c10838D8) is no longer recognised; the [new GB design](../l1/gb-billing.md) is approved, not yet live. Those charges do not become part of the conet-USDC protocol-value-fee ledger merely because the storage tip also uses archive capacity.

## Principal is not fee revenue

Asset-tip principal remains governed by exact-token conservation in the gateway specification. Burned principal, reserved replacement entitlement, execution reserve, and protocol fees are distinct accounting domains. No fee shortfall permits principal to be redirected.

## Evidence boundary

The economic model is a target protocol, not a report of current production revenue.

- The 1 bp protocol-value fee is a target for specified value movement, not a universal all-in AI fee.
- The **100 USDC-equivalent asset-tip ceiling is frozen as a safety bound**.
- The 10-USDC minimum ingress value remains a pre-production calibration seed.
- Candidate 1.2× execution and availability coverage targets are not yet economically proven.
- Production asset ingress and new-chain admission remain disabled until an accepted measured `costEpoch`, complete branch benchmarks, and the specified 30-day 5+2 pilot close the evidence gap.

If measured costs exceed the profile’s safety envelope, the specified response is to pause admission or resize funded capacity—not to raise the frozen asset-tip ceiling without a protocol revision.

## Source anchors

- Whitepaper: §13, especially §§13.3–13.7 and the P1 evidence boundary
- `DLE-AssetBurnMintGateway-Invariant-Spec.md`: accounting domains and mandatory release gates
- [Ledger classes](tip-classes.md) — where each ledger is used
- [Cross-chain assets in DLE](cross-chain-assets.md) — Treasury hand-off and conservation before economic admission
- [Normative sources](specs-index.md) — source status and precedence

## Next

[DLE explorer →](explorer.md)
