# CoNET Chat developer guide

**Evidence level: Implemented capability.** This page is a developer how-to for **CoNET Chat** on Layer Minus. The envelopes, commands, and APIs match current Beamio / chat-sdk clients. It is not a claim that Chat is a finished replacement for mainstream messengers.

CoNET Chat is relationship-private communication infrastructure: wallet identity, zero-trust mailbox routing, encrypted application envelopes, and wallet-controlled encrypted history. Use it to add wallet-addressed communication **without** first building a centralized user-and-relationship database. Product thesis, Beamio integration, and maturity limits live on [CoNET Chat](../applications/depin-chat.md).

Public site: [https://gitbook.conet.network/l0/chat-developer-guide.html](https://gitbook.conet.network/l0/chat-developer-guide.html)

L0 only forwards OpenPGP by wallet / key ID. Chat is an **application composition**: user-PGP business envelopes, mailbox listen, dual receipts, presence, and an optional encrypted history track. SI primitives and reusable helpers live on the [SI developer guide](si-developer-guide.md). Developer-track index: [L0 development](../developers/l0.md).

Public packages: [CoNET-project/chat-sdk](https://github.com/CoNET-project/chat-sdk) · [`@conet.project/chat-sdk`](https://www.npmjs.com/package/@conet.project/chat-sdk). Reference clients: SilentPassUI [`cashtree`](https://github.com/CoNET-project/SilentPassUI/tree/cashtree) (consumer) and [`cashtrees`](https://github.com/CoNET-project/SilentPassUI/tree/cashtrees) (merchant).

## What a Chat client must implement

| Step | Encrypt to | Transport |
| --- | --- | --- |
| Register user PGP + mailbox | — | `POST https://beamio.app/api/regiestChatRoute`, then confirm with AddressPGP `searchKey` |
| Send a message | Recipient **EOA user PGP** | `POST /post` to healthy entries **A ≠ B** |
| Listen | Own mailbox **B route PGP** | SSE via entry **C ≠ B**, preferred `command: "mailbox_listen"`; legacy `command: "mining"` + `listenKind: "chat"` remains supported |
| After inbound ingest | (1) **B route PGP** ACK · (2) sender user PGP receipt, then mailbox-work wrap `NoPush` to sender mailbox B | ACK and receipt both via entries ≠ B; HTTP still `{ data }` only. `NoPush` is **Chat/APNs only**. L0 duplex mailbox work must omit it; see [duplex-forward](duplex-forward.md) |
| Presence (green dot) | Contact mailbox **B route PGP** | `wallet_online_query` via **entry C ≠ B** (never dial B; that hides the querier's IP) |
| Native shell status | Contact mailbox **B route PGP** | `wallet_native_wake_query` via the **same entry C ≠ B**, after presence |
| Optional recover history | — | Encrypted IPFS fragments + `ChatIndexRegistry` head pointer |

## Relationship-privacy field contract

The application sender wallet is confidential routing metadata until the
recipient decrypts:

```text
{ from: senderEOA, text, signature }
  → encrypt complete object to recipient user PGP
  → POST { data: armor } through entry A
```

| Role | Receives | Must not receive |
| --- | --- | --- |
| **Entry A** | Client IP, ciphertext, timing, size, outer key ID | Plaintext sender wallet or Chat body |
| **Mailbox B** | Destination route, stored armor, listen state | Sender wallet inside the business envelope or Chat body |
| **Listen entry C** | Recipient-side connection IP, encrypted listen/control traffic | Decrypted Chat body |
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

## Voice-call wake-up push

Voice calls keep the media path end-to-end encrypted, but a device may need a
native wake-up before its Chat SSE is active. The caller opens its
voice-specific SSE through its own mailbox route B in one command. That
`voice_listen` carries the opaque wake-up fields and `offerArmor`, the call
offer already encrypted to the callee user PGP:

```json
{
  "command": "voice_listen",
  "targetWallet": "0xCallee",
  "callId": "opaque-call-id",
  "sessionId": "voice-session-opaque-id",
  "expiresAt": 1710000123456,
  "pushTimestamp": 1710000000,
  "offerArmor": "-----BEGIN PGP MESSAGE-----\n...\n-----END PGP MESSAGE-----"
}
```

`callId` is a random wake-up reference and must not contain the caller's
`@BeamioTag` or wallet address. `sessionId` is the per-call unique identifier
and must be used for deduplication. Before push, the caller's mailbox forwards
`offerArmor` to the callee mailbox by the armor's recipient key id. It stores
the ciphertext when that mailbox is itself, and otherwise sends one SI hop.
It does not decrypt `offerArmor`, and the caller does not POST the offer
again. After the caller's mailbox has accepted the voice SSE and sent its
`voice_ready` handshake, that mailbox calls `/api/voiceCallPush` with only the
signed metadata. The caller PWA never calls this endpoint, and it does not
send a second `voice_call_push` command to the callee mailbox. This keeps the
caller's network address outside the push API path while preserving the
existing entry-to-mailbox routing.

The mailbox must verify that the voice session belongs to its route, validate
the target and expiry, and forward only the minimal metadata to the API. It
must never decrypt or log the user-PGP offer, and it must never forward the
PGP session key, private key, or audio.

The API sends the metadata-only wake-up to registered native devices:
`ios_voip` uses APNs PushKit/CallKit and `android` uses high-priority FCM.
The native shell then opens the system call UI and the PWA obtains the
encrypted offer through its normal Chat mailbox path. A push response is not
proof that the call offer was delivered or answered.

### Implemented initiator-hidden voice protocol

`walletAddress` is intentionally absent: the mailbox authenticates the
encrypted route command by its
destination route and keeps only the opaque `sessionId`. The initiating
application EOA is never sent as `walletAddress`, `callerEoa`, `callId`, or a
signature that the mailbox can recover.

The mailbox-visible shape is:

```json
{
  "command": "voice_listen",
  "callId": "opaque-call-id",
  "sessionId": "opaque-session-id",
  "targetWallet": "0xCallee",
  "expiresAt": 1710000123456,
  "pushTimestamp": 1710000000,
  "offerArmor": "-----BEGIN PGP MESSAGE-----\n...\n-----END PGP MESSAGE-----"
}
```

`offerArmor` is the signed call offer already encrypted to the callee user
PGP. The caller's mailbox forwards that ciphertext and does not decrypt it.
The plaintext caller wallet remains only inside that offer. The callee does
not trust `from` or a tag inside that offer. It recovers the caller with
`callerSignature` (see [Inbound identity verification](#inbound-identity-verification))
and looks up `@BeamioTag` for that address. `callId` is generated solely for
native wake-up and is unrelated to the caller's BeamioTag or EOA. The session
authority is the opaque `sessionId`, scoped by expiry and mailbox route.

The plaintext initiating application EOA is absent from `voice_listen`, frame
commands, SSE frames, and push metadata. The mailbox authenticates the route,
forwards `offerArmor` without decrypting it, checks the opaque session and
expiry, and relays encrypted frames without learning the initiating
application wallet.
Comparisons with other relays must use the actual fields visible to each role.

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
| Presence | Mailbox listen-pool via `wallet_online_query` through entry C ≠ B. Ignore `searchKey.routeOnline` (SI no longer writes it) |
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

⑤ POST
   { data: <armor> } → several https://{domain}.conet.network/post  (A ≠ B)
   HTTP JSON is **only** `{ data }`. **Ordinary chat** posts the user-PGP armor
   directly (no mailbox-work `NoPush`) so an offline recipient can get a native
   badge. For a **sender receipt** only, wrap ④ as mailbox work
   `{ data: armor, NoPush: true }` encrypted to the **sender mailbox B** route PGP,
   then POST that outer armor. See [SI mailbox work](si-developer-guide.md#3-mailbox-work-envelope-mailbox-b-decrypts)
   and [Native push badge and `NoPush`](../applications/depin-chat.md#native-push-badge-and-nopush).
```

Inbound: decrypt with the recipient user PGP private key → parse ③ → `ethers.verifyMessage(text, signMessage)` must recover `from`. The **recovered address is the sender**. The JSON `from` field is only a claim that must match that recovery; a nested `from: "me"` is a direction flag, not an address. Drop the message when recovery fails or the addresses differ. Then look up `@BeamioTag` for the recovered EOA. Do not display a tag or wallet copied out of ① or ②.

### Inbound identity verification

| Check | What the recipient trusts | What it must not trust |
| --- | --- | --- |
| **Inbound chat message** (text, `voice_message_v1`, file, any Messages bubble) | `verifyMessage(text, signMessage)` equals claimed `from`. That address is the session peer and the bubble sender | `from`, a wallet, a display name, or `@BeamioTag` inside the JSON. Pending-row `from: "me"` is only a direction flag |
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

The caller signs that string with the same EOA private key (`signMessage`). The callee recovers the address and only then looks up the tag. If recovery fails, or it disagrees with the outer-envelope signer, do not present the offer’s claimed identity. A body claim that disagrees with the recovered key may be shown only as an extra unverified line with a warning. Native wake-up stays generic until this on-device check finishes.

POS terminal authorization nests another object inside ① (`type: "beamio_pos_terminal_permission_v1"`). Merchant OS must unwrap along `text` and put it on **Staff pending**, not Messages. See [CoNET Chat](../applications/depin-chat.md).

## Sample: send

Reuse `postArmor` / entry picking from the SI guide. This is the live Chat envelope.

```ts
import { createMessage, encrypt, enums, readKey } from 'openpgp'
import { ethers } from 'ethers'

export type ChatPendingRow = {
  sendId: string
  from: 'me'
  text: string
  createdAt: number
}

export async function sendChatMessage(opts: {
  wallet: ethers.Wallet
  recipientUserPublicKeyArmored: string
  mailboxDomain: string
  entryDomains: string[]
  body: string
  sendId?: string
}): Promise<{ ok: boolean; sendId: string }> {
  const sendId = opts.sendId ?? crypto.randomUUID()
  const pending: ChatPendingRow = {
    sendId,
    from: 'me',
    text: opts.body,
    createdAt: Date.now(),
  }
  const text = JSON.stringify(pending)
  const signMessage = await opts.wallet.signMessage(text)
  const envelope = {
    timestamp: Date.now(),
    text,
    from: opts.wallet.address,
    signMessage,
  }
  const pgpMsg = await createMessage({
    text: Buffer.from(JSON.stringify(envelope)).toString('base64'),
  })
  const armored = await encrypt({
    message: pgpMsg,
    encryptionKeys: await readKey({ armoredKey: opts.recipientUserPublicKeyArmored }),
    config: { preferredCompressionAlgorithm: enums.compression.zlib },
  })

  const targets = opts.entryDomains.filter((d) => d && d !== opts.mailboxDomain).slice(0, 4)
  const results = await Promise.all(
    targets.map(async (domain) => {
      const res = await fetch(`https://${domain}.conet.network/post`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ data: armored }),
      })
      return res.ok
    }),
  )
  return { ok: results.some(Boolean), sendId }
}
```

HTTP 200 on any entry means the armor was accepted for forward. It does **not** mean the recipient UI ingested it. Deduplicate inbound copies by `sendId` (several entries may deliver the same armor).

## Sample: listen

Chat listen is an SI **route command**, not user-PGP business. New clients
should use `mailbox_listen`, which accepts an opaque per-device `instanceId`.
Legacy clients must set `listenKind: "chat"` on `mining`. Full helper:
[SI developer guide](si-developer-guide.md#chat-mailbox-listen-listenkind-chat).

```ts
const command = {
  command: 'mailbox_listen',
  instanceId: crypto.randomUUID(),
  walletAddress: wallet.address,
  algorithm: 'aes-256-cbc',
  Securitykey: sessionKeyBase64,
}
// sign JSON.stringify(command); encrypt { message, signMessage } to own route PGP
// Encrypt to B route PGP; POST { data } to entry C ≠ mailbox B; read SSE.
// B fans out each saved armor to every healthy instance for this wallet.
```

| Frame | Treat as |
| --- | --- |
| Handshake / `{ status, epoch, … }` | Liveness. Ignore for Messages |
| OpenPGP armor (user-PGP) | Decrypt, verify, unwrap, then **dual receipts** |
| `udp_listen_attached` / UDP frames | Only if you implement UDP; not Chat bubbles |

Keep listen on a Worker. Reconnect with another random **C ≠ B** after idle or drop. Use a `setTimeout` chain after the previous attempt finishes.

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
  from: string
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
  if (recovered.toLowerCase() !== env.from.toLowerCase()) return null
  return { from: env.from, text: env.text, timestamp: Number(env.timestamp) || 0 }
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

1. **Mailbox ACK** — SI command `gossip_delivery_ack` encrypted to **B route PGP**. Removes the matching offline store. Sample: [SI developer guide](si-developer-guide.md#mailbox-delivery-ack).
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

Mailbox stores ciphertext first (`saveLocal`), then best-effort SSE. Do not treat SSE `forWard SUCCESS` as “the user has the message.” On every durable chat save (SSE online or offline), CoNET-SI enqueues native push when the recipient EOA has a registered `pushDevice`; Beamio API no-ops if none. `NoPush` / `skipPush` frames never enter that queue. ACK removes offline armor; it does not gate whether push was sent.

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
They must **not** consume or overload the normal `mailbox_listen` Chat SSE,
which remains reserved for messages, attachments, delivery receipts and
offline flush.

Each call creates a random `sessionId`. Both wallets open a temporary
`voice_listen` SSE on their own mailbox. After the recipient accepts the call,
encrypted audio frames are sent through short `voice_uplink` or
`voice_downlink` route commands to the peer mailbox, which writes them to the
peer's temporary voice SSE. Two one-way mailbox paths form the duplex channel;
there is no peer-to-peer socket and no WebRTC candidate exchange.

```text
Caller ── voice_listen(session A + offerArmor) ──> caller mailbox
Caller mailbox ── forward offerArmor ──> callee mailbox
Caller ── voice_uplink(target session B) ──> callee mailbox ──> callee voice SSE
Callee ── voice_downlink(target session A) ──> caller mailbox ──> caller voice SSE
```

The outgoing `voice_listen` includes `offerArmor`. The caller's mailbox
forwards that user-PGP ciphertext to the callee mailbox in the same step.
The audio payload is AES-256-GCM ciphertext. The session key is delivered only
inside the recipient-only, signed Chat offer/accept envelope. It must never
appear in `voice_listen` plaintext, `voice_uplink`, HTTP JSON, SSE plaintext,
logs, or mailbox storage outside the encrypted offer. The SI node validates the signed command, route ownership,
session ownership, timestamp, sequence and size, but never decrypts the audio.

Caller session authentication uses the encrypted mailbox route and an opaque
session identifier, not the application caller EOA.
The destination mailbox may still know the wallet whose local route and SSE it
serves; the protected identity here is the initiating application wallet.

The frame shape is:

```json
{
  "type": "voice_frame_v1",
  "callId": "call-…",
  "sessionId": "session-…",
  "seq": 12,
  "timestamp": 1710000000,
  "payload": "<base64 AES-GCM frame>"
}
```

The current implementation uses bounded temporary sessions, a 60-second
timestamp window, a 12,000-character encoded payload limit, bounded queueing
under SSE backpressure, and a two-minute idle timeout. Frames are not saved to
offline Chat, APNs, `ChatIndexRegistry`, or encrypted message history. A
successful relay means only that the frame entered the peer SSE write queue; it
does not prove that the peer audio device played it.

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

## Using `@conet.project/chat-sdk`

Prefer the SDK Worker over copying OpenPGP onto the UI thread. Host responsibilities the SDK still expects:

- inject `eoa`, user PGP private/public, **own route public key**, and the Guardian node list;
- never send the EOA private key into a Worker if your product forbids it — current CoNET Chat Worker derives listen/send from material the host already holds; keep secrets out of logs either way;
- implement UI ingest: verify (if not already), classify typed payloads, dual receipts, create-session-on-recover;
- register coupon / tag / merchant data on your own stores; the SDK is the gossip plane.

If you hand-roll, keep the same A/B/C and envelope rules so mailboxes stay interoperable with Beamio clients.

## Diagnosis: “I sent but they never see it”

Walk this order. Do not skip to “the parser is broken.”

1. Recipient EOA equals the AddressPGP row you encrypted to (not AA, not a prefix-search collision). Never take `search-users` `results[0]`.
2. Recipient listen is up with `listenKind: "chat"` and SSE Connected. Epoch / listing heartbeats prove the pipe is alive; they are not inbound Chat. If the console shows only `[Gossip] Unknown format` and no message, the business armor never entered **this** mailbox — do not conclude “the parser is broken.”
3. If the Worker reports `connect_timeout` (~12s) and changing C still fails: check whether C **peeled** then threw on hop-sign (`string` / instance of `h`) and **never** `socketForward` to B. A log-only `uncaughtException` leaves the SSE open until the client timer. See [Peel, hop-sig, and listen timeouts](peel-hop-listen.md).
4. SI `forward <ip>` after peel is the **client source IP**, not mailbox B.
5. Mailbox logged `forWard SUCCESS` or `save to Local`. Offline users get a flush on next listen; the client must process that flush (do not skip the first SSE event) and dedupe `sendId`.
6. Fake-armor **404** is SI rejecting bad PGP, not a down node.
7. Sender used entries **A ≠ B**. Direct-to-B is not the product path.
8. Recipient `isMyRoute` / wallet↔route hash consistency can block listen and presence without blocking user-PGP store.

## Checklist

- [ ] Sender registered (`regiestChatRoute` + `searchKey` shows the local subkey)
- [ ] Business encrypt-to recipient **EOA user PGP**; listen/ACK/presence encrypt-to **route PGP**
- [ ] Listen includes `listenKind: "chat"` and **C ≠ B**
- [ ] `connect_timeout` starts after `fetch`; `listening` requires `res.ok` + body
- [ ] Peel / hop-sign failure is diagnosed before “switch C” or “parser broken”
- [ ] `@tag` resolution is exact; no `results[0]`
- [ ] Inbound verify recovers `from`; typed unwrap walks `text`
- [ ] Dual receipts after ingest; receipts and POS permission are not Messages rows
- [ ] Presence is `wallet_online_query` via entry C ≠ B; failures do not clear a trusted green dot
- [ ] Native shell status is `wallet_native_wake_query` via that same entry, after presence, so mailbox B never sees the querier's IP
- [ ] Recover creates missing sessions before merge
- [ ] No private keys, full private PGP, or `Securitykey` in logs

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
