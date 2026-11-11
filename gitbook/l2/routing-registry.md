# Global Archive Routing Registry

**Evidence level: Production reference** for the CoNET L1 routing facade and the public explorer display. This page is **not** evidence that Archive Certificate, tip execution, asset ingress, or 30-day lab qualification are live.

Whitepaper §5.2.0d requires a CoNET L1 registry of every live archive group, every participating archive **wallet**, and every hosted chain NFT id. That facade is deployed and Explorer-verified.

Public UI: paused (it was the DLE explorer and its Archives page). Digest of the lab explorer: [DLE explorer](explorer.md).

Do **not** write the explorer hostname into Solidity. The registry stores wallets, uint `groupId` keys, and NFT ids. The user-visible Group ID is this group’s L1 register tx hash.

## Network facts

Observed and verified **2026-08-14**. Canonical address is the **UUPS proxy**.

| Field | Canonical value |
| --- | --- |
| Routing registry | [`0x8B261eAECdFfeE9e7aC9fFe73386B0d6C9E76AfB`](https://mainnet.conet.network/address/0x8B261eAECdFfeE9e7aC9fFe73386B0d6C9E76AfB#code) |
| Implementation | [`0x65691CFc82D55eFbe03cE91f6Ab6109b6c73ab9d`](https://mainnet.conet.network/address/0x65691CFc82D55eFbe03cE91f6Ab6109b6c73ab9d#code) |
| L1 `chainId` | **224422** (`0x36ca6`) |
| EIP-155 Chain ID (CoNET-DLE Testnet) | **281669** (`0x44c45`) — not stored on this registry |
| User-visible Group ID | this group’s **register tx** (below) |
| L1 uint `groupId` (storage key) | bootstrap **1** |
| Registry read RPC | `https://rpc1.conet.network` |
| Backup RPC | `https://publicrpc.conet.network` |
| L1 Explorer | `https://mainnet.conet.network` |
| DLE explorer | Paused |
| Archives | Paused |
| Proxy name on Explorer | `DLEERC1967Proxy` (`is_verified` and `is_partially_verified`) |
| Implementation name | `GlobalArchiveRoutingRegistryV1` (`is_verified` and `is_partially_verified`) |
| Deploy / bootstrap block | `840617` |
| Owner | `0x87cA…05E1` |
| Bootstrap group | `groupId = 1`, `membershipEpoch = 1`, `keyEpoch = 1` |
| Register tx | [`0x3076a806de71ab75b2d48063cc3f1e7d8f8e3d54cb1d45a7469c75c9276f2ad0`](https://mainnet.conet.network/tx/0x3076a806de71ab75b2d48063cc3f1e7d8f8e3d54cb1d45a7469c75c9276f2ad0) |

Read this contract on `https://rpc1.conet.network` or `https://publicrpc.conet.network`. Do not use deprecated `https://rpc.conet.network`.

## What is live versus what is not

| Live | Not implied |
| --- | --- |
| L1 registry proxy + verified implementation | Full DLE tip production |
| Bootstrap `groupId = 1` with seven distinct participant EOAs | Archive Certificate / AC finality |
| Explorer `/archives` shows each node’s participant wallet | 30-day qualification (`100` rotations / `30` re-homes / `100` takeovers remain `0`) |
| Clients may `eth_call` `liveGroupIds()` and `archivesOf(1)` | `OperatorDomainRegistryV1`, `AssetBurnMintGateway`, or a production tip RPC |

A wallet listed here is a **routing identity**. It is not a Guardian honesty proof and not a 30-day qualification claim.

## Required views (whitepaper §5.2.0d)

| View | Returns | Use |
| --- | --- | --- |
| `liveGroupIds()` | Live L1 uint keys (Solidity). Archive HTTP facade maps them to **Group ID hashes** | Enumerate groups |
| `archivesOf(groupId)` | Five active + two standby EOAs | Who belongs to that group. Solidity takes uint `1`; UI shows the register tx as Group ID |
| `chainsOf(groupId)` | Hosted chain NFT ids | Which tips this **group** hosts |
| `route(chainNftId)` | L1 uint on-chain; protocol facade returns the **Group ID hash** | Chain routing to a group — not EIP-155 |
| `historyProviders(chainNftId)` | `archivesOf(route(chainNftId))` | Authoritative history providers |

`route` and `historyProviders` revert `UnknownChain` until a chain NFT is bound. Bootstrap group `1` currently has a roster and **no** bound tip NFT.

To locate a bound tip: facade `route(nftId)` returns the **Group ID hash**, then contact `historyProviders(nftId)`. A wallet not listed for that group at the relevant membership epoch is not the canonical host.

## Bootstrap roster (`archivesOf(1)`)

Each archive **must** have its own participant wallet. The seven addresses below are distinct. Slot order is `archivesOf(1)[0]` … `[6]`.

| Slot | Lab `domainId` | Role | Participant wallet |
| --- | --- | --- | --- |
| 0 | `fd-01` | active | `0xB7D3…9d14` |
| 1 | `fd-02` | active | `0x6da4…e9B9` |
| 2 | `fd-03` | active | `0xf264…a626` |
| 3 | `fd-04` | active | `0x7C16…A026` |
| 4 | `fd-05` | active | `0x0248…7f7a` |
| 5 | `fd-06` | standby | `0xb259…fE7a` |
| 6 | `fd-07` | standby | `0xc97B…57a5` |

The Archives page renders these wallets as address capsules. The UI seeds from a local roster, then overlays a trusted `archivesOf(1)` read from CoNET L1 RPC. A failed RPC must not clear a previously trusted wallet.

Do not publish lab host IPs, SSH targets, or signing keys from this page.

## Read `archivesOf(1)`

```bash
curl -s https://rpc1.conet.network \
  -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":"0x8B261eAECdFfeE9e7aC9fFe73386B0d6C9E76AfB","data":"0xd3a448be0000000000000000000000000000000000000000000000000000000000000001"},"latest"]}'
```

Selector `archivesOf(uint64)` is `0xd3a448be`. The result is seven left-padded addresses in slot order. `liveGroupIds()` is `0x7e847d92`.

## Identifiers that must not be mixed

| Identifier | Value | Use |
| --- | --- | --- |
| CoNET L1 `chainId` | `224422` / `0x36ca6` | This registry lives here |
| EIP-155 Chain ID | CoNET-DLE Testnet `0x44c45` / `281669` | Wallets / `eth_chainId`. Not this registry’s storage key |
| User-visible Group ID | L1 register tx `0x3076a806…6f2ad0` | Distinguishes archive groups (whitepaper §5.2.0d) |
| L1 uint `groupId` | bootstrap `1` | Solidity storage key only |

## See also

- [DLE explorer](explorer.md) — paused
- [Archive plane](archive-plane.md) — production versus archive certification
- [CoNET L1 RPC and Explorer](../l1/rpc-explorer.md)
- [L2 development](../developers/l2.md)
