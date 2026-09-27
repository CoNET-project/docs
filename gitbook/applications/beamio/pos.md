# Beamio POS terminal

**Maturity: Production reference.** The active POS product is the **POS PWA**
loaded by native WebView shells.

| Entry | Role |
| --- | --- |
| https://pos.conet.network/ | Primary POS load URL (and alias paths) |
| https://beamio.app/pos/ | WebView `/pos/` fallback |
| https://pos.beamio.app/ | Root-path Web + **Embedded OTA** (`update.json` + `BeamioPOS-{ver}.zip`) |

Retired native POS business apps (`iOS_NDEF`, `android-NDEF`) are **not** the current implementation.

Parent: [Beamio whitepaper](../beamio.md).

Revision: **2026-09-11**.

## Product role

A POS terminal is a **wallet that is also a lower-level merchant administrator**. The same EOA can be payee and executing terminal. It performs in-store Charge, Top-up, membership issue, coupon claim, redeem, and coupon burn.

It is not Merchant OS. It does not create program cards or edit Programs metadata. Consumer Stripe Onramp (Buy USDC with card) and Coinbase deposit are **not** POS flows.

The public merchant Gift purchase page is also not a POS flow. It is served at
`https://beamio.app/gift/<cardAddress>` and uses the merchant Stripe Connected
Account for Visa/Mastercard checkout; the resulting Gift is claimed through
the Consumer redeem flow.

For card-present payments, Stripe Terminal remains the processor and settles
to the merchant's Connected Account. Beamio POS coordinates the authorized
program action after trusted confirmation; Beamio does not become the merchant,
take title to the proceeds, or receive the terminal wallet's private key.

## Chain placement

The bound **merchant program card** (`merchantInfraCard`) is **CoNET L1 only**. Base merchant cards are retired; POS must not resolve program-card views or Charge / Top-up / membership against Base UserCard Factory deployments.

## What exists today

| Flow | Behavior |
| --- | --- |
| **Charge** | Bill in the **card currency**. Client sends `amountFiat6 + currency`. The server computes points from `pointsUnitPriceInCurrencyE6`. The client must not convert fiat ↔ USDC for `items[].amount`. After the customer is scanned (NFC or QR), if this POS EOA is admin on **more than one** program card, POS loads that customer's store credit and Reward PT on each card and the cashier picks which balance to charge. A card whose currency does not match the bill is shown but disabled. Settle burns customer **`#0`** via `burnPointsByAdmin` (not a real `#0` transfer). When Charge Reward PT is on (**beacon impl V19+**), same-cycle actor/referrer **`#13`** mints from `chargeRewardRatioE6` / referrer charge ratio on that burn (parity with the legacy transfer path). Master must not enqueue a second `#13` mint. Not Social `getRewardRule`. |
| **Top-up** | Credits program points (`#0`) after a valid membership. Without a valid membership, plain top-up is refused; the cashier uses **Check Balance → issue membership**. Optional Top-up Promotion may mint extra `#0`. When Reward PT / Referrer Top-up are configured, same-cycle `#13` uses **`topupActorRewardRatioE6` / `referrerTopupAmountRatioE6`** on actual payment only — **not** Social Promotion `getRewardRule(2)`. |
| **Physical card top-up** | A merchant whose Stripe Connect account is ready can select **Card** in POS. The POS PWA asks Beamio for a `card_present` PaymentIntent, then the native iOS/Android WebView shell runs Stripe Terminal using Tap to Pay or an external reader. Stripe confirmation is not shown as a completed top-up until the server confirms the PaymentIntent and completes the normal CoNET fulfillment. |
| **Membership** | Selector shows **base membership (index 0)** plus each higher paid tier. A new BeaconProxy card creates its complete ordered tier, fee, duration schedule, and `tierQualificationMode` in the same create receipt; metadata supplies presentation only. Mode `1` is direct membership purchase and charges **fee only** (two-decimal display), mints a membership NFT with `tokenId ∈ [100, 1e11)`, and grants **no** `#0` program credit. Modes `0` and `2` are threshold qualification through top-up or charge and cannot carry membership fees. Cashiers must make a separate Top-up after membership is issued. |
| **Check Balance** | Reads membership and balances for the scanned / entered customer. |
| **Claim / Redeem / Burn** | Issued NFT claim, redeem-code consume, POS coupon burn. |
| **Authorization** | New terminals send `beamio_pos_terminal_permission_v1` over CoNET Chat to the merchant EOA. Merchant OS shows **Pending terminal authorization**, not a Messages bubble. |
| **Chat to users** | POS may send ordinary one-to-one CoNET Chat to a customer EOA. That path **must not** set mailbox `NoPush` (same as Consumer / Merchant OS Messages). Delivery receipts still use `NoPush: true`. See [CoNET Chat](../depin-chat.md). |

### Fees (B-Units)

Fixed protocol-fuel fees (not a percent of the bill):

| Flow | Fee | Payer |
| --- | --- | --- |
| Charge | **5 B-Units** | Program-card **owner** |
| NFC / QR Top-up | **20 B-Units** | As implemented on the top-up path |
| Social engagement events | **0.1 B-Unit** | Event fee path |

Cluster **prechecks** B-Unit balance before forwarding Charge. Indexer writes a standalone `{flow}:bunitService` row. Merchant OS may merge that row into the parent Charge / Top-up / Claim line for display.

### Ledger `subordinate`

For POS-executed Charge, Top-up, Claim, Burn, and Redeem, Indexer `subordinate` is the **terminal EOA**. It may equal `payee`. It must **not** equal `payer`. Gift / non-POS consumer charge must not invent a terminal subordinate.

### Native Stripe Terminal contract

The active POS implementation remains the POS PWA; native apps are WebView shells only. The PWA uses:

```text
POST /api/merchantCardStripe/createTerminalPaymentIntent
POST /api/merchantCardStripe/connectionToken
```

The first endpoint creates an idempotent `card_present` PaymentIntent for the connected merchant account. The second returns a short-lived Terminal Connection Token and the merchant Terminal Location. The shell accepts a common `startStripePhysicalPayment` command with `readerMode = auto | tap_to_pay | external_reader`, and returns `stripePhysicalPaymentResult`. The shell must never receive a Stripe secret key or a user private key.

Cluster checks the connected account country and the program-card currency before
forwarding. If the local currency is supported for `card_present`, it is used
directly. Otherwise Beamio quotes the original amount with the card oracle and
creates the PaymentIntent in USD. Fulfillment keeps using the original amount
and currency for program-card credit, while Stripe verification uses separate
actual-charge metadata. Terminal Location country comes from the connected
account.

Tap to Pay requires the platform entitlement / device eligibility checks required by Apple or Android. External readers require Bluetooth permission and a supported Stripe Reader. If the shell cannot provide a compatible reader, POS must keep the error in the current flow and must not silently fall back to NFC or cash.

## Protocol dependencies

| Dependency | POS use |
| --- | --- |
| CoNET L1 program card | Membership, points, issued NFTs (**only** live merchant-card chain; Base merchant cards retired) |
| Cluster / Master | Precheck + gas-sponsored `executeForAdmin` / Charge relay on **CoNET**. Any USDC settlement leg is an **offline signature**; the terminal must not broadcast `USDC.transfer` or pay CNET / ETH gas itself. See [Cash and USDC](cash-and-usdc.md). |
| Local IndexedDB | Terminal mnemonic (Consumer/POS persistence model) |
| Layer Minus | POS permission envelope to merchant mailbox; optional ordinary chat to customers (push-eligible) |
| Native shell | NFC / camera / `openURL`; business UI remains the PWA |

## Native shell and updates

Shells load the POS PWA. Process death must reload the WebView (no blank black screen). Embedded OTA polls **`https://pos.beamio.app/update.json`**, not `beamio.app/pos/update.json`.

iOS POS must **not** register the Consumer custom scheme `beamio://` or Associated Domains on `beamio.app`. POS uses `beamiopos://` and `applinks:pos.beamio.app` only. Consumer share URLs (`/app`, `/app-download`) must never open BeamioPOS.

## Membership information (KYC)

POS does not hold the customer’s private key. When membership issue or upgrade requires member information, the terminal shows the same **Become a member** form. The terminal wallet (a card admin) signs the on-chain link; the mapping key is the customer wallet from the scan. The ciphertext is still encrypted to admin user public keys and uploaded to IPFS. A gift or top-up for someone who already holds a valid membership NFT does not reopen the form.

## Trust boundary

- A compromised authorized terminal can charge, top-up, and claim until revoked.
- The terminal wallet is the signer; the merchant owner does not co-sign every ticket.
- Redeem **codes** stay on the client; the chain stores hashes only (except the authenticated gasless-claim relay, which must not persist the plaintext).
- Failed chain reads must not present “no membership / zero balance” when a last trusted value exists.

## Related

- [Beamio](../beamio.md)
- [Consumer PWA](consumer.md)
- [Merchant OS](merchant-os.md)
- [Cash and USDC](cash-and-usdc.md)
- [CoNET Chat](../depin-chat.md)
