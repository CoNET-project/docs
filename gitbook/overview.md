# System overview

## Architectural thesis

CoNET separates concerns that are often collapsed into one “decentralized network” label:

1. **Where do decentralized network, storage, and compute resources come from?** — L0, the permissionless cloud resource plane.
2. **How does encrypted application traffic move without using a stable public origin as the application identity?** — Layer Minus, the wallet/OpenPGP-addressed privacy-routing protocol built on L0.
3. **Where does shared, production state settle?** — L1 CoNET Blockchain (EVM PoS, `chainId` **224422**).
4. **How can application activity scale into specialized parallel ledgers?** — L2 CoNET-DLE.
5. **How are wallet-addressed applications opened and published?** — The
   [`web3://` Application Protocol](l0/web3-application-protocol.md) defines
   locators, caller-signed requests, correlated encrypted responses,
   persistent streams, and browser adaptation on top of Layer Minus.

Operational facts in this book come from current source code, deployed contracts, and live endpoints. Destination architecture is labeled separately from production join paths.

## Responsibility by layer

### L0 — decentralized cloud resources

[L0](l0/README.md) is the **permissionless decentralized cloud resource
plane**. Participants may contribute traffic forwarding, ciphertext storage,
service hosting, CPU/GPU capacity, and other measurable resources. GB is the
active resource unit. L0 uses ordinary TCP/IP as its underlay and does not
claim that every resource provider is trusted, independently operated, or
able to reconstruct an application.

**Any node may be malicious.** Applications must add recipient encryption,
fragmentation, redundancy, verification, and recovery rules appropriate to
their data. Those are not automatic properties of resource contribution.
The intended AI direction keeps models, data, and agents as independent
wallet-addressed roles. See [Permissionless cloud and zero-trust applications](l0/permissionless-cloud.md),
[Privacy-first Decentralized AI](applications/privacy-first-ai.md), and the
[whitepaper](applications/privacy-first-ai-whitepaper.md).

### Layer Minus — privacy routing on L0

[Layer Minus](l0/layer-minus.md) uses L0 resources to forward application
ciphertext by wallet-linked OpenPGP identity. Wallets, OpenPGP keys, and
on-chain route bindings replace a stable origin IP as the durable application
route name. A sender posts recipient-encrypted traffic to entry **A**. A
recipient listens through entry **C**. Both are distinct from mailbox **B**.
This is the [A → B / C → B mailbox model](l0/mailbox-routing.md).

The carrier is ordinary HTTP between nodes and HTTP or HTTPS from clients to
entries. HTTP-shaped traffic reduces reliance on a distinctive custom
protocol, but does not guarantee indistinguishability from all Web traffic.
TCP/IP remains the underlay. Entry and mailbox roles reduce direct endpoint
exposure only when operators and identifiers are sufficiently separated;
they do **not** prove absolute anonymity, censorship resistance, or immunity
to traffic analysis. [How to use Layer Minus](l0/using-l0.md) explains how
applications select wallets, encryption targets, and envelope contents.

### `web3://` — application protocol

The [`web3://` Application Protocol](l0/web3-application-protocol.md) is an
**application-layer** contract: URI grammar, exact wallet/tag resolution,
caller-signed requests, correlated encrypted responses, persistent
application streams, host-adapter security, and failure semantics. It is not
a new Layer Minus wire command; Layer Minus continues to route encrypted
application envelopes over L0 resources.

The canonical product and platform model is
[`web3://` under Applications](applications/web3-url.md). Linux servers and
clients can use [`conet-l0d`](developers/conet-l0d.md); browser and native
clients on Windows, macOS, Android, and iOS implement the same protocol
contract. `conet-l0d` is a Linux runtime, not a separate application family.

### L1 — shared state and settlement

The [CoNET Blockchain](l1/README.md) is the production EVM network with `chainId` **224422**. It anchors network identity, validator and Guardian state, canonical assets, the [cross-chain Treasury](l1/cross-chain-treasury.md), and application settlement. The [AAC proof-driven settlement](l1/aac-cross-chain.md) read-only Shadow is production-approved and deployed for observation, but AAC custody, mint/release, and miner-vote cutover remain closed.

Validator consensus, Guardian participation, and application state are related but distinct concerns. In particular, “stealth” describes the objective of reducing publicly exposed network topology; it is not the name of a separate consensus algorithm. Do not label `ValidatorDepositRedeem.totalStakedValidatorCount()` (~475) as the L1 Beacon set, and do not treat the Guardian registry (~472) as that census either. Those two figures are the L0 / VDR-managed scale. Beacon `validator_index` values already pass **2000**. See [L1 decentralization](l1/decentralization.md).

### L2 — specialized parallel ledgers

[CoNET-DLE](l2/README.md) specifies Decentralization Clusters and parallel atomic ledger classes for asset, storage, and trade activity. The design moves high-frequency application events away from one globally serial execution lane while retaining explicit archive, finality, and settlement rules. **EIP-155 Chain ID** is unique for the DLE plane (**CoNET-DLE Testnet** `0x44c45` / `281669`). User-visible **Group ID** for the first archive group is that group’s L1 register transaction hash. Lab M6 added a second live group; its user-visible Group ID is that group’s L1 `registerLiveGroup` transaction. Neither identifier is CoNET L1 `224422`.

The L2 section is a digest of the English whitepaper (revision **2026-08-18**) and normative specifications. It states design maturity separately from L0/L1 production status. A public [lab explorer](l2/explorer.md) at [https://dle.conet.network/](https://dle.conet.network/) inspects isolated Archive health, testnet `0x44c45`, the bootstrap Group ID hash, lab M6 **Clusters = 2**, and a **non-green** 30-day clock chip (`pilotStartedAt=2026-08-18T09:53:58.092Z`; clock ≠ qualification). The L1 [Global Archive Routing Registry](l2/routing-registry.md) is deployed; that does not launch Archive Certificate or asset ingress, and it does not yet register the second lab group.

For an ERC-20 issued elsewhere, entering CoNET L1 and activating DLE are different transitions. Treasury route execution can establish a canonical CoNET representation; [DLE asset admission](l2/cross-chain-assets.md) additionally requires its own pool, oracle, registry, gateway, conservation, and release gates.

## One composition, end to end

Consider a paid social post:

1. **Identity and delivery:** the publisher and reader use wallet-linked identities; Layer Minus moves encrypted payloads through L0 entry and mailbox resources.
2. **Rights and payment assets:** ownership, access rights, and settlement assets can be anchored on L1.
3. **High-frequency events:** reads, tips, boosts, or revenue shares can be modeled as L2 application events and periodically settled according to a DLE ledger class.

The broader stack supports very different products, but a product need not
depend on every layer. [SilentPass](applications/silentpass-vpn.md) focuses
on network access, [CoNET Chat](applications/depin-chat.md) on
relationship-private wallet communication, [Beamio](applications/beamio.md) on wallet and merchant workflows,
and [`web3://`](applications/web3-url.md) on wallet-addressed application
access.

A second composition is **wallet-addressed hosting**: a browser or native
client resolves a `web3://` target, signs an Application Protocol request,
and submits ciphertext through a healthy Layer Minus entry. A Linux host can use
`conet-l0d` to verify the requester and map the logical port to a loopback
Web, API, AI, or TCP application service. Other server runtimes may implement
the same protocol contract.

A proposed [miner-matched order-book exchange](applications/miner-orderbook-dex.md) illustrates another composition: externally issued ERC-20s first enter through explicit Treasury routes; admitted canonical assets can then be represented in signed limit orders; miner matchers coordinate deterministic fills; and a contract, rather than the matcher, controls final asset movement. The exchange remains a design study, not a shipped DLE application.

## How CoNET differs from adjacent designs

The comparison below is architectural, not a throughput or anonymity benchmark.

| Design family | Typical identity and route anchor | Primary strength | Different focus in CoNET |
| --- | --- | --- | --- |
| IP-native P2P / libp2p | IP, DNS, or multiaddress | General peer discovery and content protocols | Wallet/OpenPGP identity plus entry-to-mailbox routing and a cross-platform `web3://` application contract |
| Content networks / IPFS | Content identifiers and provider records | Content-addressed distribution | Adds private message routing and L1/L2 settlement |
| Mix networks | Layered relay paths | Stronger traffic-correlation resistance, usually with latency cost | Uses ordinary HTTP(S)-shaped sessions and application-specific relays |
| Decentralized RPC / AVS | Public service endpoints plus stake | Replicated access to an existing chain or service | Couples a communication plane, an EVM L1, and application-ledger designs |
| Cloudflare Tunnel / Tor Onion / SIWE alone | Tunnel hostname, onion address, or login proof | Origin hiding or wallet login in isolation | Combines **wallet identity + exact target resolution + Layer Minus routing over L0 + signed application requests** |
| Typical “L1 + L2” stacks | Public Internet as external P2P | Execution / scaling layers | CoNET adds an L0 cloud resource plane and the Layer Minus wallet-addressed privacy protocol alongside L1 and DLE |

## Security and engineering boundaries

- **End-to-end encryption is recipient-specific.** Entry and mailbox nodes must not be trusted with application plaintext.
- **Routing metadata still exists.** An entry sees the connecting client; a mailbox knows which route it serves. The design limits correlation by separating those roles.
- **A successful entry request is not proof of delivery.** Mailbox persistence and recipient acknowledgements provide the stronger delivery signal.
- **Short sessions trade state for overhead.** Fetch-and-Close reduces persistent-flow exposure but is not an anonymity protocol; Chat SSE remains a traffic fingerprint.
- **Wallet identity does not solve Sybil resistance alone.** Stake, admission, rate limits, or application policy are still required.
- **Backend must not trust client-supplied identity headers.** A host adapter
  must strip colliding fields and inject only verified values.
- **Specification is not deployment.** DLE's normative design, a live L1 endpoint, the DLE lab explorer, and the Application Protocol draft have different evidence levels. The explorer does not make Archive Certificate or asset ingress live.

## Evidence map

| Question | Read |
| --- | --- |
| How are peers identified and messages forwarded? | [Layer Minus](l0/layer-minus.md), [wallet-addressed P2P](l0/wallet-address-p2p.md), [mailbox routing](l0/mailbox-routing.md) |
| Why is L0 a permissionless cloud, and why trust no node? | [Permissionless cloud and zero-trust applications](l0/permissionless-cloud.md) |
| What is the `web3://` Application Protocol? | [`web3://` Application Protocol](l0/web3-application-protocol.md) |
| How can Linux publish or open a `web3://` service? | [`conet-l0d` Linux runtime](developers/conet-l0d.md) |
| How do I write an SI or Chat client? | [L0 development](developers/l0.md), [SI developer guide](l0/si-developer-guide.md), [CoNET Chat developer guide](l0/chat-developer-guide.md) |
| How do I run a geth + Prysm node (public join today)? | [Run an L1 node](developers/l1-node.md) |
| How do I participate in DePIN mining? | [Participate in mining](developers/l1-mining.md) |
| What does L0 actually protect? | [Security limits and threat grades](l0/security-limits.md) |
| Which chain and endpoints are current? | [Network identity](l1/chain-identity.md), [RPC and Explorer](l1/rpc-explorer.md) |
| What L1 decentralization facts can an outsider reproduce? | [Decentralization and verifiability](l1/decentralization.md) |
| How can an external ERC-20 enter CoNET and later use DLE? | [Bring an ERC-20 into CoNET](developers/l1-erc20-bridge.md), [Cross-chain Treasury](l1/cross-chain-treasury.md), [cross-chain assets in DLE](l2/cross-chain-assets.md) |
| What is the AAC proof-driven bridge work? | [AAC proof-driven cross-chain settlement](l1/aac-cross-chain.md) — production read-only Shadow; no production light client, custody, or cutover |
| How could miner matching support a non-custodial order book? | [Miner-matched order-book exchange](applications/miner-orderbook-dex.md) |
| What does DLE actually specify? | [L2 development](developers/l2.md), [Design thesis](l2/design-thesis.md), [normative specifications](l2/specs-index.md) |
| What does the DLE explorer show? | [DLE explorer](l2/explorer.md) — [https://dle.conet.network/](https://dle.conet.network/); lab Archive inspection, not a tip chain |
| Where are archive participant wallets recorded? | [Global Archive Routing Registry](l2/routing-registry.md) — CoNET L1 facade + `/archives` |
| What is usable versus under development? | [Applications](applications/README.md) |
| What does Beamio ship today (Consumer / Merchant / POS / USDC)? | [Beamio whitepaper](applications/beamio.md) · [Cash and USDC](applications/beamio/cash-and-usdc.md) |
| Where are source and live-service references? | [Resources](resources.md) |
