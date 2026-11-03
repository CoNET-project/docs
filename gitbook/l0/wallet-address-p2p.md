# Wallet-addressed peer identity

## What it is

Layer Minus names a peer with an **EOA wallet address** and OpenPGP keys registered for that address. The wallet is the durable protocol identity. IP addresses remain transient connection locators used by the [TCP/IP underlay](tcp-ip.md).

Three key roles must remain distinct:

| Material | Controlled by | Used for |
| --- | --- | --- |
| EOA private key | User or client | EIP-191 authentication of registration, messages, and control commands |
| User OpenPGP key | Recipient | End-to-end encryption of business messages for that recipient |
| Route OpenPGP key | Mailbox node B | Encryption of commands that B must read, such as listen, presence, acknowledgement, and UDP relay control |

A symmetric session key may protect high-volume application frames, but it is not a replacement for either OpenPGP role.

## Why it matters

A wallet identity can remain stable while a device roams between networks, an entry changes, or a user selects a different mailbox. Senders can authenticate envelopes without treating an IP address or DNS name as the recipient's identity.

The separation also limits which actor can decrypt which object:

- only the recipient's user key should decrypt a business payload;
- only mailbox B's route key should decrypt a command intended for B; and
- intermediate entries route ciphertext without receiving either private key.

## Registration and resolution

AddressPGP on CoNET L1 stores the public bindings used by Layer Minus. A typical registration flow is:

1. Generate the user's OpenPGP key pair on the client.
2. Select the encryption subkey ID used for routing encrypted business envelopes.
3. Select a mailbox route and obtain its route key ID.
4. Sign the request with the wallet (EIP-191 over the fields, a millisecond timestamp and a single-use nonce) and submit it to the register API named `regiestChatRoute`. Unsigned requests, requests signed by another wallet, stale timestamps and replays are refused. Format: [SI developer guide](si-developer-guide.md#sample-register-a-mailbox-route).
5. Resolve the wallet with `searchKey(walletAddress)` before sending or listening.

A client registers only when a **successful** read of its own record shows no record, a recorded key that differs from the local key, or no mailbox. A failed or timed-out read is retried; it never triggers registration, a new mailbox or a new key. A registration keeps the existing mailbox (on chain, else the one the device uses); only a new wallet with no mailbox anywhere gets a random one. Changing the mailbox is a deliberate choice, not a recovery step.

Usable EOA and OpenPGP private keys must remain client-controlled. Public lookup returns the recipient key and mailbox route material needed by other peers.

```text
wallet address
  ├─ user PGP key ID ───── business-message recipient
  ├─ user public key ───── business-message encryption
  └─ route key ID ──────── selected mailbox B
```

Current CoNET Chat and POS-permission traffic often use **one** EOA for AddressPGP, listen, and envelope `from`. That is the simple default. It is **not** required.

Human-readable tags are an application lookup aid, not the protocol identity. When an application resolves `@BeamioTag`, it must select an exact account match or use an explicit wallet hint. Prefix-search `results[0]` is not authoritative.

## Routing wallet versus sender / recipient wallets

L0 forwards by **OpenPGP key ID** and authenticates SI commands with whatever EOA signed `walletAddress`. An application **may use different EOAs** for network routing and for the people in the product.

| Wallet | What it does | Who sees it |
| --- | --- | --- |
| **Routing wallet** | AddressPGP mailbox row; listen / ACK / presence `walletAddress`; last-hop **GB** meter | Mailbox B, hop-sig GB accounting, `wallet_online_query` |
| **Sender wallet** | Chat / business envelope `from` and the EIP-191 that binds that body | Recipient after decrypt; **not** required on the hop header |
| **Recipient wallet** | Product identity of the inbox owner (display, payments, POS) | Application layer; may differ from the routing EOA |

```text
App identity (sender / recipient EOA)
  └─ signs and names the business envelope

Routing wallet (separate EOA)
  ├─ AddressPGP: inbox user PGP + mailbox B
  ├─ listen / ACK / presence (route-PGP commands)
  └─ GB credit on the last signed command hop
```

**Why split:** mailbox B, entry metadata, and hop GB see the **routing** EOA. They do not need the user’s payment, social, or display wallet. Changing C or rotating the routing wallet does not force a new product identity.

**How to wire it:**

1. Create a routing EOA. Generate the **inbox** user PGP on the client. Register AddressPGP (`regiestChatRoute`, signed by the routing wallet) **on the routing wallet**.
2. Listen, `gossip_delivery_ack`, and `wallet_online_query` sign with the **routing** wallet. `isMyRoute` is that EOA.
3. Encrypt business armor to the **inbox user PGP** registered on the routing wallet (that key ID is what SI routes).
4. Put the **sender / recipient** EOAs only inside the encrypted application object (`from`, display id, payment id).
5. Keep the mapping **routing EOA ↔ app EOA** in the client. Do not write both onto `X-CoNET-Hop-Sigs`.

**What this does not hide:** funding the routing wallet from a master wallet on L1 still links them on-chain. Putting both addresses in the same **plaintext** command, log, or hop header undoes the split. L0 will not invent stealth addresses or ZK membership. See [security limits](security-limits.md).

## Guarantees and non-guarantees

With valid registrations and protected private keys, the protocol can:

- bind signed data to an EOA;
- discover public encryption and route material by wallet;
- route an OpenPGP envelope by recipient **key ID** without exposing its plaintext to an entry — the key ID is an intentional packet side channel used to look up mailbox B;
- let the entry forward that ciphertext over HTTP and earn **GB** for the relay; and
- change the selected mailbox without changing the wallet identity.

Registration does not prove civil identity, current liveness, message delivery, or control of a device after its keys are compromised. It also does not hide traffic timing, ciphertext size, or the client IP from the entry it contacts.

A wallet is more autonomous than an IP and is **not** automatically harder to correlate. Reusing one EOA for Chat, POS, payments, mining, Treasury, and public social identity creates a join key. Compromise of the long-term user OpenPGP private key can decrypt stored historical armor (no Double Ratchet / MLS in the live plane). Applications that need unlinkable planes should register **separate wallets** and keep delegation off the public envelope. See [security limits](security-limits.md).

Misusing the key roles breaks the security boundary:

- encrypting business content to B's route key allows B to decrypt it;
- encrypting a mailbox command to the user's key prevents B from processing it; and
- putting a UDP symmetric key in a route-key command reveals it to B.

## Implementation anchors

- AddressPGP: [`0x684b0ac760cEE9c9b85de36d69746420648Cf9e2`](https://mainnet.conet.network/address/0x684b0ac760cEE9c9b85de36d69746420648Cf9e2)
- Client registration and lookup: [SilentPassUI `cashtree` `chat.ts`](https://github.com/CoNET-project/SilentPassUI/blob/cashtree/src/services/chat.ts), [SilentPassUI `cashtrees` `chat.ts`](https://github.com/CoNET-project/SilentPassUI/blob/cashtrees/src/services/chat.ts)
- POS sender registration: live POS PWA; no standalone public repository identified
- SI route resolution: [CoNET-SI `getRoute.ts`](https://github.com/CoNET-project/CoNET-SI)

## Next

[How to use Layer Minus](using-l0.md) shows how applications combine these keys. [Zero-trust mailbox routing](mailbox-routing.md) defines the `S → A → B` send path and the `R → C → B → R` listen path.
