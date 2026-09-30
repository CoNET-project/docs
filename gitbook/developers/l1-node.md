# Run an L1 node

**Evidence level: Production reference.** The genesis files, public peer
addresses, and ports below describe CoNET L1 (`chainId` **224422**). Fetch
live ENRs when joining and verify all downloaded genesis artifacts.

Anyone may run a **geth + Prysm beacon** full node. A separate operator
can follow the complete commands in
[Confirm the period-18 checkpoint](l1-independent-confirmation.md). After depositing
**32 CNET** per validator into the Beacon deposit contract, an operator may
also run a Prysm validator.

This is the public, permissionless L1 joining path. It is separate from:

- Guardian admission and LayerMinus mining;
- the `ValidatorDepositRedeem` application ledger; and
- application protocols such as `web3://`.

A laboratory destination — unmodified geth / Prysm peering through
`conet-l0d` by **wallet locator** instead of public `IP:port` — is
evaluated in
[L1 overlay lab — wallet-addressed geth / Prysm](conet-l0d-l1-overlay-lab.md).
Do not use that lab as the production bootstrap list.

## 1. What you are joining

| Role | Permission | Purpose |
|---|---|---|
| Execution + consensus full node | Open | Sync and serve the canonical L1 tip through geth and Prysm P2P |
| Beacon validator | Open after a 32 CNET deposit | Propose and attest after the deposit is processed |
| Guardian / DePIN miner | Permissioned by `GuardianNodesInfoV6` | Operate the L0 service plane; see [Participate in mining](l1-mining.md) |
| VDR stake record | Application contract | Application staking ledger; not the Beacon deposit contract |

Do not use `totalStakedValidatorCount()` as the Prysm active-validator count.
See [Validators](../l1/validators.md).

## 2. Download the network files

Keep these files beside your node configuration:

| File | URL | SHA-256 |
|---|---|---|
| `genesis.json` | [download](https://gitbook.conet.network/l1/network/genesis.json) | `bc8e77990a5b76d75b6a2041a2ae4d69c9cda03d120b1434b8ce3e11296fde60` |
| `genesis.ssz` | [download](https://gitbook.conet.network/l1/network/genesis.ssz) | `ae0a63e7bf175bb4312d5b728ff1eced7ceb4286ff5d7074cecbfa21dfd7fb46` |
| `config.yml` | [download](https://gitbook.conet.network/l1/network/config.yml) | `4bda580c4cfec801ecaed6fa04ad38bb9f1e941833fa7237ed5c6327f3cfbe24` |

Checksum list: [SHA256SUMS](https://gitbook.conet.network/l1/network/SHA256SUMS)

```bash
BASE=https://gitbook.conet.network/l1/network
mkdir -p conet-l1 && cd conet-l1
curl -fsSL \
  -O "$BASE/genesis.json" \
  -O "$BASE/genesis.ssz" \
  -O "$BASE/config.yml" \
  -O "$BASE/SHA256SUMS"
shasum -a 256 -c SHA256SUMS
```

If a checksum fails, stop and re-download. Do not edit a genesis artifact to
make a checksum pass.

## 3. Confirm chain parameters

Confirm the consensus genesis against a live beacon before treating a local
copy as authoritative:

```bash
curl -s http://38.102.126.50:4100/eth/v1/beacon/genesis
```

| Field | Value |
|---|---|
| `chainId` / deposit network | **224422** (`0x36ca6`) |
| `genesis_time` | `1781376367` |
| `genesis_fork_version` | `0x20000089` |
| `genesis_validators_root` | `0xacac7566fdf384a1ada45c01dcf9030d7eb0e1e5f5302659101d0b2a5bb59092` |
| Beacon deposit contract | [`0x4242424242424242424242424242424242424242`](https://mainnet.conet.network/address/0x4242424242424242424242424242424242424242) |
| Deposit per validator | **32 CNET** |
| Slot / epoch | `SECONDS_PER_SLOT=6`, `SLOTS_PER_EPOCH=32` |
| Eth1 follow | `ETH1_FOLLOW_DISTANCE=64`, `EPOCHS_PER_ETH1_VOTING_PERIOD=4` |
| Electra | Disabled |
| Recommended clients | geth **1.17.x**, Prysm **v7.1.4+** |

The Beacon deposit contract is `0x4242…4242`. It is not
[`ValidatorDepositRedeem`](https://mainnet.conet.network/address/0xc71e246DD78B37C2fABc905D340932F28F503433).

## 4. Public L1 hosts and ports

Current public execution, consensus, and DHT hosts:

| Public IP | Role |
|---|---|
| `38.102.126.30` | Archive RPC, DHT hub, production beacon |
| `38.102.126.50` | Public RPC, DHT hub, production beacon |
| `216.225.202.23` | Full node, validators, DHT hub |
| `216.225.202.22` | Full node, validators, DHT hub |
| `216.225.197.3` | Full node, validators, DHT hub |
| `216.225.202.82` | Full node, validators, DHT hub |

Do not bootstrap from retired hosts such as `216.225.192.76`,
`207.90.192.71`, or `38.102.85.33`.

| Plane | Port | Protocol | Public inbound |
|---|---:|---|---|
| Geth P2P | `8400` | TCP + UDP | Allow if the node accepts inbound peers |
| Beacon REST | `4100` | TCP | Bind your own API to loopback unless intentionally public |
| Beacon P2P | `4200` / `4300` | TCP / UDP | Allow if the node accepts inbound peers |
| DHT ENR API | `4110` | TCP | Optional client access |
| DHT P2P | `4210` / `4310` | TCP / UDP | DHT hubs only |

Do not expose the Engine API, JWT, geth HTTP/WS, beacon gRPC, or validator RPC
to the public Internet. Bind application and administrative RPC to
`127.0.0.1`.

## 5. Fetch live consensus ENRs

Peer IDs can change if a DHT process is rebuilt, so prefer live ENRs:

```bash
for ep in \
  38.102.126.30:4110 \
  38.102.126.50:4110 \
  216.225.202.23:4110 \
  216.225.202.22:4110 \
  216.225.197.3:4110 \
  216.225.202.82:4110
do
  echo "== $ep"
  curl -s --connect-timeout 5 "http://${ep}/eth/v1/node/identity" \
    | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d['peer_id']); print(d['enr'])"
done
```

Pass several returned `enr:` values to Prysm as `--bootstrap-node`.

Snapshot DHT peer IDs from 2026-08-17:

| Host | DHT peer ID on `:4110` |
|---|---|
| `38.102.126.30` | `16Uiu2HAmQoVe9DeBo4gW1WEmXohZLk3ACUkEeRGmBM7B5NAjU4YD` |
| `38.102.126.50` | `16Uiu2HAm3a8Ak19rig7uwDKbWivRnjiwpfZNqZv6SsUeaTcBUPw8` |
| `216.225.202.23` | `16Uiu2HAmN51gXoyK9kyr5HkSWuRYizeA2m1ipW4fn3V3tGo1fCKs` |
| `216.225.202.22` | `16Uiu2HAmBcwKE21Y2WV2guKpwBDkDXvxqQ9hRn1agC1S2Aneg3Nq` |
| `216.225.197.3` | `16Uiu2HAkxR4cZAKjehmczq3teuYCAWqrkDmhsZLabJBa7QPyDj6q` |
| `216.225.202.82` | `16Uiu2HAmGnXxJijMnNHQfrngvNNMvTdESCuJyuzbEQfxPdKMFx3T` |

These are DHT sidecar IDs, not production beacon IDs. Do not combine a DHT
peer ID with beacon port `4200`.

## 6. Configure geth bootnodes

Public geth bootnodes on port `8400`:

```text
enode://e5fe89d9ad924db6e4699480242a12fccba2c00e35772db706e46190c0ded9bb2b7e0d996826f5e46d369e01336213ef263c5038f94552e5f5e6e8ec76573a3f@38.102.126.30:8400
enode://d9243095bca94720f88d38c93ae4ccefc8b67651c66b4c93c915f845f6abfd39a091465db02db32b1a5b8061566c1558d2e6842f75620bf533480bab8a180168@38.102.126.50:8400
enode://5cf9a159e641318cda27e6bc1b4185667c0cdb1b54c3df5b8626eacbacea93af64c243dbdd09b40c62ba24792d0afc571cf17cbc47a5ed5a6207f27054c01d65@216.225.202.23:8400
enode://8e09d44bb4c29543a172e53dd8a74677a2a63d3d98a3d530f9d8b6f6bd6802a542f5b79d509ff737a9a764a66ab44a81403597cb50e350178ddd91f487e28f2d@216.225.202.22:8400
enode://dc0624c81896cdec036af7096886b1629a288b4824a467038df645c5c6b0f7fe75e13758ea80c0c37ba6245b221680db1fb553d564e54b55410eb6063bb64ca0@216.225.197.3:8400
enode://f1e249c97ce861441b3bd4832213cc634dd5c23d1a8722cd9c1aea28492779f6b64e012e8d97d56006d69be5224903ea5a787d8af68e9542db82ac1f76491dd5@216.225.202.82:8400
```

Use several as comma-separated `--bootnodes`. Your `--nat=extip` value must
match the public address that peers can reach.

## 7. Start a full node

These commands show the required shape. Use your own datadirs, JWT secret,
fee recipient, service account, and firewall.

### Initialize execution once

```bash
geth init --datadir ./execution ./genesis.json
```

Do not run `geth init` over an existing production datadir unless you have
explicitly planned a rebuild.

### Start geth

```bash
geth \
  --datadir ./execution \
  --networkid 224422 \
  --port 8400 \
  --discovery.port 8400 \
  --nat extip:<YOUR_PUBLIC_IP> \
  --bootnodes "<enode1>,<enode2>,..." \
  --http --http.addr 127.0.0.1 --http.port 8545 --http.api eth,net,web3 \
  --authrpc.addr 127.0.0.1 --authrpc.port 8551 \
  --authrpc.jwtsecret ./jwtsecret \
  --authrpc.vhosts localhost
```

`gcmode=full` is suitable for a validator-only machine. Archive mode is
optional and requires more storage.

### Start Prysm beacon

```bash
beacon-chain \
  --accept-terms-of-use \
  --chain-id=224422 \
  --genesis-state=./genesis.ssz \
  --chain-config-file=./config.yml \
  --execution-endpoint=http://127.0.0.1:8551 \
  --jwt-secret=./jwtsecret \
  --deposit-contract=0x4242424242424242424242424242424242424242 \
  --p2p-host-ip=<YOUR_PUBLIC_IP> \
  --p2p-tcp-port=4200 \
  --p2p-udp-port=4300 \
  --rpc-host=127.0.0.1 \
  --grpc-gateway-host=127.0.0.1 \
  --bootstrap-node=<LIVE_ENR_1> \
  --bootstrap-node=<LIVE_ENR_2>
```

Prefer several live DHT ENRs over one historical static peer.

### Open P2P ingress

Allow inbound:

- geth: `8400/tcp` and `8400/udp`;
- Prysm: `4200/tcp` and `4300/udp`.

Apply the same policy in the host firewall and cloud security group. Opening
only loopback RPC does not make the node reachable as a P2P peer.

## 8. Verify sync

Geth:

```bash
curl -s http://127.0.0.1:8545 \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}'

curl -s http://127.0.0.1:8545 \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":2,"method":"net_peerCount","params":[]}'
```

Beacon:

```bash
curl -s http://127.0.0.1:4100/eth/v1/node/peer_count
curl -s http://127.0.0.1:4100/eth/v1/node/syncing
```

Healthy catch-up evidence includes:

- geth has peers and block height rises;
- beacon has connected peers;
- `head_slot` rises;
- `sync_distance` falls; and
- the local consensus genesis root matches the published network.

Compare execution height with `https://rpc1.conet.network` or
`https://publicrpc.conet.network`. Do not use deprecated
`https://rpc.conet.network`.

## 9. Add a validator

After the full node is synced:

1. Generate validator keystores with a current Ethereum deposit or Prysm key
   tool. Keep the mnemonic offline.
2. Submit **32 CNET** per validator to
   [`0x4242424242424242424242424242424242424242`](https://mainnet.conet.network/address/0x4242424242424242424242424242424242424242)
   on chain 224422, with deposit calldata for those keys.
3. Wait for the eth1 follow distance and voting period before expecting the
   validator to appear.
4. Start the Prysm validator against the local beacon and configure your own
   fee recipient.

The validator talks to the local beacon over loopback. Never publish deposit
private keys, the mnemonic, keystore passwords, JWT, or validator RPC.

## 10. Safety boundary

- Joining does not authorize restarting another operator's geth, beacon, or
  validator.
- Do not wipe execution or beacon data on an active node to troubleshoot an
  unrelated application.
- Do not expose Engine API or validator secrets.
- Do not copy service units or secret files from another operator.
- Do not invent another download hostname; canonical artifacts are under
  `https://gitbook.conet.network/l1/network/`.

## Related

- [Confirm the period-18 checkpoint](l1-independent-confirmation.md)
- [Validators](../l1/validators.md)
- [Network identity](../l1/chain-identity.md)
- [RPC and Explorer](../l1/rpc-explorer.md)
- [Participate in mining](l1-mining.md)
- [L1 decentralization](../l1/decentralization.md)
- [`web3://` application protocol](../applications/web3-url.md)
- [L1 overlay lab — wallet-addressed geth / Prysm](conet-l0d-l1-overlay-lab.md)

## Next

[Participate in mining →](l1-mining.md)
