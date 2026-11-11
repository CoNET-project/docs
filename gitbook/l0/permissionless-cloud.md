# Permissionless cloud and zero-trust applications

**Evidence level: mixed.** The forwarding plane, hop **GB** metering, mailbox ciphertext store, and fragment APIs are live; GB issuance from metering is paused. Storage, WASM / container, and GPU work that a given node actually offers is deployment-specific. Decentralized AI is an **application composition**, not a shipped L0 product.

Layer Minus is a **permissionless, decentralized cloud**. Anyone may use it. Anyone may join by offering resources. Developers build **privacy-first** applications on top of it. They must assume that **any one node can be malicious**.

## What the cloud is

Layer Minus is not a licensed SaaS and not a single operator’s data center. It is a shared infrastructure of independent CoNET-SI nodes on the public Internet. Participants contribute one or more of:

| Resource | What the node does | Why it is paid |
| --- | --- | --- |
| **Network forward** | Carry OpenPGP armor toward a mailbox or next hop | Metered forwarded bytes → **GB** |
| **Storage** | Hold ciphertext fragments, mailbox offline armor, or sealed indexes | Useful retention and retrieval, not custody of plaintext |
| **CPU / GPU compute** | Run a signed job (storage command, WASM / container, inference helper) | Work the client can **verify** without trusting the host |

The reward asset for DePIN service is **GB**. The previous `GBToken` is no longer recognised and its services have stopped; the new GB design is [approved, not yet live](../l1/gb-billing.md). Forwarding is the live, byte-metered path, and GB issuance from it is paused. Storage and compute settlement follow the same rule: pay for **useful ciphertext work**, never for reading user plaintext.

**Use of the plane is permissionless.** A developer does not apply to CoNET to send Chat, store fragments, or schedule a job. A user does not need an account issued by a node operator.

**The public Guardian roster is a discovery set, not a license.** `GuardianNodesInfoV6.getAllNodes` is what current clients use to find domains and route keys. Adding a row with `addNode` today requires `adminList`. That is an L1 admission fact for the *listed* set. It does not make Layer Minus a permissioned application platform, and it does not make a listed node trusted. See [Guardian nodes](../l1/guardian-staking.md) and [Participate in mining](../developers/l1-mining.md).

## Zero trust: any node may be malicious

Treat every Layer Minus node as an untrusted host:

- it may drop, delay, or replay traffic;
- it may log client IPs, sizes, and times;
- it may lie about storage or compute results;
- it may collude with other nodes.

L0 therefore **must not** require any node to see business plaintext. A/B/C roles, user-PGP encryption, and hop-sig metering are the live forwarding expression of that rule. They are not a promise that a node is honest.

```text
Do not trust a node with
  ├─ message text, files, or model inputs in the clear
  ├─ a reconstructable whole object
  ├─ the only copy of a secret
  └─ an unverified compute result

Trust only
  ├─ keys the client holds
  ├─ ciphertext the client can re-encrypt or re-split
  └─ results the client can verify or recompute
```

Collusion of A+B or C+B still binds a wallet to an IP. Distinct Guardian addresses are not an operator-domain proof. See [security limits](security-limits.md).

## How developers compose a privacy-first application

A privacy-first app is **not** “pick one honest node.” It is a **combination** of techniques so that a single malicious node cannot read, reconstruct, or silently rewrite the user’s work.

| Technique | What it does | Live anchors |
| --- | --- | --- |
| **Privacy routing** | Sender and listener do not dial mailbox B. Nested PGP can hide the inner key ID from the first hop. Routing and product wallets may be different EOAs. | [Mailbox routing](mailbox-routing.md), [hop-sigs](hop-sigs.md), [split wallets](wallet-address-p2p.md#routing-wallet-versus-sender--recipient-wallets) |
| **Data fragmentation** | Applications should encrypt and fragment sensitive state so that no single storage provider receives enough material to reconstruct the whole. Store fragments by hash. Keep the assembly index encrypted to keys the client (or authorized set) controls. Fragmentation thresholds, redundancy, recovery, deletion, and availability verification remain application-specific. This is **not** an automatic property of all L0 traffic. | IPFS `storageFragment` / `getFragment`; Chat history index; copyright / DCDN designs |
| **Client-side cryptography** | Encrypt to the recipient **user PGP** (or a session key that B never sees). Sign application objects. Verify compute outputs. | [How to use L0](using-l0.md), [SI developer guide](si-developer-guide.md) |
| **Other application policy** | Split routing / payment identities, consumed nonces, sealed indexes, multi-node reconstruction, challenge windows | Application-owned. Not an L0 header field |

```text
Privacy-first application
  ├─ privacy routing     (A ≠ B, C ≠ B, optional outer wrap, optional routing wallet)
  ├─ fragmentation       (no single node has the whole object)
  └─ other client crypto (encrypt, sign, verify)
        │
        ▼
Layer Minus nodes  (forward / store / compute — all untrusted)
        │
        ▼
Privacy-first surfaces
  communications · storage · compute · decentralized AI
```

## Application surfaces

These are **what developers build**. They are not extra L0 protocols.

| Surface | Composition | Do not |
| --- | --- | --- |
| **Communications** | User-PGP Chat, typed control messages, UDP frames, SilentPass egress | Give mailbox B business plaintext or a UDP `Securitykey` |
| **Storage** | Encrypted fragments + sealed index; mailbox only stores armor it cannot read | Put a reconstructable file on one node in the clear |
| **Compute** | Send a sealed job to one or more nodes (WASM / container / GPU). Verify the result or use redundancy | Treat the host’s stdout as truth |
| **Decentralized AI** | Private prompts and weights as fragments; inference as untrusted compute; results returned encrypted to the user | Upload a model or prompt in the clear to “the AI node” |

Chat, SilentPass, fragment history, and hop **GB** metering are the current production building blocks. Bulk DCDN, copyright delivery, and a general GPU / AI marketplace remain **application designs** on the same zero-trust cloud. Document them as compositions, not as automatic SI policy.

## Future direction: privacy-first decentralized AI

**Three independent roles. One open intelligence economy.**

Centralized AI combines models, data, and user agents under one platform.
CoNET separates them across independent wallet-addressed participants—and
uses private application paths and programmable micropayments to make that
separation economically sustainable.

Models, data, and AI agents need neither mutual trust nor ownership by the
same platform. Layer Minus and `web3://` reduce the need for one network
intermediary to observe the complete user–service relationship. That
benefit is conditional on operator separation, client-side key control,
route diversity, limited identifier reuse, and the absence of collusion.
CoNET-DLE micropayments are designed so value can move among independent
participants for each measurable contribution. That is why the three-role
split is not only a technical architecture. It can become an AI production
relationship that economic incentives keep in place.

Prediction is not intervention. The governance risk becomes more severe
when the same actor that predicts a user also controls the ranking,
price, recommendation, or agent action presented to that user. A model
can be packaged and replaced as a capability. An agent is a continuing
relationship: it retains context, holds authority, selects services, and
mediates action over time. See
[Privacy-first Decentralized AI — Whitepaper §1.3](../applications/privacy-first-ai-whitepaper.md).

| Role | Product line | Privacy and economic boundary |
| --- | --- | --- |
| **Model builders** | Build intelligence without owning the user. | Publish models or verifiable artifacts. Do not automatically receive complete user prompts or control the data-provider network. |
| **Data providers** | Contribute data without surrendering control. | Contribute and attest inputs. Fragment and encrypt sensitive material so one collector does not become the universal data custodian. |
| **AI agents** | Act for users without becoming the platform. | Request work, protect private context, and return results to the user. Do not silently become the model owner and data authority. |

### Private coordination

**Implementation status.** Layer Minus forwarding is an **Implemented
capability** over L0 resources. `web3://` is **Under development**: v1
components include wallet locators, signed requests, encrypted response
correlation, Linux runtime support, and early persistent streams. Complete
cross-platform handling and general public hosting are not production
references.

Layer Minus and `web3://` reduce the need for one network intermediary to
observe the complete user–service relationship.

This benefit is conditional on operator separation, client-side key
control, route diversity, limited identifier reuse, and the absence of
collusion. Protocol-role separation alone does not prove legal-entity or
infrastructure independence.

In the proposed application model, the durable application owner is
represented by a wallet identity. Layer Minus routing additionally
depends on OpenPGP identity and mailbox-route bindings; an exact
`@BeamioTag` may provide an application-facing alias.

L0 GPU nodes remain an untrusted compute plane. Applications should
encrypt and fragment sensitive state so that no single storage provider
receives enough material to reconstruct the whole. Fragmentation
thresholds, redundancy, recovery, deletion, and availability verification
remain application-specific. Layer Minus provides forwarding and mailbox
primitives; higher-layer client cryptography is application composition,
not an automatic property of all L0 traffic.

The full paper defines **contestable intelligence**: independently sourced
data, contestable model supply, user-controlled agents, and an operational
evaluation matrix.

### Economic coordination

CoNET-DLE is designed for small, frequent payments among agents, models, data
providers, and infrastructure operators. Each participant can earn from a
measurable contribution without controlling the entire AI stack. The
one-basis-point protocol-value fee is a target for specified classes of
applicable value movement, not a universal all-in fee for every AI task.
AI event classes are proposed, not frozen DLE tip classes. Official
developer documentation still lists DLE as a normative design and
experimental environment, not a production SDK or a launched L2 service.

**Privacy-preserving settlement requirement.** A future AI payment protocol
should prove only the service right, amount, and settlement condition
required for one interaction. It should avoid placing prompts, dataset
identifiers, long-term agent identity, or the complete service graph on a
public ledger. This property requires a specified payment-session and
unlinkability design; it is not provided automatically by wallet payments
or by DLE. A public-chain micropayment can add metadata rather than hide
it.

Privacy creates independence. Micropayments make independence sustainable.

The product-facing landing digest is
[Privacy-first Decentralized AI](../applications/privacy-first-ai.md).
The full architecture paper is
[Privacy-first Decentralized AI — Whitepaper](../applications/privacy-first-ai-whitepaper.md).

## What this page does not claim

- A listed Guardian is honest.
- Running an unlisted SI automatically appears in `getAllNodes`.
- Every node offers GPU or WASM.
- Fragmentation by itself is anonymity, or that all L0 traffic is
  automatically fragmented so no node holds a reconstructable whole.
- That `web3://` is a complete production cross-platform handler or
  general public hosting service.
- That Layer Minus application identity is only a wallet address.
- Protocol-role separation proves legal-entity or infrastructure
  independence, or hides the complete user–service relationship without
  operator separation and limited identifier reuse.
- That wallet payments or DLE automatically hide prompts, dataset
  identifiers, long-term agent identity, or the complete service graph.
- That the one-basis-point protocol-value fee is a universal all-in fee
  for every AI task.
- That listed AI events (inference, licensed data access, verification)
  are frozen DLE tip classes, or that DLE is a production SDK or a
  launched L2 service.
- Decentralized AI is a live CoNET product name.
- That every predictive analysis is manipulation. Prediction and
  intervention are distinct stages.

## Next

- [How to use Layer Minus](using-l0.md) — forwarding primitives and combinations
- [L0 development](../developers/l0.md) — client how-to
- [Zero-trust mailbox routing](mailbox-routing.md) — A/B/C path
- [Security limits](security-limits.md) — what the live plane does not protect
- [Privacy-first Decentralized AI](../applications/privacy-first-ai.md) — landing digest
- [Privacy-first Decentralized AI — Whitepaper](../applications/privacy-first-ai-whitepaper.md) — full architecture paper
