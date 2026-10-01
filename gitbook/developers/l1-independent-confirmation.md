# Confirm the CoNET period-18 checkpoint

**Evidence level: Production reference.** This page is a complete join for an
operator who does not administer the existing CoNET hosts. It uses the
published genesis, a local geth, and a local Prysm beacon. The confirmation
is the local beacon's own answer for slot **155646**.

Follow [Run an L1 node](l1-node.md) for the network facts. This page repeats
the commands so the join can be completed from here.

## What counts as your confirmation

Your beacon HTTP API on `127.0.0.1:4100` must return:

| Field | Required value |
|---|---|
| Slot | `155646` |
| Block root (`data.root`) | `0x442a5f8c64592b4e45820e0e27398f0532b15a2e22456bc02f8c74df8b591336` |
| State root (`header.message.state_root`) | `0x70001a2f373450a6057e506c89bb7a3b502c58bb7ae6ed97cfeea45f590a1410` |
| `peer_id` | The identity of **this** beacon |

A `peer_id` already used by the publishing operator does not add an
independent confirmation. Those consensus identities are:

| Host | Consensus `peer_id` |
|---|---|
| `216.225.202.22` | `16Uiu2HAmCtPRBmiYPNcfwscvKzhDqsFwVtm2DmsMZCvtR2rHgDtA` |
| `216.225.197.3` | `16Uiu2HAmQgiLAC8bfpYKVt8WakbkC3wvdG8VwGUc4KQKXfM53t7g` |
| `216.225.202.82` | `16Uiu2HAmDJCHuVkXtkPrrL8YykQ9gFZnQkR9Q6WjZZUrmueohPfd` |
| `70.35.205.77` | `16Uiu2HAmAoxo8HWa724Vm6zPMJNn1uXv2Vtpbjm9vLSJMA3KnjgZ` |

DHT identities on port `4110` are a different set. Do not mix them with the
beacon `peer_id` from port `4100`.

## Machine

Use a host you administer, with at least **8 CPU cores**, **16 GiB RAM**, and
**1 TiB** free disk. A 1 vCPU VPS cannot hold geth. Open inbound **8400/tcp**,
**8400/udp**, **4200/tcp**, and **4300/udp** on the host firewall and the
cloud security group. Bind geth HTTP, the Engine API, and the beacon REST API
to `127.0.0.1`.

## 1. Download genesis

```bash
BASE=https://gitbook.conet.network/l1/network
mkdir -p "$HOME/conet-l1" && cd "$HOME/conet-l1"
curl -fsSL \
  -O "$BASE/genesis.json" \
  -O "$BASE/genesis.ssz" \
  -O "$BASE/config.yml" \
  -O "$BASE/SHA256SUMS"
shasum -a 256 -c SHA256SUMS
openssl rand -hex 32 > jwtsecret
chmod 600 jwtsecret
```

Expected checksums:

| File | SHA-256 |
|---|---|
| `genesis.json` | `bc8e77990a5b76d75b6a2041a2ae4d69c9cda03d120b1434b8ce3e11296fde60` |
| `genesis.ssz` | `ae0a63e7bf175bb4312d5b728ff1eced7ceb4286ff5d7074cecbfa21dfd7fb46` |
| `config.yml` | `4bda580c4cfec801ecaed6fa04ad38bb9f1e941833fa7237ed5c6327f3cfbe24` |

Stop if a checksum fails. Do not edit these files. `config.yml` already sets
`EPOCHS_PER_ETH1_VOTING_PERIOD: 4`. Prysm reads that value from the file.

## 2. Start geth 1.17.5

Use geth **1.17.5**. Older geth rejects the published genesis because the
Cancun `blobSchedule` entry is missing. Initialize once, then start it in its
own terminal. Replace `<YOUR_PUBLIC_IP>`.

```bash
cd "$HOME/conet-l1"
geth init --datadir ./execution --state.scheme=hash ./genesis.json
```

```bash
cd "$HOME/conet-l1"
geth \
  --datadir ./execution \
  --state.scheme=hash \
  --networkid 224422 \
  --syncmode full \
  --gcmode full \
  --port 8400 \
  --discovery.port 8400 \
  --nat extip:<YOUR_PUBLIC_IP> \
  --bootnodes "enode://e5fe89d9ad924db6e4699480242a12fccba2c00e35772db706e46190c0ded9bb2b7e0d996826f5e46d369e01336213ef263c5038f94552e5f5e6e8ec76573a3f@38.102.126.30:8400,enode://d9243095bca94720f88d38c93ae4ccefc8b67651c66b4c93c915f845f6abfd39a091465db02db32b1a5b8061566c1558d2e6842f75620bf533480bab8a180168@38.102.126.50:8400,enode://8e09d44bb4c29543a172e53dd8a74677a2a63d3d98a3d530f9d8b6f6bd6802a542f5b79d509ff737a9a764a66ab44a81403597cb50e350178ddd91f487e28f2d@216.225.202.22:8400,enode://f1e249c97ce861441b3bd4832213cc634dd5c23d1a8722cd9c1aea28492779f6b64e012e8d97d56006d69be5224903ea5a787d8af68e9542db82ac1f76491dd5@216.225.202.82:8400" \
  --http --http.addr 127.0.0.1 --http.port 8545 --http.api eth,net,web3 \
  --authrpc.addr 127.0.0.1 --authrpc.port 8551 \
  --authrpc.jwtsecret ./jwtsecret \
  --authrpc.vhosts localhost
```

Geth stays at block 0 until the beacon sends execution payloads. That is
expected. Do not point this geth at another operator's Engine API, and do
not import another operator's datadir.

## 3. Start Prysm v7.1.8

```bash
cd "$HOME/conet-l1"
curl -fsSL https://raw.githubusercontent.com/OffchainLabs/prysm/master/prysm.sh -o prysm.sh
chmod +x prysm.sh
```

Fetch live beacon ENRs, then start the beacon. The checkpoint URL only helps
the node reach the current tip. Slot 155646 still has to be stored locally
before the confirmation commands succeed.

```bash
cd "$HOME/conet-l1"
ENR=$(curl -fsS http://216.225.202.22:4100/eth/v1/node/identity \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['enr'])")
USE_PRYSM_VERSION=v7.1.8 ./prysm.sh beacon-chain \
  --accept-terms-of-use \
  --chain-id=224422 \
  --genesis-state=./genesis.ssz \
  --chain-config-file=./config.yml \
  --checkpoint-sync-url=http://216.225.202.22:4100 \
  --genesis-beacon-api-url=http://216.225.202.22:4100 \
  --execution-endpoint=http://127.0.0.1:8551 \
  --jwt-secret=./jwtsecret \
  --deposit-contract=0x4242424242424242424242424242424242424242 \
  --p2p-host-ip=<YOUR_PUBLIC_IP> \
  --p2p-tcp-port=4200 \
  --p2p-udp-port=4300 \
  --rpc-host=127.0.0.1 \
  --grpc-gateway-host=127.0.0.1 \
  --grpc-gateway-port=4100 \
  --bootstrap-node="$ENR"
```

Use the beacon identity on port `4100`. That ENR already contains the beacon
P2P address. Do not substitute a DHT peer id from port `4110`. Add more live
beacon ENRs from port `4100` with repeated `--bootstrap-node` flags. Keep the
beacon running. Historical sync back to slot 155646 can take about a day
after the tip is reached.

## 4. Read the local confirmation

Run this on the same machine. A 404 on the header means slot 155646 is not
in the local database yet.

```bash
curl -s http://127.0.0.1:4100/eth/v1/node/identity
curl -s http://127.0.0.1:4100/eth/v1/beacon/headers/155646
curl -s http://127.0.0.1:4100/eth/v1/node/syncing
```

Send both JSON documents to the operator who invited you. The identity
`peer_id` must be the beacon you started, and the header must show slot
`155646`, block root
`0x442a5f8c64592b4e45820e0e27398f0532b15a2e22456bc02f8c74df8b591336`, and
state root
`0x70001a2f373450a6057e506c89bb7a3b502c58bb7ae6ed97cfeea45f590a1410`.

The inviting operator sees a new consensus node when that `peer_id` appears
in a public beacon's peer list and is absent from the operator table above.
The two JSON documents are the checkpoint confirmation.

## Optional Lighthouse build

Stock Lighthouse hashes this chain with a 64-epoch eth1 voting period and
rejects a valid CoNET checkpoint. Prysm does not need that change. Use
Lighthouse only when you want a second client.

Clone tag `v5.3.0` and change the first `MainnetEthSpec` block in
`consensus/types/src/eth_spec.rs`:

```rust
type EpochsPerEth1VotingPeriod = U4;
type SlotsPerEth1VotingPeriod = U128; // 4 epochs * 32 slots
```

Leave `MinimalEthSpec` unchanged. Build `lighthouse`, then run it with
`--testnet-dir` containing `genesis.ssz` and `config.yml`,
`--execution-endpoint http://127.0.0.1:8551`, `--execution-jwt ./jwtsecret`,
`--checkpoint-sync-url http://216.225.202.22:4100`, `--genesis-backfill`,
and a live `--boot-nodes` ENR. Read the same local REST paths on port 5052
if you keep Lighthouse's default HTTP port.

### Operating a Lighthouse node on this chain

These points come from a node that sat at `peers: 0` while a second node with
the same binary held 16 peers.

- **Keep default discovery and the default peer count.** Use one boot ENR.
  Do not pin a short peer list with `--libp2p-addresses` or `--trusted-peers`.
  Pinning concentrates sync load on a few Prysm peers.
- **Backfill is paced by Prysm, not by you.** After checkpoint sync Lighthouse
  backfills history, with or without `--genesis-backfill`. A Prysm peer
  answers `rate limited` when asked for more than about one 32-block batch per
  30 s, counts that against your peer id, and then replies `Goodbye` on every
  later connection. Spread backfill over many peers. If you run few peers, cap
  the outbound rate, for example
  `--self-limiter-protocols beacon_blocks_by_range:32/30`. The protocol name
  must be `beacon_blocks_by_range`; the binary refuses other spellings.
- **Do not restart in a loop or delete the peer key to "fix" it.** Every restart
  repeats the start-up request burst. The peer id is kept in
  `<datadir>/beacon/network/key`; a fresh id is struck again if the load is the
  cause.
- **Share an IP with Prysm and expect some refusals.** A Prysm instance that
  does not list your IP in `--p2p-colocation-whitelist` rejects a second peer
  from that IP with `Goodbye(Fault)`. That is harmless while you keep at
  least eight other peers. Ask the hub operator to whitelist the IP.
- **Read the debug log.** The reasons for a dropped peer are in
  `<datadir>/beacon/logs/beacon.log`, not in the journal.
- **Judge a change over 15 minutes.** Peers can rise at start and fall minutes
  later. Healthy means peers stay at eight or more, `sync_distance` is 0 to 2,
  and there are no `rate limited` replies.

## Do not

- Copy another operator's chain data, JWT, or beacon database.
- Attach your beacon to another host's Engine API.
- Restart or wipe a node you do not administer.
- Treat a peer-list entry alone as the slot 155646 confirmation.

## Related

- [Run an L1 node](l1-node.md)
- [AAC proof-driven cross-chain settlement](../l1/aac-cross-chain.md)
