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
| `genesis.json` (Osaka/Fulu) | [download](https://gitbook.conet.network/l1/network/genesis.json) | `e9889e1970251a145a2199caa9b889fd8868ab132372a69ff171b14476ae0b43` |
| `genesis.ssz` | [download](https://gitbook.conet.network/l1/network/genesis.ssz) | `ae0a63e7bf175bb4312d5b728ff1eced7ceb4286ff5d7074cecbfa21dfd7fb46` |
| `config.yml` (Osaka/Fulu) | [download](https://gitbook.conet.network/l1/network/config.yml) | `51c2c4dac8c50b7e3fa7b4be2a68be5ac813da8aa7389193d1785b1bbdae4840` |

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

`genesis.json` and `config.yml` are the Osaka and Fulu files. Osaka activated at
2026-10-18 13:26:07 UTC and Fulu at epoch `57050`, at the same instant
([section 8](#8-network-upgrades)). `genesis.ssz` is unchanged. A new node starts
from these files.

A node that still runs an older file set cannot follow the chain past block
`1767139`, the first Osaka block. The older files have these SHA-256 values, so
you can check a copy you already have:

| File | Prague SHA-256 | Pre-Prague SHA-256 |
|---|---|---|
| `genesis.json` | `894b39e610add4f6d15fc22eadc95d4b5943e0d705aee645a069b45dc7aec7f0` | `bc8e77990a5b76d75b6a2041a2ae4d69c9cda03d120b1434b8ce3e11296fde60` |
| `config.yml` | `12a5704003329afd84d2b4c891fe6ba51388991894d1331b50e93eeea1d39cf1` | `4bda580c4cfec801ecaed6fa04ad38bb9f1e941833fa7237ed5c6327f3cfbe24` |

All of these files give the same genesis hash. The pre-Prague files do not
schedule Electra or Prague. The Prague files do not schedule Osaka or Fulu.

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
| Beacon slot-0 header root | `0x37fae6d950f588ef15839dcdf69f4547ee2283d6f2815cf9b9e0ee563abc2fb3` |
| Beacon genesis state root | `0xbc1524ab2dfb1ac3efe6f7cca7eaebddda67a54fd3d8ceb6afdbfcf626394bb2` |
| Beacon deposit contract | [`0x4242424242424242424242424242424242424242`](https://mainnet.conet.network/address/0x4242424242424242424242424242424242424242) |
| Deposit per validator | **32 CNET** |
| Slot / epoch | `SECONDS_PER_SLOT=6`, `SLOTS_PER_EPOCH=32` |
| Eth1 follow | `ETH1_FOLLOW_DISTANCE=64`, `EPOCHS_PER_ETH1_VOTING_PERIOD=4` |
| Execution genesis hash | `0x97cde7aae67599cd6df35a551eb289ace211210a0d91c5456e55f0d3c9d63de1` |
| Electra (consensus) | `ELECTRA_FORK_EPOCH` **`56902`** (slot `1820864`); `ELECTRA_FORK_VERSION` `0x20000094` |
| Prague (execution) | `pragueTime` **`1792301551`** = **2026-10-18 05:32:31 UTC**, the same instant as epoch `56902` |
| Osaka (execution) | `osakaTime` **`1792329967`** = **2026-10-18 13:26:07 UTC** |
| Fulu (consensus) | `FULU_FORK_EPOCH` **`57050`** (slot `1825600`); `FULU_FORK_VERSION` `0x20000095`; the same instant as Osaka |
| Blob schedule | `prague` and `osaka`: target `6`, max `9`, `baseFeeUpdateFraction` `5007716` |
| Recommended clients | The latest official release of Geth and the latest official release of Prysm. Use the release pages, not a version pinned in this document. A [patch-geth](https://github.com/CoNET-project/patch-geth) build is needed only to re-execute blocks before Prague (section 7) |

The validators-root field is stored inside the genesis state. A beacon can
copy that field into a different state and a different sync committee. Treat
a local genesis copy as this chain only when its slot-0 header root and
genesis state root match the table.

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

### CoNET execution client and EIP-2537

Run the **latest official Geth release**. AAC proofs of a Base receipt on CoNET need the EIP-2537 BLS12-381 precompiles `0x0b`–`0x11`. Prague includes EIP-2537, and Osaka keeps it. Prague has been active since `pragueTime` (block `1762626`), and Osaka is the current fork, so the official Geth runs those precompiles natively. It executes every current block the same way as the patched build. You do not need a patch to follow the chain or to verify AAC proofs.

The fork also enables EIP-7702, EIP-6110, EIP-7002, EIP-7251, and EIP-2935. Use the published `genesis.json`; do not edit `pragueTime`, `osakaTime`, or `blobSchedule` in a local copy.

**When the patch is still needed.** Before Prague, CoNET ran Cancun with the BLS precompiles added by [patch-geth](https://github.com/CoNET-project/patch-geth), and AAC transactions called them. For example, settle `0x726426028cb6e0d71b86f3a24c33f0e62fefe5fd1fc8017d7e40f567cfc9b34d` in block `1727574` succeeded through the CoNET AAC verifier, which calls the pairing precompile `0x0f`. Under Cancun rules, the official Geth treats `0x0b`–`0x11` as empty accounts. It computes a different result for such a block and rejects it. Use the patched build only when a node re-executes blocks before `1762626`:

- a full sync from genesis (`--syncmode full`), as in [Confirm the period-18 checkpoint](l1-independent-confirmation.md), including a rebuild of an archive node; or
- a node that must return exact traces of pre-Prague BLS transactions, for example to re-index Explorer history.

An archive node that is already synced can switch to the official Geth build and keep following the chain. Only `eth_call` and traces at blocks before `1762626` that reach a BLS precompile then differ from the chain record; the settle above, for example, would trace as a failure. AAC safety does not depend on those historical answers.

The start command below uses the default sync mode (snap), which downloads a recent state and does not re-execute old blocks. CoNET peers serve the snap protocol: on 2026-10-20, two checked CoNET-operated nodes each had 11 peers, and every peer advertised `snap/1`.

**Official sources.** The Geth source is the latest official release of [go-ethereum](https://github.com/ethereum/go-ethereum/releases/latest). Binary archives are listed at [geth.ethereum.org/downloads](https://geth.ethereum.org/downloads). Each archive is named `geth-linux-amd64-<version>-<commit>.tar.gz` and has an `.asc` PGP signature beside it. Import the build-server keys linked from that page and verify the signature before you use an archive.

**Build the patched binary from source (full replay only).** Run these on a build machine, not on a live node. The patch adds the BLS implementations that already exist in the Geth release into `PrecompiledContractsCancun` only:

```bash
GETH_TAG=$(curl -fsSL https://api.github.com/repos/ethereum/go-ethereum/releases/latest \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
echo "$GETH_TAG"
git clone --depth 1 --branch "$GETH_TAG" https://github.com/ethereum/go-ethereum
git -C go-ethereum rev-parse HEAD
git clone --depth 1 https://github.com/CoNET-project/patch-geth
cd patch-geth
go run . apply --src ../go-ethereum
go run . check --src ../go-ethereum
cd ../go-ethereum
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o geth ./cmd/geth
./geth version
```

Before you build, read the `go` line in `go.mod` in the Geth source, install that Go version or a newer one from [go.dev/dl](https://go.dev/dl/), and run the commands above.

Compare the commit printed by `git rev-parse HEAD` with the commit that the GitHub release page shows for `$GETH_TAG`. They must match. The patch changes source files, not the commit, so a matching commit does not prove the patch is present. Check the patch with the `0x0b` probe in section 9.

`apply` and `check` must both exit with status 0. `apply` is safe to repeat on a newer Geth tag. If it cannot find the Cancun table, or a `bls12381*` type, it exits without writing a partial patch. If either command fails, do not build and do not edit the source by hand. Keep the last accepted binary.

**Prebuilt patched binary (full replay only).** The latest [patch-geth release](https://github.com/CoNET-project/patch-geth/releases/latest) publishes a static Linux amd64 `geth` and a `SHA256SUMS` file. Download both into the same folder and check the binary before use:

```bash
sha256sum -c SHA256SUMS
```

Use the prebuilt binary only when its patch-geth release names the same Geth release as the latest official Geth release.

Historical record: before the fork, on 2026-10-15, the checked execution clients (`38.102.126.30:8889`, `38.102.126.50` ports `8888`, `8883`, and `8884`, and `38.102.126.58:8885`) run the patched build of the Geth release current on that date. An empty `eth_call` to `0x0b` returns `invalid input length`. `rpc1.conet.network` and `publicrpc.conet.network` return the same error. Probe `0xed2E4B55152A657B43A5065a01B9655dB0033713` reports the precompile available. The earlier probe `0x864896C7dD5CA603AA11C3dC0BA329EB78Cc5F78` still returns false, because a revert with empty return data is not an empty success. Probe `0xbaff644E6C06A277AaDFde016d2eeB87AE18EB6B` is superseded: its uncapped presence check burned the transaction gas. A mixed fleet, where one client still returns empty success, is an execution fork. The CoNET checkpoint `0x52b3bc7A8c58EC64A57a62783E2e1F8CB8457b3a` stores Ethereum period 1884 and `rootReady` is true. A 0.01 Base USDC receipt in that period is covered, and the CoNET settler is installed. An empty call is still not a pairing proof.

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

### Get Prysm from the official release

Use the latest official release of [Prysm](https://github.com/OffchainLabs/prysm/releases/latest). Each binary has a `.sha256` file on that release page. Download the binaries into one folder and check them:

```bash
PRYSM_TAG=$(curl -fsSL https://api.github.com/repos/OffchainLabs/prysm/releases/latest \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
BASE=https://github.com/OffchainLabs/prysm/releases/download/$PRYSM_TAG
for b in beacon-chain validator; do
  curl -fsSL -O "$BASE/$b-$PRYSM_TAG-linux-amd64"
  curl -fsSL -O "$BASE/$b-$PRYSM_TAG-linux-amd64.sha256"
  shasum -a 256 -c "$b-$PRYSM_TAG-linux-amd64.sha256"
  install -m 0755 "$b-$PRYSM_TAG-linux-amd64" "$HOME/bin/$b"
done
```

On Linux, `sha256sum -c` does the same check. The commands above install the binaries as `beacon-chain` and `validator` in `$HOME/bin`. Put that folder on `PATH` or change the install path.

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

## 8. Network upgrades

CoNET L1 has two forks after Cancun, and both are active. Osaka / Fulu is the
current fork. Each fork has an execution-layer time and a consensus-layer
epoch. The two layers switched at the same instant:

| Upgrade | Status | Execution (`genesis.json`) | Consensus (`config.yml`) | Time (UTC) |
|---|---|---|---|---|
| Prague / Electra | Active | `pragueTime` `1792301551` | `ELECTRA_FORK_EPOCH` `56902`, `ELECTRA_FORK_VERSION` `0x20000094` | 2026-10-18 05:32:31 |
| Osaka / Fulu | Active (current) | `osakaTime` `1792329967` | `FULU_FORK_EPOCH` `57050`, `FULU_FORK_VERSION` `0x20000095` | 2026-10-18 13:26:07 |

Gloas is not scheduled. The genesis hash does not change, so the current files
describe the same chain as the earlier files. The record of each upgrade is in
[L1 network upgrades](../l1/upgrades.md).

### Osaka and Fulu: upgrade a node that is still on older files

Osaka and Fulu activated at 2026-10-18 13:26:07 UTC. The first Osaka block is
`1767139`. A node that still runs older files cannot verify blocks from that
height and stops following the chain. Upgrade it in place with the steps
below. If you run several nodes, upgrade one node at a time. Finish each node
(section 9) before you start the next.

1. Back up your current files, then download and check the current files:

   ```bash
   cd "$HOME/conet-l1"
   mkdir -p backup-pre-osaka
   cp -p genesis.json config.yml backup-pre-osaka/
   BASE=https://gitbook.conet.network/l1/network
   curl -fsSL -O "$BASE/genesis.json" -O "$BASE/config.yml" -O "$BASE/SHA256SUMS"
   grep -E ' (genesis\.json|config\.yml)$' SHA256SUMS | shasum -a 256 -c -
   ```

2. Stop geth. Re-initialize it with the new `genesis.json` on the existing
   datadir, then start it again with the flags from section 7:

   ```bash
   geth init --datadir ./execution --state.scheme=hash ./genesis.json
   ```

   The genesis hash is unchanged, so this only rewrites the stored chain
   configuration. The init log must show genesis hash `97cde7..d63de1`
   (full hash in section 3). Stop if it differs.

3. Stop the validator client, if you run one. Replace `config.yml` with the new
   file and restart the beacon with your other flags. Start the validator client
   after the beacon is synced.

4. Confirm the node is at the chain tip (section 9). Upgrade the next node
   only after this node is healthy.

Upgrade in place. Do not delete the execution or beacon datadir. Keep
`beacondata/network-keys` in place: a beacon that starts without that file
creates a new peer ID.

### Check the fork on a node

Run these on each node:

```bash
curl -s http://127.0.0.1:4100/eth/v1/beacon/states/head/fork
curl -s http://127.0.0.1:4100/eth/v1/config/spec
curl -s http://127.0.0.1:8545 \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_config","params":[]}'
```

Expect:

- the fork endpoint reports `current_version` `0x20000095`;
- the config endpoint reports `FULU_FORK_EPOCH` `57050`;
- `eth_config` reports `current.activationTime` `1792329967`, `forkId`
  `0xe59eefd1`, and no `next` fork; and
- block `1767139` has hash
  `0x20ab2d9cb6917a0b9a7c223fce7f77265e9b993711930dba5c246fdc26d2ebc2`, the same
  as on `rpc1.conet.network`.

### Prague system contracts

CoNET L1 already has the three EIP system contracts. They were deployed at
block `1758939` with their canonical keyless transactions, and they have the
same addresses, transactions, and runtime code as the Ethereum mainnet
deployments. Operators do not deploy them. Check them with `eth_getCode`:

| Contract | Address | Deployment transaction | Runtime bytes |
|---|---|---|---|
| EIP-2935 history storage | `0x0000F90827F1C53a10cb7A02335B175320002935` | `0x67139a552b0d3fffc30c0fa7d0c20d42144138c8fe07fc5691f09c1cce632e15` | 83 |
| EIP-7002 withdrawal requests | `0x00000961Ef480Eb55e80D19ad83579A64c007002` | `0x8ded54be89448d78d4bc97782c0187b099e45380ab681742f9d3754e405c2572` | 504 |
| EIP-7251 consolidation requests | `0x0000BBdDc7CE488642fb579F8B00f3a590007251` | `0x379269d571beff3ed1d8eba3abb24076a7267b0eaf0cc66d728fb0544f5a690d` | 414 |

Empty code at any of these addresses after the fork means the node is not on
this chain's state.

## 9. Verify sync

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

### BLS probe (full-replay nodes only)

At the current head, an empty call to `0x0b` fails with `invalid input length` on both the official and the patched build, because Prague provides the precompile. To check that a node runs the patched build, call `0x0b` at block `1762625` (`0x1ae541`), the last block before Prague:

```bash
curl -s http://127.0.0.1:8545 \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":"0x000000000000000000000000000000000000000b","data":"0x"},"0x1ae541"]}'
```

The patched build returns `invalid input length`, the same as `rpc1.conet.network`. The official build returns `0x`, an empty success. A node that does not keep the state of that block returns a missing-state error instead; that node does not need the patch. An empty result is never a pairing proof.

## 10. Add a validator

Validator keystores and the 32 CNET deposits do not change at the Prague or
Osaka/Fulu forks.

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

## 11. Safety boundary

- Joining does not authorize restarting another operator's geth, beacon, or
  validator.
- Do not run a full sync from genesis with the official Geth build. It
  rejects the first block before Prague that calls a BLS precompile. Use the
  patched build for that sync (section 7).
- Do not run the Osaka/Fulu files on one layer only. An execution client or
  beacon on older files cannot follow the chain past block `1767139`.
- Do not delete `beacondata/network-keys`. Without it, a beacon starts with a
  new peer ID.
- Do not wipe execution or beacon data on an active node to troubleshoot an
  unrelated application.
- Do not expose Engine API or validator secrets.
- Do not copy service units or secret files from another operator.
- Do not invent another download hostname; canonical artifacts are under
  `https://gitbook.conet.network/l1/network/`.

## Related

- [patch-geth](https://github.com/CoNET-project/patch-geth) — adds EIP-2537 to the Cancun precompile table; needed only to re-execute blocks before Prague
- [AAC proof-driven cross-chain settlement](../l1/aac-cross-chain.md)
- [Confirm the period-18 checkpoint](l1-independent-confirmation.md)
- [Validators](../l1/validators.md)
- [Network identity](../l1/chain-identity.md)
- [L1 network upgrades](../l1/upgrades.md)
- [RPC and Explorer](../l1/rpc-explorer.md)
- [Participate in mining](l1-mining.md)
- [L1 decentralization](../l1/decentralization.md)
- [`web3://` application protocol](../applications/web3-url.md)
- [L1 overlay lab — wallet-addressed geth / Prysm](conet-l0d-l1-overlay-lab.md)

## Next

[Participate in mining →](l1-mining.md)
