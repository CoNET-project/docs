# X-CoNET-Hop-Sigs v1 canonical encoding

**Evidence level: Implemented capability** for the compact miner hop record in CoNET-SI `siHopSigs.ts`. **Protocol freeze** for the rules on this page. A richer `HopRecordV1` (message IDs, previous-hop hashes, expiry, hopIndex, maxHops) is **rejected**: the header exists to **meter DePIN traffic**, not to publish a reconstructable forward graph.

Public source: [CoNET-SI `siHopSigs.ts`](https://github.com/CoNET-project/CoNET-SI/blob/main/src/util/siHopSigs.ts).

## Why this header exists

`X-CoNET-Hop-Sigs` is the SI-to-SI credential that a **miner / Guardian node** signs when it forwards OpenPGP armor. The last hop that decrypts a **signed command** verifies those miner signatures and adds the signed byte counts to that **user wallet’s** GB meter.

It is **not**:

- a mix-net proof;
- an anti-replay store;
- a public itinerary of `messageId` / inner hashes / previous-hop hashes;
- something a client sets on the first `POST /post`.

A detailed forward JSON would let any path observer bind outer armor, inner armor, hop index, and node wallets into one object. That is a **privacy loss**. The protocol therefore freezes **miner signatures only**.

## Client POST versus SI-to-SI

| Hop | `X-CoNET-Hop-Sigs` | Body | If the outer OpenPGP key ID cannot be routed |
| --- | --- | --- | --- |
| **Client → entry A** | **Must be absent** | `{ "data": "<OpenPGP armor>" }` only | **404** — A does not accept unsigned junk or an unknown key |
| **A → B (and later SI hops)** | **Present** after A miner-signs | Same JSON `{ data }` over HTTP `:80` | Destination `end` / discard; do not invent a new route |

Entry A therefore:

1. accepts a headerless PGP body;
2. reads the outer `getEncryptionKeyIDs()`;
3. **404** if that key is not a routable node / mailbox binding;
4. if the key **is this node**, decrypts **once**;
5. if the plaintext is still OpenPGP for another key, or the outer key was already another node, **miner-signs the forwarded armor** and HTTP `:80` forwards to B.

B sees hop signatures because A created them. B never trusts a client-supplied hop header.

Live SI `main` still forwards a headerless non-local outer key when AddressPGP / Guardian lookup succeeds (one-layer Chat). When lookup fails it answers HTTP 200 with `{"ok": false, "error": "no_route"}` (since 2 November 2026), which clients treat as a clear failure. The **frozen** miss is **404**.

## Nested PGP (one peel per node)

```text
POST { data: PGP }          // no hop header on the client
  → read outer key ID
      ├─ not a routable node     → 404
      ├─ not this node           → miner-sign + forward same armor to its mailbox
      └─ this node               → decrypt once
            ├─ still OpenPGP and inner key == this node  → end (attack)
            ├─ still OpenPGP and hop signatures already 3 → end / discard
            ├─ still OpenPGP and inner key ≠ this node   → miner-sign + forward inner armor
            ├─ still OpenPGP and this node is the mailbox → store / SSE to the listener
            ├─ mailbox-work JSON { data, NoPush? }       → unwrap inner armor; NoPush skips APNs
            └─ plaintext JSON { message, signMessage }   → checkSign + run the API command
```

API commands after a local decrypt include listen, presence, ACK, UDP relay, SilentPass / SOCKS proxy, and other route-key work (egress, storage, or a WASM / container request). Those objects are **inside** the PGP layer A or B can open. Intermediate hops still see only armor and the compact hop header.

Mailbox work `{ data, NoPush? }` is a third peel result: B unwraps the inner user-PGP armor and may skip APNs. It is **not** a signed `{ message, signMessage }` command and **must not** appear as an HTTP sibling field. See [mailbox routing](mailbox-routing.md#mailbox-work-envelope-b-decrypts-a-delivery-instruction).

## Canonical hop record (do not extend)

Domain separator: `conet.l0.hop.v1`

```text
SiHopSig {
  w   miner EOA that signed this hop
  t   unix seconds
  n   meteredBytes = UTF-8 byte length of the forwarded armor
  h   keccak256(utf8(armor))
  k   next OpenPGP key ID (uppercase hex)
  s   EIP-191 personal_sign(payload)
}
```

Signed payload (exact join, lowercase `w` and `h`, uppercase `k`):

```text
conet.l0.hop.v1|{w}|{t}|{n}|{h}|{k}
```

`s = wallet.signMessage(payload)`. Recovered address must equal `w`.

### Header encoding

| Item | Frozen value |
| --- | --- |
| Header name | `X-CoNET-Hop-Sigs` |
| Header value | `base64(utf8(JSON.stringify(SiHopSig[])))` |
| Parse | Base64 JSON array, or a raw JSON array starting with `[` |
| Max records | **3** |
| Timestamp window | `abs(now - t) ≤ 600` seconds |
| Armor hash | `keccak256(utf8(armor))` — same rule as mailbox `armorHash` |
| Metered bytes | `n` on each **verified** hop; last command hop sums `n` onto `command.walletAddress` |
| Header size | One HTTP header line carrying at most three compact records. Reject an unparsable or oversized value as invalid. Do not add extra JSON fields. |

Clients **must not** send this header. SI appends it only when forwarding to another SI.

## Signature scheme

```text
sig_i = Sign_{Node_i}( domainSeparator ∥ compact SiHopSig without s )
```

Verification is EIP-191 recover. Invalid `s`, a clock skew outside ±600 s, a missing field, or a non-address `w` makes the **whole header** an attack: emit socket `end`.

Last-hop GB credit uses **verified** hops only (`verifyHopSig`). Unverified rows do not add bytes.

## What is intentionally not signed

The following fields are **out of scope** for v1. Do not add them to the header to “strengthen” the hop:

| Rejected field | Why it is omitted |
| --- | --- |
| `messageId` / `nonce` | Application identity. Putting it on every hop publishes a join key |
| `outerArmorHash` + `innerArmorHash` | Binds two layers in one public object |
| `previousHopHash` / `hopIndex` / `maxHops` | Reconstructs the path; `maxHops` is already the array length cap **3** |
| `expiry` beyond `t ± 600` | Extra clock field without a consumed-nonce store |
| `recipientWallet` / `applicationId` | Not required to meter forwarded bytes |

Replay, payment consumption, and POS authorization are **application** duties. See [security limits](security-limits.md).

## Loop protection (why a path JSON is unnecessary)

A loop that never reaches a valid recipient inside **3** miner signatures is **discarded**. That makes `A → D → A` or `A → D → E → D` useless as a delivery or metering attack: the packet dies, and no extra hop JSON is published.

Independent checks already on the node:

| Check | Action |
| --- | --- |
| After one local decrypt, inner key ID **equals this node** | `end` — adjacent loop / peel attack |
| Incoming hop count **> 3** | `end` |
| Another forward would make count **≥ 3** (cannot append) | `end` — never a fourth miner signature |
| This node’s miner wallet **already appears** in `w[]` | refuse append (`end`) |
| Header missing, unparsable, or fails recover | `end` |
| Forward armor is not UTF-8 text (OpenPGP.js 6 `armor()` stream / thenable) | **404** — coerce with `pgpArmorToUtf8String` first; prefer peel plaintext |
| Hop-sign throws after a successful peel | **404** / socket `end` — a log-only `uncaughtException` must not leave the client SSE open |
| C→B TCP connect exceeds ~8s | **404** |
| Hop count exhausted before a valid recipient | **discard** |

There is **one** hop budget: **`maxHops = 3` miner signatures**. Do not maintain a second counter (`maxPeels` versus `maxForwardHops`). Peel and forward share the same header length.

`ERR_ROUTE_LOOP` in this protocol means: same-node inner PGP, or this miner wallet already signed a hop on this header. It does **not** require a public list of every previous hop hash.

## Last-hop verification and GB

Only the hop that decrypts a signed `{ message, signMessage }` command and passes `checkSign` meters GB:

1. Parse and verify hop signatures (window + EIP-191).
2. Sum `n` on verified rows.
3. Add that sum to `transferCount[command.walletAddress]` — that EOA is the **routing** wallet. An app may use a different sender / recipient EOA inside user-PGP business armor.
4. Run the command (listen, proxy, storage, WASM / container, and so on).

A mailbox **store** of user-PGP business armor (no command decrypt) does **not** charge the user from this header. Forwarding miners are paid for carrying ciphertext, not for reading it.

## Failure codes

Documentary names. HTTP/socket behavior is what clients observe.

| Code | When | Client / previous hop sees |
| --- | --- | --- |
| `ERR_NOT_PGP` | Body is not OpenPGP armor | **404** (`body has not PGP message`) |
| `ERR_OUTER_KEY_UNROUTABLE` | Headerless POST; outer key ID is not a node / mailbox route | **404** (frozen; live SI answers 200 `{"ok": false, "error": "no_route"}`) |
| `ERR_HOP_HEADER_INVALID` | Header present but not a valid compact array | socket `end` |
| `ERR_HOP_LIMIT` | More than 3 signatures, or no room to append | socket `end`; packet discarded |
| `ERR_ROUTE_LOOP` | Inner key is this node, or this miner `w` already in the header | socket `end` |
| `ERR_HOP_VERIFY` | `t` outside ±600 s or recover(`s`) ≠ `w` | that hop is not metered; invalid header → `end` |
| `ERR_HOP_ARMOR_NOT_UTF8` | Hop-sig `n` / `h` cannot be computed because armor is a stream, thenable, or non-UTF-8 | **404** — do not hang until the client `connect_timeout` |
| `ERR_NEXT_HOP_CONNECT` | C→B (or A→B) TCP connect exceeds ~8s | **404** |

## SSE return path (not a hop signature)

**Live:** the mailbox writes Chat SSE frames as plaintext JSON
(`data: {"data": "<armor>"}`). Older listen commands carry
`algorithm: "aes-256-cbc"` and a `Securitykey`, but SI does not use them for
Chat, so entry C sees every frame, including the recipient key ID of each
delivered armor.

**In rollout:** `mailbox_listen` carries a fresh 32-byte `streamKey` inside the
route-PGP command, which only mailbox B can read. B seals every frame on that
SSE with AES-256-GCM (random 12-byte IV per frame, plaintext padded to a
multiple of 256 bytes) and refuses a listen without the key. Intermediate
entries that only forward armor never receive it. See
[mailbox routing](mailbox-routing.md).

The user may **change entry C at any time** and open another SSE. That rotates the listen ingress. It does not remove the SSE traffic shape on the new C. See [security limits](security-limits.md).

## Implementation anchors

- Compact record, domain, window, wallet-repeat guard, UTF-8 armor coerce: [CoNET-SI `siHopSigs.ts`](https://github.com/CoNET-project/CoNET-SI/blob/main/src/util/siHopSigs.ts) (`pgpArmorToUtf8String`, `signAndAppendHop`)
- Peel, 404 / `end`, forward, last-hop GB: [CoNET-SI `localNodeCommand.ts`](https://github.com/CoNET-project/CoNET-SI/blob/main/src/util/localNodeCommand.ts) (`postOpenpgpRouteSocket`, `forwardEncryptedSocket`, `creditUserGbFromHopSigs`)

## Next

- [Peel, hop-sig, and listen timeouts](peel-hop-listen.md) — wrap-to-C listen: peel plaintext, hung SSE, `forward <clientIP>`.
- [How to use Layer Minus](using-l0.md) — when to wrap to A versus encrypt only to the recipient.
- [Zero-trust mailbox routing](mailbox-routing.md) — A/B/C roles.
- [Security limits](security-limits.md) — replay, HTTP versus HTTPS, SSE fingerprint, forward secrecy.
- [SI developer guide](si-developer-guide.md) — clients must not set this header.
