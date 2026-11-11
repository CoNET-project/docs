# Design thesis

## Scale by independent ledgers

CoNET-DLE does not try to make one globally shared execution tip process every application event. The design partitions state into many independently advancing **tips**.

A tip is a chain-specific, deterministic state machine:

- it is bound to one L1 NFT;
- it has exactly one class-fixed transition table;
- it produces a block only when an accepted event changes state; and
- it is hosted by one archive group while the current L1 placement record remains active.

There is no general-purpose tip VM and no free-form cross-tip call mechanism. Applications compose class-specific tips with CoNET L1 contracts.

## Identifiers (whitepaper §5.2.0d)

CoNET-DLE has two user-visible identifiers. **EIP-155 Chain ID** is unique for the plane (`eth_chainId` / wallets). **CoNET-DLE Testnet** is `0x44c45`. **Group ID** is that archive group’s L1 **register transaction hash**. L1 `archiveGroupId[tokenId]` remains a uint storage key.

| Identifier | Meaning | Must not be used as |
| --- | --- | --- |
| **EIP-155 Chain ID** | Unique uint for this DLE plane. Testnet = `0x44c45` | Group membership or tip identity |
| **Group ID** | L1 register tx hash of one 5-active + 2-standby roster | EIP-155 chain id or tip NFT id |
| **L1 uint `groupId`** | Registry storage key (`nextGroupId`, `archiveGroupId[tokenId]`). Bootstrap = `1` | User-visible Group ID or EIP-155 |
| CoNET L1 EVM `chainId` | Settlement L1 `224422` / `0x36ca6` | DLE plane id, Group ID, tip routing |
| Tip / chain NFT id | L1 ERC-1155 `tokenId` of one atomic ledger | Group roster or “which archives vote” |
| Archive NFT id | One archive node’s registration NFT | EIP-155, Group ID, or tip identity |

Bootstrap starts with **one** live group. Fission when \(U_e \ge 7\) allocates a new unused L1 uint **and** a new register tx hash; dissolved hashes and uints are never reused. The [DLE explorer](explorer.md) (paused) reported testnet `0x44c45` plus the bootstrap Group ID hash. The deployed L1 [routing registry](routing-registry.md) still stores bootstrap uint `1`.

## What remains global

Parallel execution does not remove global trust anchors. CoNET L1 remains responsible for chain birth records, ownership, archive placement, the **Global Archive Routing Registry**, canonical assets, and cross-layer settlement or exit records.

The design therefore separates three scopes:

| Scope | Responsibility |
| --- | --- |
| Tip | Class-specific event ordering and state transition |
| Hosting archive group | Candidate replay, availability checks, and archive certification |
| CoNET L1 | Canonical ownership, placement, routing registry, asset authority, settlement, and dispute anchors |

## Meaning of “atomic”

“Atomic chain” does not mean every DLE ledger commits in one global transaction.

- A normal tip event is final only after the required validator certificate and the hosting archive group’s Archive Certificate.
- A trade tip coordinates a sale, but final payment and NFT ownership transfer occur atomically in the L1 Settlement Contract.
- Asset ingress and exit depend on the L1 gateway and Treasury authority preserving principal conservation.

Each guarantee is local to its specified state machine and cross-layer boundary.

## Failure isolation

Independent tips are intended to keep one ledger’s congestion or state-machine failure from stopping unrelated tips. The frozen **100 USDC-equivalent ceiling** limits direct principal exposure on each active asset tip.

That ceiling is not:

- a cap on a seller-defined trade quote;
- a claim that committee collusion has zero incentive;
- a limit for every storage or application value; or
- evidence that the full system has reached production safety.

## Trilemma and throughput claims

The whitepaper explicitly does **not** claim to eliminate the blockchain trilemma. DLE changes the operating boundary from one global execution tip to many isolated state machines.

Aggregate capacity may grow as independent tips and archive groups are added. Security remains conditional on committee sampling, archive-group honesty, data availability, L1 settlement, operator independence, and client key isolation. Per-tip latency still depends on voting, retries, and archive certification.

No public production-throughput claim should be inferred from the architecture alone. The documented 30-day 5+2 pilot and economic measurement gates have not closed.

## Network privacy is separate

CoNET’s wallet-address routing and encrypted DePIN transport are network-layer goals. They can protect communication metadata and payloads, but they are not the DLE consensus algorithm. Wallet-level multi-address or ERC-5564 techniques are also separate from tip finality and do not replace key isolation.

## Source anchors

- Whitepaper: Abstract; §§3.1–3.4; §§4.2–4.5; §§5–5.2.0d; §6; §10
- [Normative sources](specs-index.md) — specification precedence and status

## Next

[Archive availability and finality →](archive-plane.md)
