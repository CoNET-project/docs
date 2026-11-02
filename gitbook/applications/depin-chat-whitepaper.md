# CoNET Chat Whitepaper: Relationship-Private Messaging and Calls on Layer Minus

**Version:** v0.1 (discussion draft) | **Date:** 1 November 2026 | **Basis:** operator decisions of 31 October and 1 November 2026; CoNET-SI `main` as deployed on the Guardian fleet; chat-sdk-ios 0.1.7, chat-sdk-android 0.2.5 and the Consumer PWA 0.52.925; the [CoNET Chat](depin-chat.md) product page and the [CoNET Chat developer guide](../l0/chat-developer-guide.md) | **Status:** discussion draft. Parts are live, parts are written but not deployed, and parts are designed only. Each section is labelled.

Wallet-addressed messages and calls in which no single node learns who talks to whom.

**How to read the labels**

- **[Live]**: deployed on the CoNET-SI fleet and in released clients.
- **[Live, being replaced]**: deployed today, and scheduled for removal by the in-rollout work.
- **[In rollout]**: code is written and tested, but not deployed. Not backward compatible unless stated.
- **[Planned]**: the design is decided by the operator; no code is deployed.
- **[Open]**: not decided; listed in Appendix B.
- **[Known limitation]**: a gap that stays after the rollout and is stated so that no page claims more.

An operator decision is not a DAO vote. Wire formats marked [Planned] are not final.

---

## Summary

CoNET Chat is a messaging and calling protocol built on Layer Minus, the
wallet-addressed routing layer of CoNET L0. It has three goals:

1. **Content privacy.** Only the recipient can read a message or hear a call.
2. **Relationship privacy.** No relay, mailbox, push service or RPC endpoint
   should learn both who sends and who receives.
3. **No platform database.** Identity is a wallet, routing state lives on
   decentralized nodes, and history is encrypted fragments that only the
   wallet can recover.

The design rests on a few rules:

- Every message is signed by the sender's wallet and encrypted to the
  recipient's user PGP key. The sender's wallet, signature and PGP key exist
  only inside that ciphertext.
- Every delivery goes through a **random entry node** that is neither the
  sender's nor the recipient's mailbox. A client never connects to a mailbox
  directly. Listening to one's own mailbox also goes through an entry.
- **[In rollout]** Every delivery is wrapped once more to the recipient's
  mailbox node, so an entry sees only a node key that many users share. The
  mailbox seals every frame of its listen stream with a per-listen key, so the
  listening entry sees only padded opaque frames.
- Call offers go only to the callee's own mailbox, which rings its own user.
  Call control (cancel, decline, timeout, hang-up) travels as ordinary
  messages through the mailbox.
- Voice and video travel over **voice channel v2** **[Live]**: after a channel
  is opened, a node sees only a channel locator and padded ciphertext, with no
  wallet, sequence number, timestamp or media type.
- **[Planned]** Voice channels are paid for by the callee through
  payer-signed temporary wallets, one per channel. Nodes verify the payer
  signature only; settlement arrives with the GB settlement module.

Section 14 lists what the protocol does **not** protect today.

---

## 1. Scope and design goals

### 1.1 Scope

This paper covers one-to-one messages, small groups (Group chat V1, at most
10 members), delivery receipts, presence, encrypted history, one-to-one voice
and video calls, native push wake-up, and the client daemon that runs all of
it. Large groups and channels (MLS or epoch keys) are research and out of
scope; see [Security limits](../l0/security-limits.md#chat-crypto-profile-roadmap).

The forwarding primitives (OpenPGP key-ID routing, peel and forward, hop
signatures, `/post`) belong to Layer Minus and are specified in
[Zero-trust mailbox routing](../l0/mailbox-routing.md) and the
[SI developer guide](../l0/si-developer-guide.md). This paper describes how
Chat composes them.

### 1.2 Goals

| ID | Goal |
|---|---|
| G1 | Message and media content is readable only by the intended recipient |
| G2 | The sender's identity (wallet, signature, PGP key) is visible only to the recipient |
| G3 | No single node learns both the sender's IP and the recipient |
| G4 | No single node learns both parties of a call |
| G5 | Media nodes receive minimal metadata once, when a channel opens, and none per chunk |
| G6 | A recipient trusts only the wallet recovered from a signature, never a claimed name or address |
| G7 | History survives device loss and is recoverable only with the wallet |
| G8 | Three implementations (browser, iOS, Android) share one protocol and one test suite |

### 1.3 Non-goals

- Hiding that a device uses CoNET Chat from its own network operator.
- Resistance to a global observer who can correlate timing on both sides.
- Hiding the client IP from the entry it connects to.
- Protection against a compromised endpoint.

---

## 2. Roles and threat model

### 2.1 Roles

| Role | What it is |
|---|---|
| Client | A browser PWA (TypeScript Worker) or a native app (iOS / Android Chat SDK) |
| Entry A | A random Guardian node that accepts a client's `POST /post` for a send |
| Entry C | A random Guardian node that relays a client's listen stream or command |
| Mailbox B | The Guardian node registered on-chain for a wallet; stores ciphertext and holds listen streams |
| Session node | The node that holds a temporary voice session (today the listener's own mailbox or a relay) |
| Push API | The service that sends APNs PushKit / FCM wake-ups to registered devices |
| CoNET RPC | Read access to CoNET L1 (AddressPGP, ChatIndexRegistry, GuardianNodesInfoV6) |
| IPFS gateway | Stores encrypted history fragments |

A, B and C are **roles** for one request, not machine classes. One node can
be an entry for one user and the mailbox for another.

### 2.2 Adversaries

Every node is assumed curious and possibly malicious. The protocol relies on
encryption and role separation, not on choosing honest operators. Considered
adversaries:

- a single entry, mailbox or session node that logs everything it sees;
- the push API and the RPC endpoint;
- a network observer between a client and its entry;
- a peer who tries to impersonate another wallet;
- a peer who tries to waste another user's resources (relevant to paid voice).

Collusion between an entry and a mailbox, one operator running several roles,
and a global timing observer can relink identities. They are acknowledged in
Section 14, not defended against.

---

## 3. Identity and keys

### 3.1 Keys

| Key | Owner | Purpose |
|---|---|---|
| Wallet (EOA) | User | Identity; signs messages, listen commands, ACKs, offers |
| User PGP | User | Encryption target for every message and offer |
| Route PGP | Mailbox node | Encryption target for commands that the mailbox executes and for the mailbox layer of deliveries |
| `streamKey` | One listen session | **[In rollout]** Seals frames of one mailbox listen stream |
| Channel key and write key | One voice channel | AES-GCM media key; write key authorizes chunks on a session node |
| Temporary wallet | One voice channel | **[Planned]** Proves that a payer funds the channel |

A wallet registers its user PGP key and its mailbox binding in the AddressPGP
contract on CoNET L1. `@BeamioTag` is a display label looked up by address,
never an identity.

### 3.2 Looking up a contact

A client reads `AddressPGP.searchKey(contact)` over CoNET RPC to get the
contact's user PGP key and mailbox route key. The call does not depend on who
asks. **[Live, being replaced]** The Consumer PWA sends this `eth_call` with
its own wallet as `from`, so the RPC endpoint sees both wallets and the IP.
**[In rollout]** The lookup carries no `from`. Only reading one's own
encrypted private key identifies the caller, as it must.

### 3.3 Inbound identity

The sender of a message is the wallet recovered from its EIP-191 signature,
and nothing else:

1. Decrypt with the recipient's user PGP private key.
2. Recover the signer with `verifyMessage(text, signMessage)`.
3. File the message under the recovered signer. If the envelope's claimed
   `from` differs, keep the message and show a warning on it that names the
   claimed address. Drop the message only when no signer can be recovered.
4. Look up `@BeamioTag` for the recovered address only.

A call offer carries a second signature, `callerSignature`, over a canonical
text that excludes identity fields; it must recover the same wallet. Native
SDKs pass both the signer and the claim to the app; they do not drop messages.

### 3.4 Routing wallet split

An application may register AddressPGP and sign listens, ACKs and presence
with a dedicated routing wallet, and keep the product wallet only inside
encrypted messages. The mailbox then sees the routing wallet. See
[Wallet-addressed peer identity](../l0/wallet-address-p2p.md#routing-wallet-versus-sender--recipient-wallets).
Beamio clients currently use one wallet for both.

---

## 4. Message delivery

### 4.1 Envelope layers

```text
① body         plain text, or typed JSON (receipt, file manifest, call control, …)
② pending row  { sendId, from: "me", text: ①, createdAt }
③ envelope     { timestamp, text: JSON(②), from: senderEOA, signMessage: sign(text) }
④ user layer   OpenPGP( base64(JSON(③)) ) → recipient user PGP
⑤ mailbox layer  OpenPGP( JSON({ data: ④, NoPush? }) ) → recipient mailbox route PGP   [In rollout: always]
⑥ HTTP         POST /post  { "data": "<armor>" }  to one random entry
```

The HTTP body is only `{ "data": "<armor>" }`. Flags such as `NoPush` live
inside layer ⑤, which only the mailbox can read. Each OpenPGP armor exposes the
key ID of its recipient; that side channel is how nodes route.

**[Live, being replaced]** Ordinary messages are posted as layer ④ directly,
so entry A reads the recipient's user key ID, which is public on chain. Only
receipts carry layer ⑤.

**[In rollout]** Every delivery carries layer ⑤. Entry A sees only the
mailbox node's route key ID, shared by all users of that node. If the client
cannot find the recipient's mailbox route key, the send fails with
`recipient_mailbox_unknown`; it never falls back to layer ④ alone.

### 4.2 Choosing an entry

- The entry is random for every delivery, and is neither the recipient's
  mailbox nor the sender's own mailbox. A mailbox that saw a direct
  connection would learn the sender's IP.
- **[In rollout]** One entry at a time. The client switches to another
  entry only after a clear failure, and tries at most four. A clear failure
  is a connection error, a reset before any response, a non-2xx status, a 2xx
  body `{"ok": false}`, or no response within about 8 seconds.
  **[Live, being replaced]** Browser clients post one message to up to four
  entries in parallel; native SDKs were already sequential.
- A timeout may hide a delivery that did arrive, so a retry can create a second
  copy of the same ciphertext. **[In rollout]** The mailbox stores one copy per
  armor hash; recipients deduplicate by `sendId`.

### 4.3 At the mailbox

The entry forwards the armor by key ID to mailbox B. B unwraps layer ⑤ (in
rollout), stores the user-layer ciphertext, and then pushes it to every live
listen session of that user. Store comes first: a message is never only in
flight. B keeps the offline copy until the recipient's ACK.

`NoPush` means "do not send a native push for this delivery" and is used for
sender receipts. **[Live, being replaced]** The deployed SI drops the flag
when it unwraps the work envelope. **[In rollout]** The flag is honoured.

### 4.4 Receipts and ACK

After the recipient has verified and **stored** a message:

1. **Mailbox ACK** `gossip_delivery_ack`: encrypted to B's route key, through
   an entry; carries the armor hash. B deletes the offline copy.
2. **Sender receipt** `beamio_chat_delivery_receipt_v1`: an ordinary signed
   message to the sender, with `NoPush: true`. The sender marks the bubble
   delivered and does not show a new row.

### 4.5 Groups (Group chat V1)

A group message is N independent one-recipient deliveries, one per member,
each padded to a fixed bucket and encrypted to exactly one key. SI rejects an
armor with more than one recipient key ID, because it would reveal the member
set. Roster and tombstone objects are owner-signed and live inside the
ciphertext. Details:
[Group chat V1](../l0/chat-developer-guide.md#group-chat-v1-small-groups).

---

## 5. Listening

### 5.1 Mailbox listen

A client receives messages by holding a long-lived SSE stream from its own
mailbox:

```text
client ── POST { data: OpenPGP(signed mailbox_listen) → B route PGP } ──▶ entry C ──▶ mailbox B
client ◀────────────────── SSE frames ─────────────────── C ◀──────────────────── B
```

`mailbox_listen` is signed by the user's wallet and carries an opaque
per-device `instanceId`. One wallet may hold several sessions; B fans every
message out to all of them. Entry C must not be B. Keepalives are sent on a
60–180 second jittered schedule for connection reliability.

### 5.2 Sealed listen stream

**[Live, being replaced]** B writes each frame as plaintext JSON
`data: {"data": "<armor>"}`. Entry C therefore sees the recipient key ID of
every delivered message.

**[In rollout]** The listen command carries a fresh 32-byte `streamKey`,
created for each listen and kept only in memory. B refuses a listen without
it. Every frame B writes (handshake, offline flush, live message, keepalive)
is:

```text
data: base64( iv[12] ‖ AES-256-GCM( frameJSON padded with spaces to a multiple of 256 bytes ) ‖ tag[16] )
```

The IV is random per frame, because a reconnect may reuse the same encrypted
command and therefore the same key. Entry C sees only B's address, frame
timing and 256-byte length buckets. A client drops a frame it cannot open,
and reconnects with a new key after three in a row. The ACK still hashes the
inner user-layer armor.

### 5.3 Legacy listen pool

**[Live, being replaced]** Older clients listen with `mining` +
`listenKind: "chat"`. **[In rollout]** That pool receives no Chat messages,
because its frames cannot be sealed; it keeps presence and mining only.

---

## 6. What each role sees

| Role | Live | After the in-rollout work |
|---|---|---|
| Entry A (send) | Sender IP, size, timing, **recipient's user key ID** | Sender IP, size, timing, recipient mailbox node's route key ID |
| Entry C (listen) | Listener IP, **key ID of every delivered message** | Listener IP, B's address, frame timing, 256-byte buckets |
| Mailbox B | Its own user for each message, entry IPs (not client IPs), ciphertext, ACK hashes, listen membership; presence queriers | Same, plus `NoPush` honoured and one copy per ciphertext |
| Session node (voice v2) | Entry IPs, channel locator, write key, padded chunk ciphertext and timing | Same; [Planned] also the payer wallet of the channels it serves |
| Push API | The woken user's registered device, opaque `callId` / `sessionId` | Same |
| CoNET RPC | Looked-up addresses, client IP, **own wallet as `from`** | Looked-up addresses, client IP |
| IPFS | Encrypted fragments | Same |

No role in either column sees message plaintext, the sender's wallet, or a
session key.

---

## 7. The Chat daemon

### 7.1 One daemon, three implementations

All protocol work (signing, encryption, routing, listening, ACKs, history,
presence, call signalling) runs in a **daemon**. The app's UI only displays
results and passes user actions. Three daemons implement one command protocol:

| Environment | Daemon |
|---|---|
| Browser | TypeScript Web Worker (`@conet.project/chat-sdk`) |
| iOS app | chat-sdk-ios (Swift) |
| Android app | chat-sdk-android (Kotlin) |

Inside a native app the page never starts a Worker.

### 7.2 Native key custody **[Live]**

At sign-in the page hands the wallet private key and the user PGP keys to the
native SDK once (`provisionIdentity`). The SDK stores them only in the iOS
Keychain (`AfterFirstUnlockThisDeviceOnly`, not synced) or as ciphertext under
an Android Keystore key (excluded from backups), never logs them, and wipes
them on `clearIdentity`. It signs listens, ACKs and messages itself. The
browser daemon keeps keys only in Worker memory, never on disk.

### 7.3 Lifecycle **[Live]**

The native daemon runs only while the app is in the foreground, while a call
push is ringing, and during a call (including with the screen locked).
Nothing keeps running after the app exits: no Android foreground service for
Chat, no new iOS background mode. While it runs, the mailbox listen stays open
the whole time, including during dialing, ringing and calls, so messages from
others still arrive mid-call. A call push opens the listen with the stored
keys without waiting for the page. Messages that arrive with no page loaded
are kept as ciphertext and ACKed once the page has taken them.

### 7.4 Entry pool and node table **[In rollout]**

- The native daemon keeps a pool of about eight probed, healthy random
  entries while it is active, so a send picks one immediately. Probes carry no
  wallet and no signature. Each send still uses a different entry and
  excludes both mailboxes.
- The daemon maintains the node table itself, the same way CoNET-SI does: it
  watches the storage root of the `GuardianNodesInfoV6` contract and pulls the
  full table only when the root changes, with sanity checks against an empty
  or sharply shrunken table. The page's node list is secondary.

### 7.5 ChatDaemon interface

| Phase | Content | Status |
|---|---|---|
| P0 | Native key custody, local signing, daemon-owned listen lifecycle, native recognition of caller cancel | **[Live]** |
| P1 | Versioned protocol spec (`src/protocol.ts` plus generated JSON Schema), `hello` capability handshake, shared test vectors run by all three daemons | **[In rollout]** |
| P2 | Inbound verification, parsing, storage and ACK inside the daemon; the daemon's store is the single source of truth and the page's chat list a display cache | **[Planned]** |
| P3 | Sending, presence, offers, nodes and route registration inside the daemon; no OpenPGP on the UI thread | **[Planned]** (native entry pool and node table already in rollout) |
| P4 | Remove old paths: the page sign broker, legacy history, the separate posPwa SDK copy | **[Planned]** |

`hello` is the first command. Its answer lists `protocolVersion`,
`sdkVersion` and capabilities; the page decides by capability, never by
checking whether a method exists. Each command in the spec is annotated with
whether it carries a wallet signature, whether it goes through an entry, and
what nodes see.

---

## 8. Call signalling

### 8.1 Offer and ring **[Live]**

```text
caller: offer = sign({ callId, sessionId, to, createdAt, expiresAt, sessionKey, … })
        → encrypt to callee user PGP
        → voice_offer_store { callId, sessionId, expiresAt, push: 1, pushTimestamp, offerArmor }
          encrypted to the CALLEE's mailbox route PGP, through a random entry ≠ either mailbox
callee mailbox: store offerArmor under callId + sessionId; find its own user from the
        offer's recipient key ID; ask the push API to ring that user; answer { ok, pushed }
```

The callee mailbox already serves the callee, so no other node learns whom the
caller is calling. `callId` is random and unrelated to the caller's wallet or
tag. The command carries no wallet and no signature; `sessionId` is the
capability for this offer. The mailbox never decrypts the offer.

**[In rollout]** The callee mailbox also writes the offer into the callee's
live listen stream, so a browser callee needs nothing else.

**[Live, being replaced]** If the callee mailbox does not confirm
`pushed: true` within about three seconds, current clients send a legacy
`voice_listen` to the **caller's** own mailbox carrying `targetWallet` and
`offerArmor`; that mailbox forwards the offer and rings the callee, and so
learns the callee's wallet. **[In rollout]** The fallback is deleted from every
client and ignored by the node. The callee-mailbox ring is the only wake path.

### 8.2 Killed-app wake **[Live]**

The push carries only `callId` and `sessionId`. The woken native daemon shows
the system call UI with a neutral label, fetches the offer with
`voice_offer_fetch` (encrypted to its own mailbox, through an entry), decrypts
it with its stored user PGP key, recovers the caller from `callerSignature`,
and updates the call UI with the verified `@BeamioTag` and a shortened
address.

### 8.3 Call control through the mailbox

Every online client keeps its mailbox listen open during a call, so call
control needs no separate channel. Cancel, decline, ring timeout and hang-up
are **ordinary signed messages** encrypted to the peer and delivered through a
random entry, exactly like text. A connected call may also send the same
hang-up as an AES control chunk on the voice channel; the receiver acts on the
first copy by `callId`.

**[In rollout]** The native caller prepares its cancel when the dial starts:
signed with the stored wallet key, encrypted to the callee (and wrapped to the
callee's mailbox), held only in memory, and discarded when the call is
answered, declined, times out or ends. When the caller hangs up before an
answer, the daemon posts it at once through the warm entry pool. Device tests
measured about 0.15–0.35 seconds from the caller's post to the callee's ringing
UI closing.

### 8.4 Accept **[Live]**

Today the callee answers with an accept message and an AES control chunk on
the caller's voice channel. The payer-signed design (Section 10) moves the
accept to the caller's mailbox.

---

## 9. Voice channel v2 **[Live]**

### 9.1 Opening a channel

Each listening side opens a temporary voice session that never shares the
mailbox listen:

```json
{ "command": "voice_listen", "sessionId": "<16-byte locator, hex>", "timestamp": 1710000000, "v": 2, "wk": "<32-byte write key, base64>" }
```

It is encrypted to the route PGP of the node that will hold the session, sent
through an entry that is not that node, and carries **no wallet and no
signature**. The locator and the write key are the only credentials. A v2 node
answers `voice_ready` with `v: 2`. The listener hands the locator and write key
to the peer only inside the signed offer or an AES control chunk, and
announces v2 in `voice_media_caps_v1` (`chan: 2`).

### 9.2 Chunks

```text
chunk = "CVC2" ‖ locator(16) ‖ HMAC-SHA256(wk, locator ‖ blob)[:16] ‖ blob
blob  = nonce(12) ‖ AES-GCM ciphertext ‖ tag(16), padded to a multiple of 256 bytes, ≤ 9000 bytes
AAD   = "CVC2" ‖ locator
plaintext header (28 bytes):
  ver u8 = 2 | kind u8 (0 audio, 1 video, 2 control) | flags u8 | reserved u8 |
  seq u32 (per kind) | captureMs u64 | frameId u32 | fragIdx u16 | fragCnt u16 | dataLen u32
```

The chunk is an OpenPGP binary literal encrypted to the session node's route
key and posted through a random entry, a different one for each chunk, from a
probed rotation pool that excludes both mailboxes. Entries forward without
reading it.

### 9.3 At the session node

The node checks the HMAC and the size, rate-limits per channel, and writes the
blob to the session SSE as `data: {"t":"c","d":"<base64>"}`. It answers
`{ok: true}`, `voice_chunk_auth`, `invalid_voice_chunk` or
`target_voice_session_not_found`. It never decrypts, reorders or stores media,
and media never enters offline storage, push or history.

The node sees, once, the locator and write key; afterwards only padded
ciphertext and its timing. Sequence numbers, timestamps, media kind and
fragment numbers are inside the ciphertext.

### 9.4 At the receiver

The receiver decrypts first, then reorders by `(kind, seq)`, drops frames whose
capture time is too old, and reassembles video by `frameId` / `fragIdx` /
`fragCnt`. Buffers are bounded. The service is real-time best effort.

### 9.5 Fallback

Voice channel v1 (`voice_uplink` / `voice_downlink` JSON with outer `seq`,
`callId` and session IDs, reordered before decryption) remains only for peers
that do not announce v2. Device tests measured v2 audio chunks about 21%
smaller than v1 and the per-chunk post about 110 ms faster. When v1 is removed
is an operator decision.

---

## 10. Payer-signed temporary voice channels **[Planned]**

### 10.1 Why

Today no one pays GB for voice sessions. The existing per-wallet byte counts
in CoNET-SI **issue** GB to wallets; they are not a charge, and voice usage must
not enter them. The temporary wallet field in today's offer is unused, and one
caller-generated key serves both directions and both media.

### 10.2 Decisions (operator, 1 November 2026)

1. **The callee pays for every channel of a call.**
2. **One temporary wallet and one key per channel.** A call has four
   channels: caller receives voice, callee receives voice, caller receives
   video, callee receives video. All four are set up at the start of the call.
3. **Each side chooses its own relay.** The caller chooses the relay for the
   channels it receives, so the callee cannot place the caller's channels on a
   node it colludes with.
4. **Payment may be split across wallets.** A payer may sign different
   channels with different wallets of its own. The client composes this;
   CoNET-SI does not take part.
5. **This round builds the authorization architecture only.** No usage table
   and no charging. Settlement arrives with the GB settlement module.
6. **CoNET-SI only verifies the payer signature** on the temporary wallet, and
   refuses a `voice_listen` without a valid one.
7. **Not backward compatible** with the current call flow.

### 10.3 Flow

```text
1. caller → callee mailbox   offer (no session key, no temporary wallet, no relay)
2. callee rings; may prepare 4 temporary wallets + 4 channel keys in memory
3. callee answers:
     opens its own receiving channels on relays it chooses, with payer proofs
     sends an accept message to the CALLER's mailbox (signed by the callee,
     encrypted to the caller, through a random entry) carrying, for the
     caller's two channels: temporary wallet key, payer signature, channel key
4. caller opens its receiving channels on relays it chooses, presenting the
   temporary wallet and the callee's payer signature
5. each side tells the other where its channels are (control chunk, or a
   mailbox message if the channel is not up yet); media starts
6. hang-up: both sides close their channels
```

Each channel key derives the AES-GCM key and the write key, so the node never
receives a key that decrypts media. A temporary wallet signs its
`voice_listen` to prove possession; the payer signature binds that temporary
wallet to the payer.

Because the caller no longer listens while ringing, the callee-to-caller
direction starts about one to two seconds later than today. Accept messages and
signatures can be prepared during ringing.

### 10.4 Privacy trade-off

A relay that verifies a payer signature learns that the payer wallet has a
voice channel open, for how long, and how many bytes it carries, and it holds a
signed record of that. This is a deliberate exception to the rule that nodes
see no wallet. The relay still does not learn the other party: chunks arrive
through entries, and the authorization carries no call identifier. Because the
callee pays for every channel, only one wallet appears; splitting payment
across the payer's wallets limits how much one relay can attribute to a single
wallet.

### 10.5 Abuse

The caller holds the write key of channels the callee pays for and could fill
them with traffic. Bounds on each authorization (duration, bytes, expiry) and
payer revocation are proposed but not decided **[Open]**.

---

## 11. Push

- **Registration [Live].** The app signs a `push_device_register` command with
  the user's wallet and sends it, encrypted, to the user's own mailbox, which
  forwards it to the push API. The page never calls the push API, and device
  tokens are not logged.
- **Message push [Live].** When a mailbox stores a message for a user with a
  registered device, it asks the push API to show a badge, unless the delivery
  carries `NoPush` (honoured in rollout).
- **Call push [Live].** Only the callee's own mailbox rings, on
  `voice_offer_store` with `push: 1`. iOS uses PushKit / CallKit and Android
  high-priority FCM.
- A push carries no sender wallet, tag, key, audio or plaintext. A push is a
  ringing hint, not proof of delivery.

---

## 12. Encrypted history **[Live]**

History is a second, optional track:

```text
master    = keccak256( wallet.sign("beamio.chat.history.v1|224422|<eoa>") )
indexKey  = HKDF(master, "index-enc")
k_i       = HKDF(master, "frag|<seq>|<cid_{i-1}>")        ratcheting fragment keys
cipher_i  = AES-256-GCM(k_i, record_i);  cid_i = keccak256(cipher_i)
pointer   = ChatIndexRegistry on CoNET L1 (gas-relayed EIP-712 SetPointer)
```

Fragments and the encrypted index live on IPFS; the chain stores only the
head pointer (`ChatIndexRegistry`
`0x1511Caa71081C84d8a591490D1b83879088EED72`). Without the wallet's signing
key the history is unreadable. Devices merge indexes by `sendId` (union, never
replacement) and repair forks by re-encrypting a linear chain. A failed or
partial network read never clears the trusted local mirror. Decrypted records
stay in a daemon-local corpus and are not downloaded twice.

---

## 13. Presence and native wake

`wallet_online_query` asks a contact's mailbox whether the contact has a live
listen session; `wallet_native_wake_query` then asks whether the contact has a
registered native app that push can wake. Both are encrypted to the contact's
mailbox and sent through an entry, so the mailbox does not see the querier's
IP. Failed answers never overwrite a trusted value. The green dot follows
online state only; the call button is available when the contact is online or
wakeable.

**[Known limitation]** Both queries carry the querier's wallet and are signed
with it, so the contact's mailbox learns who asks about whom. This will be
solved with the [`web3://`](web3-url.md) protocol. Until then clients must
not patch it ad hoc or add other commands that hand a sender's wallet to a
peer's mailbox.

---

## 14. Known limitations and non-guarantees

| Limitation | Effect | Plan |
|---|---|---|
| Presence queries carry the querier's wallet | The contact's mailbox learns who asks about whom | `web3://` |
| Native apps use plain HTTP on port 80, without an extra entry layer | An observer between the phone and the entry sees the entry address, sizes, timing and the outer key ID (after the rollout, the recipient mailbox's route key ID) | Not being changed now |
| Entries see client IPs | Entry A knows who sends; entry C knows who listens | By design; role separation only |
| Mailboxes know their own users | B knows a message or call is for its user, and when its user listens | By design |
| Payer visibility (planned voice) | A relay learns the payer wallet of each channel | Accepted; payment may be split across wallets |
| Timing and size | Padding hides coarse sizes, not timing | Out of scope |
| Collusion | Entry + mailbox, or one operator in several roles, can relink sender, IP and recipient | Out of scope |
| Long-term PGP keys | No forward secrecy for stored ciphertext | Chat crypto V3 research |
| Replay | A valid old armor can be posted again | Application dedupe by `sendId`; mailbox dedupe by armor hash (in rollout) |
| Endpoints | A compromised device exposes what it can decrypt | Out of scope |

---

## 15. Compatibility and rollout

The in-rollout privacy changes are **not backward compatible**: a mailbox on
the new CoNET-SI refuses a listen without `streamKey` and gives no Chat to the
legacy pool, and new clients never send the legacy call-wake fields. Rollout
order (each step needs operator approval):

1. CoNET-SI on two canary mailbox nodes, then the whole fleet. Entries do not
   need upgrading; only mailboxes execute the new rules.
2. chat-sdk-ios and chat-sdk-android releases.
3. iOS and Android apps embedding the new SDKs and PWA.
4. PWA over-the-air update.
5. GitBook pages move labels from [In rollout] to [Live].

Other clients that share the browser SDK (merchant and POS apps) must take the
same update, or their real-time receive stops when their mailbox upgrades.

The payer-signed voice channels follow after the privacy rollout, in the same
order, and are also not backward compatible.

---

## Appendix A — Command reference

| Command / object | Encrypted to | Sent through | Signed by wallet | Status |
|---|---|---|---|---|
| Message (layers ①–⑤) | Recipient user PGP, then recipient mailbox route PGP | Random entry ≠ both mailboxes | Yes, inside the user layer | Live; layer ⑤ always in rollout |
| `mailbox_listen` | Own mailbox route PGP | Entry C ≠ B | Yes | Live; `streamKey` in rollout |
| `gossip_delivery_ack` | Own mailbox route PGP | Entry ≠ B | Yes | Live |
| `wallet_online_query` / `wallet_native_wake_query` | Contact mailbox route PGP | Entry ≠ B | Yes (known limitation) | Live |
| `push_device_register` | Own mailbox route PGP | Entry ≠ B | Yes | Live |
| `voice_offer_store` (`push: 1`) | Callee mailbox route PGP | Random entry ≠ both mailboxes | No | Live |
| `voice_offer_fetch` | Own mailbox route PGP | Entry ≠ B | No | Live |
| `voice_listen` v2 | Session node route PGP | Entry ≠ that node | No | Live; payer proof planned |
| `CVC2` chunk | Session node route PGP | Random entry per chunk | No | Live |
| `voice_uplink` / `voice_downlink` v1 | Session node route PGP | Random entry | No | Fallback only |
| Call control (`voice_end_v1`, decline, cancel, timeout) | Peer user PGP (+ mailbox layer in rollout) | Random entry | Yes, inside the user layer | Live |
| `voice_listen` with `targetWallet` / `offerArmor` | Own mailbox route PGP | Entry ≠ B | No | Live, being removed |

## Appendix B — Open items

1. Duration, byte and expiry bounds for payer authorizations, and whether a payer can revoke a channel mid-call.
2. Final wire format of the payer proof, the accept message and the channel-ready notice.
3. Whether a relay should check the payer's GB balance when a channel opens (adds a chain read that also reveals the payer).
4. When to retire voice channel v1 and the legacy listen pool after the rollout.
5. The `web3://` design for presence without the querier's wallet.
6. Whether native apps move to an entry outer layer or TLS for `/post` and the listen stream.

## Appendix C — Revision history

| Version | Date | Change |
|---|---|---|
| v0.1 | 1 November 2026 | First draft, from the operator decisions of 31 October and 1 November 2026 and the deployed and in-rollout code |
