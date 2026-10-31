# Node and client roles

Layer Minus roles describe what a process does for one route. They are not permanent machine classes: one healthy CoNET-SI node can be an entry for one request and the registered mailbox for another wallet.

## Runtime roles

| Role | Responsibility | Plaintext boundary |
| --- | --- | --- |
| **User client** | Holds wallet and OpenPGP private keys; signs, encrypts, decrypts, and acknowledges | Sees its own application plaintext |
| **Entry A** | Accepts HTTP (or optional HTTPS) `/post`, reads the OpenPGP key ID, forwards or peels a local outer layer, meters bytes for **GB** | Does not decrypt user-PGP business plaintext; may decrypt an outer layer addressed to A |
| **Entry C** | Accepts a listen or mailbox-control request and forwards it to B | Does not decrypt B's route-key command |
| **Mailbox B** | Decrypts mailbox control and mailbox-work JSON (`NoPush`), verifies route ownership, stores business ciphertext, and manages delivery sessions | Does not decrypt user-PGP business content |
| **UDP server client** | Receives `udp_subscribe`, obtains the symmetric key, and encrypts or decrypts application frames | Sees its UDP application plaintext |
| **LayerMinus mining client** | Opens mining listens to SI nodes, verifies signed gossip, and reports accounting data when configured | Sees signed mining gossip, not mailbox business plaintext |

The privacy boundary depends on role separation. If a user connects directly to mailbox B, B becomes both entry and mailbox for that session and sees the user's source IP.

## CoNET-SI

CoNET-SI is the active node runtime. It terminates an HTTP entry (and an optional HTTPS listener), exposes `/post`, and dispatches encrypted commands. Client `/post` confidentiality does not require the HTTPS listener.

Its Layer Minus duties include:

- read the OpenPGP encryption key ID from inbound armor;
- if the key is not local, look up its mailbox and forward the same armor over HTTP :80;
- if the key is local, decrypt; if the plaintext is still PGP and the inner key ID is not local, forward the inner armor;
- meter forwarded bytes for **GB** compensation;
- act as mailbox only when `isMyRoute` confirms the wallet-to-node binding;
- persist offline armor before best-effort SSE delivery;
- maintain labeled chat and mining sessions in the liveness pool;
- maintain separate UDP client and server pools;
- process `gossip_delivery_ack` and `wallet_online_query`;
- emit signed mining/liveness frames to connected LayerMinus clients; and
- for supported paid proxy commands, open an origin TCP connection as an exit.

SI relays AES-GCM UDP payloads and forwards user-PGP duplex gossip as ordinary Chat mail. It must not receive overlay / UDP session keys in a route-key command, and it must **not** implement `duplex_*`.

## CoNET-DL and mining listeners

CoNET-DL or an equivalent LayerMinus worker is a client of SI:

1. It encrypts a `command: "mining"` listen to the target node's route key and directly opens HTTP/SSE to that target SI.
2. It omits `listenKind`, so SI classifies the session as mining.
3. It holds the HTTP/SSE response open and receives signed gossip.
4. It verifies the node wallet signature.
5. It may forward verified aggregates to a cluster master for epoch accounting.

The connection direction matters: the LayerMinus worker dials the SI node. The cluster master does not establish mailbox listens on behalf of every SI.

This direct mining connection is an infrastructure collection path, not the privacy-preserving mailbox-delivery path. It is the deliberate exception to the application rule `C ≠ B`. Chat listens, presence queries, mailbox ACKs, and UDP control must still be encrypted to mailbox B and sent through an independent entry C.

Chat clients reuse the `mining` command for transport compatibility but set `listenKind: "chat"`. This label prevents chat-only session policy from being applied to mining pipes.

## Registration, liveness, and accounting

Public Guardian nodes may also be registered in `GuardianNodesInfoV6` on CoNET L1. That record is an eligibility and discovery input, not proof that the runtime is reachable.

These states are distinct:

| State | Evidence |
| --- | --- |
| Registered Guardian | L1 contract record |
| Reachable entry | A current client request succeeds |
| Active mining listener | LayerMinus has a usable SSE session and verifies gossip |
| Online Chat wallet | The wallet has a non-stale session in its mailbox's local listen pool |

Mining aggregates and L1 staking belong to the accounting and consensus layers. They do not change the business-message encryption rule or make an HTTP handshake a delivery receipt.

## Guarantees and non-guarantees

Role separation limits plaintext exposure and prevents a mailbox from learning the client's direct IP on the intended A/B/C path. It does **not** make SI nodes trusted. **Any Layer Minus node may be malicious.** Applications must still fragment data, encrypt to the recipient, and verify compute. See [Permissionless cloud and zero-trust applications](permissionless-cloud.md). Role split also does not guarantee that every registered Guardian is live, or prevent colluding or globally observing parties from correlating connections.

Availability depends on current entry health, route correctness, writable sessions, and client retries. Chain registration alone cannot satisfy those runtime conditions.

## Implementation anchors

- SI entry server: `src/CoNET-SI/src/endpoint/server.ts`
- SI command and role dispatch: `src/CoNET-SI/src/util/localNodeCommand.ts`
- Session health and mailbox persistence: `src/CoNET-SI/src/util/util.ts`
- UDP pools: `src/CoNET-SI/src/util/udpForward.ts`
- LayerMinus routing diagnostic: `scripts/testConetDepinMessage.ts`

## Next

- [How to use Layer Minus](using-l0.md) shows how applications combine these roles.
- [Security limits](security-limits.md) states that roles are not independent operators.
- [Zero-trust mailbox routing](mailbox-routing.md) specifies entry and mailbox behavior.
- [UDP frame forwarding](udp-forward.md) specifies the separate UDP session plane.
- [Persistent application streams](duplex-forward.md) — historical reference;
  the L0 attachment primitives were removed from SI on 2026-10-31.
- [L1 Guardian nodes and staking](../l1/guardian-staking.md) covers registration and economics outside L0.
- [SilentPass](../applications/silentpass-vpn.md) covers the product-level proxy path.
