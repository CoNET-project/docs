# `conet-l0d` — Linux runtime for `web3://`

> **Removed from CoNET-SI (2026-10-31).** The exclusive L0 attachment primitives this page relies on (`l0_listen`, `l0_connect`, `mining` with `listenKind: "l0"`, and idle-L0 delivery of mailbox work) are no longer implemented by SI; `l0_listen` / `l0_connect` close the connection. The rest of this page is kept as a historical reference and does not describe current network behavior.

**Maturity: Under development.**

`conet-l0d` is the Linux server/client runtime for the
[`web3://` Application Protocol](../l0/web3-application-protocol.md). It publishes
local services through CoNET Layer Minus and opens remote wallet-addressed
services as local endpoints.

Product overview: [`web3://` wallet-addressed applications](../applications/web3-url.md)  
Protocol contract: [`web3://` Application Protocol](../l0/web3-application-protocol.md)  
Source: [CoNET-project/CoNET-L0D](https://github.com/CoNET-project/CoNET-L0D)  
Crate design: [whitepaper](https://github.com/CoNET-project/CoNET-L0D/tree/main/whitepaper)

## Runtime roles

| Role | Command/config | Use |
|---|---|---|
| Persistent-stream server (L1 overlay hub primary) | `--proxyDuplex HOST:PORT` / `[[l0.proxy_duplex]]` | Publish a persistent bidirectional TCP service |
| Persistent-stream client (L1 overlay spoke primary) | `--clientDuplex web3://HOST:PORT` / `l0.client_duplex` | Expose remotes through `127.0.0.1`; the same logical port may map to several remotes |
| Request/response server | `--proxy HOST:PORT` / `[[l0.proxies]]` | Publish a bounded local request/response service (not the L1 geth/beacon primary path) |
| Signed Web gateway | `gateway` + `[gateway]` | Map signed GET/HEAD requests to a loopback HTTP origin |

Linux servers and Linux clients can use this binary. Windows, macOS, Android,
iOS, and browser applications implement the same protocol in client code and
do not require `conet-l0d`.

## Build

```bash
git clone https://github.com/CoNET-project/CoNET-L0D.git
cd CoNET-L0D
cargo test
cargo build --release
sudo install -m 0755 target/release/conet-l0d /usr/local/sbin/conet-l0d
```

Validate the example before enabling any route:

```bash
conet-l0d check-config --config config/conet-l0d.example.toml
```

## Commands

| Command | Purpose |
|---|---|
| `check-config` | Validate TOML without opening a network session |
| `resolve` | Parse a `web3://` locator and show a configured mapping when available |
| `start` | Run configured server proxies and client endpoints |
| `gateway` | Run the signed GET/HEAD application gateway |
| `status` | Print recorded runtime state |
| `stop` | Signal the recorded process and clean runtime state |
| `teardown` | Remove stale daemon-owned runtime state |

```bash
conet-l0d resolve \
  'web3://0x1111111111111111111111111111111111111111:9443' \
  --config /etc/conet-l0d.toml

conet-l0d start --config /etc/conet-l0d.toml
conet-l0d status --config /etc/conet-l0d.toml
conet-l0d stop --config /etc/conet-l0d.toml
```

CLI endpoint flags override the corresponding endpoint lists:

```bash
conet-l0d start \
  --config /etc/conet-l0d.toml \
  --proxyDuplex 127.0.0.1:9443

conet-l0d start \
  --config /etc/conet-l0d.toml \
  --clientDuplex 'web3://ExactPeer.web3:9443'
```

`--proxy` and `--proxyDuplex` are repeatable. `--clientDuplex` is repeatable.
The same logical port may map to several remotes.

`--debugSI` (optional SI URL, domain, or route key id) pins exclusive/temp
mailbox B for laboratory isolation. Without the flag, mailbox B is a random
on-chain SI. Entry A/C stays random and must not equal B.

## Locator

The application endpoint grammar is:

```text
web3://0x<40-hex>:<port>
web3://<exact-tag>.web3:<port>
```

Examples:

```text
web3://0x1111111111111111111111111111111111111111:443
web3://ExampleMerchant.web3:9443
```

An exact BeamioTag match is required. Never select a non-exact search result
or `results[0]`.

## Base configuration

Copy `config/conet-l0d.example.toml` and keep L0 disabled until the real
wallet identities and key files are configured:

```toml
state_path = "/run/conet-l0d/state.json"

[identity]
locator = "web3://0x1111111111111111111111111111111111111111/app"

[l0]
enabled = false
rpc = "https://rpc1.conet.network"
address_pgp = "0x684b0ac760cEE9c9b85de36d69746420648Cf9e2"
route_register_url = "https://beamio.app/api/regiestChatRoute"
si_pool_from_contract = true
# Optional overrides only when si_pool_from_contract = false:
# entries = []
# listen_entries = []
```

## SI entry discovery (GuardianNodesInfoV6)

Default discovery does **not** depend on a static TOML `entries` /
`listen_entries` list.

With `si_pool_from_contract = true` (default), startup pages
GuardianNodesInfoV6 (`0xBC6b53065b5647261396d002bDBA0d3396E0722f`) via
`l0.rpc` (`rpc1` or `publicrpc`) using `getAllNodes` — the same path as the
client UI / SilentPass: load all nodes → local pool → periodic refresh.

When listen / POST / an `l0_connect` pipe needs an SI entry:

1. **Random**-pick a candidate from the pool.
2. Soft-qualify with a short TCP `:80` probe to `http://{domain}.conet.network`.
3. Hand the URL back to the caller; on failure (including SI `pool_full`) cool
   the host down and pick another.

Do not invent a domain. Outbound application delivery uses an entry distinct
from destination mailbox B; mailbox receive uses another healthy entry
distinct from B. Static `entries` / `listen_entries` remain only as an
explicit override when `si_pool_from_contract = false`. Gateway mode still
uses its own `listen_entries` / `post_entries` (independent of the overlay
SI pool).

Live occupancy commands are **`l0_listen`** and **`l0_connect`** only
(`listenKind: "l0"`). Do **not** send the retired `command: "mining"` +
`listenKind: "l0"` variant. Chat offers still use `mining` +
`listenKind: "chat"` (**proxy hubs** need this for inbound `duplex_offer`;
pure `--clientDuplex` spokes no longer open a static Chat SSE). Never send
`mining` + `listenKind: "duplex"`, and never treat SI `duplex_*` /
`p2p_stream_*` / `listenKind: "l1p2p"` as current SI.

## Server profile

Publish a local request/response service:

```toml
[l0]
enabled = true
# identity, key files, and existing entries omitted

[[l0.proxies]]
host = "127.0.0.1"
port = 8080
```

Publish a persistent bidirectional service:

```toml
[[l0.proxy_duplex]]
host = "127.0.0.1"
port = 9443
```

The host and port identify the local origin. Keep that service on loopback or
a private network unless it is intentionally public by another route.

Each accepted duplex connection receives its own session, temporary
communication identity, queue, occupied line, and upstream TCP socket.
Several connections may use the same logical port, but they do not share
socket or identity state.

## Client profile

Open remote duplex services as local TCP endpoints:

```toml
[l0]
enabled = true
# identity, key files, and existing entries omitted

client_duplex = [
  "web3://ExactPeer.web3:9443",
  "web3://0x2222222222222222222222222222222222222222:7443",
]
```

The same logical port may map to several remotes. Use two entries for two
hubs on `:8400`, or `:8400` and `:4200` for two services. The same
`(host, PORT)` listed twice is rejected.

The Linux runtime binds each line on `127.0.0.1`. The preferred listener is
the logical port. If that port is already occupied, the runtime walks
`port + 10000`, `port + 20000`, and so on. An optional `@LOCAL` suffix is a
Linux bind pin only — it is not part of the public `web3://` locator
contract. Prefer the protocol form `web3://0x…:8400`. Use `@18400` only when
the local application must hard-code a loopback port. Read the startup log
or `status` and configure the local application with the actual endpoint.

`@LOCAL` does **not** change the offer. `web3://0x66dC…:8400@18400` still
offers remote service `8400`. If this host also publishes `--proxyDuplex`
on `8400`, inbound offers to **this** billing wallet use the proxy origin.
Outbound client sessions to **another** wallet's `8400` must not attach
that proxy drain. A current Linux implementation still keys
`maybe_start_proxy_drain` by the logical port integer; that is a runtime
defect, not a reason to put `@18400` into the public URI.

One host may be **both** a client and a published wallet. Outbound
`client_duplex` lists only the wallets that host must join. Inbound
`proxy_duplex` publishes the local origin so **any** conforming client can
dial this host's billing EOA. The host does not add those callers to
`client_duplex` and does not dial them back. Laboratory evidence:
[L1 overlay lab](conet-l0d-l1-overlay-lab.md).

## Wallet and key roles

The runtime separates:

| Role | Purpose |
|---|---|
| Application target EOA | Stable destination in the `web3://` locator |
| Routing EOA + PGP | Communication identity registered through AddressPGP |
| Billing EOA | Signs and settles paid mailbox/channel commands |
| Temporary line identity | Isolates one accepted duplex connection |

For a server profile:

```toml
[l0]
billing_eoa = "0x..."
billing_eth_key_file = "/etc/conet-l0d/billing.eth"
billing_pgp_file = "/etc/conet-l0d/billing-pgp.asc"

routing_eoa = "0x..."
routing_key_file = "/etc/conet-l0d/routing-pgp.asc"
routing_eth_key_file = "/etc/conet-l0d/routing.eth"
mailbox_route_pgp_file = "/etc/conet-l0d/mailbox-route.asc"
```

Keep secret files local, mode `0600`, and outside the repository. Do not pass
private keys in shell arguments, environment variables, logs, or service
unit text.

Multi-port servers may use `[[l0.channels]]` to assign one communication
identity per logical port. This avoids competing exclusive receive sessions
for one routing wallet.

## Persistent-stream bootstrap

The implemented sequence is:

1. Accept one local TCP connection.
2. Create and register a temporary communication route for that line.
3. Wait until AddressPGP returns the expected route key.
4. Establish the temporary receive session.
5. Send a signed `duplex_offer`, optionally with the first application bytes.
6. The remote server validates billing identity, target, and logical port.
7. The remote server opens exactly one configured upstream socket.
8. `duplex_accept` is mailbox work to the initiator temp mailbox (inner user PGP, no `NoPush`). SI copies it onto idle `l0_listen` by `userPgpKeyId`.
9. The initiator occupies the responder mailbox; only then the responder reverse-occupies. Occupying the initiator SSE first drops the accept.
10. If the proxy temporary line fails, the hub posts `duplex_reject` to the client L0d request listen and does not retry that wallet. The client application reconnects with a new offer.
11. Both sides carry ordered encrypted frames on the occupied pipes.
12. Close or retry that line independently.

Registration HTTP `200` is queue admission only. AddressPGP visibility and
the receive session must be ready before application bytes are treated as
deliverable.

The runtime uses existing Layer Minus listen, routing, and occupied-line
primitives. It does not require a new SI command family.

## Signed gateway

Use a dedicated config for the gateway:

```toml
[gateway]
rpc = "https://rpc1.conet.network"
upstream = "http://127.0.0.1:8080"
listen_entries = []
post_entries = []
routing_eoa = "0x..."
routing_key_file = "/etc/conet-web3-gateway/gateway-pgp.asc"
routing_eth_key_file = "/etc/conet-web3-gateway/gateway.eth"
mailbox_route_pgp_file = "/etc/conet-web3-gateway/mailbox-route.asc"
allowed_methods = ["GET", "HEAD"]
max_body_bytes = 8388608
request_timeout_seconds = 15
```

Then run:

```bash
conet-l0d gateway --config /etc/conet-l0d-gateway.toml
```

The gateway validates request type, expiry, target, method, path, and
EIP-191 signer; connects only to its configured loopback origin; and encrypts
the response to the caller's registered user PGP key.

## systemd

The repository contains:

- `systemd/conet-l0d.service`
- `systemd/conet-l0d-gateway.service`

Install the binary, config, and restricted key files before enabling a unit.
Use a dedicated Unix user where practical. The daemon must not run as the
same account that owns validator keys or unrelated production secrets.

## Verification

Check evidence at each layer:

| Layer | Evidence |
|---|---|
| Configuration | `check-config` succeeds |
| Identity | exact EOA/tag and AddressPGP route are visible |
| Entry path | SI pool (or override list) returns a healthy entry that accepts the encrypted request |
| Session | offer and accept refer to the expected wallet, port, and session |
| Data | frame counters continue in both directions |
| Origin | configured local service accepts the upstream connection |
| Application | correlated decrypted response or application protocol handshake succeeds |

A running process or entry HTTP `200` alone is not an end-to-end test.

Laboratory evidence that unmodified geth / Prysm can peer through this
runtime by **wallet locator** (not public `IP:port`) is recorded in
[L1 overlay lab — wallet-addressed geth / Prysm](conet-l0d-l1-overlay-lab.md).
That page is a lab review, not the public L1 join path.

## Failure order

1. Validate the exact locator and wallet identity.
2. Confirm the routing and mailbox PGP records.
3. Confirm the SI pool refreshed from GuardianNodesInfoV6 (or that static
   override entries are existing, healthy Guardians when the pool is off).
4. Confirm the local client endpoint or server origin is listening.
5. Match offer, accept, and session IDs.
6. Confirm encrypted frames flow both ways.
7. Inspect the origin application's own protocol result.

Do not convert a timeout or routing failure into a successful empty result.

## Related

- [`web3://` product and platform overview](../applications/web3-url.md)
- [`web3://` Application Protocol contract](../l0/web3-application-protocol.md)
- [L0 development](l0.md)
- [How to use Layer Minus](../l0/using-l0.md)
- [L1 overlay lab — wallet-addressed geth / Prysm](conet-l0d-l1-overlay-lab.md)
