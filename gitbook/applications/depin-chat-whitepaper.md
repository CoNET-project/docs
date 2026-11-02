# CoNET Chat Whitepaper: Relationship-Private Messaging and Calls on Layer Minus

**Version:** v0.2 (discussion draft) | **Date:** 2 November 2026 | **Basis:** operator decisions of 31 October to 2 November 2026; CoNET-SI `main` as deployed on the Guardian fleet, and the canary branch running on a few test mailbox and relay nodes; chat-sdk-ios 0.1.7, chat-sdk-android 0.2.5 and the Consumer PWA 0.52.925 as released, plus the release-candidate builds under device test; the [CoNET Chat](depin-chat.md) product page and the [CoNET Chat developer guide](../l0/chat-developer-guide.md) | **Status:** discussion draft. Parts are live, parts are on canary nodes and test builds, and parts are designed only. Each section is labelled.

Wallet-addressed messages and calls in which no single node learns who talks to whom.

**How to read the labels**

- **[Live]**: deployed on the CoNET-SI fleet and in released clients.
- **[Live, being replaced]**: deployed today, and removed by the in-rollout work.
- **[In rollout]**: code is written and tested. It runs on a few canary nodes and in release-candidate builds, and is not released. Not backward compatible unless stated.
- **[Planned]**: the design is decided by the operator; no code is written or deployed.
- **[Open]**: not decided; listed in Appendix B.
- **[Known limitation]**: a gap that stays after the rollout and is stated so that no page claims more.

An operator decision is not a DAO vote. Wire formats marked [In rollout] may still change before release.

---

## Summary

CoNET Chat is a messaging and calling application built on
[Layer Minus](../l0/layer-minus.md), the wallet-addressed privacy-routing
protocol of the CoNET L0 decentralized cloud. Every node it uses is a Guardian
node running CoNET-SI in a Layer Minus role (entry or mailbox, or a relay for
voice); Chat runs no servers of its own. It has three goals:

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
  mailbox node, and goes to one entry at a time. The mailbox seals every frame
  of its listen stream with a per-listen key, so the listening entry sees only
  padded opaque frames. Contact lookups no longer name the asking wallet.
- Call offers go only to the callee's own mailbox, which rings its own user.
  Call control (wake receipt, cancel, decline, busy, timeout, hang-up) travels
  as ordinary signed messages through the mailboxes.
- Voice and video travel in padded `CVC2` chunks: after a channel is opened, a
  relay sees only a channel locator and ciphertext, with no wallet, sequence
  number, timestamp or media type.
- **[In rollout]** Voice channel v3: the callee pays for all four channels of
  a call through payer-signed temporary wallets, one per channel, and each
  side places its own channels on a relay it chooses. Relays verify the payer
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

The forwarding primitives (AddressPGP wallet bindings, OpenPGP key-ID
routing, peel and forward, hop signatures, `/post`, mailbox store and listen
pools) belong to Layer Minus and are specified in
[Layer Minus](../l0/layer-minus.md),
[Zero-trust mailbox routing](../l0/mailbox-routing.md) and the
[SI developer guide](../l0/si-developer-guide.md). This paper describes how
Chat composes them; the Layer Minus page lists
[which parts Chat uses](../l0/layer-minus.md#conet-chat).

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

Node roles use the Layer Minus terms of
[Node and client roles](../l0/node-roles.md) and
[Zero-trust mailbox routing](../l0/mailbox-routing.md). Entry A, entry C,
mailbox B and the relay are all Guardian nodes running CoNET-SI.

| Role | Layer Minus term | What it does for Chat |
|---|---|---|
| Client | User client | A browser PWA (TypeScript Worker) or a native app (iOS / Android Chat SDK); holds the wallet and PGP keys |
| Entry A | Entry A | A random node that accepts a client's `POST /post` for a send and forwards it by key ID |
| Entry C | Entry C | A random node that carries a client's listen stream or a route-key command to B (`C ≠ B`) |
| Mailbox B | Mailbox B | The node bound on-chain to a wallet's route key; stores ciphertext, holds listen streams, executes route-key commands |
| Relay | SI node holding a `voice_listen` session (a separate SI listen namespace) | Holds a temporary voice session. In v2 it is the listener's own mailbox or a relay; in v3 it is a relay chosen by the listening side, never either party's mailbox |
| Push API | Beamio service called by B | Sends APNs PushKit / FCM wake-ups to registered devices |
| CoNET RPC | CoNET L1 | Read access to AddressPGP, ChatIndexRegistry and GuardianNodesInfoV6 |
| IPFS gateway | Storage, outside Layer Minus | Stores encrypted history fragments |

A, B, C and the relay are **roles** for one request, not machine classes. One
node can be an entry for one user, the mailbox for another and a relay for a
call.

### 2.2 Adversaries

Every node is assumed curious and possibly malicious. The protocol relies on
encryption and role separation, not on choosing honest operators. Considered
adversaries:

- a single entry, mailbox or relay that logs everything it sees;
- the push API and the RPC endpoint;
- a network observer between a client and its entry;
- a peer who tries to impersonate another wallet;
- a peer who tries to waste another user's resources (relevant to paid voice);
- a callee who tries to place the caller's channels on a relay it controls.

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
| Route PGP | Mailbox or relay node | Encryption target for commands that the node executes and for the mailbox layer of deliveries |
| `streamKey` | One listen session | **[In rollout]** Seals frames of one mailbox listen stream |
| Channel key and write key | One voice channel | AES-GCM media key; the write key authorizes chunks on a relay |
| Temporary wallet | One voice channel | **[In rollout]** Signs that channel's `voice_listen`; the payer signs over its address |
| Payer wallet | The callee | **[In rollout]** Signs that it funds a temporary wallet's channel |

A wallet registers its user PGP key and its mailbox binding in the AddressPGP
contract on CoNET L1. `@BeamioTag` is a display label looked up by address,
never an identity.

### 3.2 Looking up a contact

A client reads `AddressPGP.searchKey(contact)` over CoNET RPC to get the
contact's user PGP key and mailbox route key. The call does not depend on who
asks.

- **[Live, being replaced]** The Consumer PWA sends this `eth_call` with its
  own wallet as `from`, so the RPC endpoint sees both wallets and the IP. Each
  contact record also kept a copy of the asker's own encrypted private key
  that nothing read.
- **[In rollout]** The lookup carries no `from`. Only reading one's own
  encrypted private key identifies the caller, as it must. Stored contact
  records drop the stray private-key copy on the next load. A browser test
  counted one `eth_call` with `from` out of about 3,000, and it was that own-key
  read.

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
Section 8.4 applies this to the incoming-call screen.

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

**[In rollout]** Every delivery carries layer ⑤: messages, group copies,
receipts and call control. Entry A sees only the mailbox node's route key ID,
shared by all users of that node. If the client cannot find the recipient's
mailbox route key, the send fails with `recipient_mailbox_unknown`; it never
falls back to layer ④ alone. Device tests confirmed that the recipient
mailbox unwraps layer ⑤ for messages and receipts.

### 4.2 Choosing an entry

- The entry is random for every delivery, and is neither the recipient's
  mailbox nor the sender's own mailbox. A mailbox that saw a direct
  connection would learn the sender's IP.
- **[In rollout]** The entry comes from a background-warmed pool
  (Section 7.4), so a send does not wait for probes.
- **[In rollout]** One entry at a time. The client switches to another
  entry only after a clear failure, and tries at most four. A clear failure
  is a connection error, a reset before any response, a non-2xx status, a 2xx
  body `{"ok": false}`, or no response within about 8 seconds. An entry that
  has no route for the armor's key ID answers `{"ok": false, "error": "no_route"}`
  (the deployed SI answers an empty 200, which the sender takes for success).
  **[Live, being replaced]** Browser clients post one message to up to four
  entries in parallel; native SDKs were already sequential.
- A timeout may hide a delivery that did arrive, so a retry can create a second
  copy of the same ciphertext. **[In rollout]** The mailbox stores, and pushes,
  one copy per armor hash; recipients deduplicate by `sendId`.

### 4.3 At the mailbox

The entry forwards the armor by key ID to mailbox B. B unwraps layer ⑤ (in
rollout), stores the user-layer ciphertext, and then pushes it to every live
listen session of that user. Store comes first: a message is never only in
flight. B keeps the offline copy until the recipient's ACK, and sends every
unacknowledged copy again to each new listen.

`NoPush` means "do not send a native push for this delivery". **[Live, being
replaced]** The deployed SI drops the flag when it unwraps the work envelope.
**[In rollout]** The flag is honoured.

### 4.4 Receipts and ACK

After the recipient has verified and **stored** a message:

1. **Mailbox ACK** `gossip_delivery_ack`: encrypted to B's route key, through
   one entry; carries the armor hash. B deletes the offline copy. The ACK
   never triggers a push.
2. **Sender receipt** `beamio_chat_delivery_receipt_v1`: an ordinary signed
   message to the sender, with `NoPush: true`. The sender marks the bubble
   delivered and does not show a new row.

**[In rollout]** Device tests confirmed that receipts reach the sender's
mailbox with `NoPush` and do not push, including when the sender's app has
been killed.

### 4.5 Sending from inside the native apps **[In rollout]**

Inside the iOS and Android apps, the page sends only through the native
daemon's `send`. The page waits up to about 10 seconds for the daemon to be
ready and treats anything other than `sent: true` as a failure. There is no
page-side fallback that encrypts and posts on its own. The browser PWA uses
its Worker daemon.

### 4.6 Groups (Group chat V1)

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

The IV is random per frame. Entry C sees only B's address, frame timing and
256-byte length buckets. A client drops every frame it cannot open, including
any plaintext frame; new clients do not accept the old format. The ACK still
hashes the inner user-layer armor. A node test checked that the sealed stream
shows no armor, recipient key ID, wallet, `instanceId`, node wallet or frame
type.

### 5.3 Listen health **[In rollout]**

A listen that looks open but delivers nothing is worse than one that fails.
The daemons now follow these rules (all three unless marked native):

- **Listening means the mailbox answered.** A client reports "listening" only
  after it opens B's sealed handshake frame (`kind: "mailbox"`), not when the
  entry returns HTTP 200.
- **Idle timeout above the keepalive.** Native SDKs treat a stream as dead
  after 200 seconds without a frame and the browser after 240 seconds, both
  above B's longest keepalive gap of 180 seconds.
- **Fresh command on every reconnect after contact.** Once a stream has
  received any sealed frame from B and then drops, the client builds a new
  signed `mailbox_listen` with a new `instanceId` and a new `streamKey` and
  reconnects within about half a second. It reuses the same command on the
  next entry only when B never answered. Reusing an `instanceId` let a late
  close of the old connection remove the new session at B.
- **Crypto host recovery (native).** The native SDKs sign and decrypt in a hidden
  WebView. When the system reclaims that WebView in the background, the SDK
  rebuilds it and retries the call once. Before this fix every later decrypt
  failed and messages were silently dropped until the app restarted.
- **Decrypt failure reopens the listen (native).** A message that does not decrypt
  (other than one meant for a different key) reopens the listen, at most once
  every 30 seconds, so B sends the unacknowledged copy again.
- **Resume check (native).** When the app returns to the foreground and the last
  sealed frame is more than 45 seconds old, the daemon reopens the listen
  with a new command. B then sends everything still unacknowledged.

B itself is unchanged by these rules. A node-side cleanup of half-closed
listens was drafted and not adopted (Appendix B).

### 5.4 Legacy listen pool

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
| Relay (voice) | Entry IPs, channel locator, write key, padded chunk ciphertext and timing | Same, plus the channel's temporary wallet and **payer wallet** and the payer's signed authorization; never the other party |
| Push API | The woken user's registered device, opaque `callId` / `sessionId` | Same |
| CoNET RPC | Looked-up addresses, client IP, **own wallet as `from`** | Looked-up addresses, client IP |
| Beamio API (`search-users`) | A lookup of an unknown caller's wallet from the callee's IP at ring time | Same (Section 8.4) |
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

### 7.4 Warm node pools and the node table **[In rollout]**

Operator rule: random node selection is warmed in the background and returns
at once when needed. Probing at the moment of use cost up to about a second
on every dial.

- **Native pool.** While the daemon is active (foreground, dialing, ringing,
  in a call, push wake), it keeps about eight probed, healthy random nodes and
  refreshes them every 15 seconds from the node table. Every random pick (a
  send's entry, a listen's entry, a voice uplink entry, a relay candidate)
  takes from this pool first, still applying the caller's exclusions (both
  mailboxes, the call's relays). A node that fails is reported and not handed
  out again. Only when the pool is empty does the pick probe on the spot, and
  the pool refills at the same time.
- **Push wake.** After each refresh the pool saves the usable IPs to disk
  (public node-table data only, no wallet or identity). A process woken by a
  push uses that list, if under 30 minutes old, until its first refresh.
- **Browser.** The Worker keeps about eight healthy nodes, refreshed every 20
  seconds while it runs, and stops when paused or closed.
- **Relays.** Each side still chooses its own relays at random, excluding both
  mailboxes, but prefers nodes the pool has recently confirmed online.
- Probes are plain `GET /` requests with no wallet and no signature, and run
  only in the states above.
- **Node table.** The daemon maintains the node table itself, the same way
  CoNET-SI does: it watches the storage root of the `GuardianNodesInfoV6`
  contract and pulls the full table only when the root changes, with sanity
  checks against an empty or sharply shrunken table. The page's node list is
  secondary.

### 7.5 ChatDaemon interface

| Phase | Content | Status |
|---|---|---|
| P0 | Native key custody, local signing, daemon-owned listen lifecycle, native recognition of caller cancel | **[Live]** |
| P1 | Versioned protocol spec (`src/protocol.ts` plus generated JSON Schema), `hello` capability handshake, shared test vectors run by all three daemons | **[In rollout]** |
| P2 | Inbound verification, parsing, storage and ACK inside the daemon; the daemon's store is the single source of truth and the page's chat list a display cache | **[Planned]** |
| P3 | Sending, presence, offers, nodes and route registration inside the daemon; no OpenPGP on the UI thread | **[Planned]** (native send, warm pools and node table already in rollout) |
| P4 | Remove old paths: the page sign broker, legacy history, the separate posPwa SDK copy | **[Planned]** |

`hello` is the first command. Its answer lists `protocolVersion`,
`sdkVersion` and capabilities (for example `send.mailboxWrap`); the page
decides by capability, never by checking whether a method exists. Each command
in the spec is annotated with whether it carries a wallet signature, whether
it goes through an entry, and what nodes see.

---

## 8. Call signalling

### 8.1 Offer and ring

```text
caller: offer = sign(signal) → encrypt to callee user PGP
        → voice_offer_store { callId, sessionId, expiresAt, push: 1, pushTimestamp, offerArmor }
          encrypted to the CALLEE's mailbox route PGP, through a random entry ≠ either mailbox
callee mailbox: store offerArmor under callId + sessionId; find its own user from the
        offer's recipient key ID; ask the push API to ring that user; answer { ok, pushed }
```

The callee mailbox already serves the callee, so no other node learns whom the
caller is calling. `callId` is random and unrelated to the caller's wallet or
tag. The command carries no wallet and no signature; `sessionId` is the ring
identifier for this offer. The mailbox never decrypts the offer. A failed
offer store fails the dial.

**[Live, being replaced]** The v2 offer carries a caller-generated
`sessionKey`, an unused `tempWalletAddress`, entry domains, and, from native
callers, the caller's relay. If the callee mailbox does not confirm
`pushed: true` within about three seconds, current clients send a legacy
`voice_listen` to the **caller's** own mailbox carrying `targetWallet` and
`offerArmor`; that mailbox forwards the offer and rings the callee, and so
learns the callee's wallet.

**[In rollout]**

- The legacy fallback is deleted from every client and ignored by the node.
  The callee-mailbox ring is the only wake path.
- The callee mailbox also writes the offer into the callee's live listen
  stream, so an online callee needs nothing else, and answers
  `{ok, delivered, pushed}`.
- The v3 offer (`voice_call_offer_v1` with `proto: 3`) carries `callId`,
  `sessionId` (the ring identifier, not a channel), `from`, `to`, `createdAt`,
  `expiresAt`, `timestamp`, `codec`, and the caller's user PGP key and mailbox
  route key, so the callee can answer without a chain read. It carries no
  session key, temporary wallet or relay, and the caller opens no voice
  stream while dialing. `callerSignature` is an EIP-191 signature over:

```text
CoNET voice_call_offer_v3
callId:<callId>
sessionId:<sessionId>
to:<callee address, lower case>
createdAt:<n>
expiresAt:<n>
timestamp:<n>
codec:<codec>
callerPgp:<base64>
callerRoute:<base64>
```

### 8.2 Before dialing: aligning the caller's own mailbox **[In rollout]**

Before a dial or an answer, the page checks its own mailbox binding on chain.
A single failed RPC read used to fail the dial ("Voice call could not use
your current Chat mailbox"), most often right after the app returned to the
foreground. Now:

- When a known mailbox exists (the last one read for this wallet, or the one
  the live listen uses), the client waits at most about 1.5 seconds for the
  chain and otherwise uses the known one. A late chain answer still refreshes
  the cache. Only the public route key and key ID are cached, per wallet.
- Without a known mailbox, the client retries the read up to three times.
- If the node list lacks the mailbox node, the route key from the chain record
  is used.
- Error messages name the cause: network unreachable, mailbox not set up,
  node missing from the list, or Chat reconnecting.

### 8.3 Killed-app wake **[Live]**

The push carries only `callId` and `sessionId`. The woken native daemon shows
the system call UI with a neutral label, fetches the offer with
`voice_offer_fetch` (encrypted to its own mailbox, through an entry), decrypts
it with its stored user PGP key, recovers the caller from `callerSignature`,
and updates the call UI with the verified identity (Section 8.4).

**[In rollout]** A push can arrive long after it was sent. The Android app
now classifies each call push before it rings:

| Verdict | When | Action |
|---|---|---|
| Ring | On time | Ring at once |
| Hold | More than 5 seconds late, still inside the ring window | Wait up to about 5 seconds for the mailbox listen to deliver; do not ring if the call has already ended |
| Expired | `expiresAt` passed, or sent more than 195 seconds ago | Do not ring; record a missed call |
| End | A push that only reports the end of a call | Do not ring; pull the mailbox for the caller's signed end message |

A call that ended before it rang never rings later, whichever path reports
it. The iOS app has not changed here.

### 8.4 Incoming identity and caller display **[In rollout]**

- The only trusted identity is the wallet recovered from the offer's
  signatures (Section 3.3). The offer's `callerTag` is outside
  `callerSignature`, so it is a claim only and is never used for the name or
  the avatar.
- The tag is looked up for the recovered wallet: first in the local record,
  then, for a caller not in it, one exact-address query to the Beamio
  `search-users` API. That query lets the API see the callee's IP asking about
  the caller's wallet at ring time; the operator decided to keep it.
- The avatar uses local data only. A BeamioTag avatar is not stored anywhere:
  it is a deterministic DiceBear fun-emoji image seeded by the tag. The PWA
  draws it on the device; the Android app uses images the page cached
  earlier, or an initial-letter image. Nothing is downloaded when a call
  rings. Before this change, the PWA banner and the Android notification
  fetched the avatar from a third-party image service at ring time, seeded by
  the caller's tag.
- iOS CallKit shows no avatar, by design.
- Addresses appear as a short address capsule (`0x1234…5678`) that copies the
  full address. A claimed identity that differs from the recovered one
  appears on a second line with a red warning.

### 8.5 Wake receipt **[In rollout]**

As soon as the callee's device rings, it sends a wake receipt to the caller's
mailbox as an ordinary signed message with `NoPush`:

```json
{ "type": "voice_call_ringing_v1", "callId": "…", "sessionId": "<ring ID>", "from": "<callee>", "to": "<caller>", "createdAt": 0, "timestamp": 0 }
```

The caller accepts it only when `callId` matches its current dial (`callId`
is secret) and the recovered signer is the callee. The caller then shows
"Ringing…". Without a receipt within 8 seconds it shows "Their phone may be
restricting Beamio" and keeps ringing until the normal timeout. In device
tests, push to receipt at the caller's mailbox took a median of about 2.3
seconds (95th percentile about 3.1 seconds, 16 calls), so 8 seconds leaves a
margin of about 5 seconds. Old clients send no receipt, so a new caller shows
the hint for them.

### 8.6 Ring window and timeout **[In rollout]**

- Every platform rings for **60 seconds**, counted from the offer's
  `createdAt`. iOS ends an unanswered CallKit call after about 60 seconds on
  its own, so a longer window cannot hold.
- **The caller decides.** At `createdAt` + 60 seconds the caller sends
  `voice_call_timeout_v1` and records the call as timed out.
- The native caller keeps its own timer, so the timeout fires while the page
  is frozen in the background. It signs the timeout when the dial starts
  (its timestamp is known in advance), holds it in memory with the
  prepared cancel, and posts it through the warm pool when the window ends.
  Inside the apps the page's own timer waits 10 seconds longer, as a backup.
- The callee closes 60 seconds after its own ring started, a few seconds after
  the caller, as a backup. An iOS callee that the system ends after at least 55
  seconds of ringing sends a timeout, not a decline.

### 8.7 Call control through the mailbox

Every online client keeps its mailbox listen open during a call, so call
control needs no separate channel. Wake receipt, cancel, decline, busy, ring
timeout and hang-up are **ordinary signed messages** encrypted to the peer and
delivered through a random entry, exactly like text. A connected call also
sends hang-up as an AES control chunk on the peer's voice channel; the
receiver acts on the first copy by `callId`.

**[In rollout]**

- **Prepared cancel.** The native caller prepares its cancel when the dial
  starts: signed with the stored wallet key, encrypted to the callee, wrapped
  to the callee's mailbox, and held only in memory. While ringing, it re-signs
  a fresh copy every 2 seconds in the background, so the callee's record of
  when the call ended is accurate. On hang-up before an answer, the daemon
  posts the latest copy at once through the warm pool. Device tests measured
  about 0.15–0.35 seconds from the caller's post to the callee's ringing UI
  closing.
- **Prepared hang-up.** As soon as the peer's voice relay is known, the iOS
  app seals a `voice_end_v1` control chunk for it in the background. On
  hang-up it sends that chunk at once to warm entries, starting a second
  entry if the first has not answered in 0.5 seconds. This removed a delay
  of more than two seconds behind queued audio encryption: device tests
  measured 0.06–0.73 seconds from the tap to the peer's call ending. The
  Android app encrypts natively without that queue and needs no prepared copy.
- **Busy.** A device already in a call answers a new offer with
  `voice_call_reject_v1` and `reason: "busy"`, without ringing. The caller
  plays a busy tone, and both sides record the call as busy. When the same
  caller rings again while an earlier unanswered call from them is still
  shown, the earlier call ends as cancelled instead of answering busy. Busy
  signalling, the busy tone and the busy records on both sides are still
  being developed and have not had a device test.
- **Records.** On Android, an incoming call that the device never rang (app
  force-stopped, deep sleep, or a late push held back) shows as **Missed
  call** when the app next opens; only the Android app knows whether it rang.
  A call that rang and was then cancelled shows as "Call cancelled", as do
  all cancelled calls on iOS and in the browser.

### 8.8 Accept

**[Live, being replaced]** The callee answers with an accept message and an
AES control chunk on the caller's voice channel, keyed by the caller's
session key.

**[In rollout]** The callee answers with an ordinary signed message to the
caller's mailbox (`voice_call_accept_v1` with `proto: 3`, `NoPush`) that
carries all four channels' parameters (Section 10.3). The chat envelope's
signature already authenticates the callee; the caller requires the recovered
signer to be the callee it dialed. An iOS callee sends the accept as soon as
the user taps Answer and starts audio only when CallKit activates the session.

---

## 9. Voice media format and voice channel v2

The chunk format in 9.2 to 9.4 is shared by v2 and v3. Only how a channel is
opened differs.

### 9.1 Opening a v2 channel **[Live, being replaced]**

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

**[In rollout]** A node on the new CoNET-SI refuses this listen with
`voice_listen_v3_required`. Section 10 replaces it.

### 9.2 Chunks

```text
chunk = "CVC2" ‖ locator(16) ‖ HMAC-SHA256(wk, locator ‖ blob)[:16] ‖ blob
blob  = nonce(12) ‖ AES-GCM ciphertext ‖ tag(16), padded to a multiple of 256 bytes, ≤ 9000 bytes
AAD   = "CVC2" ‖ locator
plaintext header (28 bytes):
  ver u8 = 2 | kind u8 (0 audio, 1 video, 2 control) | flags u8 | reserved u8 |
  seq u32 (per kind) | captureMs u64 | frameId u32 | fragIdx u16 | fragCnt u16 | dataLen u32
```

The chunk is an OpenPGP binary literal encrypted to the relay's route key and
posted through a random entry from a warm pool that excludes both mailboxes
and the call's relays. Entries forward without reading it.

### 9.3 At the relay

The relay checks the HMAC and the size, rate-limits per channel, and writes the
blob to the session SSE as `data: {"t":"c","d":"<base64>"}`. It answers
`{ok: true}`, `voice_chunk_auth`, `invalid_voice_chunk` or
`target_voice_session_not_found`. It never decrypts, reorders or stores media,
and media never enters offline storage, push or history.

The relay sees, once, the locator and write key; afterwards only padded
ciphertext and its timing. Sequence numbers, timestamps, media kind and
fragment numbers are inside the ciphertext.

### 9.4 At the receiver

The receiver decrypts first, then reorders by `(kind, seq)`, drops frames whose
capture time is too old, and reassembles video by `frameId` / `fragIdx` /
`fragCnt`. Buffers are bounded. The service is real-time best effort.

### 9.5 Voice channel v1 **[Live, being replaced]**

Voice channel v1 (`voice_uplink` / `voice_downlink` JSON with outer `seq`,
`callId` and session IDs, reordered before decryption) remains on the deployed
fleet only for peers that do not announce v2. **[In rollout]** The new
CoNET-SI no longer forwards v1 frames, and new clients have no v1 path.

---

## 10. Voice channel v3: payer-signed temporary channels **[In rollout]**

v3 runs on a few canary mailbox and relay nodes and in release-candidate
builds of all three clients. It ships together with the privacy rollout.

### 10.1 Why

Today no one pays GB for voice sessions. The existing per-wallet byte counts
in CoNET-SI **issue** GB to wallets; they are not a charge, and voice usage must
not enter them. The temporary wallet field in the v2 offer is unused, and one
caller-generated key serves both directions and both media.

### 10.2 Decisions (operator, 1 November 2026)

1. **The callee pays for every channel of a call.**
2. **One temporary wallet and one key per channel.** A call has four
   channels: caller receives voice, caller receives video, callee receives
   voice, callee receives video. All four are opened when the call starts, so
   video needs no setup later.
3. **Each side chooses its own relay.** The caller chooses the relays for the
   channels it receives, so the callee cannot place the caller's channels on a
   node it colludes with. Both sides exclude both mailboxes.
4. **Payment may be split across wallets.** The format lets each channel name
   a different payer wallet. The client composes this; CoNET-SI does not take
   part. Current clients use the callee's main wallet for all four.
5. **This round builds the authorization architecture only.** No usage table
   and no charging. Settlement arrives with the GB settlement module.
6. **CoNET-SI only verifies the payer signature** on the temporary wallet, and
   refuses a `voice_listen` without a valid one.
7. **Not backward compatible.** Old and new clients cannot call each other.

### 10.3 Flow and wire format

```text
1. caller → callee mailbox   v3 offer (Section 8.1); the caller opens no voice stream
2. callee rings, sends the wake receipt (Section 8.5)
3. callee answers:
     creates 4 temporary wallets, 4 AES keys, 4 write keys; signs 4 payer authorizations
     opens its own two receiving channels on relays it chooses
     sends the accept to the CALLER's mailbox (Section 8.8)
4. caller opens its two receiving channels on relays it chooses, with the
   temporary wallets and payer authorizations from the accept
5. caller → callee voice channel   voice_channel_ready_v3 (AES control chunk);
   media starts
6. hang-up: voice_end_v1 (Section 8.7); all four sessions close
```

**Accept channels.** The accept carries four channel objects, all generated
by the callee:

```text
cv, cV  (caller receives voice / video):  { sid, key, wk, tk, pay }
ev, eV  (callee receives voice / video):  { sid, key, wk, relay, relayIp, relayKey }
```

`sid` is the 16-byte channel locator (hex), `key` the AES-256 media key, `wk`
the 32-byte write key, `tk` the temporary wallet's private key (sent only for
the caller's own channels), and `relay` / `relayIp` / `relayKey` the callee's
relay route key ID, address and route public key. The caller needs the
relay's address only to keep it out of its entry choices.

**Payer authorization.** `pay = { payer, notAfter, maxBytes, maxSeconds, sig }`,
where `sig` is the payer wallet's EIP-191 signature over:

```text
conet.voice.sse.pay.v3
temp=<temporary wallet address, lower case>
notAfter=<unix seconds>
maxBytes=<n>
maxSeconds=<n>
```

The authorization names no call, no peer and no relay. Clients set `notAfter`
to the answer time plus 12 hours; `maxBytes` and `maxSeconds` are 0, reserved
for the bounds in Appendix B.

**Opening a channel.** Each side sends, through an entry that is neither the
relay nor its own mailbox, encrypted to the relay's route PGP:

```text
{ command: "voice_listen", v: 3, sessionId, wk, timestamp, temp, tempSig, pay }
tempSig = EIP-191 by the temporary wallet over
          conet.voice.sse.listen.v3|<sessionId>|<wk base64>|<relay route key ID, upper case>|<timestamp>
```

`tempSig` binds the listen to one relay, so a captured listen cannot be
replayed on another node. The relay checks, in order:

| Check | Refusal |
|---|---|
| `v` is 3 | `voice_listen_v3_required` |
| Locator and 32-byte write key well formed | `invalid_voice_session` |
| Timestamp within the allowed clock skew | `invalid_voice_timestamp` |
| `tempSig` recovers `temp` for this relay's key ID | `voice_temp_auth` |
| `pay` complete and `sig` recovers `payer` | `voice_pay_auth` |
| `notAfter` later than now and at most 48 hours ahead | `voice_pay_expired` |
| The temporary wallet is not bound to a different live session | `voice_temp_reused` |

A refused listen opens no stream. On success the relay answers
`voice_ready` with `listen: 3`. It keeps the temporary-wallet binding in memory
only, so a reconnect with the same temporary wallet and locator is accepted.
It counts no bytes and charges nothing.

**Channel ready.** When both of its channels are up, the caller sends
`voice_channel_ready_v3` on the callee's voice channel, with its two relays'
key IDs, addresses and route public keys. If the callee's channel is not up
yet (`target_voice_session_not_found`), it retries every 300 ms for up to 10
seconds. The callee starts sending media only after this notice. Either side
sends it again after moving one of its channels to another relay.

**Media.** Audio and control go to the peer's voice channel, video to the
peer's video channel, each with that channel's `key`, `wk` and locator. Each
side decrypts its two streams with its own channel keys. Video format
negotiation still uses `voice_media_caps_v1`; the v2 `chan` / `wk` fields are
gone because v3 knows the peer's write keys from the start.

**Relay failure.** When a relay stops answering, the side that owns the
channel opens it on another relay it chooses and announces the move.

### 10.4 Canary results

Device tests between two phones on canary mailboxes and two canary relays, and
between the browser PWA and phones:

- **Passed:** two-way audio both ways; four channels opened at call start on
  both sides; caller and callee each on relays they chose; all seven refusal
  cases on a live relay; decline; cancel; cold-start answer after a push
  wake; cancel during a push wake; hang-up both ways; network change
  mid-call (after an Android reconnect fix); browser-to-phone calls with the
  relay seeing no real wallet.
- **Video:** phone-to-phone video in one direction started within about 1.5
  seconds of the tap, at about 4.5 frames per second and about 400 ms latency.
  The other direction has a test step written and is not yet measured.
- **Latency:** with the first canary build, the callee heard the caller about
  4.2 seconds after tapping Answer, against about 2.5 seconds for v2; the
  callee only sends the accept after its own channels are open, the caller
  then opens its channels, and channel ready makes one more round trip. The
  warm pools (Section 7.4) and the early accept on iOS are expected to bring
  this to about 2.2–2.6 seconds, and the cold-start answer from about 8.9 to
  about 5–6 seconds to first audio sent. These estimates are not yet
  measured on devices.
- **Not covered:** moving a channel after a relay fails during a call (the
  network-change test moved channels, but no relay was taken down; the
  browser test build could not limit relays); video in the second direction;
  real microphones in the browser.

Preparing all four channels and the accept during ringing could save about
another 0.5–0.8 seconds; it is not built.

### 10.5 Privacy trade-off

A relay that verifies a payer signature learns that the payer wallet has a
voice channel open, for how long, and how many bytes it carries, and it holds a
signed record of that. This is a deliberate exception to the rule that nodes
see no wallet. The relay still does not learn the other party: chunks arrive
through entries, the authorization carries no call identifier, and the two
sides' channels sit on relays chosen independently. Because the callee pays
for every channel, only one wallet appears; splitting payment across the
payer's wallets limits how much one relay can attribute to a single wallet.

### 10.6 Abuse

The caller holds the write keys and temporary wallets of channels the callee
pays for and could fill them with traffic. Each authorization expires (12
hours by client choice, at most 48 hours by the relay's rule) and a temporary
wallet serves one session only. Byte and duration bounds (`maxBytes`,
`maxSeconds`, reserved as 0) and payer revocation are not decided **[Open]**.
No charge exists yet, so nothing can be drained today.

---

## 11. Push

- **Registration [Live].** The app signs a `push_device_register` command with
  the user's wallet and sends it, encrypted, to the user's own mailbox, which
  forwards it to the push API. The page never calls the push API, and device
  tokens are not logged.
- **Message push [Live].** When a mailbox stores a message for a user with a
  registered device, it asks the push API to show a badge, unless the delivery
  carries `NoPush` (honoured in rollout). ACKs, receipts and wake receipts
  never push.
- **Call push [Live].** Only the callee's own mailbox rings, on
  `voice_offer_store` with `push: 1`. iOS uses PushKit / CallKit and Android
  high-priority FCM.
- A push carries no sender wallet, tag, key, audio or plaintext. A push is a
  ringing hint, not proof of delivery.
- **[In rollout]** FCM messages carry fixed analytics labels (`chat`,
  `chat_clear`, `call`, `call_end`) with no identity, so delivery statistics
  can be read per type. The push API change is not deployed.

### 11.1 Android delivery limits **[Known limitation]**

On Android the operating system can drop a push on the phone before the app
runs any code. Device tests on a current Samsung phone:

| App state | Message push | Call push |
|---|---|---|
| Normal, or killed from recents | Arrives (about 0.3 s) | Rings (under 0.1 s) |
| "Restricted" battery setting, or "sleeping apps" | Arrives, sometimes late (one push about 46 s) | Usually rings; a late one is held back (Section 8.3) |
| Deep sleep | Dropped on the phone | Dropped; the call is missed |
| Force stopped | Dropped on the phone | Dropped; the call is missed |

Messages are not lost: they wait in the mailbox and arrive when the user opens
the app. A notification displayed by Google Play services on the app's behalf
does show in deep sleep, but not after a force stop, and it cannot ring a
call. The operator decided not to move Chat push to that form.

What the clients do instead **[In rollout]**:

- The Android app checks on every return to the foreground whether it is
  restricted in the background or was force stopped. A restricted app shows a
  banner with a Fix button that opens the right settings list (on Samsung, the
  never-sleeping apps list). A force stop shows a one-time notice. The check
  cannot tell deep sleep from the milder restrictions, so the text says calls
  and messages "may not" arrive.
- The caller sees "Their phone may be restricting Beamio" when no wake
  receipt arrives in 8 seconds (Section 8.5).
- The callee's Android app shows **Missed call** for calls that never rang (Section 8.7).
- Other Android brands get one line of written settings guidance each.

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
| Payer visibility (voice v3) | A relay learns the payer wallet of each channel it holds, and keeps a signed record | Accepted; payment may be split across wallets |
| Unknown-caller tag lookup | The Beamio API sees the callee's IP query the caller's wallet at ring time | Kept by operator decision |
| Android push limits | Deep sleep and force stop drop pushes on the phone; calls are missed and messages wait for the app to open | Detection, guidance, wake receipt, Missed call (Section 11.1) |
| No paid-channel bounds | A caller could fill channels the callee pays for | Bounds and revocation [Open]; no charge exists yet |
| Old clients | After the rollout, old clients lose real-time receive and calls on upgraded nodes, and old and new clients cannot call each other | Not backward compatible by decision; release all clients together |
| Untested paths | Moving a channel after a relay fails during a call; video in the second direction; the latency targets of Section 10.4 | Next release-candidate round |
| Half-closed listens at the node | A client that reuses an `instanceId` can still lose its new session at B; our clients no longer do | Node-side cleanup drafted, not adopted |
| Timing and size | Padding hides coarse sizes, not timing | Out of scope |
| Collusion | Entry + mailbox, or one operator in several roles, can relink sender, IP and recipient | Out of scope |
| Long-term PGP keys | No forward secrecy for stored ciphertext | Chat crypto V3 research |
| Replay | A valid old armor can be posted again | Application dedupe by `sendId`; mailbox dedupe by armor hash (in rollout) |
| Endpoints | A compromised device exposes what it can decrypt | Out of scope |

Fixed since v0.1, all **[In rollout]**:

- A dial failed when one chain read of the caller's own mailbox failed
  (Section 8.2).
- A native listen could look healthy while every message was dropped, after
  the system reclaimed the SDK's crypto WebView or a reconnect reused an
  `instanceId` (Section 5.3).
- Hang-up from an iOS phone took 2.5–3 seconds to reach the peer
  (Section 8.7).
- An unanswered iOS call was recorded as declined, not timed out, and ring
  windows differed between platforms (Section 8.6).
- A late Android push rang for a call that had already ended (Section 8.3).
- The incoming-call screen fetched the caller's avatar from a third party at
  ring time (Section 8.4).
- The browser caller did not show "Ringing…".

The other fixes listed as in rollout in v0.1 (mailbox layer, one entry,
sealed listen, `NoPush`, lookup without `from`, removal of the legacy call
wake) passed device tests on canary nodes and are still in rollout.

---

## 15. Compatibility and rollout

The in-rollout changes are **not backward compatible**: a mailbox on the new
CoNET-SI refuses a listen without `streamKey` and gives no Chat to the legacy
pool, a relay refuses any `voice_listen` that is not v3, new clients drop
unsealed frames and never send the legacy call-wake fields, and old and new
clients cannot call each other. The privacy changes and voice channel v3
ship together.

Release order, decided by the operator on 2 November 2026 ("test everything,
package, then deploy at the same time"); each step needs operator approval:

1. Finish device tests on the canary nodes and release-candidate builds.
2. Commit the work of all sessions and tag chat-sdk-ios and chat-sdk-android.
3. Build the iOS and Android apps and submit the iOS app for review.
4. In one window: deploy CoNET-SI to the whole fleet (each node's build
   checked), push the PWA over the air, and release the Android app.
   Entries upgrade with the fleet; mailboxes and relays execute the new rules.
5. iOS users on the old app lose Chat until the new app is approved.
6. GitBook pages move labels from [In rollout] to [Live].

Other clients that share the browser SDK (merchant and POS apps) must take the
same update, or their real-time receive stops when their mailbox upgrades. The
POS copy of the SDK has not yet received the listen-health fixes.

---

## Appendix A — Command reference

| Command / object | Encrypted to | Sent through | Signed by wallet | Status |
|---|---|---|---|---|
| Message (layers ①–⑤) | Recipient user PGP, then recipient mailbox route PGP | One random entry ≠ both mailboxes | Yes, inside the user layer | Live; layer ⑤ always and one entry at a time in rollout |
| `mailbox_listen` | Own mailbox route PGP | Entry C ≠ B | Yes | Live; `streamKey` required in rollout |
| `gossip_delivery_ack` | Own mailbox route PGP | Entry ≠ B | Yes | Live |
| `beamio_chat_delivery_receipt_v1` | Sender user PGP + sender mailbox layer, `NoPush` | Random entry | Yes, inside the user layer | Live |
| `wallet_online_query` / `wallet_native_wake_query` | Contact mailbox route PGP | Entry ≠ B | Yes (known limitation) | Live |
| `push_device_register` | Own mailbox route PGP | Entry ≠ B | Yes | Live |
| `voice_offer_store` (`push: 1`) | Callee mailbox route PGP | Random entry ≠ both mailboxes | No | Live; also written to the live listen in rollout |
| `voice_call_offer_v1`, `proto: 3` | Callee user PGP, inside `voice_offer_store` | As above | Yes, plus `callerSignature` | In rollout |
| `voice_offer_fetch` | Own mailbox route PGP | Entry ≠ B | No | Live |
| `voice_call_ringing_v1` | Caller user PGP + caller mailbox layer, `NoPush` | Random entry | Yes, inside the user layer | In rollout |
| `voice_call_accept_v1`, `proto: 3` | Caller user PGP + caller mailbox layer, `NoPush` | Random entry | Yes, inside the user layer | In rollout |
| `voice_call_reject_v1` (`reason`: declined, busy) | Peer user PGP + mailbox layer | Random entry | Yes, inside the user layer | Live; busy in rollout |
| `voice_call_timeout_v1` | Peer user PGP + mailbox layer | Random entry | Yes, inside the user layer | Live; 60-second window and native caller timer in rollout |
| Caller cancel, `voice_end_v1` | Peer user PGP + mailbox layer, and an AES control chunk once connected | Random entry | Yes, inside the user layer | Live; prepared copies in rollout |
| `voice_listen` v3 | Relay route PGP | Entry ≠ relay, ≠ own mailbox | No; temporary wallet and payer signatures | In rollout |
| `voice_channel_ready_v3` | AES control chunk on the callee's voice channel | Random entry | No (AES-authenticated) | In rollout |
| `voice_listen` v2 | Session node route PGP | Entry ≠ that node | No | Live, being replaced |
| `CVC2` chunk | Relay route PGP | Random entry per chunk | No | Live; shared by v2 and v3 |
| `voice_uplink` / `voice_downlink` v1 | Session node route PGP | Random entry | No | Live, being replaced |
| `voice_listen` with `targetWallet` / `offerArmor` | Own mailbox route PGP | Entry ≠ B | No | Live, being replaced |

## Appendix B — Open items

1. Byte and duration bounds for payer authorizations (`maxBytes`, `maxSeconds`), and whether a payer can revoke a channel mid-call.
2. Whether a relay should check the payer's GB balance when a channel opens (adds a chain read that also reveals the payer).
3. Whether to prepare the four channels and the accept during ringing to shorten call setup.
4. Whether CoNET-SI should clean up half-closed mailbox listens itself (drafted, not adopted).
5. The `web3://` design for presence without the querier's wallet.
6. Whether native apps move to an entry outer layer or TLS for `/post` and the listen stream.

Settled since v0.1: the v3 wire format (Section 10.3, final at release);
retirement of voice channel v1 and of Chat on the legacy listen pool (both
removed in the rollout, no backward compatibility).

## Appendix C — Revision history

| Version | Date | Change |
|---|---|---|
| v0.1 | 1 November 2026 | First draft, from the operator decisions of 31 October and 1 November 2026 and the deployed and in-rollout code |
| v0.2 | 2 November 2026 | Voice channel v3 moves from Planned to In rollout, with its wire format, refusal codes and canary results. New: listen health (5.3), warm node pools (7.4), native-only sending in the apps (4.5), `no_route`, mailbox alignment before dialing (8.2), late-push handling (8.3), incoming identity and local avatars (8.4), the `voice_call_ringing_v1` wake receipt (8.5), the 60-second ring window and native caller timeout (8.6), prepared cancel and hang-up, busy and Missed call (8.7), Android push limits (11.1). Known limitations and open items updated; rollout order as decided on 2 November. Chat described as an application of Layer Minus, with node roles in Layer Minus terms |
