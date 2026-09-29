# Beamio Consumer PWA

**Maturity: Production reference.** The Consumer PWA is live at
[https://beamio.app/app/](https://beamio.app/app/). This chapter is a product
inventory, not a screen-by-screen manual and not a claim of audit or SLA
coverage.

Parent: [Beamio whitepaper](../beamio.md).

Revision: **2026-09-21**.

## Product role

The Consumer PWA is the end-user Beamio wallet and marketplace. A person recovers or creates a self-custody EOA, optionally uses a Smart Wallet (Express Pay), discovers merchant programs, claims issued assets, chats over Layer Minus, and adds cash through the documented USDC rails.

It is not Merchant OS and not a POS terminal. It does not hold merchant program-admin authority.

The customer owns the wallet assets and interacts with each merchant program
directly. Beamio can provide discovery, authorization checks, routing, and
gas-sponsored submission without receiving the customer's private key or
issuing a pooled balance that replaces the merchant program. Store Credit
remains issuer-specific; only eligible Reward PT participates in documented
cross-store use.

## What exists today

| Domain | Capability |
| --- | --- |
| **Wallet** | Self-custody EOA from a local 12-word mnemonic. Cold start derives a global signing key. Missing mnemonic requires Restore (`@BeamioTag` + access password → on-chain recover package). |
| **Smart Wallet** | Optional AA / Express Pay. **New consumer AA issuance is CoNET only.** Existing Base V1 accounts may remain readable; they are not a new-issuance path. |
| **Identity** | `@BeamioTag`, profile language / currency, AddressPGP registration for Chat |
| **Discover** | Featured Brands and Ongoing Coupons from the public latest-cards / coupon APIs (single merchant-visibility gate). Merchant detail **Top Up** (store-credit button and welcome-offer CTA when membership is already valid) opens a multi-step full-screen flow: amount → pay → optional Reward PT cover → confirm. **Smart Pay** (Use Points on) prefers **one CoNET payment** when Reward PT does not cover the full quote: `topupWithReward13Container` with peer `#13` redeem, same-store `#13` → `#0` on the user’s **AA** (no USDC escrow), and leftover cash as EOA **CONET-USDC EIP-3009 `cash`** in the same Relayer AA `executeBatch`. **Base USDC is not in that container.** If CONET-USDC is short, Consumer then settles Reward PT (`cash=0`) and pays the leftover via **Base USDC treasuryBridge** as a second step. The success screen is a centered confirmation (minted store-credit amount, currency prefix) plus a **Share & Earn** card that shares the Discover merchant `/app-download` link with the signer’s `ref=` when a wallet is present; **Done** closes the overlay. Insufficient CONET-USDC and Base USDC together, and a failed step, stay on the **confirm** panel (not the payment-method page). Cash-only (no Reward PT legs) may still pay with **Base USDC** via treasuryBridge, then CoNET-USDC, then third-party. A merchant card with Stripe Connect fully linked also exposes **Pay with Stripe** for program-card top-ups and membership fees. Stripe opens a hosted Checkout link, does not collect card details in the PWA, and does not supply a customer or receipt email; Stripe may still require email for a selected payment method or platform policy. The PWA displays loading while the server polls payment and fulfillment status. This is separate from wallet deposits. Non-members use **Join or Top Up**: one payment issues membership and store credit together. The amount screen shows **Member fee**, including `0.00` when the published fee is zero. Store credit is the amount above that fee. Merchant detail **Gifting** purchases an **open redeem code** with gifter CONET-USDC (see **Discover Gifting** below). It is **not** a P2P transfer of the gifter’s existing `#0` store credit. |
| **Issued assets** | Coupons and Business Catalogs: open claim, like / share stats, supply copy |
| **Programs held** | Membership NFT (`tokenId ∈ [100, 1e11)`), program points (`#0`), Reward PT (`#13`). A newly issued BeaconProxy program has its complete ordered membership or loyalty tier schedule installed atomically in its create transaction; the base membership is on-chain index `0`, while metadata mirrors its name and presentation. Tier metadata may include multiple uploaded background choices (`images[]`); wallet passes use the merchant-selected `image` and fall back to the first valid choice when needed. **Join or Top Up** charges the membership fee and any additional top-up in the same payment. The member-fee line uses two decimal places, including `0.00` when the fee is zero. Program points are minted only from the amount above the fee; the fee itself is not store credit. The membership NFT stays in `tokenId ∈ [100, 1e11)`. |
| **Gift card designs** | When a merchant card exposes multiple valid tier images, the Gift Card flow presents a horizontal design selector. The selected design is previewed on the gift card and preserved through delivery, claim links, and Chat; when no tier image exists, the card keeps its tier background color. Amount, message, and delivery settings remain independent. |
| **Messaging** | CoNET Chat (ordinary sends **omit** mailbox `NoPush` so offline peers can get a native badge), delivery receipts (`NoPush: true`), mailbox presence (listen-pool query; not on-chain `routeOnline`), a follow-up native-shell query (`wallet_native_wake_query`, CoNET Chat protocol, posted only through an entry node so the destination mailbox does not see the querier's IP) that keeps the voice-call control available when a registered iOS, Android, Windows, Linux, or macOS shell can be woken, a local BeamioTag record (tag, image, online, native shell) shown first and refreshed from the network after 180 seconds, an open conversation that re-queries online every 6 seconds through an entry, and voice calls. Inbound identity is the EOA recovered from the sender’s EIP-191 signature; `@BeamioTag` is looked up for that address and is not read from the message body. A voice offer adds `callerSignature` over a canonical text that excludes identity fields, and that signer must match the outer envelope. The caller opens its voice SSE through its own mailbox in one `voice_listen`. That command includes `offerArmor`, the offer already encrypted to the callee. The caller's mailbox forwards that ciphertext to the callee mailbox without decrypting it, then after `voice_ready` calls `/api/voiceCallPush` with signed metadata for registered iOS/Android devices. The caller PWA never calls the endpoint directly, and the callee mailbox is not used as a push proxy. Decrypted Chat history stays in a Worker-local corpus; screens read it through `@conet.project/chat-sdk` (`readDecryptedChatHistory` / `searchDecryptedChatHistory`), and a fragment that is already decrypted is not fetched from IPFS again. |
| **Network tools** | Bounty Board, CoNET mining views, Genesis referral, Referral registry |
| **Team wallets** | V2 institutional multisig AA (CoNET, optional Base). See [Institutional multisig AA](../institutional-multisig-aa.md). |
| **Fuel** | Fuel Packs shown as **price + total B-Units** only (no Paid / Free split in merchandising) |
| **Native shell** | iOS / Android WebView at `/app/` plus Embedded OTA (`update.json` + `SilentPassUI-{ver}.zip`). Share / install links (`https://beamio.app/app-download?target=https://beamio.app/app/?…`) open **Consumer only**. They never open BeamioPOS. If Consumer is not installed, the page stays in Safari or the Consumer App Store. |

Stripe Checkout is shown only after the merchant card's Connected Account is
ready. The consumer sends the card address, EOA, fiat amount, and card
currency to the Cluster; no private key is sent to Stripe or the API. A paid
session is fulfilled on CoNET by the merchant card's dedicated fulfillment
admin, and webhook/session idempotency prevents duplicate minting.

Closing the hosted Checkout page is not itself a Stripe cancellation event.
For an unpaid Checkout Session, the PWA now explicitly reconciles the session
and asks Stripe to expire it before closing the payment panel. If the payment
won a race and is already paid, the close action never marks it as failed or
rolls it back. An unfinished session ID is retained locally and reconciled
when the consumer re-enters the top-up flow, while Stripe webhook delivery
remains the authoritative asynchronous status path.

These merchant-card payments use the platform Stripe Connect flow implemented
by Beamio: the Checkout Session or PaymentIntent is created by the configured
platform account with the merchant Connected Account as the destination. The
current implementation routes `merchantCardStripe` Checkout and
PaymentIntent events through the existing verified platform webhook; it does
not depend on a separate webhook configured inside the merchant's standalone
Stripe account. A merchant-created, independent Stripe payment is therefore
outside this fulfillment path.

Wallet identity colors are fixed in the product: **EOA blue**, **AA purple**. Those colors mark wallet kind, not balances.

## Cash (consumer)

Two independent deposit rails. Do not merge them in UI copy or implementation:

| Rail | User-visible result | Chapter |
| --- | --- | --- |
| Coinbase / `walletDeposit` | CONET-USDC via Treasury LockMint | [Cash and USDC](cash-and-usdc.md) |
| **Buy USDC with card** | Stripe Crypto Onramp sends native **USDC on Base** to the owner **EOA** | [Cash and USDC](cash-and-usdc.md) |

The Consumer Home hub shows **Universal Cash** (USDC) plus **Store Credits** and **My Points** (`#13`). The Home card rail button is **Fund Wallet**. That sheet is **not** a third deposit rail. It offers:

| Fund Wallet row | What it does | Not |
| --- | --- | --- |
| **Debit card** | Stripe Crypto Onramp (`eoaUsdcStripe`) — native **USDC on Base** to the owner **EOA** | Coinbase `walletDeposit` |
| **Receive via QR** | EIP-681 QR `ethereum:<EOA>@8453` for MetaMask / Coinbase Wallet scanners. Peer-to-peer send to this EOA on Base. | A Beamio deposit API or `walletDeposit` |
| **Receive from a wallet** | Native CashTrees / CaehTrees: catalog (`queryInstalledApps`) then `openURL` with the **PWA-built** EIP-681 send link (Base USDC to the owner EOA). Native must not invent the URL. **Desktop browser:** EIP-6963 injected wallet → `eth_requestAccounts`, switch/add Base (`0x2105`), then `eth_sendTransaction` USDC `transfer` to the owner EOA (**amount required** so the extension confirmation appears). Connect-and-switch alone is not enough. Mobile browser: HTTPS / custom-scheme send links. Not a Beamio deposit API. | Coinbase Onramp / `walletDeposit` |

The middle Fund row is **Receive via QR**, not Coinbase. Coinbase `walletDeposit` remains a separate Add Cash path (CONET-USDC via Treasury LockMint). Stripe Onramp opens in the system browser (or native `openURL` bridge). Return lands on `https://beamio.app/app/?eoa_usdc_stripe=…`.

The client should pass the **EOA** (`keyID`), not the AA address. If an AA address is submitted, Master resolves the owner EOA **when creating** the Onramp session and locks that wallet. Success is Stripe `fulfillment_complete`, not a Beamio `USDC.transfer`.

## Send / pay USDC (consumer)

Beamio’s own USDC outflows (Pay / Send, Discover Gifting purchase, Discover leftover cash, AA ↔ EOA) are **offline signatures**. The Consumer wallet signs EIP-712 / EIP-3009 / EIP-2612 / Container / UserOp locally and POSTs the authorization to Cluster. Master or the Factory Paymaster submits and sponsors ETH or CNET gas. The PWA must not `eth_sendTransaction` / `USDC.transfer` for a Beamio send, and it must not require the user to hold native gas.

**Receive from a wallet** and **Receive via QR** stay inbound exceptions: a third-party wallet sends **into** the owner EOA and that peer pays gas. Do not reuse that injected `eth_sendTransaction` path for Beamio Pay / Send. Detail and signing table: [Cash and USDC](cash-and-usdc.md).

## Discover Gifting

The standalone public purchase page is available at
`https://beamio.app/gift/<merchant-card-address>`. It does not require the
Consumer PWA login gate. Buyers may connect a third-party wallet such as
MetaMask for the sponsored EIP-3009 rail, or pay with Visa/Mastercard through
the merchant's Stripe Connected Account. After payment and on-chain creation
are both confirmed, the page displays a claim URL and QR code.

The standalone page stores the plaintext redeem code only in its own browser
IndexedDB, grouped by merchant card and purchase time. The chain and Beamio
servers store only the redeem hash. Clearing that browser's IndexedDB removes
the locally recoverable plaintext code; the code is not reconstructed from the
hash.

Merchant detail **Gifting** lets a consumer buy an **open redeem code** for a friend (or anyone who holds the code). Selecting a contact is share UX only; claim does not require that peer’s address on-chain. The gift entry and Step 1 are the same for every merchant category. Step 1 is labeled **Gift Card**, titled **Send a Gift Card**, and subtitled “A little something from you, to enjoy at {merchant}.” A share icon copies or shares the gift link. The gift card’s top-right background icon follows the merchant category; the rest of the page does not. Occasion themes and the message use one shared set: Just Because, Happy Birthday, Thinking of You, Celebrate, Thank You, Congrats, and Something Special. Choosing a theme fills its greeting until the sender edits the message. The entry keeps a gift icon and the button **Send a Gift Card**. It does not claim zero platform fees or immediate activation in that shared copy. Selected controls and the gift pass still use the merchant card brand color — not a generic Beamio blue.

Two **purchase rails** share the same gift sheet and claim path. Default is **CONET-USDC**. When the merchant enables **Credit Gift** in Programs (`giftCreditPurchase.enabled`), the sheet also offers **Pay with store credit**.

| Rule | Behavior |
| --- | --- |
| **Payment (USDC)** | Gifter pays **CONET-USDC** for the gift fiat amount (fair quote). Offline **EIP-3009** `transferWithAuthorization` to the merchant card **`owner()`**. |
| **Payment (Credit)** | Gifter burns **program points `#0`** on their **Smart Wallet (AA)** for gift face **G** plus optional merchant fee **F** (`G + F`). Offline **EIP-712** `BeamioMerchantGiftCredit` / `GiftCreditPurchase` (`verifyingContract` = card). Redeem stores **G** only; **F is never minted**. |
| **Credit extras** | No Top-up **Multiplier** and no **`#13` Reward PT** on the credit rail. Claim still uses the same open-redeem split for **G**. |
| **Gas** | Gifter and claimer **pay no native gas**. Master / Factory Paymaster sponsors create and claim. |
| **Create code** | Wallet purchases use `POST /api/purchaseMerchantGiftRedeem` with `payWith: "usdc"`; the standalone Stripe page uses the existing merchant-card Stripe checkout and then the same hash-only Gift creation path. Credit Gift remains `payWith: "credit"`. **No merchant card `owner()` signature**. |
| **Secret** | Plaintext redeem code is returned **once** to the gifter. The chain stores only `keccak256(utf8(code))`. Code is not persisted in API DB. |
| **Claim** | Anyone with the code uses the existing open-redeem path (`POST /api/cardRedeem` / Factory `redeemForUser`). Cluster prechecks redeem status on **CoNET** (the merchant card’s live chain). Claimer signs only what that path requires; gas stays sponsored. |
| **Non–membership-fee card (USDC)** | Gift principal (plus Discover Top-up **Multiplier** on that principal) mints program points **`#0`**. |
| **Membership-fee card (USDC)** | Floor = **base membership** fee (`baseMembership` / legacy `tiers[0]`). Non-member claim: fee → membership NFT (`tokenId ∈ [100, 1e11)`); remainder → `#0`. Already a member: **full** gift (fee + top-up parts) → `#0`. Multiplier applies only to the top-up portion. |
| **Not this product** | Home **Merchant Asset Gift** (sender AA OpenContainer of existing `#0`) is a different path. Merchant self-issued redeem codes that still use owner `executeForOwner` stay on that merchant track and are **not** Discover Gifting. |

Indexer: create is recorded as `merchantGiftRedeem`; claim remains `cardRedeem` with gift fee/credit fields in `displayJson` when the redeem is a gift split. Detail: [Cash and USDC](cash-and-usdc.md).

## Membership information (KYC)

When the merchant has published member-information collection, a first-time member on **Join or Top Up** sees **Become a member** after pressing Continue. Saving the form is required before the membership fee is paid or a zero-fee membership is claimed. A gift claim that would mint membership still shows the form before that claim. Someone who already holds a membership on the card is not asked again. The customer enters the fields the merchant marked required or optional. Phone and email stay optional unless the merchant marks them required. Fields set to off are hidden.

Continue encrypts the payload with OpenPGP to each card admin’s registered user public key (EOA, not the smart wallet), uploads the ciphertext to `https://ipfs.conet.network/api/storageFragment`, and asks the Cluster to record the content hash on the card for that customer wallet. The customer signs that link. The screen says the next step is payment review and that the customer is not charged on the form itself. If no admin has a registered encryption key, save stops with an on-screen error.

## Protocol dependencies

| Dependency | Consumer use |
| --- | --- |
| CoNET L1 | Account, **merchant program cards** (Discover / Gifting claim / My Brands), Smart Wallet, Chat index, mining / referral views |
| Base | Stripe Onramp USDC destination; Coinbase lock step; optional institutional AA. **Not** merchant program cards (Base merchant cards are retired). |
| Layer Minus | Chat listen / send (entry ≠ mailbox) |
| Cluster / Master | Gas-sponsored writes (including all Beamio USDC outflows), Stripe session create / poll, `walletDeposit` |
| Local IndexedDB | Mnemonic and derived key (Consumer allows persistence; Merchant OS does not) |

## Trust boundary

- Device storage of the mnemonic is a product choice for Consumer. Device compromise can expose the wallet.
- Relays and Stripe do not receive the user’s private key.
- Discover lists are application-filtered public catalogs, not a chain-wide census of every created card.
- Buy USDC with card succeeds only after Stripe Onramp `fulfillment_complete`. Stripe sends the USDC; Beamio does not transfer operator inventory.

## Related

- [Beamio](../beamio.md)
- [Merchant OS](merchant-os.md)
- [POS terminal](pos.md)
- [Cash and USDC](cash-and-usdc.md)
- [CoNET Chat](../depin-chat.md)
- [Institutional multisig AA](../institutional-multisig-aa.md)
