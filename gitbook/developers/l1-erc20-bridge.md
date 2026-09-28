# Bring an ERC-20 into CoNET

**Evidence level: mixed.** `TreasuryBridgeV3` and the listed canonical CoNET assets are production references. Route policy, miner quorum, and replay controls are implemented capabilities. The AAC read-only Shadow is production-approved, while AAC custody and hand-off from a bridged asset into CoNET-DLE remain closed.

Public site: [https://gitbook.conet.network/developers/l1-erc20-bridge.html](https://gitbook.conet.network/developers/l1-erc20-bridge.html)

An ERC-20 issued on another chain is **not** a CoNET asset. It enters the ecosystem only through the **one** production Treasury, `TreasuryBridgeV3`, on an **already enabled** route. A caller-supplied token address does not create that route.

Architecture detail: [Decentralized cross-chain Treasury](../l1/cross-chain-treasury.md).

The separate [AAC track](../l1/aac-cross-chain.md) must not be used as a production custody integration guide. Its deployed Shadow is read-only and is not a Base or CoNET light client.

## The only Treasury

| Component | Address | Role |
| --- | --- | --- |
| **TreasuryBridgeV3** | [`0xa208982212978550594A7FEEB70a61665d129003`](https://mainnet.conet.network/address/0xa208982212978550594A7FEEB70a61665d129003) | Sole Treasury: route policy, quorum, mint, burn, lock, release |
| **ConetTreasuryPeer** | [`0x6093871d8a3EE6EaADc9869451D1693973cFBCC0`](https://mainnet.conet.network/address/0x6093871d8a3EE6EaADc9869451D1693973cFBCC0) | Peer module — **not** a second Treasury |
| **conet-USDC** | [`0x5209865D404aA5646eDe5B91CD4218909eA72eDA`](https://mainnet.conet.network/token/0x5209865D404aA5646eDe5B91CD4218909eA72eDA) | Canonical six-decimal settlement asset |
| **GBToken (`GB`)** | [`0xC3EF02DaE632b4C10abB66e07d92a387c10838D8`](https://mainnet.conet.network/token/0xC3EF02DaE632b4C10abB66e07d92a387c10838D8) | Canonical nine-decimal DePIN service asset |
| **Base USDC** | [`0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`](https://basescan.org/token/0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913) | Current source-chain USDC for LockMint product paths |

Older `CREATE2` / `BaseTreasury` / `ConetTreasury` addresses (including `0xa311…`) are **deprecated**. Do not document them as a second live Treasury.

The current counterpart chain is **Base (`chainId` 8453)** on this **same** V3 proxy. That is a governed CoNET ↔ Base route, not a permissionless bridge.

## Two developer jobs

| Job | What “done” means |
| --- | --- |
| **Use an enabled route** | A user or application locks or burns on the source chain; miners attest; CoNET mints or releases the **configured** canonical token |
| **Admit a new ERC-20** | Governance enables a new route (mode, decimals, authorities, replay domain). Until that exists, do not send the token |

```text
ERC-20 on a supported external chain
        │  enabled Treasury route + miner quorum
        ▼
Treasury-canonical ERC-20 on CoNET L1
        │  wallets, Explorer, applications use this address
        │
        └── optional later DLE admission  ← not live
```

## How an enabled route works

```text
user-authorized source operation
        │
        ▼
configured Treasury route
        │  one operationId-bound payload
        ▼
independent source observation
        │
        ▼
destination miner votes
        │  threshold = ceil(2N / 3)
        ▼
execute exactly once
        ├── mint configured destination asset
        └── or release configured reserve
```

| Mode | Source | Destination | Typical use |
| --- | --- | --- | --- |
| **LockMint** | Lock source asset in Treasury custody | Mint the CoNET representation | Foreign assets the bridge cannot burn (current Base USDC path) |
| **BurnMint** | Burn an authorized source representation | Mint the destination representation | Canonical assets whose source supply can shrink |
| **BurnRelease** | Burn the destination representation | Release previously locked source assets | Reverse of LockMint |

The destination contract rejects a disabled route, conflicting payloads, duplicate miner votes, failed quorum, beneficiary sums that do not match the gross amount, and a replayed `operationId`.

These controls decentralize **authorization** across the configured miner set. They do not prove operator independence, source-chain finality, or that upgrade keys cannot be compromised.

The proposed AAC route replaces this per-deposit vote only after the destination chain can verify both inclusion and source finality. A Merkle path against a relayer-supplied header is insufficient. Until an audited Base adapter, CONET adapter, asset adapters, and cutover exist, applications must continue using the enabled Treasury V3 route above.

## Use a current product path (Base USDC)

Current public product paths use **pre-registered** assets. The live example is Base USDC → **conet-USDC** via **LockMint** on Treasury V3.

Application wallets (for example Beamio) submit the user-authorized source lock through the existing relay. This book does not invent a second public mint API. Integrate against:

- the **proxy address** above (read `treasury()` / route state from chain, do not hard-code a deprecated treasury);
- CoNET RPC `https://rpc1.conet.network` (backup `https://publicrpc.conet.network`);
- Base RPC `https://base-rpc.conet.network` for the source lock;
- Explorer `https://mainnet.conet.network` for the canonical token.

After a successful destination execution, balances live on the **CoNET** ERC-20 (`conet-USDC` or the route’s configured token). Do not display the Base contract as the CoNET balance.

## Beamio social exchange settlement

Beamio issued-NFT social exchange uses the same canonical CoNET-USDC asset.
For `socialExchange.kind = "usdc"`, the user's signed claim burns Reward PT
`#13` from the user's AA, debits the merchant card's `escrowUsdc6`, and pays
the canonical CoNET-USDC reward to the user's **EOA**. It is not an AA payout.

Use the six-decimal token
[`0x5209865D404aA5646eDe5B91CD4218909eA72eDA`](https://mainnet.conet.network/token/0x5209865D404aA5646eDe5B91CD4218909eA72eDA)
and the sole active TreasuryBridgeV3 proxy
[`0xa208982212978550594A7FEEB70a61665d129003`](https://mainnet.conet.network/address/0xa208982212978550594A7FEEB70a61665d129003).
The former USDC factory address
`0xfD0D7B0706AaB5E4351bcED37bC3C77ed6813907` is deprecated. Burn, escrow
debit, and payout are one atomic operation; any failed leg reverts the claim.

## Admit a new ERC-20 (policy, not a send)

“Bridge any ERC-20 to CoNET” is **not** a supported operation until all of the following exist:

1. **Source identity** — exact `chainId`, token contract, decimals, and finality depth.
2. **Custody mode** — `LockMint`, `BurnMint`, and any reverse `BurnRelease`, conserving exact raw units.
3. **Canonical CoNET representation** — a stable CoNET token with bounded mint/burn roles.
4. **Treasury policy** — the exact route and version enabled by the configured owner / governance path.
5. **Replay domain** — unique `operationId`, nonce, source transaction hash, destination execution flag.
6. **Relayer and miner availability** — enough independent observers to reach `ceil(2N / 3)`.
7. **Exit capacity** — locked reserves or replacement-capacity accounting.
8. **Application admission** — wallets, Explorer, and indexers recognize the **CoNET** address.

Until those are met, a developer should **not** tell users to transfer a foreign token to the Treasury and expect a mint.

## Read the live quorum

Treasury miners are **not** the Guardian owner list.

```bash
RPC=https://rpc1.conet.network
T=0xa208982212978550594A7FEEB70a61665d129003

cast call $T "miners()(address[])" --rpc-url $RPC
cast call $T "requiredVotes()(uint256)" --rpc-url $RPC
cast call $T "owner()(address)" --rpc-url $RPC
```

A reproduced snapshot (re-read for a current figure) is in [L1 decentralization](../l1/decentralization.md): four miner addresses, quorum **3**, and `owner()` equal to one miner.

```ts
import { ethers } from 'ethers'

const CONET_RPC = 'https://rpc1.conet.network'
const TREASURY = '0xa208982212978550594A7FEEB70a61665d129003'

const abi = [
  'function miners() view returns (address[])',
  'function requiredVotes() view returns (uint256)',
  'function owner() view returns (address)',
]

export async function readTreasuryQuorum() {
  const c = new ethers.Contract(TREASURY, abi, new ethers.JsonRpcProvider(CONET_RPC))
  const [miners, requiredVotes, owner] = await Promise.all([
    c.miners(),
    c.requiredVotes(),
    c.owner(),
  ])
  return { miners, requiredVotes: Number(requiredVotes), owner }
}
```

Confirm `eth_chainId` is `0x36ca6` before treating the result as CoNET L1. A failed RPC is untrusted: keep the last successful read.

## After CoNET L1: DLE is a second machine

A successful Treasury mint does **not** create a DLE asset tip, activate L2 backing, or pass pool / TWAP / gateway gates.

```text
canonical ERC-20 on CoNET L1
        │
        ├── usable by enabled L1 applications today
        │
        └── future DLE admission + burn/activation
                 │ AssetAdmissionRegistry = ACTIVE
                 │ approved pool + TWAP adapter
                 │ AssetBurnMintGateway safety gates
                 ▼
          parallel DLE asset tips
```

That second transition is specified, not deployed. See [L2 development](l2.md) and [Cross-chain assets in DLE](../l2/cross-chain-assets.md).

## Related

- [Decentralized cross-chain Treasury](../l1/cross-chain-treasury.md)
- [AAC proof-driven cross-chain settlement](../l1/aac-cross-chain.md) — production read-only Shadow, not a production custody API
- [Core L1 assets](../l1/assets.md)
- [RPC and Explorer](../l1/rpc-explorer.md)
- [Miner-matched order-book exchange](../applications/miner-orderbook-dex.md) — design study on top of canonical assets

## Next

[L2 development →](l2.md)
