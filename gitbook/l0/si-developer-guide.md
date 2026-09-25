# SI developer guide

**Evidence level: Implemented capability.** This page documents how an application talks to a live **CoNET-SI** node. The command names, POST body, and encryption targets match current CoNET-SI and Beamio clients. Availability of any one Guardian domain is deployment-specific.

Public site: [https://gitbook.conet.network/l0/si-developer-guide.html](https://gitbook.conet.network/l0/si-developer-guide.html)

CoNET-SI is the Layer Minus **service node**. It accepts OpenPGP armor on `POST /post`, reads the recipient **key ID**, and either forwards the armor or decrypts **once** when the key is local. It does not implement Chat, VPN, payments, or history. Those are [application compositions](using-l0.md).

Use this page to build a client against SI. Developer-track index: [L0 development](../developers/l0.md). For a Chat product on top of the same plane, continue with the [CoNET Chat developer guide](chat-developer-guide.md).

## What you are calling

| Piece | Role |
| --- | --- |
| **CoNET-SI** | HTTP/HTTPS entry, SI-to-SI HTTP `:80` forward, mailbox store, SSE listen pools, presence, delivery ACK, UDP relay, SilentPass commands |
| **AddressPGP** | L1 binding of an EOA to user PGP and a mailbox route key |
| **GuardianNodesInfoV6** | Public node list: domain, IP, route public key |
| **Your application** | Wallet, OpenPGP keys, inner JSON schema, UI |

Public node source: [CoNET-project/CoNET-SI](https://github.com/CoNET-project/CoNET-SI) · npm [`@conet.project/mvp-si`](https://www.npmjs.com/package/@conet.project/mvp-si).

## Wire contract

Every client request is the same shape:

```http
POST /post HTTP/1.1
Host: {domain}.conet.network
Content-Type: application/json

{"data":"<OpenPGP armored message>"}
```

The HTTP JSON **must** be only `{ "data": "<OpenPGP armor>" }`. Do **not** add sibling fields (`NoPush`, `beamioNoPush`, flags, metadata). Extra plaintext fields raise inspection risk.

| Field | Meaning |
| --- | --- |
| `data` | Required. Full OpenPGP armor (`-----BEGIN PGP MESSAGE-----` …) |

If mailbox **B** must do extra work (for example skip APNs), put that instruction **inside** armor encrypted to **B’s route PGP**. See [mailbox work envelope](#3-mailbox-work-envelope-mailbox-b-decrypts). Entry A only sees `{ data }`.

Client → entry may use **HTTP or HTTPS**. HTTPS is common in browsers because mixed content forbids `http://` from an `https://` page. **HTTP is sufficient** for confidentiality: the body is already OpenPGP ciphertext. **SI → SI** forwarding is **HTTP on port 80** only. Do not treat an entry TLS certificate problem as “the DePIN mesh is down.”

Typical URLs:

```text
https://{domain}.conet.network/post
http://{domain}.conet.network/post
```

Do not invent a new hostname. Use the Guardian **domain** from `getAllNodes`. Do not default-dial mailbox **B** for Chat, listen, ACK, presence, or UDP. Pick a healthy entry **A** or **C** with `A ≠ B` and `C ≠ B`. LayerMinus mining collectors are the documented exception: they dial the target SI directly.

A **404** with a body such as `body has not PGP message` means SI rejected invalid armor. That is an intentional reject, not proof that the node process is down.

HTTP **200** on send, or an SSE handshake on listen, is **transport progress**. It is not proof that an application decrypted, verified, or rendered the payload.

### Chat voice fragment storage

`voice_message_v1` uses the existing IPFS fragment storage boundary; it does
not add an SI command or a plaintext media endpoint. The client encrypts audio
with AES-256-GCM, computes the fragment hash over the encoded encrypted
fragment, and uploads that encoded value through the chunk storage API:

```http
POST /api/storageFragmentChunk
Content-Type: application/json

{
  "wallet": "<uploader EOA>",
  "signMessage": "<signature over uploader EOA>",
  "hash": "0x<fragment hash>",
  "chunkIndex": 0,
  "totalChunks": 3,
  "chunk": "<encoded ciphertext slice>"
}
```

Chunks are ordered **512 KiB** slices and are finalized with
`POST /api/storageFragmentChunk/complete` using the same wallet signature and
hash. The gateway enforces a **256 MiB** maximum object boundary. This
endpoint sees encrypted fragment data only; it must not receive the voice
manifest's AES key or nonce. The recipient obtains those values only after
decrypting the `voice_message_v1` manifest with the recipient user-PGP key.

Storage success or HTTP 2xx proves upload progress, not message delivery,
integrity after retrieval, or playback. The client must retrieve the fragment,
verify its hash and AES-GCM tag, then create and later revoke a local object
URL. Do not log, persist, or expose decoded audio or object URLs.

## Three payload families

Do not mix encryption targets.

### 1. Opaque business armor (SI forwards, does not decrypt)

Encrypt to the **recipient’s user PGP**. SI only sees the OpenPGP key ID and routes to that key’s mailbox.

Typical use: Chat text, typed application JSON, `udp_subscribe`, and
application stream offers. UDP subscriptions and stream offers may carry
endpoint encryption material, so SI forwards their user-PGP armor without
parsing the application object. Sender delivery receipts use this inner armor,
then wrap it as
[mailbox work](#3-mailbox-work-envelope-mailbox-b-decrypts) with
`NoPush: true`.

```text
application object
  → optional EIP-191 envelope  (Chat uses this)
  → base64(JSON)
  → OpenPGP encrypt to R userPublicKeyArmored
  → POST { data } to entry A ≠ B
```

### 2. Signed SI command (mailbox B decrypts)

Encrypt `{ message, signMessage }` to **B’s route PGP**. `message` is `JSON.stringify(command)`. `signMessage` is EIP-191 `wallet.signMessage(message)`. SI `checkSign` recovers `walletAddress` and must match the signer.

That `walletAddress` is the **routing** EOA (`isMyRoute`, listen pool, last-hop GB). It does **not** have to be the sender or recipient EOA inside a user-PGP Chat body. Apps that want a stronger split register AddressPGP on a dedicated routing wallet. See [wallet-addressed peer identity](wallet-address-p2p.md#routing-wallet-versus-sender--recipient-wallets).

Typical use: Chat listen, mining listen, `gossip_delivery_ack`, `wallet_online_query`, UDP listen/relay (no `Securitykey`), SilentPass / SOCKS commands.

```text
command object  (includes walletAddress)
  → message = JSON.stringify(command)
  → signMessage = personal_sign(message)
  → base64(JSON.stringify({ message, signMessage }))
  → OpenPGP encrypt to B route public key
  → POST { data } to entry C ≠ B
```

### 3. Mailbox work envelope (mailbox B decrypts)

Wrap inner **user-PGP** armor in JSON encrypted to **B’s route PGP**. HTTP to the **entry** is still only `{ data }`.

```json
{ "data": "<inner OpenPGP armor>" }
```

| Field | Meaning |
| --- | --- |
| `data` | Inner OpenPGP armor encrypted to the recipient **user PGP** |
| `NoPush` | **Do not send** for L0 / `conet-l0d` duplex. Historical Chat field meaning “skip APNs.” If set, SI must still try the idle `l0_listen` pool **before** AddressPGP `getRoute` |

```text
inner user-PGP armor
  → JSON { data: innerArmor }
  → OpenPGP encrypt to mailbox B route public key   → <mailBoxNodeOpenPGP armor>
  → optional wrap of that armor to this entry route key
  → POST { data: <mailBoxNodeOpenPGP armor> } to entry A ≠ B
```

**B after decrypting mailbox work (normative):**

1. Inner PKESK key ID is a **user** key, not a Guardian route key.
2. Match idle `l0ListenPool` via `l0ListenByPgp` (indexed from `l0_listen.userPgpKeyId`). Hit → copy armor onto that SSE; HTTP 200; **stop**. No `getRoute`.
3. Miss → then Chat liveness / `getRoute` to another SI.

Temporary duplex wallets are **not** on AddressPGP. `getRoute` first is a protocol bug (`can not find router`).

Entry A peels (if wrapped) and forwards `{ data }` to B. Do **not** put `NoPush` on the HTTP JSON. If the client lacks B’s route public key, fail — do not fall back to a sibling HTTP field.

`gossip_delivery_ack` is a signed SI command (family 2), not mailbox work. `duplex_accept` **is** mailbox work (this family).

## Live command catalog

Source: CoNET-SI `localNodeCommandSocket`. Encrypt the command family to **route PGP** unless the table says otherwise.

| `command` | Encrypt to | HTTP / SSE | Notes |
| --- | --- | --- | --- |
| **`mailbox_listen`** | Own mailbox **B** route PGP | Long SSE via entry **C ≠ B** | Preferred Chat mailbox command. Required `walletAddress`; optional opaque `instanceId`. Multiple instances per wallet are retained and receive fan-out copies. |
| `voice_listen` | Own mailbox **B** route PGP | Separate temporary SSE via entry **C ≠ B** | Random `sessionId`; separate voice pool. Never occupies `mailbox_listen`. An outgoing call includes opaque push metadata and `offerArmor` (callee user-PGP ciphertext). B forwards `offerArmor` to the callee mailbox without decrypting it, then after `voice_ready` calls `/api/voiceCallPush`. |
| `voice_uplink` / `voice_downlink` | Peer mailbox **B** route PGP | Short POST via entry **A ≠ B** | Opaque AES-GCM frame addressed by `targetSessionId`; no session key or plaintext audio. |
| `voice_unlisten` | Own mailbox **B** route PGP | Short POST via entry **C ≠ B** | Closes one temporary voice session. |
| `mining` + `listenKind: "chat"` | Own mailbox **B** route PGP | Long SSE via entry **C ≠ B** | Chat / Merchant OS / Alliance mailbox. Required fields: `walletAddress`, `algorithm: "aes-256-cbc"`, `Securitykey` (session key) |
| `mining` (omit `listenKind`) | Target SI route PGP | Infrastructure SSE | LayerMinus mining. SI defaults `listenKind` to `"mining"`. Not a Chat shortcut |
| `gossip_delivery_ack` | **B** route PGP | Entry **C ≠ B** | After the client ingested user-PGP armor. Fields: `walletAddress`, `armorHash` (`keccak256(utf8(full armor))`), `timestamp` (unix seconds, ±600s), optional `sendId` |
| `wallet_online_query` | Contact’s mailbox **B** route PGP | Entry **C ≠ B** | Presence. Fields: `walletAddress` (signer), `targetWallet`, `timestamp` (±600s). Success: `{ ok: true, wallet, online, listenAgeMs, nodeWallet }`. Do **not** use chain `routeOnline` |
| `udp_subscribe` | UDP server **user** PGP | Entry **A ≠ B** | Contains `Securitykey`. SI rejects encryption to B (`encrypt_to_udp_server_user_pgp`) |
| `udp_listen` / `udp_server_listen` / `udp_relay` / `udp_uplink` / `udp_unlisten` | **B** route PGP | Entry ≠ B | No `Securitykey`. See [UDP frame forwarding](udp-forward.md) |
| `l0_listen` or `mining` + `listenKind: "l0"` | Own mailbox **B** route PGP | Long SSE via **C ≠ B** | Exclusive occupancy pipe. **No** overlay `Securitykey`. Field `userPgpKeyId` (encryption subkey, 16-hex) **must** be stored in `l0ListenByPgp` so later mailbox work can match this SSE. Handshake `{ ok, kind:"l0", wallet, nodeWallet }`. Idle L0 may receive user-PGP gossip without occupying. Temporary wallets are not AddressPGP; do not index only via `getWalletFromKeyID`. Separate from Chat / mining / UDP. Replacement while **live** occupied → **409** |
| `l0_connect` | **Target** mailbox **B** route PGP | Entry ≠ B; keep TCP | First occupy of idle `targetWallet` L0 SSE: write `{ type:"l0_occupied" }` on SSE, **clear idle comment keepalive**, write **HTTP 200 keep-alive** on the occupy TCP (do not `end()`), pipe remaining TCP as SSE `data:` lines, SI stops parsing that socket. Second `l0_connect` → **409**. User-PGP Chat/mining gossip on the same node must **not** 409. Idle L0 needs SSE comment keepalive (no mining epoch); occupied L0 must not write comments. Occupancy is by `targetWallet` after decrypt, not by B route key ID. On teardown while occupied: write `{ type:"l0_pipe_end" }` + `\n` on inbound TCP, optional `{ type:"l0_listen_released" }` on listen SSE, then drop pool entry ([duplex-forward](duplex-forward.md)) |
| `SilentPass` / `SaaS_Sock5` / `SaaS_Sock5_v2` | Egress node route PGP | Product-specific | Paid proxy; not a Chat path |

Old clients that omit `listenKind` on `mining` are treated as mining. During
migration, `mining` + `listenKind: "chat"` remains supported as a legacy
single-session mailbox path. New Chat clients should send `mailbox_listen`:
the session is indexed by `(wallet, instanceId)` and one encrypted business
frame is attempted on every healthy session for that wallet. A failed device
session is evicted independently. Mailbox keepalives use a bounded,
non-overlapping `setTimeout` chain with a 60–180 second delay selected per
session; this is reliability jitter, not a traffic-evasion mechanism.

## SI hop behavior (do not fight it)

When SI forwards to another SI it may append `X-CoNET-Hop-Sigs` (base64 JSON, max **3** EIP-191 hop signatures). Application clients **do not** set this header on the first `/post`.

After a **local** decrypt:

- if the plaintext is still OpenPGP **for the same node**, SI treats it as an attack, emits socket `end`, and **does not peel again**;
- if the plaintext is mailbox work JSON `{ data }` (not a signed `{ message, signMessage }`), SI unwraps the inner armor and **first** matches idle `l0_listen` by inner user-PGP key ID; only then Chat/`getRoute`. Do not treat `NoPush` as “skip L0 pool”;
- if the inner key ID is another node, SI forwards the **inner UTF-8 armor string** when hop-sig count can still grow (cap 3); SI→SI HTTP is still only `{ data }`. Prefer the peel plaintext when it already has `BEGIN PGP MESSAGE`. Coerce with `pgpArmorToUtf8String` before hop-sig `n` / `h`. Do **not** pass an OpenPGP.js 6 `Message.armor()` stream / thenable (minified class `h`) into `Buffer.byteLength`;
- hop-sign failure, non-UTF-8 armor, or C→B TCP timeout (~8s) is a **404** (or socket `end`). A log-only `uncaughtException` must still close the client socket. Do not leave the SSE open until the client’s ~12s `connect_timeout` — B was never dialed. Field lesson: [Peel, hop-sig, and listen timeouts](peel-hop-listen.md);
- more than 3 hop signatures, or a count that cannot take another hop, is an all-node flood: `end`, no forward;
- if the destination SI emits `end`, the previous hop closes and frees that socket;
- on a **signed command** path, the last hop may add verified prior-hop bytes to that wallet’s gossip **GB** meter. A mailbox store of user-PGP armor (no command decrypt) cannot charge the user.

Optional outer wrap: encrypt a user-PGP business message to an **entry** route key so the first `/post` observer sees the outer key ID. Each peel node still learns the **next** key ID. This is not a mix network. See [security limits](security-limits.md).

## Constants

| Item | Value |
| --- | --- |
| CoNET L1 | `chainId` **224422** |
| Read RPC | `https://rpc1.conet.network` (primary), `https://publicrpc.conet.network` (backup). Do not use deprecated `rpc.conet.network` |
| AddressPGP | [`0x684b0ac760cEE9c9b85de36d69746420648Cf9e2`](https://mainnet.conet.network/address/0x684b0ac760cEE9c9b85de36d69746420648Cf9e2) |
| GuardianNodesInfoV6 | [`0xBC6b53065b5647261396d002bDBA0d3396E0722f`](https://mainnet.conet.network/address/0xBC6b53065b5647261396d002bDBA0d3396E0722f) |
| Compatibility register API | `POST https://beamio.app/api/regiestChatRoute` (spelling is live) |

## Sample: discover Guardian nodes

```ts
import { ethers } from 'ethers'

const CONET_RPC = 'https://rpc1.conet.network'
const GUARDIAN_NODES = '0xBC6b53065b5647261396d002bDBA0d3396E0722f'

const guardianAbi = [
  'function getAllNodes(uint256 start, uint256 length) view returns (tuple(uint256 id, string PGP, string PGPKey, string ip_addr, string regionName)[])',
]

export type SiNode = {
  nftNumber: number
  armoredPublicKey: string
  domain: string
  ip_addr: string
  region: string
}

export async function listGuardianNodes(): Promise<SiNode[]> {
  const provider = new ethers.JsonRpcProvider(CONET_RPC)
  const c = new ethers.Contract(GUARDIAN_NODES, guardianAbi, provider)
  const pages = await Promise.all([c.getAllNodes(0, 400), c.getAllNodes(400, 800)])
  const out: SiNode[] = []
  for (const row of pages.flat()) {
    // Live clients: PGP = base64 route public key; PGPKey = Guardian domain.
    const armored = Buffer.from(String(row.PGP), 'base64').toString('utf8')
    const domain = String(row.PGPKey)
    if (!domain || !armored.includes('BEGIN PGP')) continue
    out.push({
      nftNumber: Number(row.id),
      armoredPublicKey: armored,
      domain,
      ip_addr: String(row.ip_addr),
      region: String(row.regionName),
    })
  }
  return out
}

export function postUrl(domain: string, https = true): string {
  return `${https ? 'https' : 'http'}://${domain}.conet.network/post`
}
```

Pick entries that are **not** the recipient mailbox domain. Keep a small health set: mark a domain bad on timeout / non-2xx, prefer previously healthy domains, then retry another wave.

## Sample: resolve AddressPGP

```ts
const ADDRESS_PGP = '0x684b0ac760cEE9c9b85de36d69746420648Cf9e2'

const pgpAbi = [
  'function searchKey(address to) view returns (string userPgpKeyID, string userPublicKeyArmored, string routePgpKeyID, string routePublicKeyArmored, bool routeOnline)',
]

export type AddressPgpRecord = {
  userPgpKeyID: string
  userPublicKeyArmored: string
  routePgpKeyID: string
  routePublicKeyArmored: string
}

export async function searchAddressPgp(eoa: string): Promise<AddressPgpRecord | null> {
  const provider = new ethers.JsonRpcProvider(CONET_RPC)
  const c = new ethers.Contract(ADDRESS_PGP, pgpAbi, provider)
  const r = await c.searchKey(ethers.getAddress(eoa))
  const userArmored = Buffer.from(String(r.userPublicKeyArmored), 'base64').toString('utf8')
  const routeArmored = Buffer.from(String(r.routePublicKeyArmored), 'base64').toString('utf8')
  if (!userArmored.includes('BEGIN PGP')) return null
  return {
    userPgpKeyID: String(r.userPgpKeyID),
    userPublicKeyArmored: userArmored,
    routePgpKeyID: String(r.routePgpKeyID),
    routePublicKeyArmored: routeArmored,
  }
  // Ignore routeOnline. Presence is mailbox listen-pool only (wallet_online_query).
}
```

Encrypt **business** armor to `userPublicKeyArmored` of the recipient **EOA**. An AA Smart Wallet is not a destination unless it has its own AddressPGP row.

## Sample: register a mailbox route

Current clients generate an ECC OpenPGP key, take the **encryption subkey** ID (`getKeyIDs()[1]`, uppercase hex), choose a Guardian **domain** as mailbox, and call the compatibility API. The live field name is `routeKeyID`; clients pass that **domain**, not the hex key ID.

```ts
import { generateKey } from 'openpgp'

export async function generateUserPgp() {
  const { privateKey, publicKey } = await generateKey({
    type: 'ecc',
    curve: 'curve25519',
    userIDs: [{ name: 'conet', email: 'conet@localhost' }],
    format: 'armored',
  })
  const { readKey } = await import('openpgp')
  const keyObj = await readKey({ armoredKey: publicKey })
  const keyID = keyObj.getKeyIDs()[1].toHex().toUpperCase()
  return { privateKey, publicKey, keyID }
}

export async function registerChatRoute(opts: {
  eoaPrivateKey: string
  publicKeyArmored: string
  keyID: string
  encrypKeyArmored: string
  mailboxDomain: string
}): Promise<boolean> {
  const wallet = new ethers.Wallet(opts.eoaPrivateKey)
  const res = await fetch('https://beamio.app/api/regiestChatRoute', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      wallet: wallet.address,
      keyID: opts.keyID,
      publicKeyArmored: Buffer.from(opts.publicKeyArmored, 'utf8').toString('base64'),
      encrypKeyArmored: opts.encrypKeyArmored,
      routeKeyID: opts.mailboxDomain,
    }),
  })
  const json = await res.json().catch(() => ({}))
  return res.ok && !!json?.ok
}
```

`encrypKeyArmored` is an application backup of the user PGP private key (current clients AES-GCM encrypt it with material derived from the EOA). **Do not log** the EOA key, mnemonic, PGP private armor, `Securitykey`, or full hop signatures.

After register, wait and re-read `searchKey(eoa)` until `userPgpKeyID` matches the local subkey ID.

## Sample: encrypt a signed SI command

```ts
import { createMessage, encrypt, enums, readKey } from 'openpgp'
import { ethers } from 'ethers'

export async function encryptRouteCommand(
  wallet: ethers.Wallet,
  command: Record<string, unknown>,
  routePublicKeyArmored: string,
): Promise<string> {
  const message = JSON.stringify(command)
  const signMessage = await wallet.signMessage(message)
  const literal = Buffer.from(JSON.stringify({ message, signMessage })).toString('base64')
  const pgpMsg = await createMessage({ text: literal })
  const encryptionKeys = await readKey({ armoredKey: routePublicKeyArmored })
  return encrypt({
    message: pgpMsg,
    encryptionKeys,
    config: { preferredCompressionAlgorithm: enums.compression.zlib },
  })
}

export async function wrapArmorToMailboxWork(
  innerArmor: string,
  mailboxRoutePublicKeyArmored: string,
  work?: { NoPush?: boolean },
): Promise<string> {
  const payload: { data: string; NoPush?: boolean } = { data: innerArmor }
  if (work?.NoPush) payload.NoPush = true
  const pgpMsg = await createMessage({ text: JSON.stringify(payload) })
  const encryptionKeys = await readKey({ armoredKey: mailboxRoutePublicKeyArmored })
  return encrypt({
    message: pgpMsg,
    encryptionKeys,
    config: { preferredCompressionAlgorithm: enums.compression.zlib },
  })
}

export async function postArmor(
  domain: string,
  armored: string,
  opts?: { https?: boolean; acceptSse?: boolean; signal?: AbortSignal },
): Promise<Response> {
  return fetch(postUrl(domain, opts?.https !== false), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json;charset=UTF-8',
      ...(opts?.acceptSse ? { Accept: 'text/event-stream' } : {}),
    },
    body: JSON.stringify({ data: armored }),
    signal: opts?.signal,
    cache: 'no-store',
  })
}
```

### Chat mailbox listen (`listenKind: "chat"`)

```ts
export async function openChatListen(opts: {
  wallet: ethers.Wallet
  ownRoutePublicKeyArmored: string
  mailboxDomain: string
  entryDomain: string
  signal?: AbortSignal
}): Promise<Response> {
  if (opts.entryDomain === opts.mailboxDomain) {
    throw new Error('entry C must not be mailbox B')
  }
  const Securitykey = Buffer.from(crypto.getRandomValues(new Uint8Array(16))).toString('base64')
  const armored = await encryptRouteCommand(
    opts.wallet,
    {
      command: 'mining',
      listenKind: 'chat',
      walletAddress: opts.wallet.address,
      algorithm: 'aes-256-cbc',
      Securitykey,
    },
    opts.ownRoutePublicKeyArmored,
  )
  const res = await postArmor(opts.entryDomain, armored, { acceptSse: true, signal: opts.signal })
  if (!res.ok || !res.body) throw new Error(`listen HTTP ${res.status}`)
  return res
}
```

### Dedicated Mailbox B listen (`mailbox_listen`)

Use this command for new multi-device Chat clients. `instanceId` is an opaque
per-device/session value; it must not contain an address, route key, or private
material.

```ts
export async function openMailboxListen(opts: {
  wallet: ethers.Wallet
  ownRoutePublicKeyArmored: string
  mailboxDomain: string
  entryDomain: string
  instanceId: string
  signal?: AbortSignal
}): Promise<Response> {
  if (opts.entryDomain === opts.mailboxDomain) {
    throw new Error('entry C must not be mailbox B')
  }
  const armored = await encryptRouteCommand(
    opts.wallet,
    {
      command: 'mailbox_listen',
      walletAddress: opts.wallet.address,
      instanceId: opts.instanceId,
      timestamp: Math.floor(Date.now() / 1000),
    },
    opts.ownRoutePublicKeyArmored,
  )
  const res = await postArmor(opts.entryDomain, armored, {
    acceptSse: true,
    signal: opts.signal,
  })
  if (!res.ok || !res.body) throw new Error(`mailbox listen HTTP ${res.status}`)
  return res
}
```

B persists each inbound armor before attempting live delivery. If the same
wallet has three healthy `mailbox_listen` sessions, B attempts delivery to all
three; an individual write failure does not cancel the other attempts. Clients
must still deduplicate by their application `sendId`.

Read `res.body` as a byte stream. First frames are often a handshake or mining-shaped `{ status, epoch, … }` liveness listing. Those are **not** user-PGP business messages. A browser console line `[Gossip] Unknown format: {status, epoch…}` or a Worker `heartbeat` log is that listing. It proves the SSE is alive. It does **not** prove B forwarded user-PGP armor on that socket.

Do **not** skip the first SSE frame unconditionally. Handshake and listing frames must be classified as liveness; a following `{ data: "<PGP armor>" }` (including an offline flush on reconnect) is business and must be decrypted. B stores inbound armor first (`saveLocal`), then best-effort SSE. On every durable chat save without `NoPush` / `skipPush`, B enqueues native push if the recipient has a registered `pushDevice` (SSE online or offline); Beamio API no-ops when none. Keep the SSE open; reconnect on idle / drop with another random **C ≠ B**. Production clients use a `setTimeout` chain, not `setInterval`.

Client listen contract (chat-sdk / SilentPassUI `gossip-core.ts`):

| Rule | Why |
| --- | --- |
| Start the ~12s `connect_timeout` **after** `fetch` is issued | OpenPGP wrap can consume the budget; the abort then looks like “C never answered” |
| Emit `listening` only after `res.ok` **and** a readable `res.body` | HTTP 404 / empty body is a failed hop, not a live mailbox SSE |
| On `connect_timeout` / `Failed to fetch`, exclude that `node.domain` from the next C pick | One bad C should not be retried first |
| Do not let `history.load` starve the listen loop on a single Worker thread | Recover can run before `activeClient` exists |

A peel-success log `forward <ip>` is the **client source IP**, not mailbox B. If C peels then throws on hop-sign, switching C does not help until every peeler returns UTF-8 armor. See [Peel, hop-sig, and listen timeouts](peel-hop-listen.md).

### Presence query

```ts
export async function queryMailboxOnline(opts: {
  wallet: ethers.Wallet
  targetWallet: string
  targetRoutePublicKeyArmored: string
  mailboxDomain: string
  entryDomain: string
}): Promise<{ ok: boolean; online: boolean; error?: string }> {
  if (opts.entryDomain === opts.mailboxDomain) {
    throw new Error('entry C must not be mailbox B')
  }
  const armored = await encryptRouteCommand(
    opts.wallet,
    {
      command: 'wallet_online_query',
      walletAddress: opts.wallet.address,
      targetWallet: ethers.getAddress(opts.targetWallet),
      timestamp: Math.floor(Date.now() / 1000),
    },
    opts.targetRoutePublicKeyArmored,
  )
  const res = await postArmor(opts.entryDomain, armored)
  const json = await res.json().catch(() => ({ ok: false, online: false, error: 'parse' }))
  return json
}
```

Treat only `ok === true` as trusted. On timeout or `not_my_route`, **keep** the last trusted `online` value. Do not write chain `routeOnline` into the UI.

### Mailbox delivery ACK

```ts
export function hashPgpArmor(fullArmor: string): string {
  return ethers.keccak256(ethers.toUtf8Bytes(fullArmor))
}

export async function postMailboxDeliveryAck(opts: {
  wallet: ethers.Wallet
  ownRoutePublicKeyArmored: string
  mailboxDomain: string
  entryDomain: string
  armorHash: string
  sendId?: string
}): Promise<boolean> {
  const armored = await encryptRouteCommand(
    opts.wallet,
    {
      command: 'gossip_delivery_ack',
      walletAddress: opts.wallet.address,
      armorHash: opts.armorHash,
      timestamp: Math.floor(Date.now() / 1000),
      ...(opts.sendId ? { sendId: opts.sendId } : {}),
    },
    opts.ownRoutePublicKeyArmored,
  )
  const res = await postArmor(opts.entryDomain, armored)
  return res.ok
}
```

`armorHash` is `keccak256` of the **complete** inbound PGP armor string, `0x` + 64 hex.

## Sample: post opaque user-PGP armor

```ts
export async function encryptUserPayload(
  plaintextUtf8: string,
  recipientUserPublicKeyArmored: string,
): Promise<string> {
  const pgpMsg = await createMessage({
    text: Buffer.from(plaintextUtf8, 'utf8').toString('base64'),
  })
  const encryptionKeys = await readKey({ armoredKey: recipientUserPublicKeyArmored })
  return encrypt({
    message: pgpMsg,
    encryptionKeys,
    config: { preferredCompressionAlgorithm: enums.compression.zlib },
  })
}

export async function postUserArmorToEntries(
  armored: string,
  entryDomains: string[],
  mailboxDomain: string,
): Promise<boolean> {
  const targets = entryDomains.filter((d) => d && d !== mailboxDomain).slice(0, 4)
  const results = await Promise.all(
    targets.map(async (domain) => {
      try {
        const res = await postArmor(domain, armored)
        return res.ok
      } catch {
        return false
      }
    }),
  )
  return results.some(Boolean)
}
```

Chat wraps an EIP-191 envelope **before** this encrypt step. See the [CoNET Chat developer guide](chat-developer-guide.md).

## Optional outer wrap (one extra hop)

To hide the inner user-PGP key ID from the first `/post` observer, encrypt the **already-built** user-PGP armor to an **entry** route public key, then POST that outer armor to that same entry. SI decrypts once and forwards the inner armor if the inner key is not local. Do not wrap so the inner key is again this node. Do not build a hop chain longer than SI will accept (cap **3** SI-to-SI signatures).

## Dependencies

```json
{
  "dependencies": {
    "ethers": "^6.13.0",
    "openpgp": "^5.11.0"
  }
}
```

Node samples above use `Buffer`. In browsers use `btoa` / `atob` or a UTF-8 helper. Run OpenPGP encrypt/decrypt **off the UI thread** (Web Worker) if the page must stay responsive.

## Checklist

- [ ] POST body is `{ data: <armor> }` to `{domain}.conet.network/post`
- [ ] Business encrypt-to **user PGP**; commands encrypt-to **route PGP**
- [ ] Chat listen includes `listenKind: "chat"` and uses **C ≠ B**
- [ ] `connect_timeout` starts after `fetch`; `listening` requires `res.ok` + body
- [ ] SI hop-sign uses a UTF-8 armor string (peel plaintext / `pgpArmorToUtf8String`); hop-sign or C→B failure is a fast 404
- [ ] Send / ACK / presence / UDP / application stream offers do not default-dial mailbox B
- [ ] EIP-191 `signMessage` covers the exact `message` string SI will verify
- [ ] Application stream keys / UDP `Securitykey` never appear on a B-decryptable listen or relay
- [ ] Failures do not log private keys, full PGP private armor, or `Securitykey`
- [ ] HTTP 200 / SSE Connected is not treated as application delivery
- [ ] Presence uses `wallet_online_query`, not `searchKey.routeOnline`

## Related

- [L0 development](../developers/l0.md)
- [How to use Layer Minus](using-l0.md)
- [CoNET Chat developer guide](chat-developer-guide.md)
- [Zero-trust mailbox routing](mailbox-routing.md)
- [Peel, hop-sig, and listen timeouts](peel-hop-listen.md)
- [X-CoNET-Hop-Sigs v1](hop-sigs.md)
- [Wallet-addressed peer identity](wallet-address-p2p.md)
- [HTTP transport](http-mimicry.md)
- [UDP frame forwarding](udp-forward.md)
- [Persistent application streams](duplex-forward.md) — portable application semantics over L0 attachment primitives
- [Security limits](security-limits.md)
- [CoNET Chat product page](../applications/depin-chat.md)
- [Resources](../resources.md)

## Long-connection transport lifecycle

For a persistent application byte stream, keep the mailbox listen SSE and the attached
`l0_connect` TCP as separate objects. A client may use a temporary listen
wallet/PGP identity for one attachment. Any `pipeHandle` is a random,
hop-local opaque value; it must not be derived from an EOA, port, IP, or route
key, and SI must not correlate it with another hop.

SI does not emit a same-name teardown event on the SSE. The only application
of `l0_pipe_end` is a control line on the occupied TCP that already owns the
handle:

```json
{
  "type": "l0_pipe_end",
  "pipeHandle": "<64 lowercase hex>",
  "reason": "transport_closed"
}
```

The fields `wallet`, `connector`, `sessionId`, and `session_id` are forbidden.
If an entry detects that a downstream SSE is gone before keep-alive is
committed, it returns a transport error such as `410 Gone`. Once keep-alive is
committed, it closes the corresponding TCP with FIN/RST. The sender stops
writing bytes and starts a bounded, backoff-controlled new attachment.
Neither the transport error nor the opaque handle is a user-visible gossip
message.
