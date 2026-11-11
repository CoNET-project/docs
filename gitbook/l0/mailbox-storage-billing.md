# Mailbox storage billing

**Status as of 10 November 2026.** The charging rule on this page was decided by the operator on 7 November 2026; payment options were added on 10 November 2026. It is not deployed: CoNET-SI and the clients have no code for mailbox registration, prepayment or storage charging yet.

**How to read the labels**

- **[Live]**: running on the network today.
- **[Approved, not yet live]**: a rule the operator has decided and published. It is not deployed. Deployment still needs an independent audit and a separate approval.
- **[Open]**: not decided.

## What a mailbox does today [Live]

A mailbox node (B in [Zero-trust mailbox routing](mailbox-routing.md)) keeps offline copies of ciphertext for its users until the recipient's client acknowledges them (ACK). It charges nothing for this.

## The storage rule [Approved, not yet live]

- **DAO price.** Forwarding 1 GB is priced the same as storing 1 GB of PGP ciphertext on a node for 30 days. This is a rate set by the DAO, not a statement about any cloud provider's cost.
- **Registration and deposit.** Before using a mailbox, the user registers with the chosen mailbox node and prepays at least **0.5 GB** of service credit as a storage deposit. The unit is GB of credit, not CNET and not a fixed amount of storage.
- **When charging runs.** From the moment the node has received and saved the offline ciphertext until the user's client acknowledges receipt.
- **What is measured.** The bytes actually stored, multiplied by the time they are stored.
- **Keeping and deleting.** While the prepaid balance covers further storage, the node must keep uncollected ciphertext, however long the user stays away. When the balance cannot cover another period, the node first notifies the user and allows one period of grace; after that it deletes the oldest messages first.
- **Where the deposit goes.** The deposit is paid to the mailbox node's wallet.
- **Two mailboxes.** A user with two mailboxes registers, prepays at least 0.5 GB and is charged separately with each.

## Paying for storage [Approved, not yet live]

- Storage can be paid in paid GB or in **free GB**: free GB pays for the same services as paid GB, including mailbox fees, with the user's authorisation.
- A user can also pay a mailbox node in a third-party stablecoin, if its issuer allows it. The node is then paid in GB from the issuer's deposit. See [Third-party tokens and subscriptions](../l1/third-party-assets.md).

The general fee and settlement rules are in [GB purchase, metering, fees and settlement](../l1/gb-billing.md).

## Open items [Open]

- How free GB is collected for storage, and other implementation details of the rule.

## Related

- [Zero-trust mailbox routing](mailbox-routing.md)
- [CoNET Chat whitepaper, Section 16.3](../applications/depin-chat-whitepaper.md#163-offline-mailbox-storage-approved-not-yet-live)
- [GB purchase, metering, fees and settlement](../l1/gb-billing.md)
