# Beamio

**Maturity: Production reference.** Consumer, Merchant OS, and POS entry
points are public. This page is the **Beamio product whitepaper**: what the
suite is, which surfaces exist today, and how cash rails are placed. It is not
a claim that every workflow is complete, independently audited, or covered
by a published SLA.

Revision: **2026-09-16**.

Public site: [https://gitbook.conet.network/applications/beamio.html](https://gitbook.conet.network/applications/beamio.html)

Chapters in this whitepaper:

| Chapter | What it covers |
| --- | --- |
| [Consumer PWA](beamio/consumer.md) | Wallet, Discover (Top Up + Gifting), coupons, Chat, mining tools, and how users add USDC |
| [Merchant OS](beamio/merchant-os.md) | Onboarding (website, marketplace seller page, business name, or attached PDF/Word/image lookup fills the cover; marketplace platform chrome is excluded from merchant fields), programs, staff, terminals, catalogs, coupons, and merchant treasury |
| [POS terminal](beamio/pos.md) | In-store charge, physical-card top-up through native Stripe Terminal, membership, claim, and redeem |
| [Cash and USDC](beamio/cash-and-usdc.md) | Distinct deposit rails (Coinbase / Treasury CONET-USDC vs Stripe Onramp Base USDC to EOA) **and** Beamio-initiated USDC transfers / payments (offline sign + sponsored gas) |

Cursor rule: when a Beamio product capability is added or changed, update the matching chapter in the same task (`beamio-gitbook-whitepaper-sync.mdc`).

## Unified merchant-card tier model

Every newly created merchant program card carries one canonical
`tierQualificationMode`, initialized atomically with the complete BeaconProxy tier
schedule: `0` means top-up qualification, `1` means direct membership purchase,
and `2` means charge qualification. Direct membership charges only the configured
fee and does not mint store-credit `#0`; store credit remains distinct from
cross-store Reward PT `#13`. The card metadata mirrors the schedule for
presentation, while the on-chain fee and qualification schedule is authoritative
for purchase and qualification.

## Product role

Beamio is the application suite that combines CoNET L1 wallet and account
state with Layer Minus messaging over L0 resources in three coordinated
products:

| Surface | Product role | Public entry |
| --- | --- | --- |
| **Consumer PWA** | Self-custody wallet, Smart Wallet access, Discover, coupons, messaging, and CoNET-facing account tools | [https://beamio.app/app/](https://beamio.app/app/) |
| **Gift purchase page** | Public merchant-card Gift purchase with third-party wallet or merchant Stripe card payment | [https://beamio.app/gift/<cardAddress>](https://beamio.app/gift/) |
| **Merchant OS** | Merchant program management, staff and terminal administration, settlements, coupons, and catalogs | [https://biz.beamio.app](https://biz.beamio.app) |
| **POS PWA** | In-store charge, top-up, claim, and redeem operations performed by an authorized terminal wallet | [https://pos.conet.network/](https://pos.conet.network/) · [https://beamio.app/pos/](https://beamio.app/pos/) · [https://pos.beamio.app/](https://pos.beamio.app/) |

Beamio is not a fourth protocol tier. It coordinates application state across CoNET L1, Layer Minus, local wallet storage, and gas-relay services.

### Direct-settlement positioning

Beamio is application and protocol infrastructure, not the beneficial owner of
merchant or customer assets and not the commercial counterparty between them.
Customers hold their wallet assets; merchants own their program rules and
their Stripe Connected Account. Beamio can precheck an authorization, route a
transaction, sponsor gas, and coordinate fulfillment without receiving the
user's private key or pooling merchant proceeds in a Beamio balance.

This boundary does not remove disclosed technical service providers. Stripe
remains the payment processor for card payments, and documented Treasury
contracts remain part of supported cross-chain settlement. “Direct” describes
asset ownership and the merchant–customer relationship; it is not a claim that
every network hop or card payment has no processor.

The active POS product is the **POS PWA loaded by native WebView shells**. Retired native iOS and Android POS business interfaces are not the current product implementation.

A related **Alliance** client exists as another Beamio-family surface. It is not a fourth merchant or POS product.

## Public distribution

The Beamio public homepage at [https://beamio.app/](https://beamio.app/) presents the three active application surfaces and their current distribution channels.

| Product | Apple | Google Play | Direct Android package | Web |
| --- | --- | --- | --- | --- |
| **Consumer** | [App Store](https://apps.apple.com/us/app/beamio-smart-local-pass/id6755375110) | [Google Play](https://play.google.com/store/apps/details?id=com.beamio.app) | [Beamio Android APK](https://beamio.app/beamio-android.apk) | [Consumer PWA](https://beamio.app/app/) |
| **POS** | [App Store](https://apps.apple.com/ca/app/beamio-softpos/id6763462151) | [Google Play](https://play.google.com/store/apps/details?id=com.beamio.pos) | [Beamio POS Android APK](https://beamio.app/beamio-softpos.apk) | [POS PWA](https://pos.beamio.app/) |
| **Merchant OS** | Browser application; no native-store package is required | Browser application; no native-store package is required | Not applicable | [Merchant OS](https://biz.beamio.app/) |

The public homepage presents Beamio as a low-friction route into stablecoin
settlement: merchants use the Consumer, POS, and Merchant OS applications
without operating chain infrastructure or asking customers to manage gas.
Merchants link an existing Stripe account, consumers can use Stripe-hosted
Checkout for eligible program top-ups or membership purchases, and authorized
POS terminals can accept a physical card through Stripe Terminal (Tap to Pay
or a compatible external reader). Card credentials remain with Stripe and
only trusted payment status drives program fulfillment.

The homepage presents Reward PT as the shared reward experience: customers may
earn it from Top-up, Charge, referrals, and social engagement; use it toward
the issuing merchant's top-up; or apply eligible Reward PT from participating
programs toward another merchant's top-up. Store Credit remains
merchant-specific, while any uncovered cross-store amount may be paid with
USDC. It also states the direct-settlement boundary above instead of describing
Beamio as a bank, custodian, or payment principal.

The native Consumer and POS packages are WebView shells around their corresponding active PWAs. They provide native integration and Embedded OTA delivery; they do not create a separate native business implementation.

Share and install links on `https://beamio.app/app-download` open **Consumer only**. They never open BeamioPOS. If Consumer is not installed, the landing stays in the browser or the Consumer App Store. POS uses its own custom scheme (`beamiopos://`) and Associated Domains on `pos.beamio.app`.

## Protocol dependencies

| Dependency | Beamio use |
| --- | --- |
| **CoNET L1 (`chainId` 224422)** | Wallet and account state, merchant program state, consumer Smart Wallets, institutional V2 accounts, assets, identity records, and application registries |
| **L0** | Decentralized forwarding, ciphertext storage, hosting, compute, and metering resources |
| **Layer Minus** | CoNET Chat, POS terminal-authorization messages, routed mailbox delivery, and optional UDP frame forwarding over L0 |
| **EOA + `@BeamioTag` identity** | Human-readable discovery anchored to a wallet; the EOA also owns the PGP material used by messaging |
| **Cluster / Master relay** | Prechecks application write requests and submits approved gas-sponsored transactions; it is not the source of a user’s private key. **Every Beamio-started USDC transfer or payment** (CoNET-USDC and Base USDC) is an offline signature on this path — the user wallet does not broadcast `USDC.transfer` or pay ETH / CNET gas. Merchant-card Stripe fulfillment uses an independent `initManager[]` signer pool: Master workers acquire and release idle signers around unsigned queued tasks, separately from settle gas pools |
| **Local application storage** | Holds client state and, depending on the product, self-custody wallet material or session state |
| **Base (`chainId` 8453)** | Treasury and USDC operations, plus supported institutional multisig AA. **Merchant program cards on Base are retired** — do not create, upgrade, Discover, POS-bind, or Cluster-precheck merchant cards via Base RPC. New consumer Smart Wallet issuance is CoNET only. |

**Merchant program cards are CoNET L1 only.** The historical Base UserCard Factory and any Base-deployed merchant cards are archive only; they are not the live program-card chain. Cluster / Master views that read a merchant card (`owner`, `getRedeemStatus`, membership, reward rules, balances) must use CoNET RPC — never Base as the default. New consumer Smart Wallet accounts also belong on CoNET L1. New CoNET merchant cards use a shared UpgradeableBeacon so the platform can upgrade implementation bytecode without changing card addresses. Base remains a separate execution environment for treasury / USDC / institutional multisig. A matching address on two chains does not imply shared balances or shared application state.

## How protocol capability becomes product behavior

### Consumer

The Consumer PWA derives a signing wallet from device-local recovery material, reads account state from the relevant chain, and uses application relays for gas-sponsored writes. The same EOA can register an AddressPGP identity for CoNET Chat. After mailbox presence, Chat asks `wallet_native_wake_query` whether that contact has a wakeable native shell (iOS, Android, Windows, Linux, or macOS). The query is encrypted to the contact mailbox and posted only through an entry node, so the mailbox does not see the querier's IP. A trusted `true` keeps the voice-call control available while the contact is offline. Smart Wallet state is on-chain; the interface and recoverable local cache are application concerns.

### Merchant

Merchant OS maps an owner EOA and authorized staff relationships to program-management screens. The merchant signs with session-memory key material after recovery and unlock. Long-term merchant signing material is not intended to be persisted by the Merchant OS browser application.

Merchant card payments use Stripe Connect OAuth: the merchant authorizes an
existing Stripe account, Beamio creates a destination charge for that
Connected Account, and the shared webhook records payment and fulfillment
state. Only a trusted paid event can enqueue the card mint; persistent
session/event/business-idempotency keys and recoverable Master leases prevent
one payment from minting twice. The card owner may pause Stripe top-ups without
removing the connection; membership-fee payments remain enabled. Disconnecting
the account requires a left-to-right confirmation slide and removes only
Beamio's local Connected Account association, never the Stripe account itself.

### POS

A POS terminal is its own wallet and operates as an authorized lower-level merchant administrator. It signs terminal operations through the POS PWA, while the Cluster / Master path performs validation and gas relay. Terminal authorization itself can be delivered as a typed CoNET Chat message to Merchant OS.

The application therefore combines:

```text
L1 state and signatures
        +
L0 routed messages
        +
local wallet and UI state
        +
gas-relay services
        =
consumer, merchant, and POS workflows
```

No single layer supplies the complete product experience.

## Product map (today)

The following capabilities are live on the public surfaces. Detail and limits live in the chapter pages.

| Domain | Consumer | Merchant OS | POS |
| --- | --- | --- | --- |
| Identity | `@BeamioTag`, EOA, optional Smart Wallet | Owner EOA, staff, pending terminal authorization | Terminal EOA as lower-level admin |
| Programs | Hold membership NFT (`tokenId ∈ [100, 1e11)`), program points (`#0`), Discover brands | Create and publish program cards; base membership plus Add-tier higher paid tiers | Issue membership NFT (not leftover `#0`), top-up, charge |
| Commerce | Claim coupons and catalogs, pay | Issue coupons and catalogs, review transactions | Charge, top-up, claim, redeem, burn |
| Cash | Stripe Onramp → Base USDC to EOA; Coinbase `walletDeposit` → CONET-USDC (separate Add Cash). Home Fund **Receive via QR** and **Receive from a wallet** are P2P sends to the owner EOA on Base, not deposit rails. | Treasury / USDC views; Fuel packs as B-Units | Uses program points and membership; does not replace consumer deposit rails |
| Messaging | CoNET Chat | Chat plus POS permission inbox | Sends POS permission envelopes; not a general Messages product |

Two USDC deposit rails must not be merged:

| Rail | User-visible result | Chain | See |
| --- | --- | --- | --- |
| **Coinbase / `walletDeposit`** | CONET-USDC via Treasury LockMint | CoNET settlement after Base lock | [Cash and USDC](beamio/cash-and-usdc.md) |
| **Buy USDC with card (`eoaUsdcStripe`)** | Stripe Crypto Onramp sends native USDC to the owner **EOA**. Consumer Home CTA is **Fund Wallet** (same rail). | **Base** | [Cash and USDC](beamio/cash-and-usdc.md) |

Merchant Kit Stripe (CAD kits → B-Units / Ket) is a third Stripe product and is **not** a consumer USDC deposit rail. Both Kit Checkout and Consumer Onramp use the same operator account **`StripeBeamio`** and the same live webhook **`https://beamio.app/api/stripeBeamioHook`** (signing secret **`STRIPE_WEBHOOK_SECRET_MERCHANT_KIT`**). Older Dashboard URLs are retired; the API may still forward them to the same handler. Fulfillment remains on separate rails. Consumers who buy USDC with a card receive native Base USDC **directly in the owner EOA**.

**Outbound USDC is a different rule.** Pay / Send, **Discover Gifting** (gifter CONET-USDC → open redeem; no merchant owner signature), Charge when USDC is the settlement asset, AA ↔ EOA, NFC / QR, Fuel Pack USDC debit, card `#13` escrow deposit, and institutional-multisig USDC out are **offline signatures**. Cluster prechecks; Master or the Factory Paymaster submits and sponsors gas. Do not describe those writes as “the user pays ETH or CNET.” Third-party **Receive from a wallet / Receive via QR** remains an inbound exception (the peer pays gas). See [Cash and USDC](beamio/cash-and-usdc.md) and [Consumer — Discover Gifting](beamio/consumer.md#discover-gifting).

For Beamio issued-NFT social exchange, canonical CoNET-USDC is
[`0x5209865D404aA5646eDe5B91CD4218909eA72eDA`](https://mainnet.conet.network/token/0x5209865D404aA5646eDe5B91CD4218909eA72eDA)
(6 decimals). The user's AA burns Reward PT `#13`; the merchant card escrow
pays the reward to the user's EOA. This is not a direct USDC transfer to the
AA. **Discover same-store Top-up** is a different rail: this card’s `#13`
converts to this card’s `#0` on the user’s AA and does **not** use USDC
escrow. When Reward PT does not cover the full amount, Consumer Smart Pay
prefers **one CoNET payment** after a **Confirm Top-Up** review (the
remainder / insufficient-USDC warning lives on that confirm page, not the
payment-method page): `topupWithReward13Container` with peer `#13` redeem,
same-store `#13` → `#0`, and leftover cash as EOA **CONET-USDC EIP-3009
`cash`** in the same Relayer AA `executeBatch`. **Base USDC is not in that
container.** If CONET-USDC is short, Consumer then settles Reward PT
(`cash=0`) and pays the leftover via **Base USDC treasuryBridge** as a
second step. Cluster CONET-USDC precheck applies when a request includes
`cash`. Cash-only Discover Top-up (Use Points off) may still use Base USDC
via treasuryBridge. The sole active CoNET Treasury is TreasuryBridgeV3 at
[`0xa208982212978550594A7FEEB70a61665d129003`](https://mainnet.conet.network/address/0xa208982212978550594A7FEEB70a61665d129003).
The legacy USDC factory address `0xfD0D7B0706AaB5E4351bcED37bC3C77ed6813907`
is deprecated.

## What exists today

Public endpoints:

| Item | URL |
| --- | --- |
| Consumer app | https://beamio.app/app/ |
| Merchant OS | https://biz.beamio.app |
| POS | https://pos.conet.network/ · https://beamio.app/pos/ · https://pos.beamio.app/ |
| API host | https://beamio.app |
| Explorer | https://mainnet.conet.network |
| CoNET L1 RPC | https://rpc1.conet.network · https://publicrpc.conet.network |
| Base RPC (treasury / USDC / institutional AA) | https://base-rpc.conet.network |

Source availability differs by surface.
For the cross-project list, see the
[Open source repository index](../open-source.md).

| Component | Public repository | npm |
| --- | --- | --- |
| **Consumer PWA** | [CoNET-project/SilentPassUI](https://github.com/CoNET-project/SilentPassUI/tree/cashtree) branch `cashtree` | — |
| **Merchant OS** | Live [biz.beamio.app](https://biz.beamio.app); listed public branch [SilentPassUI `cashtrees`](https://github.com/CoNET-project/SilentPassUI/tree/cashtrees) | — |
| **POS PWA** | Live endpoints; no standalone public repository identified | — |
| **Alliance client** | [CoNET-project/SilentPassUI](https://github.com/CoNET-project/SilentPassUI/tree/Alliance) branch `Alliance` | — |
| **API / Cluster / Master / Paymaster relay** | [settleonbase/x402sdk](https://github.com/settleonbase/x402sdk) | [`@settle402/sdk`](https://www.npmjs.com/package/@settle402/sdk) |
| **Marketing homepage** | [beamio-APP/homepage](https://github.com/beamio-APP/homepage) | — |
| **CoNET Chat SDK** | [CoNET-project/chat-sdk](https://github.com/CoNET-project/chat-sdk) | [`@conet.project/chat-sdk`](https://www.npmjs.com/package/@conet.project/chat-sdk) |
| **Mailbox / SI** | [CoNET-project/CoNET-SI](https://github.com/CoNET-project/CoNET-SI) | [`@conet.project/mvp-si`](https://www.npmjs.com/package/@conet.project/mvp-si) |
| **This documentation** | [CoNETProject/docs](https://github.com/CoNETProject/docs) | — |

The public surfaces and source show that the suite and its major integration paths exist. This page does not claim that every route is enabled for every account, that every chain deployment has identical configuration, or that all application services have a published SLA.

## What remains in development

- Continue hardening wallet recovery, account switching, native WebView integration, and cross-device consistency.
- Complete independent reviews of account contracts, relayers, local key handling, and merchant / POS authorization paths.
- Improve feature parity and accessibility across Consumer, Merchant OS, POS PWA, and native shells.
- Publish measured availability and performance expectations for RPC, relay, mailbox, metadata, and index-backed views.
- Continue simplifying boundaries between user-facing state, trusted chain reads, cached application data, and asynchronous settlement.
- Stripe Onramp Base USDC still depends on operator configuration (Crypto Onramp enabled; webhook secret; `crypto.onramp_session.updated`). A live create-session route is not by itself a guarantee that USDC has arrived.

## Trust and security boundary

| Boundary | Security implication |
| --- | --- |
| **Consumer and POS wallet storage** | The device can hold recoverable signing material. Device compromise can expose that wallet. Recovery and backup hygiene remain user responsibilities. |
| **Merchant OS wallet session** | Signing material is intended to remain in session memory. Closing or locking the session requires recovery and unlock again; a compromised active browser session can still sign. |
| **L1 contracts** | Enforce account and program state, but contract safety depends on deployed bytecode, upgrade authority, configuration, and audits. |
| **Cluster / Master / Paymaster** | Can validate, queue, sponsor, delay, or refuse supported writes. They must not receive or store user private keys, and their availability affects gasless UX. |
| **Layer Minus messaging** | Business plaintext is encrypted to recipient keys, but entries and mailboxes still observe limited routing, timing, and volume metadata. |
| **POS terminal authority** | A compromised authorized terminal can exercise the permissions granted to that terminal until access is revoked. |
| **Multiple chains** | CoNET and Base have independent state. A same-address deployment does not synchronize balances, nonces, policies, or tasks. |
| **Stripe Crypto Onramp** | Stripe sends Base USDC to the locked EOA. Cluster / Master create and observe the session; they do not transfer operator USDC. Success is `fulfillment_complete`, not `createSession`. |

Beamio is self-custody software with supporting relays and application services; it should not be described as trust-free, as a bank, or as a guarantee that every off-chain view is immediately current.

## Related

- [Consumer PWA](beamio/consumer.md)
- [Merchant OS](beamio/merchant-os.md)
- [POS terminal](beamio/pos.md)
- [Cash and USDC](beamio/cash-and-usdc.md)
- [Applications](README.md)
- [SilentPass VPN](silentpass-vpn.md) — privacy access on the same L0 substrate
- [CoNET Chat](depin-chat.md) — relationship-private wallet communication and terminal authorization
- [Institutional multisig AA](institutional-multisig-aa.md) — V2 team Smart Wallet capability
- [Zero-trust mailbox routing](../l0/mailbox-routing.md)
- [UDP forward](../l0/udp-forward.md)
- [Assets on L1](../l1/assets.md)
- [Decentralized cross-chain Treasury](../l1/cross-chain-treasury.md)
- [Resources](../resources.md)
