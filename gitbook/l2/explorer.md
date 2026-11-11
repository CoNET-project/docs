# DLE explorer

> **The DLE explorer is paused.** Its former address no longer serves it, and no replacement address has been published. This page is kept as a description of what the explorer showed.

This page was the **production reference for the public DLE explorer UI**. It is **not** a production reference for DLE consensus, Archive Certificate, or tip execution. CoNET L1 routing wallets are documented on [Global Archive Routing Registry](routing-registry.md).

The explorer is a read-only inspection surface for the isolated 30-day DLE Archive lab. It does not produce blocks, does not execute `eth_call`, and does not mint or burn assets.

## Network facts

| Field | Canonical value |
| --- | --- |
| Explorer | Paused |
| Archives | Paused |
| Lab health | Paused |
| Lab RPC | Paused |
| EIP-155 Chain ID (CoNET-DLE Testnet) | **281669** (`0x44c45`) |
| User-visible Group ID (first group) | L1 bootstrap register tx `0x3076a806…6f2ad0` |
| Lab M6 second Group ID | L1 `registerLiveGroup` tx `0xf781f2c2…876d5153`. Laboratory keccak `0x7b3b8eb9…7f9b1a07` aliases it. |
| L1 uint `groupId` (storage key) | bootstrap **1**; G2 **2** (storage keys only) |
| Product name | CoNET-DLE Explorer |
| Source | [CoNET-project/CoNET-DLE `explorer/`](https://github.com/CoNET-project/CoNET-DLE/tree/main/explorer) |
| Same-origin backends | `GET /health`, `POST /rpc`, `GET /api/v2/dle` |
| Lab agent | `dle-30d-lab` (first group). Second group is `dle-m6-g2` and is not the public nginx upstream. |
| Lab runtime | Node.js Archive process, `command: archive` |
| Observed 2026-08-16 | `/health` `ok: true`; **`liveGroupCount`: 2**; Home metric **Clusters** = 2 (not Tip height). Hosts emit the G2 L1 register tx as `hop1.ownGroupId` / `liveGroupIds`. Second Group ID **does** open Blockscout `/tx/`. Laboratory keccak remains an alias only. 2026-08-17 review: repository P12–P22 EIP-712 is engine + tests; **P23** keep-deploy evidence is **6/7 `LIVE_OK`** plus fd-01 409→accept; fd-06 HTTP is unstable. Do **not** claim 7/7 healthy. Green pills stay `seatingQualified === true` only. **2026-08-18:** clock started `2026-08-18T09:53:58.092Z`; public SPA `index-C8IdTq4H.js`; Home + Certificates show a **non-green** clock chip; `pilotQualified=false`. Clock ≠ qualification. **Latest runtime scrape 2026-08-20T07:43:59Z (~45.8h):** official 7/7 HTTP + clock-aligned + seating `QUALIFIED`; official `lastQuorumOk` 6/7 because active fd-05 reported `peer=1`; extra fd-08 is excluded from official counts and was also quorum false. `pilotQualified` remains false; omitted leaf/ready ≠ zero. See [Lab honesty track](lab-honesty-track.md). |

This hostname is an authorized CoNET path. Do **not** invent additional `dle.*` hostnames, and do **not** write explorer hostnames into Solidity constants. Production routing truth is the deployed L1 [Global Archive Routing Registry](routing-registry.md), not this URL.

## What the explorer is

The explorer answers one question: **what is the isolated Archive lab reporting right now?**

It shows:

- whether the proxied Archive process is healthy
- whether that process produces blocks or has a tip VM (**both are false**)
- CoNET-DLE Testnet `eth_chainId` (`0x44c45`) and the bootstrap **Group ID** (L1 register tx) as a hash capsule
- **Clusters** (\(G_e\)): live archive groups. Lab M6 fission shows **2**. The second Group ID is the G2 L1 `registerLiveGroup` transaction `0xf781f2c2…876d5153`
- heartbeat / health events
- fixture Archive rows used by the UI
- each Archive’s **participant wallet** (local seed, then a trusted L1 `archivesOf` overlay)
- first-group laboratory networked Archive Certificate status (not a production AC)

It does **not** show:

- a launched DLE tip chain
- production Archive Certificate / L1 wrapper / 30-day qualification
- Treasury lock / mint / burn
- Guardian listing as an honesty proof
- raw lab host inventories as a public API

The Archives page **does** display CoNET L1 `224422` participant wallets for the bootstrap group. That is routing identity, not tip state and not 30-day qualification.

## Pages

These public HTML routes returned `200` on 2026-08-14:

| Path | Role |
| --- | --- |
| `/` | Home: health, CoNET-DLE Testnet chain id `0x44c45` plus **Group ID** capsule (first-group bootstrap register tx; opens Blockscout `/tx/…`; no “Decimal 281,669. Not CoNET L1 224422.” hint), **Clusters** (\(G_e\); lab M6 = 2; second Group ID capsule is the G2 L1 register tx and **does** open `/tx/`), certificate status. No Tip height panel |
| `/events` | Heartbeat and health events from `/api/v2/dle/events` |
| `/archives` | 5+2 lab roster; each row has a distinct participant wallet (AddressCapsule). L1 `archivesOf(1)` is the trusted overlay |
| `/certificates` | NFT 42 lab AC (may be available) **and** P6 new-chain counts from `/health` (`newchainCount` / `newchainArchivePending` / `newchainArchiveCertified` / `newchainValidatorQuorum: 5`). Per-chain AC never writes NFT 42. Not an L1 birth certificate. |
| `/hash/:hash` | Hash lookup. Lab M7: `tipStateRoot` / `membershipRoot` hits show **Tip state root** / **Membership root** pills and a typed object, not the Archive Certificate. |

The explorer SPA source also defines `/events/:eventId`, `/archives/:domainId`, and a JSON-RPC probe page at `/rpc`. On the public host, **`POST /rpc` is the Archive JSON-RPC facade**. Do not treat a browser `GET /rpc` as a documented HTML page.

## Same-origin API

The UI talks only to its own origin. nginx proxies those paths to the lab Archive listener. Clients should use the hostname, not unpublished lab IPs.

### `GET /health`

Observed shape on 2026-08-14:

```json
{
  "ok": true,
  "command": "archive",
  "runtime": "nodejs",
  "producesBlocks": false,
  "hasTipVm": false,
  "chainId": 281669,
  "chainIdHex": "0x44c45",
  "chainName": "CoNET-DLE Testnet",
  "port": 27101,
  "agent": "dle-30d-lab",
  "isolatedFromElCl": true,
  "lastQuorumOk": true,
  "lastPeerOk": 6,
  "liveGroupCount": 2,
  "liveGroupIds": [
    "0x3076a806de71ab75b2d48063cc3f1e7d8f8e3d54cb1d45a7469c75c9276f2ad0",
    "0xf781f2c23fe3b3dac09dc3e1929016b0af200ee93978e916df64d750876d5153"
  ]
}
```

Read this as **lab process health**, not BFT quorum and not Archive Certificate.

### `GET /api/v2/dle`

Schema `DleExplorerApiV1`. The Home page uses **`liveGroupCount` / `liveGroupIds`** for the **Clusters** card (not tip height), plus certificate availability and the allowed JSON-RPC method list. Tip **hash** may still appear as a capsule.

Observed 2026-08-16:

- `liveGroupCount`: `2` (lab M6 fission; **not** 30-day qualification)
- `liveGroupIds`: `[first-group L1 register tx hash, G2 L1 register tx hash]`. Hosts emit those two txs. Explorer `canonicalGroupId` still aliases leftover laboratory keccak `0x7b3b8eb9…7f9b1a07` to `0xf781f2c2…876d5153` and Home **does** link that capsule to Blockscout `/tx/`.
- Legacy lab nodes may still emit `dle.lab.group.v1`; Explorer canonicalizes that alias to the first-group hash so it does not count as a third cluster
- `tip.height` after AC is typically `"0x1"` and is **not** shown as a Home metric
- `certificate.available`: first-group lab networked AC may be true; still not 30-day qualification

Related reads:

| Path | Schema | Role |
| --- | --- | --- |
| `GET /api/v2/dle/events` | `DleExplorerEventsV1` | Recent heartbeat / health rows |
| `GET /api/v2/dle/certificate` | `DleExplorerCertificateV1` | Explicit empty-certificate document |

### `POST /rpc`

This is a **read-only DLE facade**, not an Ethereum execution RPC.

| Method | Observed 2026-08-14 | Meaning |
| --- | --- | --- |
| `dle_info` | Archive lab info; `producesBlocks: false`; `hasTipVm: false` | Process identity |
| `dle_tip` | Height `0x0`; `finalized: false` | No production tip |
| `dle_getArchiveCertificate` | `available: false` | Certificate not produced |
| `eth_chainId` | `"0x44c45"` | CoNET-DLE Testnet EIP-155 id |
| `eth_blockNumber` | `"0x0"` | No tip blocks |
| `eth_call` | `-32601` | Rejected: no tip VM |
| `eth_estimateGas` | rejected | No tip VM |
| `eth_sendRawTransaction` | rejected | No tip VM |

The explorer Home page states the same rule: DLE has no tip VM, so `eth_call`, `eth_estimateGas`, and `eth_sendRawTransaction` are rejected.

## Three identifiers that must not be mixed

| Identifier | Value | Use |
| --- | --- | --- |
| **CoNET L1 chain id** | `224422` / `0x36ca6` | CoNET L1 RPC, explorer, and contracts. See [RPC and explorer](../l1/rpc-explorer.md). |
| **EIP-155 Chain ID** | `0x44c45` / `281669` | CoNET-DLE Testnet. Wallets / `eth_chainId`. See [Archive plane](archive-plane.md). |
| **Group ID** (first group) | L1 register tx `0x3076a806…6f2ad0` | Distinguishes the genesis archive group. Home capsule under Chain ID. Click opens Blockscout `/tx/…`. |
| **Lab M6 Group ID** (second group) | L1 register tx `0xf781f2c2…876d5153` | Home **Group ID** capsule under Clusters. Click opens Blockscout `/tx/…`. Laboratory keccak aliases it. |
| **L1 uint `groupId`** | bootstrap `1`; G2 `2` | Solidity storage keys only. Not shown as Group ID. |

Do not configure a wallet, bridge, or dapp to `0x44c45` as if it were CoNET L1 or a launched DLE tip chain.

## Lab status the explorer does not upgrade

The public UI being live does **not** close these whitepaper / spec gates:

| Gate | Status |
| --- | --- |
| Isolated 7-host lab + explorer | Deployed; 72-hour warmup started 2026-08-14 |
| 7×7 `/health` mesh | Heartbeat quorum only; seating green pill only when `seatingQualified === true` |
| Participant wallets on `/archives` | Seven distinct EOAs; participant set derived from L1 `archivesOf(1)`. Extra `fd-08` is unofficial |
| Global Archive Routing Registry | Deployed and verified — [routing registry](routing-registry.md) |
| Laboratory honesty track P12–P25 | Engine + `159/159` tests. P23 keep-deploy **6/7 `LIVE_OK`** + fd-01 409→accept; later fd-06 remap / freeze / clock (not P26). P24 isolated `node.ts` standby gate. **P25 landed:** Certificates + Home **non-green** overlays; seating copy is **lab EIP-712**, never HMAC; green pills stay `seatingQualified === true` only. Current public SPA `index-C8IdTq4H.js` (2026-08-18T10:15:00Z; `explorer:test` 10/10). **Runtime scrape 2026-08-18T23:41Z (~13.8h):** 8/8 seating `QUALIFIED`; quorum 6/8; omit leaf ≠ empty — [Lab honesty track](lab-honesty-track.md) |
| 30-day qualification | Not qualified (`100` rotations / `30` re-homes / `100` takeovers still at `0`; clock started `2026-08-18T09:53:58.092Z`; `pilotQualified=false`; clock ≠ qualification) |
| Production Archive Certificate / OperatorDomain | Not claimed. First-group lab AC may exist; it is not a frozen L1 wrapper |
| `OperatorDomainRegistryV1` / `AssetBurnMintGateway` | Not deployed as production DLE machines |
| Dual TypeScript Archive A/B | Implemented in-repo; does **not** close the independent second-language production blocker |

## What not to do

- Do not treat the DLE explorer as Blockscout or as `mainnet.conet.network`.
- Do not send asset, swap, or UserOp traffic to `POST /rpc`.
- Do not publish lab host IPs, `billingRef` values, or SSH targets from explorer fixtures.
- Do not write an explorer hostname into contract constants.
- Do not treat `0x44c45` as CoNET L1 or as Group ID. Do not display L1 uint `1` as Group ID.

## See also

- [Layer 2 overview](README.md)
- [Global Archive Routing Registry](routing-registry.md)
- [Archive plane](archive-plane.md)
- [Design thesis](design-thesis.md)
- [CoNET L1 RPC and explorer](../l1/rpc-explorer.md)
- [Lab honesty track](lab-honesty-track.md)
- [Developer quick start: Layer 2](../developers/l2.md)
