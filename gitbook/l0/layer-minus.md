# Layer Minus — Wallet/OpenPGP Privacy Routing

**Maturity: Implemented capability.** Wallet/OpenPGP routing, entry
forwarding, mailbox delivery, encrypted listen controls, receipts, presence,
UDP-shaped frame relay have implementations (the early persistent-stream L0
attachments were removed from SI on 2026-10-31).
Availability, route diversity, and product coverage remain
deployment-specific.

Layer Minus is CoNET's privacy-routing protocol built on the
[L0 decentralized cloud](README.md). It lets an application name and
authenticate peers with wallet-linked cryptographic identity while ordinary
TCP/IP remains the connection underlay.

## Why it exists

A stable public origin reveals a durable network location and gives one
intermediary a privileged view of the user-to-service relationship. Layer
Minus separates:

- the wallet that owns or signs an application identity;
- the OpenPGP key that receives business ciphertext;
- the route key that identifies a mailbox or service node;
- the entry that accepts the current client connection; and
- the mailbox, egress, or application host that performs the destination
  role.

This can reduce fixed-origin exposure and the amount of relationship
information one intermediary needs. It does not remove IP from packet
delivery or prove that role operators are independent.

For CoNET Chat, that separation is used to break three direct associations:

- the sender wallet is inside the recipient-user-PGP business envelope rather
  than a plaintext transport field;
- message content remains ciphertext to entries and mailboxes; and
- entries observe client IP connections while mailboxes observe wallet routes
  through those entries, rather than receiving the client connection
  directly.

Only the recipient learns the sender wallet after decrypting and verifying the
application envelope. This is a relationship-privacy design, not a claim that
IP metadata vanishes: A/C still see their connecting IP, and colluding roles
or a global observer can correlate observations.

## Identity and routing

A wallet route uses three distinct inputs:

| Input | Purpose |
|---|---|
| **EOA wallet** | Ownership and EIP-191 application signatures |
| **User OpenPGP key** | Recipient-specific business-message encryption |
| **Route OpenPGP key** | Mailbox and control-command routing |

AddressPGP on CoNET L1 records the wallet's user-key and route-key bindings.
Intermediate nodes inspect the OpenPGP recipient key ID needed for routing;
they must not receive user private keys or business plaintext.

## A/B/C mailbox path

```text
Send
  sender S
    → encrypt business envelope to recipient R user PGP
    → POST { "data" } to entry A
    → A forwards ciphertext to mailbox B

Receive
  recipient R
    → encrypt listen command to mailbox B route PGP
    → open SSE through entry C
    → C forwards the encrypted control to B
    → B returns stored and live ciphertext
    → R decrypts and verifies locally
```

For application mailbox traffic, **A is not B and C is not B**. A client must
not make mailbox B its direct HTTP target. This role separation hides the
client's direct network connection from B, subject to operator separation,
route diversity, identifier discipline, and the absence of collusion.

Infrastructure mining collectors are a deliberate exception: they directly
listen to each target SI for that node's signed mining gossip. That path must
not be copied into Chat, mailbox acknowledgement, presence, or UDP clients.

Normative details: [Zero-trust mailbox routing](mailbox-routing.md).

## HTTP-shaped carrier

- Client to entry: HTTP or HTTPS `POST /post`.
- SI to SI: HTTP on port 80.
- HTTP JSON shape: only `{ "data": "<OpenPGP armor>" }`.
- Mailbox instructions such as `NoPush` belong inside work encrypted to
  mailbox B's route PGP, never as clear sibling HTTP fields.

The payload is already recipient-encrypted. HTTP-shaped transport avoids
requiring a distinctive custom carrier and can remain usable where a custom
protocol or TLS handshake is classified or blocked. Browser mixed-content
rules can still require HTTPS.

This is traffic obfuscation with explicit limits. Packet size, timing,
connection behavior, SSE longevity, IP endpoints, TLS fingerprints where
used, and active probing may remain observable. Layer Minus does not claim
perfect imitation of ordinary browsing.

See [HTTP transport and Fetch-and-Close](http-mimicry.md).

## Zero-trust boundary

| Role | Needs to know | Must not know |
|---|---|---|
| **Entry A/C** | Connecting peer, ciphertext, timing, size, next route | Business plaintext, recipient private key |
| **Mailbox B** | Route ownership, ciphertext, listen state, ACK hashes | User-PGP business plaintext, user private key |
| **Application host or egress** | The application request it is authorized to serve | Unrelated wallet secrets or other sessions |
| **Client** | Its keys, intended recipient, verified response | Other participants' private keys |

Any role can drop, delay, replay, correlate, or misroute traffic. Applications
therefore need signatures, deadlines, replay protection, acknowledgements,
trusted-result handling, and local verification.

## What applications add

Layer Minus forwards encrypted envelopes. It does not define every object's
business meaning.

| Composition | Application-layer contract |
|---|---|
| **CoNET Chat** | Signed messages, `listenKind: "chat"`, mailbox ACK, sender receipt, presence, encrypted-history recovery |
| **SilentPass** | Wallet-authorized egress command and ordinary destination TCP connection |
| **`web3://`** | Locator, exact identity resolution, signed request, correlated encrypted response, stream lifecycle, rendering security |
| **Beamio** | POS authorization and commerce message types |
| **UDP forwarding** | End-to-end AES session and UDP-shaped frame semantics; mailbox only relays ciphertext |

`web3://` is an application protocol, not a new Layer Minus command.
Product envelopes can evolve without changing the HTTP `/post` contract.

## Guarantees and non-guarantees

When clients use the correct encryption targets and the A/B/C path:

- forwarding nodes do not need business plaintext;
- mailbox B sees an entry rather than the recipient's direct connection;
- a wallet-linked route can survive changes in transient IP location; and
- applications can replace entry or service resources without changing the
  durable wallet identity.

Layer Minus does **not** guarantee:

- absolute anonymity, untraceability, or unblockability;
- operator independence merely because roles have different letters;
- confidentiality after endpoint compromise;
- delivery merely because an entry returned HTTP 200;
- forward secrecy from long-lived OpenPGP alone;
- disappearance of timing, volume, and wallet-correlation metadata; or
- that every L0 resource or application uses fragmentation.

See [Security limits and threat grades](security-limits.md).

## Continue

1. [How to use Layer Minus](using-l0.md)
2. [The TCP/IP substrate](tcp-ip.md)
3. [Wallet-addressed peer identity](wallet-address-p2p.md)
4. [Zero-trust mailbox routing](mailbox-routing.md)
5. [HTTP transport and Fetch-and-Close](http-mimicry.md)
6. [Persistent application streams](duplex-forward.md) (historical; L0 attachments removed)
7. [`web3://` wallet-addressed applications](../applications/web3-url.md)
8. [L0 development](../developers/l0.md)
