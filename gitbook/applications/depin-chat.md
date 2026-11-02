# CoNET Chat

**Wallet-addressed, zero-trust communication capability using Layer Minus
over CoNET L0 resources.**

**Maturity: Implemented capability, with a privacy upgrade in rollout.** Beamio
Consumer, Merchant OS, and POS already use this infrastructure. It is not a
finished public messenger with channels or large groups. Real-time voice is an
implemented encrypted relay capability. **Group chat V1** (≤10 members,
per-recipient OpenPGP fan-out) is specified for SDK clients; product UI
coverage may lag the wire protocol. Larger groups and MLS / epoch key agreement
remain a later crypto profile
([security limits](../l0/security-limits.md#chat-crypto-profile-roadmap)).

**Whitepaper.** The [CoNET Chat whitepaper](depin-chat-whitepaper.md) (v0.1 discussion draft, 1 November 2026) collects the design goals, threat model, delivery and listen paths, the Chat daemon, call signalling, voice channel v2, the planned payer-signed voice channels, push, history and known limitations in one place.

## Protocol status (November 2026)

This page describes three stages. Each statement below says which stage it
belongs to; a design that is not yet deployed is never described as live.

| Stage | What it covers |
|---|---|
| **Live** | Recipient-PGP envelopes with the sender wallet inside; A/B/C mailbox routing; voice channel v2 (opaque chunks with no per-frame metadata); the callee's own mailbox rings the callee (`voice_offer_store` with `push: 1`); voice commands carry no wallet and no wallet signature; in the iOS and Android apps the native Chat SDK holds the wallet and PGP keys, signs for itself, and keeps the mailbox SSE (chat-sdk-ios 0.1.7, chat-sdk-android 0.2.5) |
| **Live, being replaced** | The legacy call-wake fallback through the caller's own mailbox; plaintext mailbox SSE frames; user-PGP armor posted without a mailbox layer; browser clients posting one message to several entries at once; the public-key lookup `eth_call` carrying the caller's own wallet as `from`; the legacy `mining` + `listenKind: "chat"` listen pool |
| **In rollout** (code written, not deployed) | Every delivery wrapped to the recipient mailbox route key; a per-listen `streamKey` that seals every mailbox SSE frame; the legacy call-wake fallback removed; one entry at a time; app pages sending through the native SDK; the public-key lookup without `from`; a pre-warmed native entry pool and node table; native caller cancel prepared at dial time; ChatDaemon protocol v1 (`hello`) |
| **Planned** | Payer-signed temporary voice channels; ChatDaemon phases P2–P4 |

These privacy changes are not backward compatible. Clients and nodes move
together; an old client cannot use a node that requires the new listen format.
The known limitations that remain after the rollout are listed under
[Known limitations](#known-limitations).

## Native daemon and voice-call wake-up

**Live.** In the iOS and Android apps, the native Chat SDK is the Chat daemon.
At sign-in the app page hands the wallet private key and the user PGP private
key to the SDK once (`provisionIdentity`). The SDK stores them only in the
Keychain (`AfterFirstUnlockThisDeviceOnly`) or the Android Keystore, never logs
them, and wipes them on `clearIdentity`. It signs `mailbox_listen`, mailbox
ACKs, and outgoing messages itself, so it can listen before the page has
loaded. The page no longer runs its own mailbox listen inside the app.

The daemon does not run in the background after the app exits. It keeps the
mailbox SSE open only while the app is in the foreground, while a call push is
ringing, and during a call (including with the screen locked). While it runs,
the mailbox SSE stays open the whole time, including during dialing, ringing
and calls, so other senders' messages still arrive mid-call.

A voice call can wake a registered native device with an opaque,
metadata-only VoIP/FCM push. A random `callId` and `sessionId` identify the
call; neither is derived from the caller's wallet or tag. The push never
contains private keys, session keys, audio, or plaintext, and it is only a
ringing hint, not proof that the call was answered.

**Live.** The caller sends one `voice_offer_store` command with `push: 1`,
encrypted to the **callee's** mailbox route key and posted through a random
entry that is neither mailbox. The callee's mailbox stores the offer ciphertext
under `callId` + `sessionId` and asks the push API to ring the callee. The
callee mailbox already serves that wallet, so no other node learns whom the
caller is calling. When the app process was killed, the woken SDK fetches the
offer with `voice_offer_fetch`, decrypts it with its stored user PGP key,
recovers the caller from `callerSignature`, and looks up `@BeamioTag` for that
address. CallKit / Incoming then shows a larger `@tag` and a smaller shortened
address. Mailbox nodes never decrypt the offer.

**Live, being removed.** If the callee mailbox does not confirm `pushed: true`
within about 3 seconds, current clients fall back to the legacy wake: the
caller's `voice_listen` to its own mailbox carries `targetWallet` and
`offerArmor`, and the caller's mailbox forwards the offer and calls the push
API. That fallback shows the callee's wallet to the caller's mailbox.
**In rollout:** the fallback is deleted on every client and ignored by the
node; the callee-mailbox ring is the only wake path, and `voice_offer_store`
also writes the offer into the callee's live mailbox SSE, so browser callees
receive it without the legacy leg.

A caller first learns whether the contact is online, then asks that contact's
mailbox `wallet_native_wake_query`. The command is encrypted to the contact
mailbox route key and posted only to an entry that is not that mailbox, so the
mailbox does not learn the caller's IP address. A trusted
`nativeWakeable: true` means a registered iOS, Android, Windows, Linux, or
macOS shell can be rung, so the call control stays available while the listen
session is offline. The answer is a boolean and contains no device token. A
failed lookup does not clear the last trusted value, and the green presence dot
still follows online state only. Both queries still carry and are signed by the
querier's wallet; see [Known limitations](#known-limitations).

### Call control through the mailbox

Because every online client keeps its mailbox SSE open, call control (caller
cancel, decline, ring timeout, hang-up) travels as **ordinary Chat messages**:
signed by the sender wallet, encrypted to the peer's user PGP key, and posted
through a random entry like any other message. No separate signalling channel
is used for these events. A connected call may also carry the same hang-up as
an AES control frame on the voice channel; receivers act on whichever arrives
first and ignore the duplicate by `callId`.

In the native apps, the caller's cancel is built when the dial starts: the SDK
signs and encrypts it with its stored keys and keeps it in memory only. When
the caller hangs up before the callee answers, the SDK posts it at once through
the pre-warmed entry pool (in rollout). The page receives the result and does
not send its own copy.

## Encrypted file attachments

Beamio Chat supports protected document and folder attachments through
`file_message_v1`. The browser ZIPs and AES-GCM encrypts the selected files,
uploads the encrypted Data URL through resumable 512 KiB IPFS multipart chunks,
and sends only an encrypted PGP manifest. The composer keeps concurrent upload
jobs separate with progress and cancel controls; a completed attachment is
still a draft until the user presses Send.

Recipients decrypt and unzip locally and can download or preview individual
files. Photo, audio, and voice-message paths are unchanged. Plaintext content,
keys, and fragment hashes are not placed in ordinary UI/log/localStorage; the
existing encrypted history track carries only the protected manifest.

> **Protect the relationship, not only the message.**

Encryption can protect what people say.

But communication privacy is larger than message content.

Who you communicate with, how frequently you communicate, how relationships form, and how those relationships persist over time can reveal a social graph that is more sensitive than any individual message.

**CoNET Chat is designed around a stronger privacy principle: the relationship itself should be protected.**

Instead of placing users, contacts, conversations, and readable history inside one centralized messaging database, CoNET Chat uses wallet identities, zero-trust P2P communication, encrypted decentralized storage, and user-controlled cryptographic recovery.

The goal is not simply to encrypt chat.

**The goal is to prevent the user's social relationships from becoming the property of a messaging platform.**

---

## The social graph is the most sensitive layer

A message tells someone what you said.

A social graph can reveal **who matters to you**.

Over time, communication relationships can expose families, friends, business partners, customers, communities, organizations, financial relationships, and patterns of coordination.

This makes communication metadata fundamentally different from ordinary application data.

A centralized messaging provider may encrypt message content while still maintaining a powerful relationship graph:

- **Who talks to whom**
- **How often**
- **For how long**
- **Which relationships form clusters**
- **Which identities connect otherwise separate communities**

Protecting message plaintext alone does not eliminate this concentration of knowledge.

CoNET Chat therefore treats the user's social relationships as a primary privacy boundary.

> **Messages are private. Relationships should be private too.**

---

## From encrypted messages to private relationships

CoNET Chat places the sender wallet inside the signed application envelope
**before** that envelope is encrypted to the recipient's user PGP key. The
HTTP entry receives OpenPGP armor, not a plaintext `from` wallet. The mailbox
stores and forwards that armor. Only the recipient decrypts the envelope,
recovers the EIP-191 signer, and learns the sender wallet from the message.

This makes the privacy objective concrete. The protocol attempts to separate
three direct associations:

1. **Sender wallet ↔ recipient** — forwarding infrastructure sees a routing
   key or mailbox role; the business sender wallet remains inside
   recipient-only ciphertext.
2. **Message content ↔ relay** — entries and mailboxes relay OpenPGP or
   AES-GCM ciphertext without the application plaintext.
3. **User IP ↔ communication identity** — an entry sees the connection IP,
   while the mailbox sees the wallet route and receives the connection from
   the entry rather than directly from the user.

The third statement is role separation, not disappearance of IP metadata.
Entry A or C necessarily sees the IP that connects to it. A mailbox does not
see that direct client IP on a conforming A/B/C path, and the remote Chat peer
does not receive a direct socket or WebRTC candidate. Entry–mailbox collusion
or a global timing observer can weaken this separation.

There is one more association to cut: **entry ↔ recipient**. An OpenPGP armor
shows the key ID of the key it is encrypted to, and a user's PGP key is public
on chain. In the live protocol the sender's entry A therefore sees "this IP is
writing to this recipient", and the listener's entry C sees the key ID of every
message the mailbox forwards on the SSE. **In rollout:** the sender wraps every
delivery in a second layer encrypted to the recipient's mailbox route key, so A
sees only the mailbox node's key (shared by many users); and the mailbox seals
every SSE frame with a per-listen key, so C sees only padded opaque frames.

Traditional messaging architecture tends to concentrate several kinds of information in the same operator:

```text
Identity
   ↓
Contact graph
   ↓
Message routing
   ↓
Conversation metadata
   ↓
History
   ↓
Platform database
```

Even when message bodies are end-to-end encrypted, the platform may still occupy a privileged position from which communication relationships can be reconstructed.

CoNET Chat takes a different architectural direction:

```text
Wallet identity
   ↓
Layer Minus over CoNET L0 resources
   ↓
Encrypted communication
   ↓
Fragmented encrypted history
   ↓
Wallet-controlled recovery
```

The infrastructure is designed to perform its transport and storage functions without requiring one centralized service to own the complete communication relationship.

This is the central privacy objective of CoNET Chat:

### No single messaging platform should own your social graph.

---

## Your wallet is your communication identity

CoNET Chat does not begin with a platform-owned username, phone-number directory, email account, or centralized social account.

It begins with the wallet.

**Wallet → Wallet**

The wallet address becomes the communication identity.

This changes an important relationship between the user and the communication system.

| Conventional platform | CoNET Chat |
|---|---|
| The platform creates your identity and then records your relationships. | The user already owns the identity, and the communication infrastructure serves that identity. |

The social relationship no longer needs to originate inside a platform-owned account database.

### Inbound identity is the recovered signature

This rule applies to **every inbound chat message** (plain text, voice-message attachments, files, and any Messages bubble), not only voice-call offers. A decrypted Chat object may contain a wallet address or a `@BeamioTag`. Those fields are **claims**. They are not the sender. The session peer and the bubble sender are the recovered signer.

The recipient proves the sender only by recovering an EOA from an EIP-191 signature made with that wallet’s private key:

1. Decrypt the user-PGP envelope locally.
2. Recover the outer-envelope signer with `verifyMessage(text, signMessage)`.
3. Treat that signer as the sender. When it differs from the envelope’s claimed `from`, keep the message under the recovered signer and show a warning on that message naming the claimed address. Drop the message only when no signer can be recovered.
4. Display that recovered address. Look up `@BeamioTag` for **that address** (local profile first, then an exact-address search). Never take a tag out of the message body, and never use `search-users` `results[0]`.

A typed payload such as `voice_call_offer_v1` adds a second signature, `callerSignature`, over a canonical text that **excludes** identity fields (`from`, tag, and the signature itself). The callee displays the caller only when that recovery succeeds and matches the outer-envelope signer. If either check fails, the client must not present the body’s claimed address or tag as the caller. A claim that disagrees with the recovered key is not the caller; the client may show it on an extra line as an unverified claim with a warning.

Entry nodes and mailbox nodes never see this proof in plaintext. The sender wallet address and the sender PGP key stay inside the recipient user-PGP ciphertext for the whole path. Only the recipient, after decryption, can read them. The sender PGP private key never leaves the sender device. In the live protocol the only key ID a hop may see is the **recipient** key ID used for routing; after the rollout an entry sees only the recipient **mailbox node's** route key ID. A call offer travels as `offerArmor` inside `voice_offer_store` to the callee's mailbox, which stores it without decrypting it. Wake-up push and `POST /post` carry only opaque session fields or a single `{ "data" }` armor.

---

## Zero-trust communication infrastructure

CoNET Chat is built on CoNET L0 and Layer Minus.

L0 provides decentralized network resources for forwarding and storage. Layer Minus uses those resources for wallet-addressed private communication.

A communication path can separate infrastructure roles:

```text
Sender Wallet
   ↓
Entry
   ↓
Mailbox
   ↓
Entry
   ↓
Recipient Wallet
```

Application messages are encrypted before traversing this infrastructure.

Infrastructure nodes can perform routing, forwarding, mailbox, and storage functions without needing the recipient's private key or application-message plaintext.

This is why CoNET Chat is better understood as **communication infrastructure**, rather than another messaging service.

---

## Decentralized history without a centralized social database

Conversation history creates another major privacy problem.

If one provider stores every user's complete history, that provider does not merely hold messages.

It holds a long-term record of relationships.

CoNET Chat separates encrypted history from the centralized messaging-platform model.

Conversation records can be encrypted and fragmented across decentralized storage infrastructure.

The recovery path conceptually becomes:

```text
Encrypted fragments
   *
Encrypted index
   *
Wallet-controlled cryptographic authority
   ↓
Recovered history
```

The decentralized cloud stores ciphertext.

The user's cryptographic authority controls recovery.

This means historical communication does not need to exist as a readable centralized database controlled by the messaging provider.

And that matters because protecting history is also about protecting the relationships encoded inside that history.

---

## The private key restores more than messages

When a user restores CoNET Chat history, the system is not merely reconstructing text.

It is reconstructing the user's own communication context.

The cryptographic authority associated with the wallet is required to recover encrypted historical state.

Without that authority, decentralized storage providers should see encrypted material rather than a readable conversation archive.

This creates a fundamentally different ownership model:

- **Infrastructure stores encrypted fragments.**
- **The wallet controls reconstruction.**
- **The user retains authority over communication history.**

The objective is to make social relationships cryptographically recoverable by the user without making them centrally readable by the infrastructure provider.

---

## CoNET Chat is infrastructure, not a social silo

CoNET Chat is not intended to become another platform that owns users, contacts, and communities.

It is intended to provide the private communication layer beneath applications.

The same infrastructure can support:

- **Wallet ↔ Wallet**
- **Customer ↔ Merchant**
- **Merchant ↔ POS**
- **User ↔ AI Agent**
- **Application ↔ Application**
- **Human ↔ Machine**

A wallet application can use it.

A commerce application can use it.

A decentralized social application can use it.

An AI agent can use it.

A third-party developer can use it through the CoNET Chat SDK.

The application may change.

The communication relationship remains controlled by wallet identities rather than by a centralized social platform.

---

## Developer-ready infrastructure

CoNET Chat is available to developers through:

`@conet.project/chat-sdk`

The SDK provides reusable infrastructure for wallet-addressed communication, cryptographic operations, mailbox interaction, encrypted messages, delivery state, encrypted history, and recovery.

This allows developers to add private communication without first building a centralized user-and-relationship database as the foundation of their application.

The architectural goal is simple:

**Give applications communication infrastructure without giving a platform ownership of the user's social graph.**

Wire-level how-to: [CoNET Chat developer guide](../l0/chat-developer-guide.md) and [L0 development](../developers/l0.md).

---

## Already integrated into Beamio

CoNET Chat infrastructure is already used across Beamio product environments.

| Surface | Role |
|---|---|
| **Beamio Consumer** | Wallet-to-wallet communication, presence, delivery state, offline messages, and encrypted-history recovery |
| **Beamio Merchant OS** | Merchant communication, encrypted delivery, message listening, and application-level authorization workflows |
| **Beamio POS** | Wallet communication and typed authorization messages between POS terminals and merchant systems |

This also demonstrates that CoNET Chat is broader than human text messaging.

The same private communication infrastructure can carry machine-readable application messages.

---

## Privacy boundary

CoNET Chat should not claim that communication metadata disappears completely.

Zero trust does not mean zero metadata.

Individual infrastructure participants may still observe limited information required to perform their role, such as connections, timing, traffic volume, encrypted-message arrival, or routing state.

Endpoint compromise can also expose information available to that endpoint.

The architectural objective is therefore more precise:

**Avoid concentrating identity, relationship, routing, message content, and readable history inside one trusted messaging provider.**

Role separation, encrypted payloads, decentralized infrastructure, fragmented encrypted history, and wallet-controlled recovery reduce the amount of relationship information that any single infrastructure participant needs to possess.

### Compare fields, not the word “relay”

The fact that two systems both use relay servers does not establish the same
privacy property. For voice calls, a useful comparison asks what each role
actually receives:

- Does the peer receive the other participant's network address?
- Does an entry receive a wallet identity as plaintext, or only a connection
  plus ciphertext?
- Does the voice mailbox receive the initiating application wallet, or only a
  separate routing identity / opaque call capability?
- Can a media relay decrypt frames, or does it receive only authenticated
  ciphertext and temporary session identifiers?
- Which fields and identifiers are written to logs?

Signal-style call relaying is commonly discussed in terms of preventing the
two call endpoints from learning one another's IP addresses. CoNET's stated
design target additionally separates entry IP observation from mailbox wallet
state. In the live voice channel v2, the node that holds a voice session
receives only an opaque channel locator, a write key, and padded ciphertext
chunks; voice commands carry no wallet and no wallet signature. This property
is checked against the actual command, push payload, SSE frame, and logs; the
mere existence of a relay is not evidence for it. The planned payer-signed
voice channels add one visible field, the payer's wallet, to the relay that
the payer chooses; see [Real-time voice calls](#real-time-voice-calls).

---

## Protect what people say. Protect who people know.

For decades, online communication has treated the social graph as an asset belonging to the platform.

CoNET Chat takes the opposite position.

- **Your identity belongs to your wallet.**
- **Your messages belong to you.**
- **Your history belongs to you.**
- **Your relationships belong to you.**

CoNET Chat is designed to make the social relationship itself one of the most protected forms of private information in the communication stack.

**Wallet-addressed. Zero-trust. Relationship-private.**

Built on CoNET L0.

---

## Protocol dependencies

The relationship-privacy objective is implemented on existing L0 contracts. Those contracts do not disappear because the product thesis is stronger.

| Dependency | Chat use |
|---|---|
| **AddressPGP on CoNET L1** | Registers user PGP, route PGP, and mailbox binding |
| **Layer Minus `/post`** | Carries encrypted application envelopes and listen commands |
| **A/B/C mailbox routing** | Sender uses a random entry **A**; recipient listens through a random entry **C**; neither may be the sender's or the recipient's mailbox, and mailbox **B** is never the client HTTP target |
| **EIP-191 sender signature** | Authenticates the outer envelope |
| **Recipient user PGP** | Encrypts application plaintext |
| **Mailbox route PGP** | Encrypts listen, mailbox ACK, presence query, call-offer store, and (in rollout) the mailbox layer around every delivery |
| **ChatIndexRegistry + IPFS fragments** | Encrypted recoverable history; the chain stores only a pointer |

Chat is therefore an application of L0, not a separate messaging network.

---

## Delivery path

```text
Sender wallet
    → sign envelope; encrypt to recipient user PGP
    → (in rollout) wrap { data: armor, NoPush? } to recipient mailbox B route PGP
    → POST { "data" } to one random entry A (not B, not the sender's mailbox)
    → next entry only after a clear failure
    → mailbox B stores ciphertext
Recipient wallet
    → encrypt mailbox_listen to B route PGP (in rollout: with a fresh streamKey)
    → SSE through random entry C ≠ B
    → (in rollout) open each sealed SSE frame with streamKey
    → decrypt locally, store
    → mailbox ACK to B
    → sender receipt to sender user PGP
```

Normative routing: [Zero-trust mailbox routing](../l0/mailbox-routing.md).

Chat clients use SI's dedicated `mailbox_listen` command, encrypted to B's
route PGP and submitted through C. Each device/session has an opaque connection
instance, so one wallet may maintain multiple mailbox SSE sessions. B persists
the ciphertext first and then fans it out independently to every healthy
session; clients deduplicate by application `sendId`. Mailbox keepalives use a
bounded 60–180 second per-session `setTimeout` schedule with jitter for
connection reliability and load distribution, not traffic masquerading.

**In rollout:** `mailbox_listen` must carry a fresh 32-byte `streamKey`, and B
refuses a listen without one. The legacy `mining` + `listenKind: "chat"` pool
no longer receives Chat messages (it keeps only presence and mining). A send
whose recipient mailbox route key cannot be found fails with
`recipient_mailbox_unknown` instead of going out without the mailbox layer.

---

## Delivery receipts and offline storage

Mailbox first stores ciphertext, then attempts live SSE.

A recipient that accepts a message should emit two receipts:

1. **Mailbox ACK** — encrypted to **B route PGP**, so B can delete offline ciphertext.
2. **Sender receipt** — encrypted to the **sender user PGP**, so the sender UI can mark `delivered`.

Sender receipts use mailbox-work wrap `{ data, NoPush: true }` so they do not generate extra push notifications. HTTP `/post` still carries only `{ "data" }`.

## Voice messages

Beamio Chat voice messages use the same relationship-private delivery path as
text. A client records audio locally, encrypts the bytes with a fresh
AES-256-GCM key and 12-byte nonce, and uploads only the encrypted fragment.
The client sends a `voice_message_v1` manifest inside the recipient-only,
signed Chat envelope:

```json
{
  "type": "voice_message_v1",
  "fragmentHash": "0x<64 hex characters>",
  "key": "<base64 AES key>",
  "iv": "<base64 GCM nonce>",
  "mime": "audio/webm",
  "durationMs": 4200,
  "sizeBytes": 123456
}
```

The manifest is readable only by the recipient's user-PGP private key. The
mailbox, entries, and IPFS gateway see neither the manifest key material nor
the plaintext audio. The encrypted fragment is uploaded sequentially in
**512 KiB** chunks and the gateway enforces a **256 MiB** maximum object
boundary. This is a gateway/resource limit, not a promise of unlimited
recording length; clients should apply a shorter product limit before capture.

On receipt, the client verifies the outer EIP-191 signature, validates the
manifest and fragment hash, downloads the encrypted fragment, and lets
AES-GCM authentication succeed before decoding. It creates a local Blob and
object URL only for playback, revokes the URL when the player/message view is
released, and does not put decrypted audio or object URLs into the encrypted
history track. Failed fetches, malformed manifests, hash mismatches, GCM
authentication failures, and oversized or overlong media remain unavailable;
they must not clear a previously trusted message.

The application must bind voice handling to `sendId` (and an optional
application nonce/expiry), deduplicate before playback, and treat replay as a
delivery duplicate rather than a new recording. IPFS content addressing
protects ciphertext integrity only; it does not prevent replay, traffic
analysis, endpoint compromise, or a recipient from saving the decoded audio.

Products may expose privacy controls such as disabling voice, contacts-only
voice, recipient-only delivery, recording duration/size limits, local
retention, and optional padding or delayed upload. These settings are
application policy and must not be encoded as plaintext HTTP fields or
route-key commands. Current routing still exposes ciphertext timing, size,
fragment arrival, and mailbox listen metadata to the infrastructure roles.

## Native push badge and `NoPush`

`NoPush` is a **mailbox-work** instruction inside ciphertext encrypted to **B route PGP**. It is not an HTTP JSON field.

| Traffic | Mailbox work `NoPush` | Native badge |
|---|---|---|
| Ordinary Chat / Merchant Messages / POS one-to-one Chat | **Omit** | Offline recipient may receive a native badge after `saveLocal` |
| Sender `beamio_chat_delivery_receipt_v1` | **`true`** | Must not generate an extra push |
| POS terminal-authorization envelope | Product-defined; Merchant OS still puts it on Staff pending, not Messages | Do not treat it as a Messages bubble |

HTTP `/post` remains `{ "data": "<armor>" }` only. Clients that need `NoPush` wrap the inner user-PGP armor as `{ data: innerArmor, NoPush: true }`, encrypt that object to mailbox **B route PGP**, and POST the outer armor.

**Live defect, fixed in rollout:** the live mailbox unwraps the work envelope
but drops the `NoPush` flag, so a receipt can still trigger a push. The rollout
restores the flag. Because the rollout wraps **every** delivery as mailbox work,
`NoPush` then costs nothing extra: ordinary messages simply omit it. The
rollout also makes B store one copy per ciphertext (keyed by the armor hash),
so a retry through a second entry does not store or push twice.

L0 exclusive attachments were removed from SI on 2026-10-31; mailbox work is routed by its inner user-PGP key ID only.

---

## Presence

Online state is **mailbox listen-pool state**, not an on-chain `routeOnline` flag.

A contact query uses `wallet_online_query`, encrypted to that contact’s mailbox route PGP and submitted through an entry that is not B. Failed queries must not overwrite a previously trusted online/offline value. After that answer, `wallet_native_wake_query` uses the same entry path and reports whether a registered native shell can be woken. Posting either query straight to the mailbox would expose the querier's IP; the entry hop is mandatory, including when no other entry is listed. The client keeps tag, image, online, and native-shell answers in one local BeamioTag record and shows that record first. It refreshes a field from the network when the field is older than 180 seconds. An open conversation takes over the online query and repeats it every 6 seconds. The wake boolean is separate from the green dot.

**Known limitation:** both queries carry the querier's `walletAddress` and are
signed with the querier's wallet, so the contact's mailbox learns who is asking
about whom. This is accepted for now and will be solved with the `web3://`
protocol; clients must not add an ad-hoc workaround or any new command that
hands the sender's wallet to the peer's mailbox.

Looking up a contact's keys reads `AddressPGP.searchKey(contact)` over CoNET
RPC. That call does not depend on the caller. **Live:** the Consumer PWA sends
it with its own wallet as the `eth_call` `from`, so the RPC endpoint sees both
wallets and the IP. **In rollout:** the lookup omits `from`; only reading one's
own encrypted private key still identifies the caller, as it must.

---

## History recovery

Local UI chat lists are device state. Cross-device recovery uses:

1. RPC `getPointer(eoa)` on ChatIndexRegistry (`0x1511Caa71081C84d8a591490D1b83879088EED72`);
2. encrypted index and fragments from IPFS;
3. keys derived from the wallet’s cryptographic authority.

The local and remote index manifests are union-merged by `sendId` (or fragment `cid` when `sendId` is absent), so concurrent appends from multiple devices are not lost. If sequence or `prevCid` forks are detected, the worker decrypts the affected records, orders them deterministically by timestamp and `sendId`, re-encrypts the fragments with a new linear `(seq, prevCid)` chain, uploads the repaired fragments, and publishes a new head pointer. A failed or incomplete network read never clears the last trusted local mirror.

A restore that finds no local conversations must still create missing sessions from recovered history. An empty local list is not proof that the user never communicated. After history initialization, the worker performs serialized background head synchronization through a non-overlapping `setTimeout` chain and clears that timer on destroy.

The Consumer client keeps those decrypted records in a Worker-local corpus keyed by fragment hash. The UI reads that corpus through the chat module (`readDecryptedChatHistory`, `searchDecryptedChatHistory`). A fragment that is already decrypted is not fetched from IPFS again. Search matches every whitespace-separated token against rendered message text across the stored history. The chain pointer and the encrypted fragments remain the cross-device record; the plaintext corpus never leaves the device and is not written to Local Storage, logs, or the API.

That is how history recovery reconstructs **communication context**, not only message text.

---

## What exists today

- Wallet-to-wallet encrypted messages in Beamio Consumer
- Merchant listening and POS authorization envelopes
- Dual receipts, mailbox ACK after the client has stored the message, and offline flush
- Encrypted-history append and recover on the Consumer path, with a Worker-local decrypted corpus and full-corpus text search
- Native Chat daemon in the iOS and Android apps: stored keys, local signing, daemon-owned mailbox SSE
- One-to-one voice and video calls over voice channel v2, rung by the callee's own mailbox
- Published SDKs: `@conet.project/chat-sdk` (TypeScript), [chat-sdk-ios](https://github.com/CoNET-project/chat-sdk-ios), [chat-sdk-android](https://github.com/CoNET-project/chat-sdk-android)

## Real-time voice calls

A real-time call is a temporary encrypted media session. It is distinct from
the `voice_message_v1` recording attachment and is not part of ordinary Chat
history. The normal `mailbox_listen` SSE stays open for text, files, receipts,
call control and offline delivery; media uses separate temporary voice
sessions. There is no direct peer socket, WebRTC, or exchange of peer IP
candidates.

### Live: voice channel v2

```text
offer (signed by the caller, encrypted to the callee user PGP):
  callId, sessionId, session key, codec, entry list, timestamps
  → voice_offer_store { push: 1 } to the callee mailbox, through a random entry

each listening side, per direction:
  voice_listen { sessionId, v: 2, wk } to the node that holds its session
  (no wallet, no signature) → node answers voice_ready { v: 2 }

each media or control chunk:
  "CVC2" ‖ channel locator (16 bytes) ‖ HMAC-SHA256(wk, locator ‖ blob)[:16] ‖ blob
  blob = AES-GCM ciphertext, padded to a multiple of 256 bytes
  sequence, capture time, media kind and fragment numbers are inside the blob
```

- The node that holds a session sees the entry's IP, the locator, the write
  key, and padded ciphertext with its timing. It does not see a wallet, a
  sequence number, a timestamp, or whether a chunk is audio or video.
- The node checks the HMAC before it forwards a chunk, so it drops forged
  chunks without decrypting anything.
- Clients decrypt first and then reorder by the sequence numbers inside the
  blob; the node does not reorder or decrypt.
- The session key reaches the callee only inside the signed, recipient-PGP
  offer. Each chunk is posted through a different random entry from a probed
  rotation pool.
- Voice channel v1 (per-frame JSON with an outer `seq`) remains only as a
  fallback for older clients.

The relay still exposes ciphertext size, timing and session duration, so the
design improves peer-address and identity privacy but does not resist traffic
analysis. Relay success means only that a chunk entered the peer's SSE queue,
not that it was played.

### Planned: payer-signed temporary voice channels

Today no one pays GB for voice sessions, and the offer's temporary wallet field
is unused. The decided next design:

- **The callee pays for every channel.** A call has up to four channels (each
  side receiving voice, each side receiving video), all set up at the start of
  the call. Each channel gets its own temporary wallet and its own symmetric
  key; no key is shared between directions.
- The caller's offer no longer carries a session key, a temporary wallet or a
  relay. When the callee answers, it creates the four temporary wallets and
  keys, signs the caller's channels as payer, and sends them back in an accept
  message through the caller's mailbox (a normal Chat delivery).
- **Each side chooses its own relay node**, so the callee cannot pick a relay
  it colludes with for the caller's channels.
- A `voice_listen` without a valid payer signature on its temporary wallet is
  refused. CoNET-SI only verifies that signature.
- A payer may split payment across several of its own wallets; the client
  composes this, and CoNET-SI does not take part.
- This round builds the authorization architecture only. No usage is charged
  yet; settlement arrives with the GB settlement module. Voice usage will not be
  added to the existing per-wallet byte counts, which issue GB rather than
  charge it.
- It is not backward compatible with the current call flow.

Privacy trade-off: a relay that verifies a payer signature learns that the
payer wallet has a voice channel open, for how long, and how many bytes it
carries. The relay still does not learn the other party: chunks arrive through
entries and the authorization carries no call identifier. Splitting payment
across wallets limits how much one relay can link to a single wallet. The wire
format is not final.

## What remains under development

- The privacy rollout described under [Protocol status](#protocol-status-november-2026), then removal of the legacy listen and call-wake paths
- Payer-signed temporary voice channels (planned)
- ChatDaemon P2–P4: inbound verification, storage and ACK inside the daemon; sending, presence, offers, nodes and route registration inside the daemon; removal of old paths
- Broader client coverage beyond the current Beamio surfaces
- Product UI for Group chat V1 across Consumer / Merchant / POS (wire + SDK
  helpers exist; see [Group chat V1](../l0/chat-developer-guide.md#group-chat-v1-small-groups))
- Channels and large groups (Chat crypto **V3** / MLS — research)
- Voice/video media adaptation, congestion control, and stronger
  traffic-analysis resistance

---

## Trust boundary

| Participant | Can see | Must not see |
|---|---|---|
| Entry A / C | Connecting IP, encrypted payload, timing, size, outer routing key ID. Live: the recipient's user key ID (A) and the key ID of each delivered message (C). In rollout: only the recipient mailbox's route key ID (A) and padded sealed frames (C) | Application plaintext, sender wallet inside the encrypted business envelope, recipient private key |
| Mailbox B | Ciphertext, which of its own users a message is for, listen-pool membership, ACK hashes, opaque voice session/call identifiers; presence queries reveal the querier (known limitation) | Application plaintext, sender wallet, user PGP private key |
| Voice relay (session node) | Entry IP, channel locator, write key, padded chunk ciphertext and timing. Planned: the payer wallet of the channels it serves | Session keys, media plaintext, the other party's wallet |
| Push API | Opaque `callId` / `sessionId` and the registered device of the woken user | Caller wallet or tag, keys, audio |
| CoNET RPC | Addresses whose keys are looked up and the client IP. Live: also the caller's own wallet as `from` (removed in rollout) | Message content |
| IPFS / fragment store | Encrypted fragments and encrypted index | Readable history without wallet authority |
| Beamio API | Gas-sponsored writes such as ChatIndexRegistry pointer updates | Private keys, plaintext history |
| Recipient wallet | Decrypted application objects after local verification | Other users' private keys |

Zero trust does not mean zero metadata. The design goal is to avoid putting identity, relationship, routing, content, and readable history in one trusted messaging provider.

## Known limitations

These remain after the rollout and are stated here so that no other page
claims more:

- **Presence queries** (`wallet_online_query`, `wallet_native_wake_query`) carry
  and are signed by the querier's wallet. Planned fix: `web3://`.
- **Native plain HTTP.** The iOS and Android SDKs post to entries and hold the
  mailbox SSE over plain HTTP on port 80, and native posts carry no extra
  outer layer for the entry. A network observer between the phone and the
  entry sees the entry address, sizes, timing and the outer key ID (after the
  rollout, the recipient mailbox's route key ID). This is not being changed now.
- **Payer visibility** (planned voice channels): the relay learns the payer
  wallet of each channel it serves.
- **Collusion and timing.** An entry colluding with a mailbox, one operator
  running several roles, or a global timing observer can relink sender, IP and
  recipient.
- **Endpoints.** A compromised device exposes what that device can decrypt.

---

## Related

- [CoNET Chat whitepaper](depin-chat-whitepaper.md)
- [CoNET Chat developer guide](../l0/chat-developer-guide.md)
- [L0 development](../developers/l0.md)
- [How to use Layer Minus](../l0/using-l0.md)
- [Zero-trust mailbox routing](../l0/mailbox-routing.md)
- [Security limits](../l0/security-limits.md)
- [Beamio](beamio.md)
- [Decentralized SNS](../use-cases/decentralized-sns.md)
- [Wallet-addressed applications](web3-url.md)
