# CoNET Chat developer guide

**Evidence level: Implemented capability, with a privacy upgrade in rollout.** This page is a developer how-to for **CoNET Chat** on Layer Minus. Unmarked envelopes, commands, and APIs match current Beamio / chat-sdk clients. Text marked **In rollout** describes code that is written but not deployed; **Planned** describes decided designs that are not implemented. Write new clients to the rollout form. It is not a claim that Chat is a finished replacement for mainstream messengers.

CoNET Chat is relationship-private communication infrastructure: wallet identity, zero-trust mailbox routing, encrypted application envelopes, and wallet-controlled encrypted history. Use it to add wallet-addressed communication **without** first building a centralized user-and-relationship database. Product thesis, Beamio integration, and maturity limits live on [CoNET Chat](../applications/depin-chat.md).

Public site: [https://gitbook.conet.network/l0/chat-developer-guide.html](https://gitbook.conet.network/l0/chat-developer-guide.html)

L0 only forwards OpenPGP by wallet / key ID. Chat is an **application composition**: user-PGP business envelopes, mailbox listen, dual receipts, presence, and an optional encrypted history track. SI primitives and reusable helpers live on the [SI developer guide](si-developer-guide.md). Developer-track index: [L0 development](../developers/l0.md).

Public packages: [CoNET-project/chat-sdk](https://github.com/CoNET-project/chat-sdk) · [`@conet.project/chat-sdk`](https://www.npmjs.com/package/@conet.project/chat-sdk). Reference clients: SilentPassUI [`cashtree`](https://github.com/CoNET-project/SilentPassUI/tree/cashtree) (consumer) and [`cashtrees`](https://github.com/CoNET-project/SilentPassUI/tree/cashtrees) (merchant).

## What a Chat client must implement

| Step | Encrypt to | Transport |
| --- | --- | --- |
| Register user PGP + mailbox | — | `POST https://beamio.app/api/regiestChatRoute`, then confirm with AddressPGP `searchKey` |
| Look up a contact | — | `AddressPGP.searchKey(contact)` over CoNET RPC, **without** an `eth_call` `from` (in rollout; the live Consumer PWA still sends its own wallet as `from`) |
| Send a message | Recipient **EOA user PGP**; in rollout always wrapped as mailbox work to the recipient mailbox **B route PGP** | `POST /post` to **one** random entry **A** (not the recipient's or the sender's mailbox); the next entry only after a clear failure |
| Listen | Own mailbox **B route PGP** | `command: "mailbox_listen"` as SSE via entry **C ≠ B**. In rollout it must carry a fresh `streamKey` and every frame is sealed. The legacy `mining` + `listenKind: "chat"` pool stops receiving Chat in the rollout |
| After inbound ingest | (1) **B route PGP** ACK · (2) sender user PGP receipt, then mailbox-work wrap `NoPush` to sender mailbox B | ACK only after the message is stored. ACK and receipt both via entries ≠ B; HTTP still `{ data }` only. `NoPush` is **Chat/APNs only** |
| Presence (green dot) | Contact mailbox **B route PGP** | `wallet_online_query` via **entry C ≠ B** (never dial B; that hides the querier's IP). Carries the querier's wallet: known limitation |
| Native shell status | Contact mailbox **B route PGP** | `wallet_native_wake_query` via the **same entry C ≠ B**, after presence. Same limitation |
| Call offer | Signed offer to callee **user PGP**, inside a route command to the callee mailbox **B route PGP** | `voice_offer_store` with `push: 1` via a random entry ≠ either mailbox |
| Optional recover history | — | Encrypted IPFS fragments + `ChatIndexRegistry` head pointer |

Protocol status (live, in rollout, planned) and the known limitations are
listed on [CoNET Chat](../applications/depin-chat.md#protocol-status-november-2026).
The rollout is not backward compatible: a mailbox on the new SI refuses a
`mailbox_listen` without `streamKey`.

## Relationship-privacy field contract

The application sender wallet is confidential routing metadata until the
recipient decrypts:

```text
{ from: senderEOA, text, signature }
  → encrypt complete object to recipient user PGP
  → (in rollout) wrap { data: armor } to recipient mailbox B route PGP
  → POST { data: armor } through one random entry A
```

| Role | Receives | Must not receive |
| --- | --- | --- |
| **Entry A** | Client IP, ciphertext, timing, size, outer key ID. Live: that key ID is the recipient's user key. In rollout: the recipient mailbox's route key | Plaintext sender wallet or Chat body |
| **Mailbox B** | Destination route, stored armor, listen state | Sender wallet inside the business envelope or Chat body |
| **Listen entry C** | Recipient-side connection IP, encrypted listen traffic. Live: plaintext SSE frames that show each message's recipient key ID. In rollout: sealed, padded frames | Decrypted Chat body |
| **Recipient** | Decrypted envelope and verified sender wallet | Other users' private keys |

This attempts to break three direct associations: sender wallet ↔ recipient,
message content ↔ relay, and user IP ↔ communication identity. It does not
make IP disappear: A/C see the connecting IP, while B sees route state through
an entry connection. Collusion and global timing analysis remain outside the
guarantee.

## Protected file attachments

Chat file attachments use the encrypted `file_message_v1` application type. The
composer accepts non-photo, non-audio files and browser folder drops; photos,
audio, and voice recordings continue to use their existing paths.

1. The client recursively collects dropped files, creates a ZIP in the browser
   with `fflate`, and encrypts the ZIP with AES-GCM.
2. The encrypted Data URL is uploaded to `ipfs.conet.network` using authenticated
   512 KiB multipart chunks. Upload status is queried first so interrupted
   uploads resume; each job can be cancelled independently. The client enforces
   a roughly 240 MiB Data URL ceiling before upload.
3. The encrypted PGP application envelope carries a `file_message_v1` manifest
   containing the fragment hash, AES key and IV, display name, file count,
   total size, and file names/sizes.

The manifest is protected by the normal recipient user-PGP envelope. Ordinary
UI, logs, localStorage, and encrypted history must never expose plaintext file
contents, the AES key, or fragment hash. Recipients fetch, decrypt, and unzip
locally, then receive per-file download/preview controls. Object URLs must be
revoked after each download or component unmount.

Do **not** encrypt business Chat to an AA Smart Wallet unless that AA has its own AddressPGP row. Do **not** take `search-users` `results[0]` as the gossip target (`CoNET` ≠ `CONET`).

## Voice-call wake-up and offer delivery

**Live (voice channel v2).** A device may need a native wake-up before its
mailbox SSE is up. The caller delivers the signed call offer, already
encrypted to the callee's **user PGP**, to the **callee's own mailbox** with one
route command. It is encrypted to the callee mailbox route PGP and posted
through a random entry that is neither the callee's nor the caller's mailbox:

```json
{
  "command": "voice_offer_store",
  "callId": "opaque-call-id",
  "sessionId": "voice-session-opaque-id",
  "expiresAt": 1710000123456,
  "push": 1,
  "pushTimestamp": 1710000000,
  "offerArmor": "-----BEGIN PGP MESSAGE-----\n...\n-----END PGP MESSAGE-----",
  "timestamp": 1710000000
}
```

`callId` is a random wake-up reference and must not contain the caller's
`@BeamioTag` or wallet address. `sessionId` (16–128 characters) is the
capability for this offer index and is used for deduplication. The command has
no `walletAddress` and no wallet signature.

The callee mailbox stores the ciphertext under `callId` + `sessionId`, finds its
own user from the offer's recipient key ID, and asks `/api/voiceCallPush` to
ring that user's registered devices (`ios_voip` uses APNs PushKit/CallKit,
`android` uses high-priority FCM). It answers `{ ok, pushed }`. `pushed: false`
means the callee has no push device; the call still proceeds over a live SSE.
The callee mailbox already knows its own user, so no other node learns whom the
caller is calling, and the caller never calls the push API. The mailbox never
decrypts or logs the offer and never forwards keys or audio. A push response is
not proof that the offer was read or the call answered.

**In rollout.** The callee mailbox also writes the offer into the callee's live
mailbox SSE (stored without a chat push), so a browser callee receives it with
no other leg. A failed store is a failed dial; `pushed: false` is not.

**Live, being removed: legacy wake fallback.** Current clients also encrypt a
`voice_listen` for their own mailbox that carries `targetWallet`, `callId`,
`expiresAt`, `pushTimestamp` and `offerArmor`, and post it only when the callee
mailbox has not confirmed `pushed: true` within about 3 seconds. The caller's
mailbox then forwards the offer and calls the push API. That shows the callee's
wallet to the caller's mailbox. In rollout, every client deletes this leg and
the node ignores those fields on `voice_listen`. New clients must not send
them.

### Killed-app identity (CallKit / Incoming)

`offerArmor` is too large for APNs/FCM. When the app process was killed, the
woken native Chat SDK:

1. reports the system incoming UI with a temporary opaque label;
2. posts `voice_offer_fetch` (encrypted to its own mailbox **route PGP**,
   through an entry C ≠ B, using only the push `callId` / `sessionId`);
3. decrypts the returned armor **locally** with the user PGP private key it
   already holds in the Keychain / Keystore (provisioned once by the app page,
   see [Using the SDKs](#using-the-sdks));
4. recovers the caller EOA from `callerSignature`, looks up `@BeamioTag` for
   that address, and updates CallKit / Incoming to a larger `@tag` plus a
   smaller shortened address.

```json
{
  "command": "voice_offer_fetch",
  "callId": "opaque-call-id",
  "sessionId": "voice-session-opaque-id",
  "timestamp": 1710000000
}
```

The returned `offerArmor` is a normal Chat envelope. After the PGP decrypt, the
literal is `base64(UTF-8 JSON)` (`{ timestamp, text, from, signMessage }`, with
the signed offer JSON in `text`), exactly like every other Chat message. Decode
it before looking for `voice_call_offer_v1`; a client that parses the decrypted
literal as JSON directly never finds the offer and the call stays anonymous.

Do **not** put the caller wallet or tag into the push payload.

### Call control

Every online client keeps its mailbox SSE open during dialing, ringing and the
call. Call control therefore travels as **ordinary Chat messages** through the
mailbox: signed by the sender wallet, encrypted to the peer's user PGP, posted
through a random entry (and, in rollout, wrapped to the peer's mailbox route
key). This covers caller cancel, decline, ring timeout and hang-up
(`voice_end_v1`):

```json
{
  "type": "voice_end_v1",
  "callId": "opaque-call-id",
  "sessionId": "caller-ring-session-id",
  "from": "0xEnder",
  "to": "0xPeer",
  "reason": "hangup",
  "createdAt": 1710000000000,
  "timestamp": 1710000000000
}
```

`from` and `to` are inside the recipient-PGP envelope only. A connected call
may also send the same object as an AES control chunk on the peer's voice
channel. Receivers match the call by `callId`, end it on whichever copy arrives
first, and ignore the second.

In the native apps the caller's cancel is prepared when the dial starts (signed
with the SDK's stored wallet key, encrypted to the callee, kept in memory only)
and posted through the pre-warmed entry pool the moment the caller hangs up
before an answer (in rollout). The page receives the result and sends no copy.

### Voice channel v2 (live)

Each listening side opens a temporary voice session that never occupies
`mailbox_listen`. The command is unsigned and carries no wallet:

```json
{
  "command": "voice_listen",
  "sessionId": "<16-byte channel locator, hex>",
  "timestamp": 1710000000,
  "v": 2,
  "wk": "<32-byte write key, base64>"
}
```

It is encrypted to the route PGP of the node that will hold the session and
sent through an entry that is not that node. A v2 node answers
`voice_ready` with `v: 2`. The listener gives the locator and write key to the
peer only inside the signed offer or an AES control chunk, and announces v2 in
`voice_media_caps_v1` (`chan: 2`).

Each chunk sent to the peer is an OpenPGP binary literal encrypted to the
session node's route PGP and posted through a random entry from the rotation
pool:

```text
"CVC2" ‖ locator (16 bytes) ‖ HMAC-SHA256(wk, locator ‖ blob)[:16] ‖ blob
blob = nonce(12) ‖ AES-GCM ciphertext ‖ tag(16), padded to a multiple of 256 bytes (≤ 9000)
AAD  = "CVC2" ‖ locator
plaintext header (28 bytes):
  ver u8 = 2 | kind u8 (0 audio, 1 video, 2 control) | flags u8 | reserved u8
  seq u32 (per kind) | captureMs u64 | frameId u32 | fragIdx u16 | fragCnt u16 | dataLen u32
```

The node checks the HMAC and the size, rate-limits per channel, and writes
`data: {"t":"c","d":"<base64 blob>"}` to the session SSE. It answers
`{ ok: true }`, `voice_chunk_auth`, `invalid_voice_chunk`, or
`target_voice_session_not_found`. It never decrypts, reorders or stores media,
and media never enters offline Chat, push, `ChatIndexRegistry`, or history.

Receivers decrypt first, then reorder by `(kind, seq)` from the inner header,
drop frames whose capture time is too old, and reassemble video by
`frameId` / `fragIdx` / `fragCnt`. Exact duplicates are ignored; buffer and
reassembly sizes are bounded. The protocol is real-time best effort.

Voice channel v1 (`voice_uplink` / `voice_downlink` JSON with an outer `seq`,
`targetSessionId` and base64 payload) stays only as the fallback when the peer
or its node does not announce v2. A v1 receiver reorders by the outer `seq`
before decrypting; that outer metadata is exactly what v2 removes.

### Planned: payer-signed temporary voice channels

The decided next step replaces the caller-generated session key and the unused
`tempWalletAddress`: the callee creates one temporary wallet and one key per
channel (up to four: each side receiving voice and video), signs as payer for
all of them, and returns the caller's channels in an accept message through the
caller's mailbox. Each side picks its own relay. CoNET-SI will refuse a
`voice_listen` whose temporary wallet has no valid payer signature; it only
verifies the signature, and no usage is charged until the GB settlement module
exists. Not backward compatible; the wire format is not final. See
[CoNET Chat — Real-time voice calls](../applications/depin-chat.md#real-time-voice-calls).

## Native push and call-UI capability registration

When a Consumer PWA runs inside the iOS or Android shell, the shell sends its
push token and native call-UI capabilities to the PWA. The PWA signs the
registration payload with the wallet EOA and sends it as an encrypted
`push_device_register` command to the wallet's own mailbox route:

```json
{
  "command": "push_device_register",
  "walletAddress": "0xUser",
  "deviceToken": "opaque-platform-token",
  "platform": "android",
  "bundleId": "com.beamio.app",
  "timestamp": 1710000000,
  "registrationSignature": "0x...",
  "capabilities": {
    "nativeCallUi": true,
    "fullScreenIntent": true,
    "callKit": false
  }
}
```

The mailbox validates that `walletAddress` is its route, then forwards the
signed registration to `/api/registerPushDevice`. The PWA does not call the
push API directly, and the mailbox must not log device tokens or forward
private keys. `fullScreenIntent` is a capability report only; Android still
controls the permission and may revoke it.

## Identity

| Item | Rule |
| --- | --- |
| Protocol identity | **EOA** + user OpenPGP + mailbox route |
| User PGP `keyID` | Encryption **subkey**: `getKeyIDs()[1]`, uppercase hex |
| Mailbox | A Guardian node. Current register API field `routeKeyID` is that node’s **domain** |
| `@BeamioTag` | Display label only. Look it up **after** signature recovery, by the recovered EOA. Exact username match when searching by tag. Never read a tag from the message body, and never use `search-users` `results[0]` |
| Presence | Mailbox listen-pool via `wallet_online_query` through entry C ≠ B. Ignore `searchKey.routeOnline` (SI no longer writes it). The query is signed by the querier's wallet, so the contact's mailbox sees who asks (known limitation, to be solved with `web3://`; do not patch it ad hoc) |
| Key lookup | `searchKey(contact)` does not depend on the caller: call it without `from`. Only reading your own encrypted private key needs your own address |
| Native shell status | `wallet_native_wake_query` through the same entry, after presence. Boolean `nativeWakeable`. Direct-to-B is forbidden because it would show the querier's IP to mailbox B |
| Optional split | **Routing EOA** for AddressPGP + listen / ACK / presence; **sender / recipient EOA** only inside the encrypted envelope |
| Sender confidentiality | Sender wallet address and sender PGP key stay inside the recipient user-PGP ciphertext until the recipient decrypts. Sender PGP private key never leaves the sender. Hops may see only the **recipient** key id |

Current Beamio clients often use one EOA for all of the above. A new app can split them: register and listen with a routing wallet, encrypt to that row’s inbox user PGP, and put the product `from` / display wallet only in layer ②/③. Mailbox B then sees the routing EOA. Do not also write the product wallet into listen JSON or hop-sigs. See [Routing wallet versus sender / recipient wallets](wallet-address-p2p.md#routing-wallet-versus-sender--recipient-wallets).

Register and `searchKey` samples: [SI developer guide](si-developer-guide.md#sample-register-a-mailbox-route).

## Envelope layers

Live `sendMessage` signs the **inner application string** (`text`), then OpenPGP-encrypts a JSON envelope to the recipient user PGP.

```text
① application body
   plain text  — or —  typed JSON (receipt, POS permission, …)

② pending row  (what most clients put in envelope.text)
   { sendId, from: "me", text: <① as string>, createdAt }

③ outer envelope  (EIP-191)
   { timestamp, text: <JSON.stringify(②)>, from: <sender EOA>, signMessage }
   signMessage = wallet.signMessage(text)   // signs ②, not ③

④ OpenPGP
   encrypt base64(JSON.stringify(③)) to R userPublicKeyArmored

⑤ mailbox layer  (in rollout: always)
   { data: <④ armor>, NoPush?: true } → OpenPGP encrypt to R's mailbox B route PGP
   No route key for B → fail with recipient_mailbox_unknown; do not send ④ bare

⑥ POST
   { data: <armor> } → one random entry (not R's mailbox, not the sender's mailbox)
   next entry only after a clear failure; at most 4 entries per message
   HTTP JSON is **only** `{ data }`. **Ordinary chat** omits `NoPush` so an
   offline recipient can get a native badge; a **sender receipt** sets
   `NoPush: true`. Live clients still post ordinary chat as bare ④ and wrap only
   receipts. See [SI mailbox work](si-developer-guide.md#3-mailbox-work-envelope-mailbox-b-decrypts)
   and [Native push badge and `NoPush`](../applications/depin-chat.md#native-push-badge-and-nopush).
```

A clear failure is a connection error, a reset before any response, a non-2xx
status, a 2xx body `{"ok": false, …}`, or no response within about 8 seconds.
Any other 2xx is success. A timed-out post may already have reached B, so the
retry can produce a second copy of the same ciphertext; the new SI stores one
copy per armor hash, and recipients deduplicate by `sendId`.

Inbound: decrypt with the recipient user PGP private key → parse ③ → `ethers.verifyMessage(text, signMessage)` must recover `from`. The **recovered address is the sender**. The JSON `from` field is only a claim; a nested `from: "me"` is a direction flag, not an address. Drop the message only when recovery fails. When the claim differs from the recovered address, keep the message under the recovered address and show a warning on that message that names the claimed address (native SDKs pass both to the app; they do not drop it). Then look up `@BeamioTag` for the recovered EOA. Do not display a tag or wallet copied out of ① or ②.

### Inbound identity verification

| Check | What the recipient trusts | What it must not trust |
| --- | --- | --- |
| **Inbound chat message** (text, `voice_message_v1`, file, any Messages bubble) | The address recovered by `verifyMessage(text, signMessage)`. That address is the session peer and the bubble sender; a differing claimed `from` is shown only as a warning | `from`, a wallet, a display name, or `@BeamioTag` inside the JSON. Pending-row `from: "me"` is only a direction flag |
| Display name | BeamioTag record for the **recovered** EOA (local mirror, then exact-address search) | Any tag string in the message body |
| `voice_call_offer_v1` | `callerSignature` over the canonical offer text below, and that signer equals the outer-envelope signer | `from` or a tag inside the offer |

`voice_call_offer_v1` canonical text (newline-joined, identity fields excluded):

```text
CoNET voice_call_offer_v1
callId:<opaque>
sessionId:<opaque>
to:<callee EOA lowercase>
createdAt:<ms>
expiresAt:<ms>
timestamp:<ms>
sessionKey:<or empty>
tempWalletAddress:<lowercase or empty>
entryDomains:<comma-joined or empty>
codec:<or empty>
```

`sessionKey` and `tempWalletAddress` belong to the live flow. The planned payer-signed voice channels remove both from the offer (the callee creates the channel keys and temporary wallets when it answers), so this canonical text will get a new version with that change.

The caller signs that string with the same EOA private key (`signMessage`). The callee recovers the address and only then looks up the tag. If recovery fails, or it disagrees with the outer-envelope signer, do not present the offer’s claimed identity. A body claim that disagrees with the recovered key may be shown only as an extra unverified line with a warning. Native wake-up stays generic until this on-device check finishes.

POS terminal authorization nests another object inside ① (`type: "beamio_pos_terminal_permission_v1"`). Merchant OS must unwrap along `text` and put it on **Staff pending**, not Messages. See [CoNET Chat](../applications/depin-chat.md).

## Sample: send

Reuse `postArmor` / entry picking from the SI guide. This is the Chat envelope
in its rollout form: the user-PGP armor is always wrapped to the recipient's
mailbox, and the post goes to one entry at a time.

```ts
import { createMessage, encrypt, enums, readKey } from 'openpgp'
import { ethers } from 'ethers'

export type ChatPendingRow = {
  sendId: string
  from: 'me'
  text: string
  createdAt: number
}

async function encryptText(text: string, armoredKey: string, zlib = false): Promise<string> {
  return encrypt({
    message: await createMessage({ text }),
    encryptionKeys: await readKey({ armoredKey }),
    config: zlib ? { preferredCompressionAlgorithm: enums.compression.zlib } : undefined,
  }) as Promise<string>
}

export async function sendChatMessage(opts: {
  wallet: ethers.Wallet
  recipientUserPublicKeyArmored: string
  recipientMailboxRoutePublicKeyArmored: string // from searchKey; required
  entryDomains: string[] // healthy entries, random order
  excludeDomains: string[] // recipient mailbox and own mailbox
  body: string
  noPush?: boolean // true only for sender receipts
  sendId?: string
}): Promise<{ ok: boolean; sendId: string }> {
  if (!opts.recipientMailboxRoutePublicKeyArmored) {
    throw new Error('recipient_mailbox_unknown')
  }
  const sendId = opts.sendId ?? crypto.randomUUID()
  const pending: ChatPendingRow = { sendId, from: 'me', text: opts.body, createdAt: Date.now() }
  const text = JSON.stringify(pending)
  const envelope = {
    timestamp: Date.now(),
    text,
    from: opts.wallet.address,
    signMessage: await opts.wallet.signMessage(text),
  }
  // ④ recipient user PGP: only the recipient can read the sender wallet.
  const userArmor = await encryptText(
    Buffer.from(JSON.stringify(envelope)).toString('base64'),
    opts.recipientUserPublicKeyArmored,
    true,
  )
  // ⑤ mailbox layer: the entry sees B's route key ID, not the recipient's key ID.
  const work = opts.noPush ? { data: userArmor, NoPush: true } : { data: userArmor }
  const armored = await encryptText(JSON.stringify(work), opts.recipientMailboxRoutePublicKeyArmored)

  // ⑥ one entry at a time; switch only after a clear failure.
  const skip = new Set(opts.excludeDomains)
  const targets = opts.entryDomains.filter((d) => d && !skip.has(d)).slice(0, 4)
  for (const domain of targets) {
    try {
      const res = await fetch(`https://${domain}.conet.network/post`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ data: armored }),
        signal: AbortSignal.timeout(8_000),
      })
      if (!res.ok) continue
      const reply = await res.text()
      if (/^\s*\{/.test(reply) && JSON.parse(reply)?.ok === false) continue
      return { ok: true, sendId }
    } catch {
      // connection error or timeout: try the next entry
    }
  }
  return { ok: false, sendId }
}
```

HTTP 200 on an entry means the armor was accepted for forward. It does **not**
mean the recipient UI ingested it. Deduplicate inbound copies by `sendId`.

Live clients still post ordinary messages as the bare user-PGP armor (step ④)
and wrap only receipts; the live mailbox also ignores `NoPush`. Both change in
the rollout. Inside the iOS and Android apps, pages do not post at all: they
call the native SDK's `send`, which signs, encrypts, wraps, picks the entry and
posts, and a page treats the send as done only when the SDK returns
`sent: true` (in rollout).

## Sample: listen

Chat listen is an SI **route command**, not user-PGP business. Use
`mailbox_listen`, which accepts an opaque per-device `instanceId`. Full helper:
[SI developer guide](si-developer-guide.md#mailbox-listen).

```ts
// Fresh 32-byte key for every listen. Keep it in memory only; never log it.
const streamKeyRaw = crypto.getRandomValues(new Uint8Array(32))
const streamKey = await crypto.subtle.importKey('raw', streamKeyRaw, 'AES-GCM', false, ['decrypt'])

const command = {
  command: 'mailbox_listen',
  walletAddress: wallet.address,
  instanceId: crypto.randomUUID(),
  streamKey: btoa(String.fromCharCode(...streamKeyRaw)), // in rollout: required
}
// sign JSON.stringify(command); encrypt { message, signMessage } to own route PGP
// POST { data } to entry C ≠ mailbox B; read the SSE.

/** In rollout every SSE `data:` line is base64(iv[12] ‖ AES-256-GCM ciphertext ‖ tag[16]). */
async function openFrame(line: string): Promise<unknown> {
  const raw = Uint8Array.from(atob(line), (c) => c.charCodeAt(0))
  const plain = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: raw.subarray(0, 12) },
    streamKey,
    raw.subarray(12),
  )
  return JSON.parse(new TextDecoder().decode(plain)) // trailing space padding is ignored
}
```

The plaintext of each sealed frame is the same JSON the live node writes in
the clear: the handshake, `{ data: armor }` for a stored or live message, and
`{ type: "mailbox_keepalive", ts }`. It is padded with spaces to a multiple of
256 bytes, and every frame has a random IV (a reconnect may reuse the same
encrypted command, and so the same key). Drop a frame that does not open and
log one warning without its content; after three in a row, reconnect with a
new key. The armor hash for the mailbox ACK is still computed over the inner
user-PGP armor, and the ACK is sent only after the message is stored.

The live node ignores `streamKey`, writes plaintext frames, and does not use
the old `algorithm` / `Securitykey` fields for Chat. After the rollout a node
refuses a listen without `streamKey`, and the legacy `mining` +
`listenKind: "chat"` pool no longer receives Chat messages.

| Frame | Treat as |
| --- | --- |
| Handshake / `{ status, epoch, … }` | Liveness. Ignore for Messages |
| `{ data: <user-PGP armor> }` | Decrypt, verify, unwrap, store, then **dual receipts** |
| `mailbox_keepalive` | Liveness only |
| `udp_listen_attached` / UDP frames | Only if you implement UDP; not Chat bubbles |

Keep listen on a Worker (or in the native daemon). Reconnect with another random **C ≠ B** after idle or drop. Use a `setTimeout` chain after the previous attempt finishes. Native daemons hold the listen only while the app is in the foreground, ringing, or in a call, and keep it open throughout a call.

| Client rule | Why |
| --- | --- |
| Start the ~12s `connect_timeout` **after** `fetch` | Wrap / `encrypt()` can burn the budget before C is even dialed |
| Emit `listening` only after `res.ok` **and** `res.body` | 404 / empty body is a failed peel hop, not a live mailbox |
| Exclude the failed `node.domain` on reconnect | One hung C should not be retried first |
| Do not let `history.load` starve listen on a single Worker thread | Recover can run before `activeClient` exists |

A peel-success SI log `forward <ip>` is the **client source IP**, not mailbox B. If C peels then throws on hop-sign (`Buffer.byteLength` / instance of `h`), **B is never dialed**. Switching C does not help until peelers return a UTF-8 armor string. See [Peel, hop-sig, and listen timeouts](peel-hop-listen.md).

## Sample: verify inbound

```ts
export function verifyChatEnvelope(plainUtf8: string): {
  from: string // recovered signer: the sender
  claimedFrom?: string // set only when the envelope claims someone else
  text: string
  timestamp: number
} | null {
  let env: { timestamp?: number; text?: string; from?: string; signMessage?: string }
  try {
    env = JSON.parse(plainUtf8)
  } catch {
    return null
  }
  if (!env.text || !env.from || !env.signMessage) return null
  let recovered: string
  try {
    recovered = ethers.verifyMessage(env.text, env.signMessage)
  } catch {
    return null
  }
  const claimedFrom = recovered.toLowerCase() !== env.from.toLowerCase() ? env.from : undefined
  return { from: recovered, claimedFrom, text: env.text, timestamp: Number(env.timestamp) || 0 }
}

/** Walk nested `text` for typed application JSON. */
export function unwrapTextJson(displayText: unknown, max = 6): unknown {
  let cur = displayText
  for (let i = 0; i < max; i++) {
    if (typeof cur === 'string') {
      const t = cur.trim()
      if (!t) return null
      try {
        cur = JSON.parse(t)
        continue
      } catch {
        return cur
      }
    }
    if (cur && typeof cur === 'object' && typeof (cur as { text?: unknown }).text === 'string') {
      cur = (cur as { text: string }).text
      continue
    }
    return cur
  }
  return cur
}
```

After decrypt, if the Worker received armor, compute `armorHash = keccak256(utf8(fullArmor))` before discarding the armor string. You need it for the mailbox ACK.

## Dual receipts (required)

After a **business** message is ingested (verified, not a receipt, not POS-permission-only):

1. **Mailbox ACK** — SI command `gossip_delivery_ack` encrypted to **B route PGP**, sent only after the message is stored locally. Removes the matching offline store. Sample: [SI developer guide](si-developer-guide.md#mailbox-delivery-ack).
2. **Sender receipt** — ordinary Chat business envelope whose inner type is `beamio_chat_delivery_receipt_v1`, encrypted to the **original sender’s user PGP**, then wrapped as mailbox work `{ data: <user-PGP armor>, NoPush: true }` encrypted to the **sender’s mailbox B route PGP**. HTTP to the entry is still only `{ data }`. SDK: `sendMessage(..., { beamioNoPush: true })` (requires `to.routerArmoredPublicKey`).

```ts
export const CHAT_DELIVERY_RECEIPT_V1 = 'beamio_chat_delivery_receipt_v1' as const

export type ChatDeliveryReceiptV1 = {
  type: typeof CHAT_DELIVERY_RECEIPT_V1
  sendId: string
  armorHash?: string
  deliveredAt: number
  from: string
}

export function makeDeliveryReceipt(opts: {
  sendId: string
  fromEoa: string
  armorHash?: string
}): ChatDeliveryReceiptV1 {
  return {
    type: CHAT_DELIVERY_RECEIPT_V1,
    sendId: opts.sendId,
    armorHash: opts.armorHash,
    deliveredAt: Math.floor(Date.now() / 1000),
    from: opts.fromEoa,
  }
}
```

Send that object as `pending.text` (JSON string) using the same `sendChatMessage` path, encrypting to the **sender** user PGP.

On the sender: unwrap inbound; if `type === beamio_chat_delivery_receipt_v1`, mark the existing outbound bubble `delivered` by `sendId`. **Do not** append a Messages row. **Do not** increment unread.

Mailbox stores ciphertext first (`saveLocal`), then best-effort SSE. Do not treat SSE `forWard SUCCESS` as “the user has the message.” On every durable chat save (SSE online or offline), CoNET-SI enqueues native push when the recipient EOA has a registered `pushDevice`; Beamio API no-ops if none. `NoPush` / `skipPush` frames are meant never to enter that queue; the live SI drops the `NoPush` flag when it unwraps mailbox work, which the rollout fixes. The rollout also stores one copy per armor hash, so the same ciphertext posted twice is stored and pushed once. ACK removes offline armor; it does not gate whether push was sent.

## Presence

On entering the chat list:

1. Refresh route fields (`routersArmoreds` / route PGP) from `searchKey`. **Do not** copy `routeOnline` into the green dot.
2. For each contact that has a mailbox route, send `wallet_online_query` (SI guide sample).
3. Merge `online` only when `ok === true`. Failures keep the last trusted value.
4. Then send `wallet_native_wake_query` through an **entry node that is not mailbox B**. Merge `nativeWakeable` only when `ok === true`. A failed lookup keeps the last trusted flag.
5. The green dot stays online-only. A voice-call control may be offered when `online || nativeWakeable`.

Store the trusted tag, image, names, `online`, and `nativeWakeable` in the local BeamioTag record and show that record first. Refresh a field from the network when it is older than 180 seconds. A failed lookup keeps the last trusted value. While a conversation is open, that screen owns the online query and repeats `wallet_online_query` every 6 seconds through an entry that is not the mailbox. If no such entry is available, skip the query. Do not POST it to mailbox B.

Online means: that wallet is in **this mailbox’s** `livenessListeningPool` and the listen socket is not stale. It is not a chain write.

`wallet_native_wake_query` is a CoNET Chat protocol command. Encrypt it to the contact mailbox **B route PGP** and POST `{ "data": "<armor>" }` to entry **C**. **C must not be B**, and the client must not open a connection to B. That entry hop is what keeps the querier's IP address off the destination mailbox. B answers `{ ok: true, wallet, nativeWakeable }`. `nativeWakeable` is `true` when that mailbox-registered wallet has a registered iOS, Android, Windows, Linux, or macOS shell that push can wake, including while the listen session is offline. The answer carries no device token.

## Resolve `@BeamioTag`

```ts
type TagHit = { address: string; username?: string; accountName?: string }

export function pickExactBeamioTag(
  query: string,
  results: TagHit[],
  addressHint?: string,
): TagHit | null {
  const q = query.replace(/^@/, '')
  const exact = results.filter(
    (r) => r.username === q || r.accountName === q,
  )
  if (exact.length === 1) return exact[0]
  if (exact.length > 1 && addressHint) {
    const hint = addressHint.toLowerCase()
    const hit = exact.find((r) => r.address.toLowerCase() === hint)
    return hit ?? null
  }
  const ci = results.filter(
    (r) =>
      r.username?.toLowerCase() === q.toLowerCase() ||
      r.accountName?.toLowerCase() === q.toLowerCase(),
  )
  if (ci.length === 1) return ci[0]
  return null
}
```

Current discovery HTTP: `GET/POST` `https://beamio.app/api/search-users` (application API, not SI). If the exact match is ambiguous, **fail**. Never encrypt to `results[0]`.

## Typed payloads

| `type` | UI |
| --- | --- |
| (plain / no type) | Messages bubble |
| `beamio_chat_delivery_receipt_v1` | Update existing outbound `status → delivered` only |
| `beamio_pos_terminal_permission_v1` | Merchant **Staff → Pending terminal authorization** only. Requires `childBeamioTag`. Do not show as a chat JSON dump |

POS permission is still delivered as user-PGP Chat armor. Classification happens **after** verify + unwrap.

## Voice messages: `voice_message_v1`

Voice is an application payload carried by the same recipient-only Chat
envelope. It does not add an SI command, a plaintext HTTP field, or a mailbox
media API.

```json
{
  "type": "voice_message_v1",
  "fragmentHash": "0x<64 lowercase hex characters>",
  "key": "<base64 AES-256 key>",
  "iv": "<base64 12-byte nonce>",
  "mime": "audio/webm",
  "durationMs": 4200,
  "sizeBytes": 123456
}
```

The manifest above is an illustrative decrypted shape. In transit it is
inside the signed Chat application envelope and OpenPGP-encrypted to the
recipient's **user PGP**. The audio bytes are encrypted locally with
AES-256-GCM before upload. The random 256-bit AES key and 96-bit GCM nonce
are present only in the recipient-readable manifest; they must never be
placed in HTTP JSON, a route-key command, an IPFS filename, logs, or a
mailbox plaintext field.

The encrypted audio is stored as one IPFS fragment. Clients upload the
encoded fragment in sequential **512 KiB** chunks and finalize it with the
fragment hash. The gateway rejects objects beyond the **256 MiB** gateway
boundary; clients should reject an oversized recording before starting
capture or upload. The hash identifies the encrypted fragment, not the
plaintext recording.

The receiver verifies the Chat signature and manifest fields, downloads the
fragment through the existing IPFS gateway, and lets AES-GCM authentication
fail closed before creating an object URL. Playback is local: keep the
decrypted `Blob` and its `URL.createObjectURL()` only for the active message
view, revoke the object URL when playback/unmount ends, and never persist
decrypted audio or the object URL in Chat history. A failed download,
authentication, MIME parse, size, or duration check is an unavailable voice
message—not an empty or trusted replacement.

Voice-specific replay and integrity rules are application rules: bind the
payload to the Chat `sendId` (and, where the client supports it, a message
nonce/expiry), deduplicate before playback, verify the EIP-191 sender
signature, verify the fragment hash over the uploaded encoded ciphertext,
and rely on AES-GCM authentication before release to an audio decoder.
Neither an IPFS hash nor an HTTP 2xx is proof that a human heard the clip.

Privacy modes are product configuration, not SI commands. A client may offer
voice disabled, contacts-only, recipient-only delivery, recording-length and
size limits, upload through a selected entry set, and local-only retention
policy. These options must not weaken recipient user-PGP encryption or put
the AES key in a route-visible command. Applications should disclose that
mailbox/entry nodes can still observe ciphertext size, timing, fragment
arrival, and listen state; optional padding or delayed upload is a future
application mode, not a property of the current protocol.

## Real-time voice calls

Real-time calls are a separate application stream from `voice_message_v1`.
They never consume the normal `mailbox_listen` Chat SSE, which stays open for
messages, attachments, delivery receipts, call control and offline flush.
Media uses temporary voice sessions with voice channel v2; offers go to the
callee's mailbox with `voice_offer_store`. The wire format, the v1 fallback and
the planned payer-signed channels are described under
[Voice-call wake-up and offer delivery](#voice-call-wake-up-and-offer-delivery).

```text
Caller ── voice_offer_store { push: 1, offerArmor } ──> callee mailbox ──> push / callee SSE
Caller ── voice_listen { v: 2, wk } ──> caller's session node
Callee ── voice_listen { v: 2, wk } ──> callee's session node
Caller ── CVC2 chunk (callee locator) ──> callee's session node ──> callee voice SSE
Callee ── CVC2 chunk (caller locator) ──> caller's session node ──> caller voice SSE
Either side ── call control as a Chat message ──> peer mailbox ──> peer mailbox SSE
```

The session key reaches the callee only inside the signed recipient-PGP offer.
It must never appear in `voice_listen`, a chunk header, HTTP JSON, SSE
plaintext, logs, or mailbox storage outside the encrypted offer. Voice
commands carry no wallet and no wallet signature; the locator and write key
are the only credentials. Frames are not saved to offline Chat, APNs,
`ChatIndexRegistry`, or encrypted history. A successful relay means only that
a chunk entered the peer's SSE queue.

## Encrypted history (optional second track)

L0 does not store Chat history. Apps that promise cross-device recover use:

| Item | Value |
| --- | --- |
| Registry (UUPS proxy) | [`ChatIndexRegistry`](https://mainnet.conet.network/address/0x1511Caa71081C84d8a591490D1b83879088EED72) `0x1511Caa71081C84d8a591490D1b83879088EED72` |
| Read pointer | RPC `getPointer(eoa)` on CoNET L1 (not Cluster-only) |
| Write pointer | EIP-712 `SetPointer` → Cluster `POST /api/setChatIndexPointer` (gas relay) |
| Fragments | `https://ipfs.conet.network/api/storageFragment` / `getFragment?hash=` |
| Hash | `keccak256(utf8(cipherB64))` |

Local `profile.chats` is the UI track. After recover it may be empty. Decrypt the index, **create missing sessions** by peer EOA, then merge. Do not `if (!chats.length) return`. POS permission and delivery receipts stay off the encrypted history track.

Keys are derived in a Worker from an EIP-191 domain over the EOA. Without the EOA signing key, history is unreadable. See the product page and chat-sdk `history` worker for the HKDF labels.

History synchronization is a union merge, not a length-based table replacement. Records are deduplicated by `sendId`, or by `cid` when no `sendId` exists, preserving unique appends from both devices. A conflicting `seq`/`cid` or `prevCid` fork is repaired by decrypting the records, ordering them by timestamp and `sendId`, re-encrypting them with a new linear chain, uploading the fragments, and publishing the new pointer. Network failure or an incomplete pull must preserve the trusted local mirror. The Worker serializes mutations and runs background `syncFromHead()` on a non-overlapping `setTimeout` chain, which is cleared when the Worker is destroyed; `setInterval` is not used.

The same Worker keeps a **local plaintext corpus** of fragments it has already decrypted. Each record is keyed by fragment `cid` and stored in Worker memory and Worker IndexedDB (`beamio.chat.history.plain:{eoa}:{cid}`), together with a search string taken from the rendered message (text, call status, file name, a voice-message marker, payment title). Read order for a `cid` is memory, local plaintext, local ciphertext, then IPFS. A `cid` already in the corpus is not downloaded again. A newly sent message is stored as plaintext when it is encrypted. When the chain head hash is unchanged, the Worker skips the index download.

UI code does not fetch history itself. It calls the module:

| Host function | SDK call | Behavior |
| --- | --- | --- |
| `readDecryptedChatHistory(options?)` | `history.read` | Full local corpus, optional `peer` and `limit`. No chain or IPFS round trip |
| `searchDecryptedChatHistory(query, options?)` | `history.read({ query })` | Whitespace-separated tokens, all required, case-insensitive, over the rendered text of the whole corpus |
| `onDecryptedChatHistory(cb)` | corpus published after `history.load` | UI merges newly materialized rows into sessions |

`history.read` does not sync the chain. When the Worker is not ready the host bridge returns `null`. That is an untrusted miss, not an empty history. Do not log the query string or message bodies. Cross-device recover still uses RPC `getPointer` and IPFS when local plaintext for a `cid` is missing. HTTP `/post` stays `{ "data" }` only; this corpus adds no wire field.

## Using the SDKs

Three implementations share one command protocol: the TypeScript Worker
(`@conet.project/chat-sdk`, used by browsers), [chat-sdk-ios](https://github.com/CoNET-project/chat-sdk-ios)
and [chat-sdk-android](https://github.com/CoNET-project/chat-sdk-android). Inside
the iOS and Android apps the page never starts a Worker; it talks to the native
module.

**Live (chat-sdk-ios 0.1.7, chat-sdk-android 0.2.5).**

- The page calls `provisionIdentity` once with the wallet private key, the user
  PGP keys and the own route key. The native SDK stores them only in the
  Keychain (`AfterFirstUnlockThisDeviceOnly`) or the Keystore and refuses if it
  cannot. `clearIdentity` wipes them on sign-out or wallet change. Browsers keep
  the keys only in Worker memory, never on disk.
- The native daemon signs `mailbox_listen`, ACKs and sends itself and owns the
  mailbox SSE. It connects only while the app is in the foreground, while a call
  push is ringing, and during a call; nothing runs after the app exits. A call
  push opens the listen without waiting for the page.
- Messages that arrive while no page is loaded are kept as PGP ciphertext and
  ACKed once the page has taken them.
- The native SDK posts to entries by IP over plain HTTP on port 80 (see the
  known limitations on [CoNET Chat](../applications/depin-chat.md#known-limitations)).

**In rollout.**

- `hello` is the first command (ChatDaemon protocol v1). The answer lists
  `protocolVersion`, `sdkVersion` and capabilities; hosts decide by capability,
  not by checking whether a method exists. Daemons that do not answer keep the
  pre-v1 behaviour. The spec and shared test vectors live in
  `@conet.project/chat-sdk` (`src/protocol.ts`, `spec/`).
- The native SDK keeps a pool of about 8 probed, healthy random entries, so a
  send picks one at once. Probes carry no wallet or signature. Each send still
  uses a different entry and excludes both mailboxes. The pool runs only while
  the daemon is active.
- The native SDK maintains the node table itself, like CoNET-SI does: it reads
  the storage root of `GuardianNodesInfoV6` and pulls the full table only when
  the root changes. The page's node list is secondary.
- Pages send through the native `send` instead of posting ciphertext
  themselves.

**Planned (ChatDaemon P2–P4).** Inbound verification, storage and ACK move into
the daemon, which becomes the only message store (the page's chat list is a
display cache); then sending, presence, offers, nodes and route registration;
then the old sign broker and legacy history paths are removed.

Host responsibilities that remain:

- implement UI ingest: classify typed payloads, create sessions on recover;
- register coupon / tag / merchant data on your own stores; the SDK is the gossip plane;
- keep secrets out of logs.

If you hand-roll, keep the same A/B/C and envelope rules so mailboxes stay interoperable with Beamio clients.

## Diagnosis: “I sent but they never see it”

Walk this order. Do not skip to “the parser is broken.”

1. Recipient EOA equals the AddressPGP row you encrypted to (not AA, not a prefix-search collision). Never take `search-users` `results[0]`.
2. Recipient listen is up as `mailbox_listen` (with `streamKey` once its mailbox runs the rollout SI) and SSE Connected. A legacy `mining` + `listenKind: "chat"` listen stops receiving Chat after the rollout. Epoch / listing heartbeats prove the pipe is alive; they are not inbound Chat. If the console shows only `[Gossip] Unknown format` and no message, the business armor never entered **this** mailbox — do not conclude “the parser is broken.”
3. If the Worker reports `connect_timeout` (~12s) and changing C still fails: check whether C **peeled** then threw on hop-sign (`string` / instance of `h`) and **never** `socketForward` to B. A log-only `uncaughtException` leaves the SSE open until the client timer. See [Peel, hop-sig, and listen timeouts](peel-hop-listen.md).
4. SI `forward <ip>` after peel is the **client source IP**, not mailbox B.
5. Mailbox logged `forWard SUCCESS` or `save to Local`. Offline users get a flush on next listen; the client must process that flush (do not skip the first SSE event) and dedupe `sendId`.
6. Fake-armor **404** is SI rejecting bad PGP, not a down node.
7. Sender used an entry that is neither mailbox. Direct-to-B is not the product path. After the rollout, a send without the recipient's mailbox route key fails with `recipient_mailbox_unknown` before any POST.
8. Recipient `isMyRoute` / wallet↔route hash consistency can block listen and presence without blocking user-PGP store.

## Group chat V1 (small groups)

<a id="group-chat-v1-small-groups"></a>

Group chat V1 is an **application composition** over the same single-recipient
Layer Minus path. It does **not** introduce a multi-recipient OpenPGP armor,
an SI group command, or a shared group mailbox.

| Constraint | Value |
| --- | --- |
| Max members | **10** (`GROUP_V1_MAX_MEMBERS`) |
| Delivery | One OpenPGP encrypt per recipient **user PGP**; N independent `POST { data }` |
| SI | Rejects multi-recipient armor (`rejected_multi_recipient_armor`) |
| Roster authority | **Owner-only** signed `conet_group_roster_v1` |
| Larger groups / FS | Deferred to Chat crypto **V3** (MLS / epoch) — [security limits](security-limits.md#chat-crypto-profile-roadmap) |

### Typed objects (inside user-PGP ciphertext)

| Type | Who signs | Role |
| --- | --- | --- |
| `conet_group_roster_v1` | Owner EOA | Canonical membership + admins; `version`, `prevRosterHash`, `members[]`, `policy`, validity window |
| `conet_group_admin_proposal_v1` | Admin EOA | Proposal only — does **not** change local roster until the owner issues the next roster |
| `conet_group_tombstone_v1` | Owner EOA | Ends the group; clients stop accepting new messages for that `groupId` |
| `conet_group_message_v1` | Sender EOA | Body bound to `groupId`, `rosterHash`, `sendId`, `seq`, expiry |
| `conet_group_delivery_v1` | (carrier) | Optional padding wrapper around a message before encrypt |

Signatures are EIP-191 over `CoNET <kind> v1\n` + canonical JSON (signature field omitted from the hash). Recipients verify and reject on mismatch.

### Roster chain

1. First roster: `version === 1`, `prevRosterHash === null`.
2. Next roster: `version === current + 1` and `prevRosterHash === keccak256(utf8(canonicalJSON(current)))`.
3. Owner must remain a member; admins ⊆ members; no duplicate EOAs; member count ∈ `[1, 10]`.
4. Clients apply only after `assertNextGroupRosterV1` (or equivalent). Forks and skipped versions fail closed.

### Delivery privacy

```text
for each member except sender:
  pad body to fixed bucket (default 4096 bytes)
  EIP-191 envelope (same Chat outer shape)
  OpenPGP encrypt to that member’s user PGP  (exactly one key)
  (in rollout) wrap to that member’s mailbox B route PGP
  POST { data } through one random entry ≠ that member’s mailbox B and ≠ own mailbox
```

- Prefer **distinct entries** across the fan-out so no single entry observes the full recipient set.
- Bound concurrency (SDK default ≤ 4, typically 2) and add small jitter between posts.
- Do **not** compress before encrypt when using fixed-bucket padding.
- Verify the recipient OpenPGP fingerprint against the active roster before encrypt.
- Logs must not print roster, member EOAs, fingerprints, body, or armor.

Partial fan-out success is application-visible (`acceptedRecipients` /
`failedRecipients`). Transport `2xx` on one recipient is not group delivery.

### Client apply order

1. Decrypt + verify outer Chat envelope (`verifyMessage` → sender).
2. Parse typed group object; verify object signature.
3. For messages: require `rosterHash` to match the locally accepted roster;
   reject if tombstoned or expired.
4. For proposals: store pending; wait for owner roster.
5. For roster / tombstone: apply only if owner-signed and chain rules pass.

Reference implementation: `vendor/conet-chat-sdk` (`group.ts`,
`GossipCore.sendGroup`). SDK is the protocol surface; UI only displays results.

## Checklist

- [ ] Sender registered (`regiestChatRoute` + `searchKey` shows the local subkey)
- [ ] Business encrypt-to recipient **EOA user PGP**; listen/ACK/presence/offer store encrypt-to **route PGP**
- [ ] (rollout) Every delivery wrapped to the recipient mailbox route PGP; no route key → `recipient_mailbox_unknown`
- [ ] One entry at a time, excluding both mailboxes; next entry only after a clear failure
- [ ] `searchKey` for a contact sent without `eth_call` `from`
- [ ] Group V1 uses **one armor per member** (no multi-recipient OpenPGP); SI rejects multi-key armor
- [ ] Group roster / tombstone are owner-signed; proposals do not mutate roster alone
- [ ] Listen is `mailbox_listen` via **C ≠ B**; (rollout) fresh `streamKey`, sealed frames opened before parsing
- [ ] `connect_timeout` starts after `fetch`; `listening` requires `res.ok` + body
- [ ] Peel / hop-sign failure is diagnosed before “switch C” or “parser broken”
- [ ] `@tag` resolution is exact; no `results[0]`
- [ ] Inbound sender = recovered signer; a different claimed `from` is a warning, not a drop; typed unwrap walks `text`
- [ ] Dual receipts after ingest; receipts and POS permission are not Messages rows
- [ ] Presence is `wallet_online_query` via entry C ≠ B; failures do not clear a trusted green dot
- [ ] Native shell status is `wallet_native_wake_query` via that same entry, after presence, so mailbox B never sees the querier's IP
- [ ] Call offers go only to the callee mailbox (`voice_offer_store`, `push: 1`); no `targetWallet` / `offerArmor` on `voice_listen`
- [ ] Call control (cancel, decline, timeout, hang-up) is sent as Chat messages through the mailbox
- [ ] Voice commands carry no wallet and no wallet signature; chunks are v2 `CVC2`
- [ ] Recover creates missing sessions before merge
- [ ] No private keys, full private PGP, `streamKey`, write keys or session keys in logs

## Related

- [L0 development](../developers/l0.md)
- [SI developer guide](si-developer-guide.md)
- [How to use Layer Minus](using-l0.md)
- [Zero-trust mailbox routing](mailbox-routing.md)
- [Peel, hop-sig, and listen timeouts](peel-hop-listen.md)
- [Wallet-addressed peer identity](wallet-address-p2p.md)
- [UDP frame forwarding](udp-forward.md)
- [Security limits](security-limits.md)
- [CoNET Chat](../applications/depin-chat.md)
- [Resources](../resources.md)
