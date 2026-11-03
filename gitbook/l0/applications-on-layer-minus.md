# Applications on Layer Minus

This page lists the applications built on [Layer Minus](layer-minus.md) and
which parts of the protocol each one uses. Layer Minus forwards encrypted
envelopes between wallet-addressed roles; an application adds its own signed
objects on top and does not add plaintext fields to the `/post` contract.

Maturity labels follow the [Applications](../applications/README.md) index.
A row here describes how an application uses Layer Minus, not that every part
is deployed; each linked page states what is live.

## Parts of Layer Minus

| Part | What it provides | Specified in |
|---|---|---|
| Wallet identity and AddressPGP | A wallet's user PGP key (business encryption) and route key (mailbox and commands), recorded on CoNET L1 | [Wallet-addressed peer identity](wallet-address-p2p.md) |
| `POST /post` carrier | HTTP or HTTPS to an entry with a body of only `{ "data": "<armor>" }`; SI to SI over HTTP on port 80 | [HTTP transport](http-mimicry.md) |
| Key-ID routing, peel and forward | Nodes route by the OpenPGP recipient key ID and decrypt only a layer addressed to them | [Zero-trust mailbox routing](mailbox-routing.md) |
| Entry A / C, mailbox B | A accepts a send, C carries a listen or command, B stores ciphertext for its wallets; `A ≠ B`, `C ≠ B` | [Node and client roles](node-roles.md) |
| Mailbox store and listen pools | Store before delivery, fan-out to every listen session, ACK, presence, separate pools per listen namespace | [Zero-trust mailbox routing](mailbox-routing.md) |
| Route-key commands | Commands encrypted to a node's route key and executed by that node | [SI developer guide](si-developer-guide.md) |
| SI egress | Wallet-authorized commands that open an ordinary `host:port` connection | [SI developer guide](si-developer-guide.md) |
| Guardian node table | `GuardianNodesInfoV6` on CoNET L1 lists the nodes clients choose from | [Node and client roles](node-roles.md) |
| Hop signatures and GB metering | SI-to-SI hops carry hop signatures; forwarded bytes are metered for GB | [X-CoNET-Hop-Sigs v1](hop-sigs.md) |

## Which application uses which part

| Application | Maturity | Wallet + AddressPGP | `/post` + key-ID routing | Entry / mailbox roles | Mailbox store and listen | Route-key commands | Other |
|---|---|---|---|---|---|---|---|
| [CoNET Chat](../applications/depin-chat.md) | Implemented capability | Yes | Yes | A, C, B | `mailbox_listen`, ACK, presence | Mailbox work, push registration, call offers | Voice relay sessions (`voice_listen`); node table |
| [Beamio](../applications/beamio.md) | Production reference | Yes | Yes | Through CoNET Chat | Through CoNET Chat | Through CoNET Chat | POS authorization and commerce message types |
| [SilentPass](../applications/silentpass-vpn.md) | Production reference | Wallet signs access commands; control data encrypted to the egress | Yes | Entry distinct from the egress | No | Egress commands | SI egress to ordinary TCP destinations |
| [UDP frame forwarding](udp-forward.md) | Implemented in CoNET-SI | Yes | Yes | A, C, D, B | UDP client and server pools | `udp_listen`, `udp_relay`, `udp_uplink` | AES frames; subscription as a user-PGP message |
| [`web3://` applications](../applications/web3-url.md) | Under development | Yes | Yes | Entry and mailbox delivery | Yes | No new SI command | Signed requests and correlated encrypted responses |
| [Web3 Browser + Wallet](../applications/web3-browser.md) | Under development | Yes | Yes | Through `web3://` | Through `web3://` | Through `web3://` | May also run an SI subset (entry, forward, storage) |
| [Privacy-first Decentralized AI](../applications/privacy-first-ai.md) | Design study | Proposed | Proposed | Proposed | — | — | Private paths with `web3://` |
| [DePIN DCDN / BT](../applications/bt-dcdn.md) | Under development | Proposed | Proposed | Entries in front of seeders | — | — | Bulk content; discovery not decided |

## Application notes

### CoNET Chat

The messaging and calling application. Every node it uses is a Guardian node
running CoNET-SI as an entry, a mailbox or a voice relay; Chat runs no servers
of its own. It adds EIP-191 signed envelopes with the recovered-signer
identity rule, dual receipts, group fan-out, call signalling through the
mailboxes, payer-signed voice channels, a client daemon, and
encrypted history on IPFS. Part-by-part mapping:
[Layer Minus — CoNET Chat](layer-minus.md#conet-chat). Full design:
[CoNET Chat whitepaper](../applications/depin-chat-whitepaper.md).

### Beamio

Beamio's Consumer PWA, Merchant OS and POS terminal use CoNET Chat for
messages and for POS terminal authorization (`beamio_pos_terminal_permission_v1`
to the merchant's mailbox), so their Layer Minus use is Chat's. See
[POS terminal](../applications/beamio/pos.md).

### SilentPass

A client signs an access command with its wallet, encrypts it to the selected
egress, and posts it through an entry that is not that egress. The egress
checks admission and opens an ordinary TCP connection to the destination.
SilentPass does not use mailbox delivery. See
[SilentPass](../applications/silentpass-vpn.md).

### UDP frame forwarding

Two wallets exchange AES-256-GCM frames through mailbox B. The AES key travels
once, inside a `udp_subscribe` encrypted to the UDP server's user PGP key;
every later frame and listen is a route-key command to B through an entry that
is not B. See [UDP frame forwarding](udp-forward.md).

### `web3://` and the Web3 Browser

`web3://` names an application by wallet and port and carries signed requests
and correlated encrypted responses over Layer Minus entry routing and mailbox
delivery. It is an application protocol, not a new SI command family. The
Web3 Browser opens `web3://` applications and can also run part of an SI. See
[`web3://`](../applications/web3-url.md) and the
[protocol contract](web3-application-protocol.md).

### Design studies and planned work

Privacy-first Decentralized AI and DePIN DCDN / BT describe how they would use
Layer Minus routing; neither is a deployed Layer Minus application. See their
pages for status.

## What no application may do

- Add plaintext fields (wallet, tag, flags) next to `data` in `/post`.
- Connect directly to a mailbox B for application traffic. Only the
  infrastructure mining collectors do that.
- Encrypt business content to a node's route key instead of the recipient's
  user key.
- Treat an entry's HTTP 200 as delivery.

See [Security limits and threat grades](security-limits.md).
