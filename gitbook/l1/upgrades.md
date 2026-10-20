# L1 network upgrades

**Evidence level: Production reference.** This page records the forks applied to
the CoNET L1 chain (`chainId` **224422**) and what each one changed. The
operator steps are in [Run an L1 node](../developers/l1-node.md), section 8.

## Timeline

| Upgrade | Execution layer | Consensus layer | Time (UTC) | Status |
|---|---|---|---|---|
| Cancun | `shanghaiTime` = `cancunTime` = `1781376367` | Deneb (`DENEB_FORK_EPOCH` `0`) | Genesis, 2026-06-13 18:46:07 | Active |
| Prague / Electra | `pragueTime` `1792301551` | `ELECTRA_FORK_EPOCH` `56902` | 2026-10-18 05:32:31 | Active |
| Osaka / Fulu | `osakaTime` `1792329967` | `FULU_FORK_EPOCH` `57050` | 2026-10-18 13:26:07 | Active |
| Gloas | — | `GLOAS_FORK_EPOCH` disabled | — | Not scheduled |

The two layers switch at one instant. CoNET uses 6-second slots, and
`genesis_time` is `1781376367`. Epoch `57050` starts at slot `1825600`, which
is `1792329967` seconds after the Unix epoch, the same as `osakaTime`.

## Prague / Electra

- Execution: `pragueTime` `1792301551`, with the blob schedule `prague` (target
  `6`, max `9`, `baseFeeUpdateFraction` `5007716`).
- Consensus: `ELECTRA_FORK_EPOCH` `56902` (slot `1820864`) and
  `ELECTRA_FORK_VERSION` `0x20000094`.
- The three EIP system contracts were already present at their canonical
  addresses. See [Run an L1 node](../developers/l1-node.md), section 8.

## Osaka / Fulu

- Execution: `osakaTime` `1792329967`, with a blob schedule entry `osaka` that
  has the same values as `prague`.
- Consensus: `FULU_FORK_EPOCH` `57050` and `FULU_FORK_VERSION` `0x20000095`.
- The genesis hash is unchanged (`0x97cde7…d63de1`), so the upgrade changes the
  chain configuration only. The published files for this upgrade are:

| File | SHA-256 |
|---|---|
| `genesis.json` | `e9889e1970251a145a2199caa9b889fd8868ab132372a69ff171b14476ae0b43` |
| `config.yml` | `51c2c4dac8c50b7e3fa7b4be2a68be5ac813da8aa7389193d1785b1bbdae4840` |
| `genesis.ssz` | `ae0a63e7bf175bb4312d5b728ff1eced7ceb4286ff5d7074cecbfa21dfd7fb46` (unchanged) |

### Activation

Osaka and Fulu are active on the CoNET L1 mainnet. Osaka is the current
execution fork, and Prague is no longer the current fork.

- The first Osaka block is `1767139`
  (`0x20ab2d9cb6917a0b9a7c223fce7f77265e9b993711930dba5c246fdc26d2ebc2`), with
  timestamp `1792329967`, equal to `osakaTime`. The previous block, `1767138`,
  has timestamp `1792329961` and is the last Prague block.
- On 2026-10-20, `rpc1.conet.network` and `publicrpc.conet.network` both
  returned the same hash for block `1767139`. Both returned an `eth_config`
  with `current.activationTime` `1792329967`, `forkId` `0xe59eefd1`, and no
  `next` fork.
- The chain kept producing blocks after the fork. Both endpoints reported head
  blocks above `1792000` on 2026-10-20.

To check a node yourself, see [Run an L1 node](../developers/l1-node.md),
section 8.

## Rollout record

The CoNET-operated nodes were upgraded in a rolling order, one node at a time.
Each step checked the fork configuration, the peer identity, the sync state,
and the execution block hash at a common height against another node. At
11:07 UTC on 2026-10-18, the twelve checked CoNET-operated endpoints reported
the same execution block hash at height `0x1af100` and Fulu epoch `57050`.

Two lessons from the rollout apply to every operator:

- **Restarting a node can stop a DHT hub on the same host.** After every node
  restart, check that the local DHT ENR endpoint on `:4110` answers:

  ```bash
  curl -s http://127.0.0.1:4110/eth/v1/node/identity
  ```

- **Keep `beacondata/network-keys`.** A beacon that starts without the file
  creates a new peer ID. Peers that refer to the old ID then lose the route.

- **Bootstrap from several live DHT ENRs.** One bootstrap hub is not enough
  during an upgrade window, because a restarting node needs at least one reachable
  hub to find peers.

## Related

- [Network identity](chain-identity.md) — chain identifiers and fork schedule
- [Validators](validators.md) — validator-node readiness before a fork
- [Run an L1 node](../developers/l1-node.md) — current files and the upgrade steps
- [Confirm the period-18 checkpoint](../developers/l1-independent-confirmation.md)

## Next

[Validators →](validators.md)
