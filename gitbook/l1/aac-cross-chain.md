# AAC proof-driven cross-chain settlement

**Status as of 2026-10-26.** This page follows the [GB token whitepaper](gb-whitepaper.md) (v0.3, 25 October 2026) and the [CoNET privacy and asset fragmentation whitepaper](privacy-fragmentation-whitepaper.md) (v0.3, 26 October 2026). Both are DAO discussion drafts, not approved by the DAO and not on-chain. Labels marked **[Decided]** are operator decisions with the stated date; they are not DAO approvals. No mint or release path is open. Under the deployment gate in GB §17, no new contract is deployed before independent audit.

**Evidence level: mixed.** The [bridgeAAC](https://github.com/CoNET-project/bridgeAAC) repository holds the AAC reference state machine and a production **read-only Shadow observer** (release `0.33.13`). Shadow is not a Base or CoNET light client. It controls no custody, emits no settlement transaction, and does not replace the legacy miner-vote bridge.

## What this page corrects

This page replaces the 2026-10-15 version. These statements from the earlier version are withdrawn or corrected:

- **Minting on external chains.** The earlier version said a destination GB or Peer v5 contract mints the asset. The whitepapers say the AAC secure construction holds the minting right on external chains, and the external treasury holds none (GB §3.1, §4.3).
- **Legacy addresses as targets.** The earlier version listed the legacy GB token `0xC3EF…` and the legacy CoNET USDC `0x5209…` as intended adapters. The whitepapers void the old GB balances and issue from zero on new contracts (GB §19.1). conet-USDC is deployed as a new contract (GB §3.2).
- **Rate governance venue.** The earlier version placed GB/USDC rate voting on CoNET Peer v5. The GB whitepaper makes the rate a DAO-voted parameter that the yes-voters execute, with no execution multisig (GB §15.1, §15.4).
- **wCNET completion.** The earlier version described CoNET-side completion as a release from custody. The GB whitepaper says release from custody is not an inbound method. Inbound completion is a CoNET mint after an external burn (GB §4.2).
- **Audit waiver.** The earlier version recorded that independent audit and third-party acceptance were waived by the owner on 2026-10-14. The GB deployment gate of 25 October 2026 requires independent audit before any new contract is deployed (GB §17). The waiver is kept as a historical bridgeAAC record and is not treated as satisfying that gate.
- **Host details.** Operator host addresses and partial IP addresses from the earlier version are removed from this public page.

## 1. Purpose

Atomic Asset Container (AAC) is the proposed one-time destination-chain record for cross-chain settlement. A source chain locks or burns an asset. A destination chain accepts that fact only after it verifies:

1. the lock or burn is included under a source-state commitment;
2. the commitment belongs to the intended source chain and gateway;
3. the source header is final under that chain's consensus rules;
4. the asset, amount, recipient, route, nonce and domain match; and
5. the source event has not already been consumed.

A relayer may submit a proof. It cannot choose the amount, choose the unit, or receive an unrestricted minting role.

## 2. Role in the whitepapers

- **AAC and cross-chain module** (GB §3.1). It verifies external lock or burn facts, confirms finality, and constrains one-time settlement. Tokens issued on CoNET are minted on external chains by the AAC secure construction (decided 24 October 2026).
- **External treasury** (GB §3.1, §3.2). It holds Base USDC and accounts for it by use. It holds no minting right. Cross-chain tokens are deployed at one address on external chains (decided 24 October 2026).
- **Deposit units** (privacy whitepaper §3). The proposal is that each accepted deposit corresponds to one unit, one token and one registration record, so a restriction on one unit does not by itself reach the others. The privacy whitepaper grades this as a proposed specification (§11.2).
- **Source-state proofs** (privacy whitepaper §3.7). A proof names the chain, the token address, the implementation version, the block height or hash, the state root, the storage layout and the finality rule. A single observer's signature over an RPC read is not a trustless verification.

## 3. Routes

| Route | Source action | Destination action | Basis |
| --- | --- | --- | --- |
| Base USDC to CoNET (inbound) | USDC is locked in the external treasury | CoNET mints conet-USDC after the AAC proof is verified | GB §3.2, §4.5 |
| conet-USDC to Base (outbound) | conet-USDC is burned on CoNET | The external treasury releases locked Base USDC, capped by the locked balance. Nothing is minted on Base. Blocked until the forged-burn gate passes | GB §3.2 (25 October 2026) |
| Paid GB to an external chain (outbound) | Paid GB is burned on CoNET | The AAC secure construction mints the same amount on the external chain. No other route exists | GB §4.1 |
| Paid GB from an external chain (inbound) | The external chain burns the CoNET-issued asset | CoNET mints paid GB. Release from custody is not an inbound method | GB §4.2 |
| External native assets | Base USDC, and ERC-20 tokens the DAO later votes to bridge, are locked in the external treasury | CoNET mints on inbound. On outbound the external treasury releases the asset. Nothing is minted on external chains | GB §4.5 |
| wCNET | Minted on an external chain only after the wCNET burn on CoNET | Inbound completion is a CoNET mint after an external burn | GB §4.1, §4.2 (24 October 2026) |

Rules that apply across the routes:

- Developer-issued ERC-20 tokens have no separate route. A CoNET-issued token that is bridged out follows the same rule: CoNET burn, then external mint by the AAC secure construction (GB §4.1).
- Free GB cannot be bridged. It has no right of exit and cannot be transferred, traded or bridged across chains (GB §8.2, decided 24 October 2026).
- A GB holder on an external chain who wants to exit must first bridge back to CoNET. The exit obligation is calculated on global supply: L = R × (paid GB circulating on CoNET + GB circulating on each external chain) (GB §4).
- Outbound burns and external minting only change where the supply sits. They are not a supply contraction and not new capital (GB §4).

## 4. Minting authority

- Minting of CoNET-issued tokens on external chains is done by the AAC secure construction. The external treasury holds no minting right (GB §3.1, decided 24 October 2026).
- The form of that construction is **pending** (GB §19.11). It must be decided whether the verification contract holds the minting right directly, or a dedicated representation token grants it only to the AAC secure construction. It must also be decided how the minter is replaced when the token has no admin.
- conet-USDC has no admin or owner minting and no upgrade authority (GB §3.2, decided 25 October 2026). It has two minting paths only: a Base USDC deposit, and the burn of paid GB (GB §3.2).
- Paid GB has four sources and no others: user issuance by burning conet-USDC, AMO sales, cross-chain inbound, and the miner mint as a risk-reserve exception. No address holds a minting right beyond these (GB §5.1).
- The new GB contract removes direct admin minting of paid GB and minting after burning developer FX tokens (GB §5.1, decided 24 October 2026).

**Legacy contracts.** The legacy GB contract still carries admin-side entry points, including an AAC admin role that was granted on 2026-10-15. The new GB contract removes these entry points (GB §5.1, §18). The legacy contract is a historical record, not the target design.

## 5. One-time settlement

- A cross-chain event may be confirmed, retained and completed only once. Source-chain reorganisations, expired proofs, replays, retries and concurrent requests must not cause duplicate minting or duplicate release (GB §3.3).
- The two chains do not execute atomically. The process must provide traceable pending states, timeouts and recovery rules. A claim for GB already burned but not yet paid must not be lost to interface errors, retries or pauses (GB §3.3).
- On the external side, a multi-unit payment is atomic. Either all selected unit transfers succeed or the whole payment reverts. A transfer that returns a failure value does not by itself complete the settlement accounting (privacy whitepaper §5.1).
- Cancellation may not rely on local timeouts. A source-chain request cannot be paid after a proven final cancellation, and rights are not restored merely because a timeout passed (privacy whitepaper §5.4, §9.1).
- Assets in transit and accepted exits not yet completed are shown as pending-settlement occupancy, separately from available backing (GB §3.2).

## 6. Proof boundary

- A Merkle inclusion path proves only that a leaf belongs to a supplied root. It does not prove that the root belongs to a real, final source block.
- **Base to CoNET** needs a verifier of Base finality, such as an OP Stack output-root and fault-proof adapter. A header supplied by a relayer is not sufficient.
- **CoNET to Base** needs a verifier of CoNET consensus and finality. Ethereum does not publish CoNET headers for Base to consume.
- Base has separate stages: sequencer pre-confirmation, L2 block confirmation, L1 batches, and finality. Cross-domain withdrawal proofs have their own waiting rules. They must not be collapsed into one fixed delay (privacy whitepaper §3.7).
- A consensus light client for one chain does not, by itself, verify another chain (privacy whitepaper §3.7).
- A token upgrade can change the storage layout. An adapter must bind the implementation version, and must not silently read old storage slots and continue to report a valid proof (privacy whitepaper §3.7).
- Agreement between RPC readers, a message bus, a miner signature or an HTTP success response is not a substitute for either verifier.
- The bridgeAAC reference code exposes a `FinalityVerifier` interface. Its execution-client adapters and its `MockFinality` test double are not light clients.

## 7. Security and deployment gates

- **Security gate** (decided 24 October 2026). Before any path that mints paid GB or conet-USDC opens, it must be proven that cross-chain verification rejects forged source-chain messages, including forged block headers and receipts. Positive tests with real data alone are not sufficient (GB §17).
- **Outbound release gate** (decided 25 October 2026). Before the conet-USDC outbound release path opens, it must be proven that the Base side rejects forged CoNET burn messages. The path mints no token, but a forged burn message would withdraw Base USDC from the external treasury (GB §3.2, §17).
- **Deployment gate** (decided 25 October 2026). New contracts are deployed only after discussion and independent audit are complete. Nothing is deployed before the audit is complete (GB §17).
- **The miner mint is not an AAC route.** The miner mint in GB §5.2 is a risk-reserve-backed issuance rule on CoNET. The legacy miner-vote bridge is a different mechanism and is closed (see Section 8).

## 8. Status recorded in bridgeAAC (2026-10-26)

| Item | Status |
| --- | --- |
| Reference state machine | bridgeAAC `0.33.13`, released 2026-10-16. Local tests and fail-closed smoke as recorded in the repository |
| Production Shadow | Read-only observer since 2026-10-16. Its reports keep `broadcast no`, `settled no`, `custody closed`, `light-client no`, `registry paused` and `consume denied`. Each chain is read by two execution readers, as recorded in the repository |
| Forged-message gate | **Not passed.** Audit gap G-14: the live CoNET cover for Base-origin messages does not bind the Base header to a Base block hash. Cover V4 closes the gap in source and in 15 tests (2026-10-19). V4 has no deployment record and is not wired to any settler |
| Legacy miner-vote bridge | `voteBridgeOperation`, `executeMint` and `executeRelease` revert `VoteBridgeClosed` |
| Legacy GB operations, 2026-10-15 | An AAC admin role was granted on the legacy GB contract, a 0.01 GB canary was executed, and the paid-GB bridge was paused. The monitor baseline was recorded healthy. These were executed against the legacy contract and do not pass the deployment or security gates above |
| Base checkpoint | A Base-side Ethereum sync-committee checkpoint root is installed and was rotated to period 1884 on 2026-10-15. It is observer evidence and does not open custody |
| Deposit-unit prototype | On 2026-10-26 a deposit-unit treasury prototype ran on Base Sepolia with test proofs and a test token. It tests the privacy whitepaper design. It is not AAC verification and not a production record |

## 9. Open items

1. The form of the AAC secure construction, including how the minter is replaced when the token has no admin (GB §19.11).
2. Same-address deployment of cross-chain tokens: deployer, initialisation code and salt (GB §19.10).
3. Migration of the existing conet-USDC supply, which is pending (GB §3.2). Old GB balances are void and the new contracts issue from zero (GB §19.1).
4. The holding structure of the external treasury. The GB whitepaper accounts for it by use. The privacy whitepaper proposes per-deposit units. Which structure is used is not decided.
5. Proof adapters for Base and CoNET, including proof freshness and failure behaviour (privacy whitepaper §3.7). None is implemented.
6. The outbound conet-USDC release: its burn-side design is decided, and it waits for the forged-burn gate (GB §19.12).
7. The threshold for DAO voting registration (GB §19.13) and the legal assessment of the exit mechanism and the fee types (GB §19.16).

## Related

- [GB token whitepaper (draft), v0.3](gb-whitepaper.md)
- [CoNET privacy and asset fragmentation whitepaper (draft), v0.3](privacy-fragmentation-whitepaper.md)
- [Decentralized cross-chain Treasury](cross-chain-treasury.md)
- [Core L1 assets](assets.md)
- [Bring an ERC-20 into CoNET](../developers/l1-erc20-bridge.md)
- [Cross-chain assets in CoNET-DLE](../l2/cross-chain-assets.md)
- [Run an L1 node](../developers/l1-node.md)
