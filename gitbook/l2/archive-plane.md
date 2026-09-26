# Archive availability and finality

DLE separates **block production** from **archive certification**. The two stages have different members, quorums, and authority.

## Candidate production

For a tip event, the target protocol selects seven validators and requires five accept signatures:

\[
N_V = 7,\qquad Q_V = 5
\]

The validator certificate makes a candidate eligible for archive review. It does not by itself finalize the DLE block.

Only the validator committee produces the candidate block. Archive nodes must not create substitute blocks, control blocks, or empty anchor blocks.

## Archive group

Each hosting archive group has:

- five active voters;
- two ordered, non-voting standbys; and
- a quorum of four active voters.

\[
N_A = 5,\qquad f = 1,\qquad Q_A = 4
\]

Standbys do not occupy certificate signer slots unless a finalized membership transition promotes them. Existing groups retain their assigned tips; group growth does not remap all chains.

Operator independence is not inferred from distinct wallet addresses. `OperatorDomainRegistryV1` defines challengeable identity, infrastructure, and role-domain commitments used by membership decisions and bound into `membershipRoot`.

## EIP-155 Chain ID, Group ID, and Global Archive Routing Registry

Whitepaper §5.2.0d freezes **EIP-155 Chain ID** as the unique plane id (`eth_chainId`; testnet `0x44c45`) and **Group ID** as that group’s L1 register tx hash. Gossip, `tokenId` hash, a locally assumed default chain id, and explorer hostnames are **not** routing truth. L1 Solidity still stores a uint key; the protocol facade maps it to the register hash.

The CoNET L1 **Global Archive Routing Registry** stores every live group, every participating archive **wallet**, and every hosted chain **NFT id**. The facade is **deployed and Explorer-verified**. Production addresses, the bootstrap roster, and the public explorer display are on [Global Archive Routing Registry](routing-registry.md).

Required views:

| View | Returns | Use |
| --- | --- | --- |
| `liveGroupIds()` | Live Group ID hashes on the archive facade (L1 Solidity still returns uints) | Enumerate groups |
| `archivesOf(groupId)` | Five active + two standby EOAs | Who votes; dedicated history committee |
| `chainsOf(groupId)` | Hosted chain NFT ids | Which tips this **group** hosts |
| `route(chainNftId)` | **Group ID hash** on the protocol facade | Chain routing — not EIP-155 |
| `historyProviders(chainNftId)` | `archivesOf(route(chainNftId))` | Authoritative history providers |

To locate a tip: `groupId = route(nftId)`, then contact `historyProviders(nftId)`. A wallet not listed for that group at the relevant membership epoch is not the canonical host.

Do **not** write public explorer hostnames into Solidity constants. The registry stores wallets, `groupId`s, and NFT ids only. [https://dle.conet.network/](https://dle.conet.network/) is the lab UI; it may display wallets read from this registry, but the hostname is not routing truth.

`OperatorDomainRegistryV1`, `AssetBurnMintGateway`, and Archive Certificate remain **not** production-live. A listed participant wallet is routing identity only. Do not invent a substitute roster from lab `/health` when the L1 `archivesOf` read is available.

## Availability before finality

The archive path is not a storage-only acknowledgement. Before a non-nil precommit, each voting archive implementation must:

1. obtain the canonical full candidate body;
2. validate the validator certificate and current membership context;
3. deterministically replay the class state transition;
4. re-encode the body under `dle.rs.v1`;
5. recompute the data and state commitments; and
6. reject a candidate whose bytes, transition, or availability evidence do not match.

`dle.rs.v1` freezes Reed–Solomon `(n,k)=(7,4)` encoding and exact commitment rules. Possessing four Merkle-authenticated chunks is not, by itself, permission to vote: the signer must reconstruct and verify the canonical body.

## Tendermint-style finality

The archive state machine follows:

`Proposal → PrevoteQC → PrecommitQC`

A non-nil `PrecommitQC` is the **Archive Certificate (AC)**. The protocol includes nil votes, round changes, lock and valid-round semantics, timeout certificates, candidate-reject certificates, and write-ahead-log rules that prevent double signing across restart.

Finality is reached only when the current candidate has the required non-nil archive precommit certificate. A coordinator, one archive node, or the validator certificate alone cannot finalize it.

## Membership and exit

Archive membership changes are explicit state transitions. A planned exit retains duties until the replacement root is active, promotes the first ordered standby, and does not lower the four-of-five quorum. Equivocation, invalid availability claims, premature shutdown, and failed handover belong to archive accountability; user asset force exit is a separate gateway state machine.

## Implementation status

The archive conformance document is a **normative draft** with an executable v2 corpus and an Archive A deterministic MVP. It does not authorize production signing.

The specification lists open production blockers:

- one canonical EIP-712/SSZ verification wrapper;
- reproduction by a second independent production-language implementation with differential tests; and
- production networking, key custody and rotation, L1 checkpoint verification, signature recovery, and crash-injection integration.

Until those blockers close, the normative specification states that no archive signer may be enabled for production.

A public isolated lab and [DLE explorer](explorer.md) do **not** close those gates.
The `2026-09-23` post-window scrape was taken after the nominal 30-day endpoint:
formal seating was `QUALIFIED` 7/7, but `pilotQualified=false` remained 7/7,
heartbeat quorum was only 3/7, and terminal evidence did not close the required
rotations / re-homes / takeovers. The inventory freeze blocks new hash-catalogue
writes; it does not freeze the roster or replay/catch-up locator writes. Roster
views had expanded to 9–10, while `officialStandbyReadyCount=4` reflected
classification drift from extra standby roles rather than four official
standbys. BFT start, AC hash-index commitment, and production verifier `C_G`
availability remained 0/7.

Dual TypeScript Archive A/B in [CoNET-DLE](https://github.com/CoNET-project/CoNET-DLE) is in-repo evidence. It does **not** satisfy the independent second-language production blocker.

## Source anchors

- Whitepaper: §§5.2–5.2.0d; §5.2.1; §§6.2 and 6.5; §§7.8–7.9
- `DLE-Archive-Tendermint-Conformance-Spec.md`: §§1–11
- `DLE-OperatorDomainRegistryV1-Spec.md`: §§2–11
- [Normative sources](specs-index.md) — paths and precedence

## Next

[Ledger classes →](tip-classes.md)
