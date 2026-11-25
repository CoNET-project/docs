# Resources

Operational references, public endpoints, source repositories, and maturity
boundaries for CoNET.

## Public endpoints

| Purpose | Endpoint |
|---|---|
| CoNET L1 primary RPC | `https://rpc1.conet.network` |
| CoNET L1 backup public RPC | `https://publicrpc.conet.network` |
| Explorer / Blockscout | `https://mainnet.conet.network` |
| Alternate Explorer entry | `https://scan.conet.network` |
| Beamio application/API origin | `https://beamio.ca` |
| Merchant OS onboarding website / file lookup (Cluster read; optional `files` JSON) | `POST https://beamio.ca/api/onboardingBusinessLookup` |
| Merchant OS onboarding Card Setup assets (Cluster read) | `POST https://beamio.ca/api/onboardingBusinessCardSetup` |
| Agent / referrer registry read (Cluster) | `GET https://beamio.ca/api/agentReferrerRegistry` |
| Agent / referrer registry write (Cluster → Master; EIP-712 ops) | `POST https://beamio.ca/api/agentReferrerRegister` |
| IPFS fragment service | `https://ipfs.conet.network` |
| Base RPC used by active Treasury and institutional-multisig paths | `https://base-rpc.conet.network` |

`https://rpc.conet.network` is deprecated and may be on a divergent historical
network. Do not use it as CoNET L1 truth.

## Core L1 contracts

| Contract | Address |
|---|---|
| AddressPGP | `0x684b0ac760cEE9c9b85de36d69746420648Cf9e2` |
| GuardianNodesInfoV6 | `0xBC6b53065b5647261396d002bDBA0d3396E0722f` |
| EpochMiningInfo | `0x648f1a17269627C3d465fEa40b3C229f7CacE5cA` |
| TreasuryBridgeV3 | `0xa208982212978550594A7FEEB70a61665d129003` |
| ChatIndexRegistry | `0x1511Caa71081C84d8a591490D1b83879088EED72` |
| BeamioAgentReferrerRegistry (UUPS proxy; canonical) | `0x40f1B57280f9195AfEf2B4433CEc8f79d4b58b9A` |
| BeamioAgentReferrerRegistry implementation | `0xb3535499aBAA9369681e092eAA8d84555eB3fbDe` |
| GBToken (no longer recognised; services stopped) | `0xC3EF02DaE632b4C10abB66e07d92a387c10838D8` |

Canonical CoNET-USDC for CoNET L1 application settlement:
[`0x5209865D404aA5646eDe5B91CD4218909eA72eDA`](https://mainnet.conet.network/token/0x5209865D404aA5646eDe5B91CD4218909eA72eDA)
(6 decimals). The current conet-USDC contract will be replaced by a newly deployed contract (decided, not yet live); the switch-over plan will be announced. The current contract will not be upgraded. The status of the current contract is to be verified. The sole Treasury is TreasuryBridgeV3 at the address
above, and its cross-chain bridge is paused; legacy USDC factory addresses and older Treasury addresses are
deprecated.

The GBToken above is no longer recognised and its services have stopped. The new GB design is described in [GB purchase, metering, fees and settlement](l1/gb-billing.md); it is approved, not yet live, and deployment needs an independent audit and a separate approval. The earlier [GB token whitepaper](l1/gb-whitepaper.md) is superseded.

Verify current code and state on the active RPC before relying on a historical
deployment note.

## Application and developer guides

| Goal | Guide |
|---|---|
| Understand decentralized cloud resources | [L0](l0/README.md) |
| Understand privacy routing | [Layer Minus](l0/layer-minus.md) |
| Build with Layer Minus | [L0 development](developers/l0.md) |
| Build a wallet-addressed application | [`web3://` Application Protocol](l0/web3-application-protocol.md) |
| Use the Linux `web3://` runtime | [`conet-l0d`](developers/conet-l0d.md) |
| Implement a browser/native `web3://` client | [`web3://` application](applications/web3-url.md) |
| Understand AAC | [AAC whitepaper v1](l1/aac-whitepaper.md) (normative specification; implementation and deployment are not accepted or claimed) · [two-way policy](l1/aac-two-way-bridge.md) · [earlier dated record](l1/aac-cross-chain.md) |
| Understand GB fees and settlement | [GB purchase, metering, fees and settlement](l1/gb-billing.md) · [Mailbox storage billing](l0/mailbox-storage-billing.md) |
| Understand node registry V2 | [Node registry V2](l1/node-registry-v2.md) (approved, not yet live) |
| Understand third-party tokens and subscriptions | [Third-party tokens and subscriptions](l1/third-party-assets.md) (approved, not yet live) |
| Understand DAO voting and the next-generation treasury | [DAO and the next-generation treasury](l1/dao-treasury.md) (approved, not yet live) |
| Run an L1 node | [Run an L1 node](developers/l1-node.md) |
| Confirm the period-18 checkpoint | [Confirm the period-18 checkpoint](developers/l1-independent-confirmation.md) |
| Participate in mining | [L1 mining](developers/l1-mining.md) |
| Build against DLE specifications | [L2 development](developers/l2.md) |
| Read the CoNET Chat product thesis | [CoNET Chat](applications/depin-chat.md) |
| Read the privacy-first decentralized AI design study | [Landing](applications/privacy-first-ai.md) · [Whitepaper](applications/privacy-first-ai-whitepaper.md) |

## Source repositories

CoNET is developed as open source. The complete, categorized list of public
infrastructure, protocol, application, contract, SDK, client, and
documentation repositories is maintained in the
[Open source repository index](open-source.md).

| Project | Repository |
|---|---|
| CoNET SI | [CoNET-project/CoNET-SI](https://github.com/CoNET-project/CoNET-SI) |
| LayerMinus / mining client | [CoNET-project/CoNET-DL](https://github.com/CoNET-project/CoNET-DL) |
| Linux `web3://` runtime | [CoNET-project/CoNET-L0D](https://github.com/CoNET-project/CoNET-L0D) |
| Browser `web3://` client | [CoNET-project/web3Url](https://github.com/CoNET-project/web3Url) |
| CoNET DLE | [CoNET-project/CoNET-DLE](https://github.com/CoNET-project/CoNET-DLE) |
| AAC Rust reference gateway | [CoNET-project/bridgeAAC](https://github.com/CoNET-project/bridgeAAC) |
| CoNET execution-client BLS patch (pre-Prague replay only) | [CoNET-project/patch-geth](https://github.com/CoNET-project/patch-geth) |
| Documentation | [CoNETProject/docs](https://github.com/CoNETProject/docs) |

## Maturity

| Capability | Evidence level |
|---|---|
| L0 decentralized resource plane | Implemented capability |
| Layer Minus encrypted entry/mailbox forwarding | Implemented capability |
| L1 chain, RPC, Explorer, validators, and assets | Production reference |
| CoNET Chat delivery, receipt, presence, and encrypted-history components | Implemented capability |
| `web3://` locator, Linux runtime, caller-signed gateway, and early browser client | Under development |
| AAC proof-driven cross-chain settlement | Historical October 2026 Shadow and canary receipts are preserved on the [earlier AAC page](l1/aac-cross-chain.md). They were not re-verified for this document and do not establish current service, custody or chain state. The new two-way design is [not deployed](l1/aac-whitepaper.md) |
| CoNET-DLE specifications | Normative design; lab evidence is separate from production |

These labels are not security-audit, uptime, or anonymity guarantees.

## Operational boundaries

- The public L1 node-joining path uses the documented geth and Prysm P2P
  interfaces and does not require `conet-l0d`.
- `web3://` uses Layer Minus over existing L0 resources; it does not add a
  second network or SI command family.
- SilentPass provides wallet-authorized privacy egress to ordinary Internet
  services. It is not an L1 consensus transport.
- Do not create a new public domain or endpoint without prior DNS, TLS, and
  operator approval.
- Do not restart geth, beacon-chain, validator, Reth, or rollup-node
  infrastructure without explicit operator authorization.

## Independent verification

For L1 reads:

1. query `eth_chainId` and expect 224422;
2. query the active RPC rather than a deprecated endpoint;
3. compare contract code and state with Explorer when appropriate; and
4. distinguish a successful RPC response from proof of an application action.

For L0 or `web3://`:

1. verify exact wallet/tag and AddressPGP identity;
2. verify the configured entry and mailbox route;
3. verify the versioned request or session ID;
4. verify the response request ID, nonce, expiry, and encrypted return path,
   or verify bidirectional session data; and
5. verify the origin application's result.
