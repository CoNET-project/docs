# Peel, hop-sig, and listen timeouts

**Evidence level: Implemented capability.** These rules come from a live Chat listen failure: the client reported `connect_timeout` after about 12 seconds, while entry **C** had already peeled the outer OpenPGP layer and then crashed **before** `socketForward` to mailbox **B**. Switching C did not help. The mailbox and the client were not the first fault.

This page is the **field lesson** for nested PGP listen. Protocol roles stay on [mailbox routing](mailbox-routing.md). Byte-level hop records stay on [hop-sigs v1](hop-sigs.md). Client samples stay on the [SI](si-developer-guide.md) and [Chat](chat-developer-guide.md) guides.

Do not treat this page as a node-operations runbook.

## What the client sees

A Chat Worker (or equivalent) wraps the listen command to **C’s route PGP**, then `POST /post` to C with `Accept: text/event-stream`.

Typical false picture:

| Observation | Wrong first conclusion |
| --- | --- |
| Worker abort `connect_timeout` (~12s) | C is dead, `routerInfo` is stale, or the home IP is blocked |
| Console `[Gossip] Unknown format: {status, epoch…}` | The Chat parser is broken |
| Changing entry C still times out | The mailbox IP or AddressPGP row is wrong |
| SI log `forward 174.7.x.x` (or any client IP) | That IP is mailbox **B** |

Those conclusions skip the peel hop. The listen command is already encrypted to **B**. C only has to peel once, hop-sign the **inner UTF-8 armor string**, and HTTP `:80` forward to B. If that hop-sign throws, B never sees the listen.

## What actually failed

```text
R ── wrap listen (encrypt to C) ──▶ C
C ── peel OK ── inner key = B’s route key
C ── Message.armor() is a stream / thenable (OpenPGP.js 6, minified class h)
C ── signAndAppendHop → Buffer.byteLength(armor, 'utf8') throws
C ── uncaughtException logs only; socket stays open
R ── waits until the 12s connect timer
B ── no chat listen, no socketForward inbound
```

A peel-success log such as `peeled … inner key AE85A2AEEC768225 … forward <peer-ip>` means:

- the **inner OpenPGP key ID** is the next hop (here mailbox B’s route key);
- the **`forward <ip>`** field is the **client source IP** that opened `/post` on C, not B’s locator.

About 11–12 seconds later C may log `createServerSSL socket.on('end')`. That lines up with the client abort. It is not proof that TCP to B failed. B was never dialed.

## SI rules (normative)

After a **local** decrypt, if the plaintext is still OpenPGP for another node:

1. **Prefer the peel plaintext string** when it already contains `-----BEGIN PGP MESSAGE-----`. Do **not** call OpenPGP.js 6 `Message.armor()` just to rebuild that string.
2. Hop-sig fields `n` (UTF-8 byte length) and `h` (`keccak256(utf8(armor))`) require a **real UTF-8 string**. Coerce first (`pgpArmorToUtf8String`): string, `Uint8Array`, thenable, async iterable, or `ReadableStream`. Official `encrypt()` already `await`s `armor()` because the runtime value is often **not** a string.
3. Hop-sign failure or non-UTF-8 armor is a **fast 404** (or socket `end`). Do **not** leave the client SSE open.
4. C→B `socketForward` has an **~8s TCP connect** budget. Timeout is a **404**, not a hang until the client’s 12s timer.
5. C→B `socketForward` must **not** destroy the TCP on **60s receive-idle**. Also call `sourceSocket.setTimeout(0)` on the **client→C** half — `socketData` still arms 60s idle on every inbound socket; leaving it on kills idle L0 listen even when C→B is already 24h. Long-lived SSE (Chat / mining / `l0_listen`) and occupied L0 AES pipes can be quiet for minutes; a 60s idle kill ends the listen, drops L0 occupy, and causes later `l0_connect` **404** (`no idle listen`). Idle `l0_listen` must also emit SSE comment keepalives. Keepalive + `end`/`close`/`error` reclaim dead peers. A multi-hour safety idle (e.g. 24h) is optional. Short HTTP still completes via response `end`.
6. `uncaughtException` that only logs is **not** a delivery path. A throw after peel must still close the client socket. Clients cannot see the TypeError.
7. A healthy writable chat listen must **not** expire by wall-clock age (`LISTEN_SESSION_MAX_MS` of a few seconds). Heartbeats can still flow while business frames are only `saveLocal` and never `forWard`. Expiry is socket stale / unwritable only.

Same-node inner PGP, hop count already 3, or this miner wallet already in `w[]` remains `end` / discard. See [hop-sigs](hop-sigs.md).

## Client rules (normative)

| Rule | Why |
| --- | --- |
| Start the ~12s `connect_timeout` **after** `fetch` is issued, not before OpenPGP wrap | Wrap / `encrypt()` can consume most of the budget; the abort then looks like “C never answered” |
| Emit `listening` only after `res.ok` **and** a readable `res.body` | HTTP 404 / empty body is a failed hop, not a live mailbox SSE |
| On `connect_timeout` / `Failed to fetch` / idle abort, **exclude that `node.domain`** from the next C pick | A single bad C should not be retried first; this does **not** fix a fleet-wide peel crash |
| Do not treat mining / listing frames as Chat ingest | `{ status, epoch, … }` proves the pipe, not user-PGP delivery |
| Do not let `history.load` starve the listen loop on a single Worker thread | Recover can run before `activeClient` exists; listen must still be scheduled |
| Never take `search-users` `results[0]` as the encrypt-to EOA | Prefix hits such as `@rrr000` / `@rrr0000` or `CoNET` / `CONET` are different mailboxes |

HTTP **200** or an SSE handshake is still only transport progress.

## Misdiagnosis table

| Symptom | Do not conclude | Check first |
| --- | --- | --- |
| `connect_timeout` ~12s | C is unreachable; rotate C as the fix | C peel log, then TypeError `string` / `instance of h`, then **no** `socketForward` on B |
| `forward <home IP>` | That IP is mailbox B | AddressPGP `routeKeyID` / Guardian IP for B. The log IP is the client |
| Only `[Gossip] Unknown format` | Parser regression | Business armor never entered **this** mailbox (wrong EOA / tag, peel crash, or saveLocal without forWard) |
| Fake-armor **404** `body has not PGP message` | SI process is down | Intentional reject of invalid armor |
| Entry HTTPS certificate error | Inter-node DePIN is down | SI→SI is HTTP `:80` only |
| Direct-to-B listen works | Product path should dial B | Privacy model requires **C ≠ B** |

Walk [mailbox routing](mailbox-routing.md) and the [Chat diagnosis list](chat-developer-guide.md#diagnosis-i-sent-but-they-never-see-it) in order. Do not skip to “switch C” or “the parser is broken.”

## Implementation anchors

| Piece | Source |
| --- | --- |
| Peel, inner armor, `socketForward` | CoNET-SI `localNodeCommand.ts` (`postOpenpgpRouteSocket`, `tryReadInnerPgpMessage`, `forwardEncryptedSocket`) |
| UTF-8 armor coerce + hop-sig `n` / `h` | CoNET-SI `siHopSigs.ts` (`pgpArmorToUtf8String`, `signAndAppendHop`) |
| Uncaught exception must not hide a hung SSE | CoNET-SI `server.ts` — log-only handlers are not a substitute for a 404 |
| Listen timer, `listening`, exclude failed C | chat-sdk / SilentPassUI `worker/gossip-core.ts` |

## Next

- [Zero-trust mailbox routing](mailbox-routing.md)
- [X-CoNET-Hop-Sigs v1](hop-sigs.md)
- [SI developer guide](si-developer-guide.md)
- [CoNET Chat developer guide](chat-developer-guide.md)
