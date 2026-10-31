# L1 overlay lab — wallet-addressed geth / Prysm

> **Removed from CoNET-SI (2026-10-31).** The exclusive L0 attachment primitives this page relies on (`l0_listen`, `l0_connect`, `mining` with `listenKind: "l0"`, and idle-L0 delivery of mailbox work) are no longer implemented by SI; `l0_listen` / `l0_connect` close the connection. The rest of this page is kept as a historical reference and does not describe current network behavior.

**Evidence level: laboratory review (2026-08-24).** This page records a
read-only evaluation of two **non-production** spokes that run unmodified
geth and Prysm behind [`conet-l0d`](conet-l0d.md). It is **not** the public
L1 join path, **not** a claim that production validators have moved off
public `IP:port` peering, and **not** a new SI command family.

The design under test is:

```text
remote identity = wallet + logical port
  → web3://0x…:8400 | web3://0x…:4200
  → conet-l0d client_duplex / proxy_duplex
  → 127.0.0.1:<bound port>
  → unmodified geth / Prysm
```

Layer Minus carries encrypted duplex frames. geth still names an EL peer
with an `enode://` public key. Prysm still names a CL peer with a libp2p
peer ID. Those application identifiers stay. The **durable remote** that
`conet-l0d` dials or accepts is a **billing / channel EOA**, not a public
host address.

Public operators continue to use [Run an L1 node](l1-node.md).

## Verdict

| Host | Role in this lab | Wallet-addressed overlay | Unmodified clients on loopback | Notes |
|---|---|---|---|---|
| Spoke `.98` | Client toward `.82` and toward `.45` | **Meets the lab design** | **Yes** | Dials two wallets; geth/beacon have **no** public P2P sockets |
| Spoke `.45` | **Client + published wallet host** | **Meets the lab design** | **Yes** | Outbound only to `.82`; inbound `proxy_duplex` accepts **any** client that targets `.45` billing |
| Hub `.82` | Production L1 + L0d proxy | **Dual-stack** | No — still public `:8400` / `:4200` | Expected for a live validator host; not an L0d-only spoke |

**`.45` dual role is the design, not a compromise.** The host is:

1. a **client** that joins `.82`'s wallet-addressed network
   (`web3://0x66dCB48f…:8400` / `:4200`); and
2. a **published wallet** (`0xEF107528…`) that any conforming client may
   dial. The host does **not** pre-list those clients and does **not**
   dial them back.

`.98` is one such client. A future third client would use the same
`web3://0xEF107528…:port` locator. Requiring `.45` to add a
`client_duplex` row for every inbound peer would invert that model.

**Overall:** both spokes peer by wallet locator; remaining operational
limits are SI listen-pool capacity and the hub still advertising public
L1 P2P — not a return to IP-first identity on the spokes.

## Identity map (do not treat as a production roster)

| Host | Billing EOA (duplex signer / `client_duplex` target) | Channel `:8400` routing EOA | Channel `:4200` routing EOA |
|---|---|---|---|
| `.82` hub | `0x66dCB48ff905f5f5f3692f302da0A84e0265A792` | `0x66dCB48ff905f5f5f3692f302da0A84e0265A792` | `0x3048925d768694D4b95524DFB71b38e812D705Dd` |
| `.45` spoke | `0xEF10752843cAC32C73DAb86658B8ab6E5667199B` | `0xEF10752843cAC32C73DAb86658B8ab6E5667199B` | `0x3F84B8f11BF7886DCf0c902A3148cc2926E185dA` |
| `.98` spoke | `0x72c240E4e35caF9822E6B71BBB816db83E1534a5` | `0x8a2b04C82B43447b69946b31BCCEa14ed29471f4` | `0x2Ae19d1f39445fFa218F540cdD6BDCAfBD68ca7b` |

This matches the documented wallet split in
[`conet-l0d` — Wallet and key roles](conet-l0d.md#wallet-and-key-roles) and
[wallet-addressed peer identity](../l0/wallet-address-p2p.md):

- **billing EOA** signs the duplex offer / is the `web3://` host in
  `client_duplex`;
- **per-port routing EOA** owns AddressPGP listen for that logical port
  (`[[l0.channels]]`);
- **temporary line wallets** are process-memory identities for one occupied
  pipe (examples on `.98`: `0xc8b1ae25…`, `0x60c12814…`).

`.98` is the fuller split (billing ≠ geth routing ≠ beacon routing). `.45`
reuses the billing wallet on `:8400` and still isolates beacon on
`0x3F84B8f1…`.

## How the spokes actually connect

### `.98` — full wallet mesh (outbound)

`l0.client_duplex` at the snapshot:

```text
web3://0x66dCB48ff905f5f5f3692f302da0A84e0265A792:8400@18400
web3://0x66dCB48ff905f5f5f3692f302da0A84e0265A792:4200@14200
web3://0xEF10752843cAC32C73DAb86658B8ab6E5667199B:8400@18401
web3://0xEF10752843cAC32C73DAb86658B8ab6E5667199B:4200@14201
```

The `@LOCAL` suffix is a Linux bind pin only. It is not part of the public
`web3://` locator. geth bootnodes and Prysm `--peer` use those loopback
ports:

| Client | Remote | Loopback target |
|---|---|---|
| geth | hub `.82` | `127.0.0.1:18400` |
| geth | spoke `.45` | `127.0.0.1:18401` |
| Prysm | hub `.82` | `/ip4/127.0.0.1/tcp/14200/p2p/16Uiu2HAmDJCHuVkXtkPrrL8YykQ9gFZnQkR9Q6WjZZUrmueohPfd` |
| Prysm | spoke `.45` | `/ip4/127.0.0.1/tcp/14201/p2p/16Uiu2HAkxjzYKtKJZc9E7pMTa3LzB9XHdHoDBaRHymQgtofmbKUA` |

Observed **2026-08-24T12:25Z–12:30Z UTC**:

- `admin_peers` = **2**, both `127.0.0.1:18400` and `127.0.0.1:18401`;
- beacon `connected` = **2**;
- geth/beacon established sockets were **loopback only**;
- L0d log: `l0_connect HTTP 200; pipe_tx installed` and
  `duplex_offer complete` for ports `8400` and `4200`;
- hub log allocated proxy lines with **`billing_wallet=0x72c240e4…`** (the
  `.98` billing EOA), not a public IP.

geth flags that enforce the overlay: `--nat none --netrestrict 127.0.0.0/8`.
Prysm flags: `--no-discovery --p2p-local-ip=127.0.0.1`.

### `.45` — client of `.82`, server for any wallet client

Intended roles on one process:

| Direction | Config | Remote identity |
|---|---|---|
| Outbound client | `l0.client_duplex` | Only `.82` billing `0x66dCB48f…` on `:8400` / `:4200` |
| Inbound host | `[[l0.proxy_duplex]]` on loopback `:8400` / `:4200` | Callers target `.45` billing `0xEF107528…`; callers are **not** pre-listed |

`l0.client_duplex` at the snapshot:

```text
web3://0x66dCB48ff905f5f5f3692f302da0A84e0265A792:8400@18400
web3://0x66dCB48ff905f5f5f3692f302da0A84e0265A792:4200@14200
```

There is **no** `.45` → `.98` `client_duplex` or `[[peers]]` row. That is
correct. `.98` (or any later client) reaches `.45` by dialing
`web3://0xEF10752843cAC32C73DAb86658B8ab6E5667199B:8400` /
`:4200`. The offer is authorized as a signed `mainWallet:port` event, not
by a static peer roster.

Observed **2026-08-24** (rechecked after the dual-role clarification):

- geth peers: outbound `127.0.0.1:18400` (client → `.82`) **and** inbound
  `127.0.0.1:44776` (accepted wallet line; `.98` in this lab);
- beacon `connected` = **2** (client → `.82` on `14200`, plus inbound on
  local `:4200`);
- no geth/beacon sockets to a public hub `:8400` / `:4200`;
- L0d: `pipe_tx installed` / `duplex_offer complete` on `:8400` and `:4200`.

## Checklist against the written design

| Design rule | Source | `.45` | `.98` |
|---|---|---|---|
| Remote is `web3://0x…:port`, not `IP:port` | [Locator](conet-l0d.md#locator), [duplex lifecycle](../l0/duplex-forward.md) | Pass (client → `.82`; host accepts by own billing) | Pass (client → `.82` and `.45`) |
| Client of a published wallet | `client_duplex` | Pass (only `.82`) | Pass (`.82` + `.45`) |
| Published wallet any client may dial | `[[l0.proxy_duplex]]` | **Pass** (does not roster inbound peers) | Pass (also publishes loopback origins) |
| One communication identity per logical port | `[[l0.channels]]` | Pass | Pass |
| Temporary identity per accepted line | Persistent-stream bootstrap | Pass (`listen-ready` temp wallets) | Pass |
| Origin service stays on loopback | Server / client profile | Pass | Pass |
| Unmodified geth / Prysm | This lab thesis | Pass | Pass |
| No public EL/CL P2P from the spoke process | Lab intent | Pass at snapshot | Pass at snapshot |

## Sync status (do not confuse with overlay correctness)

Overlay success is **wallet duplex + loopback peers**. Tip height is a
separate catch-up problem.

| Host | EL `eth_blockNumber` | CL `head_slot` / `sync_distance` | Hub tip (same window) |
|---|---|---|---|
| `.98` | `0x0` (importing potential segments; `eth_syncing` still reports start `0x0`) | `1215` / `1031840`, `is_syncing=true` | EL `0xef37e`, CL slot `1033055`, `is_syncing=false` |
| `.45` | `0x0` | `23519` / `1009536`, `is_syncing=true`, `is_optimistic=true` | same |

Both spokes were **behind** the canonical tip. That does **not** undo the
wallet-addressed transport. It does mean they are not yet production-quality
full nodes.

## Gaps that are still real

1. **SI listen pool.** Temporary-identity pre-warm and inbound `duplex_offer`
   fail with `{"ok":false,"error":"pool_full"}` when Guardian `l0_listen`
   slots are exhausted. Restarting the hub process freed slots in this lab.
   Capacity is an L0 operational limit, not an IP-identity fallback. Current
   L0d cools a failing SI host and random-picks another from the
   GuardianNodesInfoV6 contract pool (`si_pool_from_contract`); see
   [SI entry discovery](conet-l0d.md#si-entry-discovery-guardiannodesinfov6).
2. **Hub dual-stack.** `.82` still listens on public `:8400` / `:4200` for
   the production L1 set. Its `proxy_duplex` for `:4200` was bound to the
   public address. Spokes must keep `--netrestrict 127.0.0.0/8` and must not
   add those public ports as geth bootnodes or Prysm `--peer`.
3. **Host firewall is not the identity model.** `.98` additionally rejects
   egress TCP to hub/spoke `:8400` / `:4200`. That is a safety net. The
   contract remains the wallet locator.
4. **AES decrypt refusals** appeared on `.98` during early offers (stale
   armor / wrong key set). Later sessions completed with `pipe_tx`
   installed. Treat decrypt failure as fail-closed, not as a reason to open
   public P2P.

Do **not** treat “`.45` has no `client_duplex` toward `.98`” as a defect.
Inbound authorization is the signed offer to `.45` billing
`0xEF107528…`, not a reverse dial.

## What this is not

- Not a replacement for the six-host public L1 roster in
  [Run an L1 node](l1-node.md).
- Not evidence that Beacon validators on `.45` / `.98` are in service.
  Those hosts are **not** on the current production L1 voting set.
- Not a claim that Layer Minus hides the spoke IP from the selected Guardian
  entry. L0d still posts to existing entry hosts over HTTP.
- Not a new SI `duplex_*` command. Offer/accept remain encrypted application
  objects; SI only provides `l0_listen` / `l0_connect`.

## Related

- [Linux `conet-l0d` runtime](conet-l0d.md)
- [Persistent application streams](../l0/duplex-forward.md)
- [Wallet-addressed peer identity](../l0/wallet-address-p2p.md)
- [Run an L1 node](l1-node.md)
