# Participate in mining

**Evidence level: mixed.** Guardian registration, validator deposits, and Treasury miner views are production references. Runtime mining gossip is an implemented capability in CoNET-SI and CoNET-DL. Admission to the Guardian registry is **permissioned**.

Public site: [https://gitbook.conet.network/developers/l1-mining.html](https://gitbook.conet.network/developers/l1-mining.html)

“Mining” in CoNET is **not one role**. Before you write a client or provision a host, pick the set you actually mean.

## Five sets (do not collapse them)

| Set | Plane | How membership is evidenced | What it is not |
| --- | --- | --- | --- |
| **L1 validators** | Proof-of-stake consensus (Geth + Prysm) | Beacon duties; Explorer block withdrawals carry `validator_index` (already **≥ 2000**, see [block 169843](https://mainnet.conet.network/block/169843)) | Not `totalStakedValidatorCount()`, not Guardian registration, not a live SI listener |
| **VDR stake ledger** | Application contract on L1 | `ValidatorDepositRedeem.totalStakedValidatorCount()` (snapshot **475**) | Not the Prysm Beacon active set |
| **Guardian Nodes** | L0 DePIN registry on L1 | `GuardianNodesInfoV6.getAllNodes` (snapshot **472** IPs / owners) | Not proof the process is online; not the L1 consensus census |
| **Runtime miners** | LayerMinus ↔ SI gossip | A collector has a usable mining SSE and verifies the node signature | Not an L1 block voter |
| **Treasury miners** | Bridge quorum | `TreasuryBridgeV3.miners()` | Not the Guardian owner list |

A temporary gap between registered Guardians and live miners is expected after a restart or onboarding wave. It is not evidence that L1 consensus lost validators. See [L1 decentralization](../l1/decentralization.md).

This page is the developer path for **DePIN mining gossip** (Guardian + LayerMinus). L1 validator operation is a separate, **permissionless** consensus stack (geth + Prysm). Genesis downloads and peers: [Run an L1 node](l1-node.md). The **32 CNET** unit on the Beacon deposit contract (`0x4242…`) is not the same as a **VDR-counted** deposit record. See [Validators](../l1/validators.md).

## What DePIN mining is

```text
LayerMinus collector
  └─ encrypt command: "mining"  (omit listenKind)
     └─ HTTP/SSE to the target SI   ← infrastructure exception: may dial that SI directly
        └─ SI pushes signed gossip { epoch, nodeWallet, hash, nodeWallets[], … }
           └─ collector verifies the node wallet signature
              └─ optional report to a cluster master
                 └─ epoch totals written on L1
```

CoNET-SI emits signed mining / liveness frames to connected LayerMinus clients. CoNET-DL (or an equivalent worker) **dials the SI**. The cluster master does not open mailbox listens on behalf of every node.

This direct SI listen is the documented exception to the application rule **C ≠ B**. Do **not** copy it into Chat, presence, mailbox ACK, or UDP sessions. Those still encrypt to mailbox B and enter through an independent entry.

Chat reuses `command: "mining"` for transport compatibility but **must** set `listenKind: "chat"`. Omitting `listenKind` classifies the session as mining.

## How to participate

### 1. Decide the role

| You want to… | Do this |
| --- | --- |
| Run a public DePIN node that others can use as entry / mailbox | Operate **CoNET-SI** on a host that is (or will be) in `GuardianNodesInfoV6` |
| Collect and verify mining gossip | Run **CoNET-DL** / a LayerMinus worker, or write a collector against the SI command below |
| Stake L1 consensus | [Run an L1 node](l1-node.md) — **not** this gossip listen |
| Vote Treasury bridge operations | Be on the owner-managed `TreasuryBridgeV3.miners()` list — a different, small set |

Guardian `addNode` / `removeNode` require `adminList`. The node list is publicly readable; **joining the registry is not permissionless**. A running SI that is not registered will not appear in `getAllNodes` discovery.

### 2. Run the node (Guardian / SI)

A registered row is only eligibility and discovery. Runtime mining also needs:

1. **CoNET-SI** accepting `POST /post` (HTTP `:80` for SI-to-SI; client HTTPS optional).
2. A reachable public IP that matches the registry / advertised address.
3. A route OpenPGP key that `isMyRoute` can bind to wallets that chose this mailbox.
4. At least one LayerMinus collector that successfully opens a **mining** SSE and verifies gossip.

Public runtime: [CoNET-project/CoNET-SI](https://github.com/CoNET-project/CoNET-SI) · [`@conet.project/mvp-si`](https://www.npmjs.com/package/@conet.project/mvp-si).

Do not treat this page as a host rebuild or process-restart runbook. Changing execution / consensus / validator processes is outside DePIN mining and requires an explicit operations decision.

### 3. Run or write a collector (LayerMinus)

Public collector / data plane: [CoNET-project/CoNET-DL](https://github.com/CoNET-project/CoNET-DL) · [`@conet.project/mvp-dl`](https://www.npmjs.com/package/@conet.project/mvp-dl).

A collector:

1. Lists Guardians from L1 (`getAllNodes`). Live mapping: `PGP` = base64 route public key, `PGPKey` = **domain**.
2. Encrypts a signed `command: "mining"` (no `listenKind`) to **that node’s route PGP**.
3. Opens HTTP/SSE to that SI `/post` (infrastructure may use the target host directly).
4. Verifies `hash` recovers `nodeWallet`.
5. May forward verified aggregates to a configured master for epoch accounting.

Handshake frames may omit `nodeWallets`. Signed gossip is **not** mailbox business plaintext.

### 4. Sample: mining listen command

Reuse the SI signed-command helper from the [SI developer guide](../l0/si-developer-guide.md#sample-encrypt-a-signed-si-command). The command object is:

```ts
const command = {
  command: 'mining',
  // omit listenKind — SI defaults the session to mining
  walletAddress: wallet.address,
  algorithm: 'aes-256-cbc',
  Securitykey: sessionKeyBase64,
}
```

Encrypt `{ message: JSON.stringify(command), signMessage }` to the **target SI route PGP**. Keep the HTTP/SSE response open.

```ts
// Chat clients must not copy this. They send listenKind: "chat" via entry C ≠ B.
const miningListen = {
  command: 'mining',
  walletAddress: collectorWallet.address,
  algorithm: 'aes-256-cbc',
  Securitykey: sessionKeyBase64,
}
```

First-frame `{status, epoch, …}` / “Unknown format” heartbeats are liveness, not Chat messages.

## Compensation and accounting

| Mechanism | Meaning |
| --- | --- |
| **GB meter on last hop** | On a **signed command** path, the last hop may add verified prior-hop bytes to the user wallet’s gossip **GB** meter. User-PGP mailbox store (no command decrypt) cannot charge that way. GB issuance from the meter is paused. |
| **GBToken (`GB`)** | **No longer recognised; its services have stopped.** Balances do not carry over to the new GB, which is not yet deployed ([new GB design](../l1/gb-billing.md)). Previous DePIN service asset, **9 decimals**, [`0xC3EF02DaE632b4C10abB66e07d92a387c10838D8`](https://mainnet.conet.network/token/0xC3EF02DaE632b4C10abB66e07d92a387c10838D8). Do not use deprecated `ConetGB1155` as a wallet balance. |
| **Epoch totals** | When a master is configured, verified gossip can be aggregated and written to L1 epoch-mining state. Registration count ≠ that epoch’s miner count. |

Forwarding pays for **carrying ciphertext**, not for reading it.

## Read the current sets

```bash
RPC=https://rpc1.conet.network
G=0xBC6b53065b5647261396d002bDBA0d3396E0722f
VDR=0xc71e246DD78B37C2fABc905D340932F28F503433

cast call $G "getUniqueOwnerCount()(uint256)" --rpc-url $RPC
cast call $VDR "totalStakedValidatorCount()(uint256)" --rpc-url $RPC
```

`getUniqueOwnerCount()` is the **L0 Guardian** scale. `totalStakedValidatorCount()` is the **VDR application ledger**. Neither is the Beacon active-set size. Confirm consensus-layer indexes from Explorer withdrawals (example: [block 169843](https://mainnet.conet.network/block/169843), `validator_index` **2000**).

Page `getAllNodes` as in the [SI node sample](../l0/si-developer-guide.md#sample-discover-guardian-nodes). Reproduce the three-count table from [L1 decentralization](../l1/decentralization.md). Treat a failed RPC as untrusted; do not overwrite a previous success with zero.

## Related

- [Guardian Nodes](../l1/guardian-staking.md) — registry vs runtime
- [Run an L1 node](l1-node.md) — permissionless geth + Prysm + Beacon deposit
- [Validators](../l1/validators.md) — Beacon consensus role versus the VDR 32 CNET ledger
- [Node and client roles](../l0/node-roles.md) — SI vs LayerMinus
- [SI developer guide](../l0/si-developer-guide.md) — `/post` and command catalog
- [Bring an ERC-20 into CoNET](l1-erc20-bridge.md) — Treasury miners are a different set

## Next

[Bring an ERC-20 into CoNET →](l1-erc20-bridge.md)
