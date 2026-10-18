# Merchant card custody handoff

**Maturity: Normative design (card custody) + live identity registry.**
Card-custody registry source is `src/mainnet/BeamioAgentRegistry.sol` — it is
**not** deployed and has no address. Separately, live CoNET identity /
invite relationships use **`BeamioAgentReferrerRegistry`** (UUPS proxy
`0x40f1B57280f9195AfEf2B4433CEc8f79d4b58b9A`, implementation
`0xb3535499aBAA9369681e092eAA8d84555eB3fbDe`, deploy block `1705690`; source
`src/mainnet/BeamioAgentReferrerRegistry.sol`). That live registry records
agent / temp / merchant / referrer EOAs via gasless EIP-712; it does **not**
yet reserve temps for card creation, bind card addresses, or dispose POS
admins. The card entry that accepts an offline owner signature, and the
Governance calls that revoke or re-parent POS admins, are specified here and
are not in live bytecode. Live cards can still move `owner()` only by a hot
`transferOwnership` from the current owner. Factory creation lists still do
not follow `owner()`.

Parent: [Beamio whitepaper](../beamio.md). Operational home:
[Merchant OS](merchant-os.md).

Revision: **2026-10-14**.

Chain: **CoNET L1 only**, `chainId` 224422. Merchant program cards are not
created or transferred on Base.

## What this handoff is

An agent provisions a merchant program card with a disposable **temp EOA**.
The merchant later takes that card with their own long-term **merchant EOA**.
The temp EOA signs `transferOwnership(merchant EOA)` offline. Beamio Cluster
prechecks that signature and Master submits it, paying CoNET gas. The
merchant then, with their own key, becomes the sole top-level admin, removes
the temp EOA, and chooses what happens to any POS admins that already hang
under the temp EOA.

When the handoff is complete:

- `owner()` is the merchant EOA.
- The merchant EOA is a top-level admin (`isAdmin` true, `adminParent` zero).
- The temp EOA is neither owner nor admin.
- Every POS admin that was under the temp EOA has either been revoked or
  re-parented to the merchant EOA, according to the merchant’s signed choice.
- Merchant OS returns this card for the merchant EOA.
- The agent registry row for this temp EOA stores the agent, the temp EOA,
  the merchant EOA, and the card address, and that temp EOA cannot create
  another merchant card.
- Possession of the temp private key no longer grants owner or admin authority
  on this card.

“Agent” is an operator EOA recorded by the registry. It is not a Factory role
and not the paymaster.

## Merchant OS product surface

Live Merchant OS (`https://biz.beamio.app`) implements the agent product path
against **`BeamioAgentReferrerRegistry`** (agent / temp / merchant / invite
referrer). Full card-custody registry steps below remain normative until
`BeamioAgentRegistry` and sponsored `transferOwnershipWithSignature` ship:

1. Merchant OS onboarding is **Merchant** only. New agent registration is
   Consumer Rewards Hub **Invite a business**, which offline-signs
   **RegisterAgent**.
2. A wallet that is already an agent signs in with `@BeamioTag` and Access
   Password and opens `#/agent` when chain `isAgent` is true (no Recovery QR).
3. The Temp EOA dashboard creates disposable merchant wallets with random tags
   and passwords, offline-signs **RegisterTemp**, reveals those credentials,
   and opens `#/native-pos` under a temp session for full program-card
   management (tiers, coupons, POS). Agents copy an invite URL
   (`?invite=0x…`) for Consumer referrer binds.
4. When `owner()` is no longer the temp EOA, the card is shown as
   **Transferred** and management is blocked; the agent may
   **RegisterMerchant** for the receiving merchant EOA.
5. A session banner returns from a temp session to the agent workspace.

Operational detail:
[Agent workspace in Merchant OS](merchant-os.md#agent-workspace-in-merchant-os).

## Keys

| Key | Who creates it | Who may hold it | What it is for |
| --- | --- | --- | --- |
| Temp EOA | Agent, one fresh key per card | Agent until delivery; merchant only in session memory while signing the owner payload | Initial `owner()` and sole top-level admin; EIP-712 signature over `transferOwnership(merchant EOA)` |
| Merchant EOA | Merchant, already recovered in Merchant OS | Merchant only | Signs the admin add, the POS disposition, and the temp-admin removal after it is `owner()` |

The merchant EOA private key is never sent to the agent, to Cluster, or to
Master. The temp private key is never an API field. The API receives the
EIP-712 signature only. Merchant OS may hold the temp key in process memory
long enough to sign that payload, then wipe it. It is not written to disk,
`localStorage`, or `sessionStorage`, and it is not logged.

The temp EOA does not need CNET for the owner move. Master pays that gas from
the CoNET settle pool after Cluster accepts the signature.

Security is the on-chain role strip, not a promise that every copy of the temp
key has been destroyed. Until the admin removal receipt is confirmed, anyone
who still has the temp key can still act as an admin.

## Agent registry (card custody — not yet live)

> **Live today:** identity and Consumer invite binds use
> **`BeamioAgentReferrerRegistry`** at
> `0x40f1B57280f9195AfEf2B4433CEc8f79d4b58b9A` (see
> [Merchant OS — Agent workspace](merchant-os.md#agent-workspace-in-merchant-os)).
> That contract does **not** store card addresses or `posDisposition`.

`BeamioAgentRegistry` is the planned UUPS card-custody registry on CoNET. It
is the airdrop basis for cards created through an agent temp EOA. The proxy
address stays stable once deployed. The Factory is not this registry and is
not upgraded to become it.

One temp EOA has at most one issuance:

| Field | Meaning |
| --- | --- |
| `agent` | Agent EOA that attested this temp |
| `temp` | Temp EOA used as `cardOwner` |
| `card` | Merchant program card created under that temp |
| `merchant` | Merchant EOA that received `owner()`. Zero until the sponsored ownership transfer confirms |
| `posDisposition` | `0` unset, `1` revoke every POS admin under the temp, `2` accept every POS admin under the temp |
| `used` | True once this temp has created a card. A used temp is rejected as `cardOwner` on any later create |

Before create, the agent signs EIP-712 `ReserveTemp(agent, temp, nonce, deadline)`.
Any relayer may submit `reserveTempWithSig`; the API pays gas. That marks the
temp reserved and records `agent`. It does not yet mark the temp used.

Cluster accepts an agent create only when that reservation exists, the signer
is `agent`, and `used` is still false. After the create receipt, a registry
admin (the Master settle admin) calls `bindCard(temp, card)`. The call
requires `owner()` of `card` to equal `temp`, then sets `used`, `card`, and
`tempOfCard`. `merchant` stays zero. A second `bindCard` for that temp reverts.
Until that bind confirms, Cluster also keeps an in-flight lock on the temp so
a second create cannot pass precheck in the same window.

A second `createCard` whose `cardOwner` is a temp with `used == true` fails
Cluster precheck. The temp is not recycled for another card, whether or not
the first card has been handed off.

Airdrop reads completed rows only: `used`, `merchant` equals the card’s
`owner()`, `merchant` is not zero, and the temp EOA is not an admin on
`card`. The airdrop recipient is `merchant`, not `temp` and not `agent`.
Factory `beamioUserCardOwner` is not an airdrop input.

## Creation

The agent creates the card through the existing create-card path with
`cardOwner` set to the temp EOA and the agent attestation attached. Cluster
resolves an AA address to its EOA before creation; the on-chain owner is
always an EOA. Cluster rejects the create when the registry already marks
that EOA used. The settle / paymaster signer pays create gas and is not the
card owner.

A successful create leaves all of the following true:

- `owner()` equals the temp EOA.
- `isAdmin(temp EOA)` is true, `adminParent(temp EOA)` is zero, and
  `threshold` is 1.
- The registry row stores `agent`, `temp`, and `card`, with `used` true and
  `merchant` still zero.
- Factory `beamioUserCardOwner(card)` equals the temp EOA, and
  `cardsOfOwner(temp EOA)` includes the card.
- The application row `beamio_cards.card_owner` equals the temp EOA until the
  handoff acceptance checks pass.

Live Factory:

`0xfA52a0CcC96C19cF4b6Ea864615F6d52BD0774FB`

That Factory is not a proxy. Its bytecode cannot be upgraded in place. Its
owner index is written at deploy. `transferOwnership` does not rewrite
`beamioUserCardOwner` or `_cardsOfOwner`. Discovery uses
`beamio_cards.card_owner` after it is rewritten to the merchant EOA. The
registry is the airdrop record, not a replacement for that application index.

## Sponsored ownership transfer

Inherited `transferOwnership(address)` is `onlyOwner`: it requires
`msg.sender == owner()`. Master cannot call that selector. The handoff does
not use it, and it does not use `executeForOwner` for the same reason: the
Factory would be `msg.sender` and the card would revert.

The card gains a sponsored entry, `transferOwnershipWithSignature`:

- The temp EOA signs EIP-712 over the card address, `chainId` 224422, the
  merchant EOA, a deadline, and a nonce.
- Cluster recovers the signer, requires it to equal the current `owner()`,
  requires the merchant EOA to be non-zero, and requires the registry row for
  this temp to point at this card.
- Master submits the call and pays CoNET gas.
- The card checks the signature again and then performs the same owner change
  as `transferOwnership`.
- Master then calls `recordMerchant(temp, merchant)`. That call succeeds only
  when `owner()` is already the merchant EOA. It writes `merchant` on the
  registry row.

Do not use `renounceOwnership()`. It sets `owner()` to `address(0)` and
assigns the card to nobody.

After this receipt, `owner()` is the merchant EOA and the Charge **5 B-Unit**
fee payer is the merchant EOA. The temp EOA is still an admin. The handoff is
not complete.

## Required order

Admin removal refuses to remove the current `owner()`
(`UC_OwnerCannotBeRemoved`). The last remaining admin cannot be removed.
Subordinate POS admins are one level under a top-level admin
(`adminParent` of the POS EOA is the temp EOA). Removing the temp EOA does
not re-parent those children and does not clear them.

```text
1. Agent signs ReserveTemp. reserveTempWithSig records agent and temp
   createCard(cardOwner = temp EOA)
   bindCard sets used = true, card; merchant = 0
   A later createCard with this temp is rejected

2. Deliver the temp private key to the merchant (one-time, off the API)

3. Temp EOA signs transferOwnership(merchant EOA) offline
   Cluster prechecks. Master pays gas and submits
   transferOwnershipWithSignature
   recordMerchant writes registry.merchant once owner() is the merchant EOA
   temp is still admin
   Factory lists still name temp

4. Merchant EOA signs executeForOwner
   adminManager(merchant EOA, true, 1, metadata)
   Merchant is a top-level admin. Threshold stays 1

5. Merchant EOA signs DisposePos (revoke-all or accept-all)
   disposePosWithSig stores posDisposition. It does not change admins
   The owner-signed Governance call then revokes or re-parents, and
   removes the temp admin

6. After CoNET reads match the acceptance checks, rewrite
   beamio_cards.card_owner := merchant EOA

7. Wipe the temp key from merchant session memory
```

Steps 4 and 5 use owner-signed `executeForOwner` after step 3, so the signer
is the merchant EOA. Gas for those calls follows the normal owner relay.
Step 3 is the signature relay above, not `executeForOwner`.

## POS admins under the temp EOA

The merchant EOA chooses after it is `owner()` and after it has been added as
a top-level admin. The choice is exclusive. The merchant signs EIP-712
`DisposePos`. `disposePosWithSig` stores `posDisposition` on the registry row
and does not add, remove, or re-parent card admins.

| Choice | On-card result | What the POS terminal does |
| --- | --- | --- |
| **Revoke all** (`posDisposition = 1`) | Every EOA in `adminChildren(temp)` loses `isAdmin` and leaves `adminList`. Their `adminParent` is cleared. The temp EOA is then removed. | Each terminal must send a new `beamio_pos_terminal_permission_v1` and be approved again under the merchant EOA. Existing admin authority on this card is gone. |
| **Accept all** (`posDisposition = 2`) | Each child keeps `isAdmin`. `adminParent` moves from the temp EOA to the merchant EOA, and the child moves onto the merchant’s `adminChildren` list. The temp EOA is then removed, with an empty child list. | Those terminals stay admins. They do not re-apply. |

Live `adminManager` cannot express either choice. Revoke-all and accept-all
are new Governance calls, `onlyGateway`, executed by owner-signed
`executeForOwner`. They run the child updates first and the temp removal
second, so a POS EOA is not left parented to an address that is no longer an
admin.

If `adminChildren(temp)` is empty, the merchant still signs a disposition.
Both choices then only remove the temp admin. `posDisposition` is still
recorded.

## Acceptance

Read these from CoNET RPC (`https://rpc1.conet.network` or
`https://publicrpc.conet.network`). An HTTP success or a local cache is not
acceptance.

| Check | Required value |
| --- | --- |
| `owner()` | merchant EOA |
| `isAdmin(merchant EOA)` | true |
| `adminParent(merchant EOA)` | `address(0)` |
| `isAdmin(temp EOA)` | false |
| temp EOA in `adminList` | absent |
| `adminChildren(temp EOA)` | empty |
| Revoke-all | every former child has `isAdmin` false |
| Accept-all | every former child has `isAdmin` true and `adminParent` equal to the merchant EOA |
| `threshold` | 1, and not greater than `adminList.length` |
| Registry | `used` true, `agent` set, `temp` and `card` match, `merchant` equals `owner()`, `posDisposition` is 1 or 2 |
| `beamio_cards.card_owner` | merchant EOA, written only after the rows above |

The merchant finds the card by querying the application index with their own
EOA, then confirming `owner()` on the card. Airdrop uses the completed
registry row. That row is not the Merchant OS card list.

Do not use these as the live owner after a handoff:

- Factory `cardsOfOwner(merchant EOA)` — still the creation-time list.
- Factory `cardsOfOwner(temp EOA)` — still contains the card.
- Factory `beamioUserCardOwner(card)` — still the temp EOA.
- A registry row whose `merchant` is still zero.

## What the temp key can no longer do

After acceptance, an owner signature from the temp EOA fails because
`owner()` is the merchant EOA. An `executeForAdmin` signature from the temp
EOA fails `isAdmin`. The key may still exist. It is not an owner key and not
an admin key for this card, and `createCard` rejects it as `cardOwner`.

## Incomplete windows

| Window | State |
| --- | --- |
| After create, before step 3 | Temp EOA is owner and sole admin. Registry `merchant` is zero. The temp is already `used` and cannot create a second card. |
| After step 3, before step 5 confirms | Merchant EOA is owner and is the Charge B-Unit payer. Temp EOA is still admin. Submit steps 4 and 5 immediately. |
| After step 5, before step 6 | On-card roles match the signed POS choice, but “my cards” for the merchant EOA stays empty until `beamio_cards.card_owner` is rewritten. |
| After acceptance | Temp EOA fails owner and admin checks. The merchant EOA is the owner and a top-level admin. The application index returns the card for that EOA. The registry row is eligible as airdrop input. |

## Non-goals

- Renouncing ownership to `address(0)`.
- Hot `transferOwnership` from the temp EOA as the handoff path.
- Routing the owner move through `executeForOwner`.
- Moving Factory `owner`. That changes the Factory admin, not a merchant card.
- Changing a Smart Wallet `BeamioAccount.owner`.
- Sending the temp private key to Cluster or Master.
- Reusing one temp EOA as `cardOwner` of more than one card.
- Airdrop to the temp EOA, the agent EOA, or Factory `beamioUserCardOwner`.
- Leaving POS admins parented to the temp EOA after the temp admin is removed.
- Treating the handoff as finished while the temp EOA is still an admin, while
  `posDisposition` is unset, or while the application index still names the
  temp EOA.

## Current chain boundary

| Behavior | Status |
| --- | --- |
| Hot `transferOwnership` from the current owner | On live cards. Not the handoff path |
| `executeForOwner` calls `transferOwnership` | Reverts; `msg.sender` is the Factory |
| `transferOwnershipWithSignature` plus Master-paid gas | **Required. Not deployed** |
| `BeamioAgentReferrerRegistry` (`RegisterAgent` / `RegisterTemp` / `RegisterMerchant` / `RegisterReferrer`) | **Live** on CoNET — proxy `0x40f1B57280f9195AfEf2B4433CEc8f79d4b58b9A`, impl `0xb3535499aBAA9369681e092eAA8d84555eB3fbDe`, block `1705690`, Blockscout-verified (identity + invite; not card-custody reserve/bind) |
| `BeamioAgentRegistry` (`reserveTempWithSig`, `bindCard`, `recordMerchant`, `disposePosWithSig`) | **Source written. Not deployed. No address** |
| `createCard` rejects a used temp | **Required** once the registry is live. Not a current precheck |
| Owner-signed add-self via `adminManager` | On live cards, after `owner()` has moved |
| Remove the temp admin while it is still `owner()` | Reverts `UC_OwnerCannotBeRemoved` |
| Revoke-all or accept-all for `adminChildren(temp)` | **Required new Governance calls. Not deployed** |
| Factory `cardsOfOwner` / `beamioUserCardOwner` follow the new owner | Not supported. Discovery does not wait for a Factory upgrade |
| `beamio_cards.card_owner` follows `OwnershipTransferred` by itself | Not a current listener. Step 6 is required |

## Related

- [Beamio](../beamio.md)
- [Merchant OS](merchant-os.md)
- [POS terminal](pos.md)
- [Cash and USDC](cash-and-usdc.md)
