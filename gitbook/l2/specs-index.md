# Normative sources

This page defines the source boundary for the L2 digest. The controlling files are public in [CoNET-project/CoNET-DLE](https://github.com/CoNET-project/CoNET-DLE). A local engineering checkout may keep the same tree under `src/conet-layer2/`; that path is a workspace label, not a closed-source claim.

## Primary design document

English whitepaper:

[Decentralization Cluster multi-chain.md](https://github.com/CoNET-project/CoNET-DLE/blob/main/src/whitepaper/Decentralization%20Cluster%20multi-chain.md)

Reviewed revision: **2026-08-18** (EIP-155 plane Chain ID `0x44c45` vs Group ID = L1 register tx hash; L1 uint `groupId` is a storage key only — §5.2.0d; G2 user-visible Group ID is L1 `registerLiveGroup` tx `0xf781f2c23fe3b3dac09dc3e1929016b0af200ee93978e916df64d750876d5153`; laboratory keccak aliases it; laboratory clock started `2026-08-18T09:53:58.092Z` and is **not** 30-day qualification; honesty-track review does not change production formulas)

Paired translation:

[Decentralization Cluster multi-chain.zh-CN.md](https://github.com/CoNET-project/CoNET-DLE/blob/main/src/whitepaper/Decentralization%20Cluster%20multi-chain.zh-CN.md)

The paired files are maintained together. GitBook pages summarize them but do not replace their definitions, formulas, state machines, or release gates.

## Normative implementation specifications

The public whitepaper directory contains exactly three English `DLE-*Spec.md` files:

| Boundary | Public source | Declared status |
| --- | --- | --- |
| Archive bytes, voting, WAL, membership, and conformance | [DLE-Archive-Tendermint-Conformance-Spec.md](https://github.com/CoNET-project/CoNET-DLE/blob/main/src/whitepaper/DLE-Archive-Tendermint-Conformance-Spec.md) | Normative draft; executable v2 corpus and Archive A MVP frozen; production closure incomplete |
| Asset burn, backing, refund, exit, and remint conservation | [DLE-AssetBurnMintGateway-Invariant-Spec.md](https://github.com/CoNET-project/CoNET-DLE/blob/main/src/whitepaper/DLE-AssetBurnMintGateway-Invariant-Spec.md) | Normative v1 safety specification |
| Operator identity and correlated-failure domains | [DLE-OperatorDomainRegistryV1-Spec.md](https://github.com/CoNET-project/CoNET-DLE/blob/main/src/whitepaper/DLE-OperatorDomainRegistryV1-Spec.md) | Normative v1 identity/correlation specification |

Within their stated boundaries, these specifications control over a shorter or less precise GitBook summary. They do not, by themselves, prove that a production deployment exists.

## Supporting executable evidence

Supporting artifacts include:

- the `DLEAssetBurnMintGateway.tla` model and checked configuration in [CoNET-DLE](https://github.com/CoNET-project/CoNET-DLE);
- archive JSON Schema, vector corpora, and integrity manifests;
- deterministic archive reference implementations and differential-test tooling; and
- CI evidence and pilot scaffolding in the same public repository.

A second independent Archive implementation remains an open production blocker in the Archive specification. Public design files do not close that gate.

These artifacts support conformance and review. Their scope must be stated precisely. For example, the recorded TLC run is a bounded state-space result; it is not a proof over arbitrary Solidity values, live adapters, cryptography, or deployment configuration.

## Precedence

Use this order when interpreting the public digest:

1. the relevant normative companion specification for its explicit boundary;
2. the whitepaper for the broader product architecture and frozen decisions;
3. executable vectors and models for their declared test domain;
4. GitBook pages as explanatory summaries.

An apparent conflict between paired translations or normative sources is a specification issue to resolve. It must not be hidden by choosing whichever wording is more convenient.

## Non-normative material

Everything under `src/canvas/` is **non-normative**. Canvas applications and their Markdown snapshots are design reviews, calculations, criticism-to-control maps, or analytical records. They may identify a release blocker or motivate a specification change, but they do not establish protocol behavior.

The Canvas index is:

`src/canvas/README.md`

The [DLE explorer](explorer.md), now paused, was a **non-normative lab UI**. Its `/health`, `/rpc`, and `/api/v2/dle` payloads describe the isolated 30-day Archive lab. They do not amend the whitepaper or the three `DLE-*Spec.md` files.

The deployed [Global Archive Routing Registry](routing-registry.md) on CoNET L1 is **production bytecode** for the §5.2.0d routing facade. It does not close Archive Certificate, asset-ingress, or 30-day qualification gates.

Other planning notes, issue discussions, marketing pages, and this GitBook are also non-normative unless a normative source explicitly incorporates them.

## Citation rules

When asserting protocol behavior:

- cite the exact whitepaper section or specification filename and section;
- include the source revision when byte-level compatibility matters;
- label a target, provisional parameter, bounded result, or production blocker as such; and
- do not cite Canvas as authority for a `MUST`, `SHOULD`, state transition, quorum, or wire encoding.

## Source anchors

- Whitepaper front matter and §5.2.0d — revision, EIP-155 plane Chain ID, Group ID = L1 register tx hash, Global Archive Routing Registry, and non-normative Canvas notice
- Archive conformance specification §11 — frozen machine boundary and production blockers
- Asset gateway invariant specification §10 — mandatory formal-verification release gate
- Operator registry specification §§2–11 — canonical identity and policy-root semantics

## Related

- [L2 development](../developers/l2.md) — implementer how-to
- [Global Archive Routing Registry](routing-registry.md) — deployed L1 facade
- [DLE explorer](explorer.md) — paused
- [Lab honesty track](lab-honesty-track.md) — 2026-08-18 laboratory review (non-normative; clock ≠ qualification)
- [Cross-chain assets in DLE](cross-chain-assets.md) — Treasury-to-DLE admission and conservation digest
- [Decentralized cross-chain Treasury](../l1/cross-chain-treasury.md) — production L1 route and quorum boundary

## Next

[Return to the CoNET-DLE overview →](README.md)
