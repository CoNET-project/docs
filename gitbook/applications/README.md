# Applications

CoNET applications combine infrastructure and protocol capabilities into
user-facing behavior. They are not additional network layers.

- **L0** supplies decentralized forwarding, ciphertext storage, hosting,
  compute, and metering resources.
- **Layer Minus**, built on L0, supplies wallet/OpenPGP-addressed privacy
  routing.
- **CoNET L1** supplies public identity, contracts, accounts, assets, and
  settlement.
- **DLE L2** specifies specialized parallel application ledgers.
- **Applications** define their own schemas, authorization, storage,
  verification, recovery, and user experience.

## Maturity labels

| Label | Meaning |
|---|---|
| **Production reference** | A live endpoint, contract, or public application entry exists |
| **Implemented capability** | Present in source or integrated into a product, but not necessarily enabled everywhere |
| **Under development** | Documented and partially implemented, without a complete production release |
| **Normative design** | Controlled by a protocol specification; production deployment is separate |
| **Design study** | Non-normative architecture or economic proposal; not a shipped application |

Maturity is not an audit, uptime, or anonymity guarantee.

## Choose an application

| Application | Product role | Maturity | Start here |
|---|---|---|---|
| **`web3://` wallet-addressed applications** | Cross-platform application protocol using Layer Minus on L0 | Under development | [`web3://`](web3-url.md) |
| **Web3 Browser + Wallet** | Native shell + local PWA: browse/publish `web3://`, SI subset, L2 on-demand | Under development | [Web3 Browser](web3-browser.md) |
| **SilentPass** | Wallet-authorized privacy access to ordinary Internet services | Production reference | [SilentPass](silentpass-vpn.md) |
| **Beamio** | Consumer wallet, Merchant OS (including website lookup onboarding), POS, Cash and USDC, merchant-card custody handoff (normative) | Production reference | [Beamio](beamio.md) |
| **CoNET Chat** | Relationship-private messaging and real-time voice: sender wallet inside recipient-only ciphertext, Layer Minus IP/route separation, encrypted history, and opaque voice relay sessions | Implemented capability | [CoNET Chat](depin-chat.md) |
| **Privacy-first Decentralized AI** | Three independent roles and one open intelligence economy: private paths plus candidate micropayments (not a live AI fee rail) | Design study | [Landing](privacy-first-ai.md) · [Whitepaper](privacy-first-ai-whitepaper.md) |
| **Institutional multisig AA** | Team-controlled Smart Wallet with on-chain tasks and threshold votes | Implemented capability | [Institutional multisig AA](institutional-multisig-aa.md) |
| **Miner-matched order-book exchange** | Proposed non-custodial ERC-20 order book | Design study | [Miner-matched exchange](miner-orderbook-dex.md) |
| **DePIN DCDN / BT** | Planned encrypted bulk-content distribution | Under development | [DePIN DCDN / BT](bt-dcdn.md) |

The [`web3://` application page](web3-url.md) is the canonical cross-platform
entry. `conet-l0d` is documented under Developers as its Linux runtime, not as
a second application or protocol.

## Protocol dependencies

| Dependency | Application use |
|---|---|
| **L0** | Decentralized forwarding, ciphertext storage, hosting, compute, and GB-metered resources |
| **Layer Minus** | OpenPGP key-ID routing, entry forwarding, mailbox receive, and encrypted sessions over L0 |
| **L1 / CoNET** | AddressPGP, account and asset state, application registries, and history pointers |
| **L2 / CoNET-DLE** | Prospective multi-party and high-frequency accounting designs; not a production dependency today |
| **Application services** | Relaying, indexing, metadata, local encrypted storage, and UI coordination where these are not protocol functions |

**Design study** (non-normative and not a shipped application):
[Privacy-first Decentralized AI](privacy-first-ai.md) is the landing digest.
The [whitepaper](privacy-first-ai-whitepaper.md) explains why models, data,
and agents can stay independent: Layer Minus and `web3://` reduce the need
for one network intermediary to observe the complete user–service
relationship, **conditional** on operator and identifier separation;
CoNET-DLE is designed so each measurable contribution can be paid without
one party owning the stack. AI event classes are proposed, not frozen
DLE tip classes. The one-basis-point protocol-value fee is a target for
specified value movement, not a universal all-in fee for every AI task.
Privacy-preserving settlement is a **design
requirement**, not an automatic property of wallet payments or DLE.
Prediction is not intervention: the closed loop is more severe when the
same actor that predicts also controls ranking, price, recommendation,
or agent action. The paper defines
contestable intelligence (independently sourced data, contestable model
supply, user-controlled agents, and an operational evaluation matrix), a
threat model, governance, and a staged research roadmap. Figure 1 states the
layer split: L0 private coordination; L1 identity, assets, and final
settlement; DLE candidate event ledger; limited agent authority; and
identifier separation. It does not claim a live AI product.

An application can depend on several layers without becoming a new layer.

## Product boundaries

- Chat, SilentPass, mining, UDP, and `web3://` are application compositions
  using Layer Minus over L0 resources.
- SilentPass is privacy egress to an ordinary Internet destination. It is not
  a `web3://` application host and not an L1 consensus path.
- `web3://` names an application by wallet identity and returns an
  encrypted, request-correlated application response or a persistent
  stream. Layer Minus routing additionally depends on OpenPGP identity
  and mailbox-route bindings; an exact `@BeamioTag` may be an alias.
  v1 components are implemented; complete cross-platform handling and
  general public hosting remain under development.
- CoNET-DLE specifications and its lab explorer do not imply a launched
  production L2.

## Trust boundary

- Wallet addressing is pseudonymous, not automatically anonymous.
- Intermediate encryption does not remove endpoint trust.
- Availability is separate from confidentiality.
- Entry, mailbox, RPC, relayer, and application failures must not be converted
  into successful empty data.
- Product maturity does not imply independent security certification.

## Related

- [L0 decentralized cloud](../l0/README.md)
- [Layer Minus](../l0/layer-minus.md)
- [How to use Layer Minus](../l0/using-l0.md)
- [`web3://` Application Protocol contract](../l0/web3-application-protocol.md)
- [Developers](../developers/README.md)
- [Resources](../resources.md)
