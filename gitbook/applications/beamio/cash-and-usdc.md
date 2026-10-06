# Beamio cash and USDC

**Maturity: Production reference.** Coinbase / Treasury `walletDeposit` and
Stripe Crypto Onramp session APIs are live on `https://beamio.app`. Onramp
settlement depends on Stripe Crypto Onramp being enabled for the operator
account and on the webhook event set. This page is not a claim that every paid
session has already settled.

Parent: [Beamio whitepaper](../beamio.md).

Revision: **2026-10-05**.

## Product role

Beamio exposes **more than one cash rail**. They share Stripe or Coinbase as a payment front only when documented. They **must not** share fulfillment code, destination tokens, or user-facing copy.

**Buy USDC with card** is the consumer card rail: the user pays with a credit card on Stripe Crypto Onramp, and Stripe sends native USDC on Base **directly to the owner EOA**. Beamio does not hold inventory USDC or call `USDC.transfer`.

This chapter is the whitepaper source for **deposit** semantics **and** for **Beamio-initiated USDC transfers and payments**. Merchant Fuel Packs and Merchant Kit are listed only so they are not confused with consumer USDC.

**Outbound rule:** every Beamio-started USDC transfer or payment (canonical CoNET-USDC and native Base USDC) is an **offline signature**. Cluster prechecks; Master or the Factory Paymaster submits and sponsors native gas. The user’s wallet must not `eth_sendTransaction` / `USDC.transfer` and must not pay ETH or CNET gas. Private keys never go to the API. Reads (`balanceOf`, Multicall, dashboard snapshot) stay RPC-first and do not use this relay.

### Settlement and custody boundary

Beamio lowers the operational threshold for using stablecoin settlement, but
it does not become the owner of customer or merchant assets. The customer
signs with a self-custody wallet, merchant program state is attached to the
merchant card, and Stripe card proceeds settle to the merchant's Connected
Account. Cluster / Master may validate, queue, route, sponsor, or refuse a
supported write; those roles do not make Beamio the payment principal or give
it the user's private key.

Card rails still use Stripe as a processor, and cross-chain rails still use
their documented Treasury contracts. The product phrase “direct settlement”
therefore refers to ownership and the commercial relationship, not to the
absence of all processing, contract, or network infrastructure.

## Rails (do not merge)

| Rail | User pays | On-chain result | Destination | Implementation |
| --- | --- | --- | --- | --- |
| **Coinbase / `walletDeposit`** | Coinbase Onramp / x402 settle | TreasuryBridgeV3 **LockMint** | **CONET-USDC** on CoNET | Existing wallet-deposit workflow. Do **not** retarget it to Base USDC. |
| **Buy USDC with card** | Stripe Crypto Onramp (card / Stripe policy) | Stripe sends native USDC | **Native USDC on Base** to the owner **EOA** | `eoaUsdcStripe` — independent of `walletDeposit` |
| **Merchant Kit Stripe** | Card (CAD kits) | Kit fulfillment | **B-Units / Ket** on CoNET | Merchant fuel / kit product — **not** a consumer USDC deposit |
| **Merchant card Stripe** | Stripe-hosted Checkout link | Program-card top-up or membership fulfillment | Destination charge to the merchant's Connected Account | Checkout Session rail; Beamio supplies no customer/receipt email, and it is not a wallet deposit |
| **POS Stripe Terminal** | Physical card presented to Tap to Pay or an external Stripe Reader | Program-card top-up or membership fulfillment after confirmed `card_present` payment | Connected merchant account | Native iOS/Android shell through POS PWA bridge; separate from consumer Onramp and Checkout |

## Merchant card Stripe Connect

This is a separate Stripe Connect OAuth rail for merchant program cards. The
merchant authorizes Beamio to use an existing Stripe account; Beamio does not
create an Express account or use an Express Account Link. OAuth state is
short-lived, single-use, and bound to the merchant EOA and card address. The
OAuth start requires a short-lived, single-use signature from the current
on-chain card owner. The returned `stripe_user_id` is stored as the merchant's
Connected Account, never as the Beamio platform account.

For a linked card, Beamio creates a destination charge with
`transfer_data[destination] = stripe_user_id`. Stripe settles the payment into
the merchant's own Stripe account. This rail is not a wallet deposit,
Merchant Kit purchase, or operator-inventory USDC transfer.

The consumer may use **Pay with Stripe** for a linked card's program-card
top-up or membership fee. The PWA opens a Stripe-hosted Checkout link and
shows loading while the server polls the Checkout Session and fulfillment
status. Beamio does not supply a customer or receipt email; Stripe may still
request one when required by the selected payment method or Stripe policy.

### POS Stripe Terminal

After a merchant completes Stripe Connect, an authorized POS terminal can use
the same connected account for in-person card acceptance. The POS PWA requests
an idempotent PaymentIntent with `payment_method_types = ["card_present"]`
and a Terminal Connection Token. The native shell then uses Stripe Terminal
to discover/connect either Tap to Pay or an external reader and collect the
PaymentIntent client secret.

The PWA does not treat reader success alone as business success. It polls the
PaymentIntent and the existing idempotent merchant-card fulfillment record;
only after the CoNET card operation succeeds is the POS top-up shown as
completed. The shell receives no platform secret, connected-account secret,
private key, or plaintext wallet credential. Terminal Location creation and
reuse are account-scoped and persisted with the linked card.

Terminal currency is selected per connected account. When the merchant
account's country supports the program card currency, the card-present
PaymentIntent uses that local currency. When it does not, Beamio quotes the
original card amount through the card's on-chain currency oracle and creates a
USD PaymentIntent instead. The original amount and currency remain in
fulfillment metadata, while the quoted USD amount and currency are recorded
separately for Stripe amount verification. Terminal locations use the
connected account country; they are not hard-coded to Canada.
After Stripe confirms payment, the server performs the corresponding CoNET card operation through a dedicated
`initManager[]` Stripe fulfillment signer pool: a top-up mints program points,
while a membership payment follows the card's membership-fee staging and
membership NFT flow. A Master worker acquires one idle EOA only when it starts
the chain task, signs the `ExecuteForAdmin` payload, submits it through the
gas/EntryPoint path, and releases the EOA in all completion and error paths.
The signer pool is separate from the settle gas pool. During Stripe Connect,
all configured fulfillment admins are registered in one owner-signed
`adminManagerBatch` transaction, with an unlimited owner-authorized mint
allowance applied to each signer; repeating the operation safely updates the
same admin records. Every configured fulfillment admin must be registered as
an admin on the merchant card. Checkout
`session_id`, business idempotency key, and Stripe webhook event ID
are persisted with unique constraints. Only a trusted paid event can enqueue an
unsigned task. A recoverable lease lets Master reclaim work after a restart;
the same payment can reach `ExecuteForAdmin` mint at most once, and a recorded
transaction hash makes retries observational rather than a second mint.

This rail is only offered when the Connected Account is ready
(`charges_enabled` and `details_submitted`). A merchant may turn **Stripe
topup off** in Merchant OS: it blocks only new program-card top-up Checkout
sessions, leaves the account connected, and does not block membership-fee
payments. The owner can turn top-ups back on later. Stripe receives no user
private key, and all card/merchant UI errors remain in the current flow for
retry.

A merchant can choose **Disconnect Stripe** from the same Merchant OS status
control. The owner must drag a left-to-right confirmation control and sign a
short-lived, single-use authorization; Beamio then removes only that card's
saved Connected Account and OAuth credentials. The action blocks all new
Checkout sessions for the card but does not close, delete, or restrict the
merchant's Stripe account.

Treasury (sole active): **TreasuryBridgeV3** `0xa208982212978550594A7FEEB70a61665d129003`.

Canonical CoNET-USDC for CoNET L1 application settlement is
[`0x5209865D404aA5646eDe5B91CD4218909eA72eDA`](https://mainnet.conet.network/token/0x5209865D404aA5646eDe5B91CD4218909eA72eDA)
(6 decimals). The legacy USDC factory address
`0xfD0D7B0706AaB5E4351bcED37bC3C77ed6813907` is deprecated and must not be
used in new application modules or accounting.

Base USDC: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`.

Base RPC for these reads: `https://base-rpc.conet.network`. Beamio does **not** submit the Onramp USDC transfer.

## Coinbase / Treasury (`walletDeposit`)

Coinbase `walletDeposit` is still the CONET-USDC LockMint path. Home **Fund Wallet** includes a **Coinbase** row: one tap fetches the Onramp session and opens Coinbase in the system browser or native `openURL`, with no second confirmation sheet. That row does not share fulfillment with **Debit card** (`eoaUsdcStripe`) or **Receive from a wallet**. **Receive via QR** remains a follow-on view (peer-to-peer EIP-681 to the owner EOA on Base), not a deposit rail. The **Receive from a wallet** sheet has no USDC amount field and no “Receive Funds” row. In the **native shell**, it always lists Phantom, MetaMask, OKX Wallet, and Trust Wallet, then opens the **PWA-built** deep link so that app can send Base USDC to the same EOA. In an **ordinary browser**, it lists only already-installed EIP-6963 / injected extensions; if none are present, the sheet shows an on-panel empty alert. Tapping an injected row connects and switches/adds Base. Neither the deep link nor the injected connect is a deposit rail. Clients must keep `WALLET_USDC_DEPOSIT_WORKFLOW = 'walletDeposit'` for the Coinbase row.

1. User completes Coinbase / x402 settle.
2. Master occupies the **Base** settle pool for the lock step.
3. Treasury V3 LockMint produces **CONET-USDC** for the user on CoNET.

This rail is unchanged by the Stripe Onramp product. Clients must keep `WALLET_USDC_DEPOSIT_WORKFLOW = 'walletDeposit'` for Coinbase.

## Buy USDC with card (`eoaUsdcStripe`)

Consumer path: **Home → Fund Wallet** (Stripe Crypto Onramp; same rail as **Buy USDC with card**). Stripe **Crypto Onramp** sends native USDC on Base to the owner **EOA**. Beamio does **not** accept card cash and then `USDC.transfer` from an operator settle wallet.

```text
Consumer PWA
  │  POST /api/eoaUsdcStripe/createSession
  │  { walletAddress, amountUsdc6 }
  ▼
Cluster precheck → Master
  │  Resolve owner EOA (if the submitted address is an AA, read factory owner())
  │  POST Stripe /v1/crypto/onramp_sessions
  │    destination_network=base, destination_currency=usdc
  │    lock_wallet_address=true
  │    source_amount + source_currency=usd
  ▼
User completes Stripe Onramp in the system browser
  │
  ├─ return: https://beamio.app/app/?eoa_usdc_stripe=success|cancel&session_id=…
  ├─ poll:   POST /api/eoaUsdcStripe/poll
  └─ hook:   POST /api/stripeBeamioHook  (crypto.onramp_session.*)
        ▼
  Stripe fulfillment_complete → session succeeded
  Optional transaction_id (0x + 64 hex) stored as usdcTxHash
```

Retired Stripe Checkout (`cs_`) sessions are marked failed. Users must start a new Onramp deposit.

### Amounts

| Rule | Value |
| --- | --- |
| Client units | `amountUsdc6` — 6 decimals (`1 USDC` = `1000000`) |
| Minimum | 1 USDC |
| Maximum | 10,000 USDC |
| Stripe create | `source_amount` as human-readable USD + `source_currency=usd` |
| Credited USDC | May be slightly less than the selected `$N` after Stripe Onramp fees |

A successful `createSession` is **not** proof that USDC has arrived. Success is Stripe `fulfillment_complete`. Do not treat `fulfillment_processing` as succeeded.

### HTTP (application API host `https://beamio.app`)

| Method | Path | Body | Result |
| --- | --- | --- | --- |
| `POST` | `/api/eoaUsdcStripe/createSession` | `{ walletAddress, amountUsdc6 }` | `{ sessionId, url }` (`cos_` Onramp) |
| `POST` | `/api/eoaUsdcStripe/poll` | `{ sessionId, userClosedCheckout? }` | Session status + optional `usdcTxHash` / `recipientEoa` |
| `POST` | `/api/stripeBeamioHook` | Stripe signed payload | Shared live webhook; Onramp events mirror status and **do not** send operator USDC |

Cluster performs precheck (address, amount bounds). Master creates the Onramp session and holds the in-memory session map. Master **does not** occupy `Settle_BasePool` and **does not** call `USDC.transfer` on this rail.

### Recipient

Onramp creation **locks** the destination to the owner **EOA** on Base:

- Preferred client input: Consumer `keyID` (EOA).
- If the client sends an AA address, the server resolves `owner()` via the Base (then CoNET) AA factory **before** creating the Onramp session.

The product does **not** mint CONET-USDC on this rail and does **not** send USDC to the AA.

### Operator configuration

The operator Stripe account is the **`StripeBeamio`** key on the API host’s local `~/.master.json`. Merchant Kit Checkout and Consumer Onramp use this account. The account must have **Crypto Onramp** enabled (including sandbox approval in the Stripe Dashboard).

The only live Dashboard webhook is **`https://beamio.app/api/stripeBeamioHook`**. Verification uses **`STRIPE_WEBHOOK_SECRET_MERCHANT_KIT`** (environment or the same `~/.master.json`). This book does not publish secret values. The Dashboard event set for that endpoint must include `crypto.onramp_session.updated` (Onramp) and the Merchant Kit `checkout.session.*` events. Without that secret, Onramp can still be created, but webhook confirmation will abort.

The API still **forwards** the retired paths `/api/eoa-usdc-stripe-webhook` and `/api/merchant-kit-stripe-webhook` to the same `stripeBeamioHook` handler. Do **not** add those URLs in the Stripe Dashboard. `https://hooks.conet.network/api/stripeHook` is not a Beamio live hook.

Onramp handlers must ignore `checkout.session.*` for consumer USDC. Those events must not trigger operator inventory transfers or Merchant Kit fulfillment on the Onramp rail.

## Discover Smart Pay cash

Discover merchant **Top Up** with **Use Points** on is a **spend** path, not a deposit rail. When Reward PT does not cover the full quote, Consumer UI prefers **one CoNET payment**. **Base USDC is not** included in that container.

| Item | Rule |
| --- | --- |
| Same-store `#13` | `topupWithReward13Container`. Converts to this card’s `#0` on the user’s AA. No USDC escrow. |
| Peer `#13` | Same container. Quoted CONET-USDC paid to the **target merchant card**. |
| Remaining cash (preferred) | Same Relayer AA `executeBatch`: EOA **CONET-USDC EIP-3009 `cash`**. Cluster `balanceOf` precheck applies. |
| Remaining cash (fallback) | If CONET-USDC is short: Reward PT container with **`cash=0`**, then leftover fiat via **Base USDC treasuryBridge** (`payDiscoverTreasuryBridgeWithLocalWallet`). |
| UI | One-shot CONET path until that container confirms. Fallback waits until Reward PT then Base both complete. Failure stays on the confirm panel (`role="alert"`). |
| Cluster | CONET-USDC `balanceOf` reject applies when a request includes `cash`. A failed RPC read is **not** treated as zero. |
| Base USDC | **Not** in the CoNET container. Used only when CONET-USDC cannot cover leftover cash, or on cash-only Top-up. |

Cash-only Discover Top-up (**Use Points** off, no `#13` legs) still pays with **Base USDC** via treasuryBridge, then CONET-USDC, then third-party (`purchasingCard` / `postBuyCardPoints`). Those leftover-cash writes still follow the **offline sign + sponsored gas** rule below.

## USDC transfers and payments (offline sign + sponsored gas)

Deposit rails above move USDC **into** a user or Treasury path. This section is the opposite: **Beamio products moving USDC out** — Pay / Send, **Discover Gifting** (gifter CONET-USDC; optional Credit Gift burns `#0` instead), Charge when USDC is the settlement asset, NFC / QR, AA ↔ EOA, Fuel Pack USDC debit, card `#13` escrow deposit, social-exchange user authorization, institutional multisig USDC out, and in-wallet “send USDC.”

```text
Client (EOA / AA / POS / institutional multisig)
  1. Build the authorization locally (do not broadcast)
  2. Sign offline (EIP-712 / EIP-3009 / EIP-2612 / UserOp / Container)
  3. POST only { authorization fields + signature } to Cluster
Cluster
  4. Full precheck (signature, balance, deadline, nonce, requestHash, …)
  5. Forward to Master only when the request passes
Master
  6. No second business precheck; settle / EntryPoint / Paymaster pays gas
```

| Chain | Token | Sponsor occupancy |
| --- | --- | --- |
| **CoNET** `224422` | Canonical CoNET-USDC `0x5209865D404aA5646eDe5B91CD4218909eA72eDA` | `Settle_ConetPool` / CoNET Factory Paymaster |
| **Base** `8453` | Native USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | `Settle_BasePool`. AA UserOp that also consumes CoNET B-Units occupies **both** pools |

Legacy CoNET-USDC `0xfD0D7B0706AaB5E4351bcED37bC3C77ed6813907` must not appear on a new path.

| Funding source | Offline signature on the device | Typical relay |
| --- | --- | --- |
| **AA** (Express Pay / Smart Wallet) | Container / OpenContainer / UserOp | `POST /api/AAtoEOA` + Factory Paymaster |
| **EOA → CoNET-USDC** | EIP-3009 `transferWithAuthorization` or EIP-2612 `permit` | Cluster → Master `Settle_ConetPool` |
| **EOA → Base USDC** | EIP-3009 `transferWithAuthorization` | Cluster → Master `Settle_BasePool` |
| **Institutional V2 multisig** | Account EIP-712 task (not an EntryPoint nonce) | V2 Factory Paymaster / Proxy |
| **Card-owner escrow deposit** | EIP-2612 `permit` + `fundSocialExchangeUsdcEscrow` | `executeForOwner` / Conet pool |
| **Charge / NFC · QR** | Offline Container or `executeForAdmin` | `/api/AAtoEOA`, `/api/nfcTopup`, and the matching Charge relays |
| **Discover Gifting (USDC)** | EOA EIP-3009 `transferWithAuthorization` to card `owner()` (CONET-USDC) | `POST /api/purchaseMerchantGiftRedeem` (`payWith=usdc`) → Master collect + EntryPoint `createGiftRedeemForPayer` (**no** merchant `ownerSignature`). Claim: `/api/cardRedeem` |
| **Discover Gifting (Credit)** | EOA EIP-712 `GiftCreditPurchase`; burn `#0` on buyer AA for **G + F** | Same API (`payWith=credit`) → Master `createGiftRedeemWithCreditBurn`. Redeem face = **G** only. Claim: `/api/cardRedeem` |

### Discover Gifting (open redeem)

Discover merchant **Gifting** is a **purchase of an open redeem code**, not a Home Merchant Asset Gift (AA OpenContainer of the gifter’s existing `#0`).

| Step | Actor | Signature / gas |
| --- | --- | --- |
| Quote + pay (USDC) | Gifter | Fair CONET-USDC quote for gift fiat; offline EIP-3009 only; **zero** user gas |
| Pay (Credit) | Gifter | When Programs **Credit Gift** is ON: burn AA `#0` for **G + F**; offline EIP-712 only; **zero** user gas. No Multiplier / `#13` on this rail |
| Create redeem | Master / Paymaster | USDC: collect to `owner()` then `createGiftRedeemForPayer`. Credit: burn then `createGiftRedeemWithCreditBurn` (`membershipFeeE6` + `topupCreditE6` = **G**; **F** never minted). **Merchant owner does not sign.** |
| Share | Gifter | Plaintext code shown once; optional friend pick is UX only |
| Claim | Friend / code holder | Existing open redeem (`cardRedeem`); **zero** claimer gas |

Membership-fee cards (USDC rail): floor = base membership; non-member claim splits fee → membership NFT and remainder → `#0`; member claim mints the full gift as `#0`. Multiplier applies only to the top-up portion on the **USDC** rail. Non-fee cards mint principal (+ Multiplier on USDC) as `#0`. Merchant-operated create-redeem that still requires owner `executeForOwner` is a separate product track.

The same offline-sign + sponsored-gas rule applies on Consumer PWA, Merchant OS, POS PWA, Alliance, and new x402sdk write paths.

### What is not “user-paid USDC gas”

| Exception | Why it is not a Beamio outbound `USDC.transfer` |
| --- | --- |
| **Receive from a wallet / Receive via QR** | A third-party wallet (MetaMask, Coinbase Wallet, …) **sends into** the owner EOA. That peer pays its own gas. Beamio must not reuse this as its own send path. |
| **Fiat onramp** | Stripe Crypto Onramp and Coinbase `walletDeposit` stay on their documented rails. Success is Stripe `fulfillment_complete` or Treasury LockMint — not operator inventory `USDC.transfer`. |
| **Treasury LockMint** | Master’s initiator pays gas for TreasuryBridgeV3. The client does not broadcast Base or CoNET USDC. |
| **Read-only** | `balanceOf` / Multicall / dashboard `snapshot` — no signature and no sponsor. |

Master / settle admins **are** the gas sponsors. They are not a user hot wallet paying ETH or CNET.

## What this page does not cover

- Merchant Fuel Pack checkout (B-Units merchandising).
- POS Charge / Top-up **program-points** math and B-Unit fees. See [POS terminal](pos.md). Any USDC leg on those flows still uses offline sign + sponsored gas (this chapter).
- Issued-NFT social exchange: burning `#13` is paid from merchant card
  `escrowUsdc6` in canonical CoNET-USDC to the user's EOA, not directly to the
  user's AA. See [Merchant OS](merchant-os.md). Discover Smart Pay remainder
  (one CoNET container with CONET-USDC `cash`; Base treasuryBridge only if
  CONET-USDC is short) is documented above.
- Cross-chain Treasury mechanics beyond naming the V3 proxy. See [Decentralized cross-chain Treasury](../../l1/cross-chain-treasury.md).

## Trust boundary

| Actor | Can do | Must not |
| --- | --- | --- |
| Stripe | Confirm payment and send Base USDC to the locked EOA | Hold Beamio user keys; send a different token or destination than the locked Onramp session |
| Cluster / Master | Create Onramp sessions, poll, mirror webhook status | Persist user private keys; `USDC.transfer` from an operator wallet; reuse Merchant Kit fulfillment; write CONET-USDC on this rail |
| Operator settle wallet | Not used on this rail | Be described as the source of Buy-USDC-with-card funds |
| Consumer client | Open Onramp, poll, show EOA destination; **sign USDC outflows offline** and POST the signature to Cluster | Treat AA as the Onramp payout address; merge Onramp into `walletDeposit`; broadcast `USDC.transfer` and pay ETH/CNET for a Beamio send |

## Related

- [Beamio](../beamio.md)
- [Consumer PWA](consumer.md)
- [Merchant OS](merchant-os.md)
- [L1 assets](../../l1/assets.md)
- [Decentralized cross-chain Treasury](../../l1/cross-chain-treasury.md)
