# CoNET Chat

**Wallet-addressed, zero-trust communication capability using Layer Minus
over CoNET L0 resources.**

**Maturity: Implemented capability.** Beamio Consumer, Merchant OS, and POS
already use this infrastructure. It is not a finished public messenger with
groups or channels. Real-time voice is an implemented encrypted relay
capability; groups and channels remain outside the current product.

## Native voice-call wake-up

Beamio Chat voice calls can wake a registered native device with an opaque,
metadata-only VoIP/FCM push. A random `callId` and `sessionId` identify the
temporary call; neither is derived from the caller's wallet or tag.
The push never contains private keys, PGP session keys, audio, or plaintext.
The native shell presents the system call UI, while the encrypted offer and
media continue through the normal Chat mailbox path. Push delivery is only a
ringing hint and does not mean that the call was answered.

The upgraded voice route removes the initiating application EOA from
`voice_listen`, frame commands, push metadata, and relay logs. The mailbox
receives only the encrypted route command, opaque session identifiers, and the
callee routing target. The initiating application wallet remains only inside
the recipient-user-PGP call offer.

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
3. Accept the message only when that signer equals the envelope’s claimed `from`.
4. Display that recovered address. Look up `@BeamioTag` for **that address** (local profile first, then an exact-address search). Never take a tag out of the message body, and never use `search-users` `results[0]`.

A typed payload such as `voice_call_offer_v1` adds a second signature, `callerSignature`, over a canonical text that **excludes** identity fields (`from`, tag, and the signature itself). The callee displays the caller only when that recovery succeeds and matches the outer-envelope signer. If either check fails, the client must not present the body’s claimed address or tag as the caller. A claim that disagrees with the recovered key is not the caller; the client may show it on an extra line as an unverified claim with a warning.

Entry nodes and mailbox nodes never see this proof in plaintext. The sender wallet address and the sender PGP key stay inside the recipient user-PGP ciphertext for the whole path. Only the recipient, after decryption, can read them. The sender PGP private key never leaves the sender device. The only key id a hop may see is the **recipient** key id used for routing. An outgoing `voice_listen` may also carry that ciphertext as `offerArmor`; the caller's mailbox forwards it to the callee mailbox and does not decrypt it. Wake-up push and `POST /post` still carry only opaque session fields or a single `{ "data" }` armor.

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
state. The implemented initiator-hidden voice protocol requires the voice
mailbox to receive a separate routing identity or opaque session authority,
rather than the initiating application wallet. That last property is an upgrade requirement and must be
validated against the implemented command, push payload, SSE frame, and logs;
the mere existence of a relay is not evidence for it.

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
| **A/B/C mailbox routing** | Sender uses entry **A**; recipient listens through entry **C**; mailbox **B** is never the client HTTP target |
| **EIP-191 sender signature** | Authenticates the outer envelope |
| **Recipient user PGP** | Encrypts application plaintext |
| **Mailbox route PGP** | Encrypts listen, mailbox ACK, and presence query |
| **ChatIndexRegistry + IPFS fragments** | Encrypted recoverable history; the chain stores only a pointer |

Chat is therefore an application of L0, not a separate messaging network.

---

## Delivery path

```text
Sender wallet
    → encrypt to recipient user PGP
    → POST { "data" } through healthy entry A
    → mailbox B stores ciphertext
Recipient wallet
    → encrypt listen to B route PGP
    → SSE through healthy entry C
    → decrypt locally
    → mailbox ACK to B
    → optional sender receipt to sender user PGP
```

Normative routing: [Zero-trust mailbox routing](../l0/mailbox-routing.md).

New Chat clients use SI's dedicated `mailbox_listen` command, encrypted to B's
route PGP and submitted through C. Each device/session has an opaque connection
instance, so one wallet may maintain multiple mailbox SSE sessions. B persists
the ciphertext first and then fans it out independently to every healthy
session; clients deduplicate by application `sendId`. Legacy clients may still
use `mining` with `listenKind: "chat"`, while mining collectors omit
`listenKind`. Mailbox keepalives use a bounded 60–180 second per-session
`setTimeout` schedule with jitter for connection reliability and load
distribution, not traffic masquerading.

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

L0 duplex mailbox work must omit Chat/APNs `NoPush`. See [Persistent application streams](../l0/duplex-forward.md).

---

## Presence

Online state is **mailbox listen-pool state**, not an on-chain `routeOnline` flag.

A contact query uses `wallet_online_query`, encrypted to that contact’s mailbox route PGP and submitted through an entry that is not B. Failed queries must not overwrite a previously trusted online/offline value.

---

## History recovery

Local UI chat lists are device state. Cross-device recovery uses:

1. RPC `getPointer(eoa)` on ChatIndexRegistry (`0x1511Caa71081C84d8a591490D1b83879088EED72`);
2. encrypted index and fragments from IPFS;
3. keys derived from the wallet’s cryptographic authority.

The local and remote index manifests are union-merged by `sendId` (or fragment `cid` when `sendId` is absent), so concurrent appends from multiple devices are not lost. If sequence or `prevCid` forks are detected, the worker decrypts the affected records, orders them deterministically by timestamp and `sendId`, re-encrypts the fragments with a new linear `(seq, prevCid)` chain, uploads the repaired fragments, and publishes a new head pointer. A failed or incomplete network read never clears the last trusted local mirror.

A restore that finds no local conversations must still create missing sessions from recovered history. An empty local list is not proof that the user never communicated. After history initialization, the worker performs serialized background head synchronization through a non-overlapping `setTimeout` chain and clears that timer on destroy.

That is how history recovery reconstructs **communication context**, not only message text.

---

## What exists today

- Wallet-to-wallet encrypted messages in Beamio Consumer
- Merchant listening and POS authorization envelopes
- Dual receipts, mailbox ACK, and best-effort offline flush
- Encrypted-history append and recover on the Consumer path
- Published SDK: `@conet.project/chat-sdk`

## Real-time voice calls

CoNET Chat is developing a privacy-preserving one-to-one voice call mode.
This is distinct from the already implemented `voice_message_v1` recording
attachment: it is a temporary encrypted media session and is not part of
ordinary Chat history.

The normal Chat `mailbox_listen` SSE remains available for text, files,
receipts and offline delivery. A call creates a random temporary `sessionId`
and two temporary `voice_listen` SSE sessions, one on each participant's own
mailbox. Short `voice_uplink` / `voice_downlink` commands deliver encrypted
frames to the peer's temporary session. This creates a duplex relay without a
direct peer socket, WebRTC, or exchange of peer IP candidates.

The browser encrypts each audio frame with AES-256-GCM. The session key is
delivered only inside the signed recipient-user-PGP call offer/accept envelope.
Entries and mailboxes route opaque ciphertext and must not receive the key,
plaintext audio, or an HTTP media field. The MVP does not write frames to
offline storage, push notifications, or encrypted Chat history.

The relay exposes metadata such as encrypted frame size, timing, session
duration and mailbox routing state. It therefore improves peer-address privacy
but does not provide complete traffic-analysis resistance. Relay success means
only that a frame entered the peer SSE queue, not that it was played.

### Initiator-hidden voice protocol

The voice privacy profile separates call discovery from mailbox transport:

```text
recipient-user-PGP offer (also attached as voice_listen.offerArmor):
  initiating application wallet + callee wallet + session key + call policy

caller mailbox voice_listen:
  opaque callId + random sessionId + callee target + offerArmor ciphertext

voice relay:
  random session/capability identifiers + encrypted frames
```

The caller mailbox attaches the temporary SSE using the encrypted route and
opaque session identifier. In the same command it forwards `offerArmor` to
the callee mailbox and does not decrypt it. It does not receive the initiating
application wallet as `walletAddress`, `callerEoa`, `callId`, or another
reversible field. The recipient learns the initiating wallet only after
decrypting the call offer and recovering the caller from `callerSignature`.
The offer body’s address or tag is not that proof. `@BeamioTag` is looked up
for the recovered address. The callee route remains an operational delivery
target.

The current wire shape excludes the initiating application wallet from
mailbox-visible voice commands, wake-up push metadata, and voice-frame relay
fields. The callee routing target remains an operational destination field.

## What remains under development

- Broader client coverage beyond the current Beamio surfaces
- Groups and channels
- Production-grade voice-call media adaptation, congestion control, codec
  portability and stronger traffic-analysis resistance

---

## Trust boundary

| Participant | Can see | Must not see |
|---|---|---|
| Entry A / C | Connecting IP, encrypted payload, timing, size, outer routing key ID | Application plaintext, sender wallet inside the encrypted business envelope, recipient private key |
| Mailbox B | Ciphertext, destination route, listen-pool membership, ACK hashes, opaque voice session/call identifiers | Application plaintext, initiating application wallet, and user PGP private key |
| IPFS / fragment store | Encrypted fragments and encrypted index | Readable history without wallet authority |
| Beamio API | Gas-sponsored writes such as ChatIndexRegistry pointer updates | Private keys, plaintext history |
| Recipient wallet | Decrypted application objects after local verification | Other users’ private keys |

Zero trust does not mean zero metadata. The design goal is to avoid putting identity, relationship, routing, content, and readable history in one trusted messaging provider.

---

## Related

- [CoNET Chat developer guide](../l0/chat-developer-guide.md)
- [L0 development](../developers/l0.md)
- [How to use Layer Minus](../l0/using-l0.md)
- [Zero-trust mailbox routing](../l0/mailbox-routing.md)
- [Security limits](../l0/security-limits.md)
- [Beamio](beamio.md)
- [Decentralized SNS](../use-cases/decentralized-sns.md)
- [Wallet-addressed applications](web3-url.md)
