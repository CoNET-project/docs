# Beamio UI (open source)

**Beamio UI** is the open-source consumer interface of Beamio. It is the
application behind the [Consumer PWA](consumer.md) at
[https://beamio.ca/app/](https://beamio.ca/app/), and the same interface runs
inside the Beamio iOS and Android shells.

| | |
|---|---|
| Repository | [CoNET-project/beamio-UI](https://github.com/CoNET-project/beamio-UI) |
| Default branch | `main` |
| License | MIT |
| Product chapter | [Consumer PWA](consumer.md) |

## What the repository contains

The repository holds the consumer PWA only: wallet creation and recovery,
merchant discovery, memberships, coupons and rewards, merchant-issued store
credit, supported USDC payments, CoNET Chat messaging, and voice and video
calling over the CoNET Chat transport (not WebRTC). It is a React 18 and
TypeScript application built with CRACO. It uses Ethers v6, IndexedDB and
PouchDB for device-local data, web workers, and the CoNET Chat SDK with OpenPGP.

Beamio POS, Merchant OS, the native shell projects, backend services, and smart
contracts are separate components with their own repositories and release
processes. Local development needs no production operator keys or native
signing credentials.

## Build

Use the toolchain declared by the checked-out revision (currently Node.js 20
in `.nvmrc` and Yarn Classic 1.22.22).

```bash
git clone https://github.com/CoNET-project/beamio-UI.git
cd beamio-UI
nvm use
yarn install --frozen-lockfile
yarn start                          # local development
CI=true yarn test --watchAll=false  # tests
yarn tsc --noEmit                   # type check
yarn build                          # browser build
yarn build:shell-embedded           # root-path build for a native shell
```

`yarn build` produces the browser application served under the `/app/` path
of the Beamio web origin. `yarn build:shell-embedded` produces the same
interface with a root public path, so that a native shell can serve it locally
from its embedded UI package. Use the scripts declared in the `package.json` of
the revision you check out.

A local build is for development and review. Official web releases and the
package embedded in the native shells are produced by the Beamio release
process; a local `build/` directory is not a release.

## Contributing

- Open an issue or a pull request against `main` in
  [CoNET-project/beamio-UI](https://github.com/CoNET-project/beamio-UI).
- Describe the affected runtime, application version, expected behavior, and
  reproduction steps, and include the relevant checks with a change.
- Never include wallet secrets, recovery codes, test-account credentials,
  signing files, or private service configuration in issues, pull requests,
  or commits. Use disposable test accounts, not a personal wallet.

## How it relates to other Beamio components

| Component | Relationship |
|---|---|
| **Consumer app** (iOS, Android, web) | Beamio UI *is* the consumer interface. The native shells load the same PWA build; native code adds platform features such as secure key storage, notifications, and store distribution. |
| **[Beamio POS](pos.md)** | A separate terminal application for authorized merchant staff. It is not part of Beamio UI. Consumers present cards, coupons, and payment requests that POS reads. |
| **[Merchant OS](merchant-os.md)** | A separate merchant control plane at [biz.beamio.ca](https://biz.beamio.ca). Merchant programs created there appear to consumers in Beamio UI. |
| **Beamio API** | Beamio UI calls the application API for gas-sponsored relays, search, and program data. The API source is listed on [Open source](../../open-source.md#beamio). |
| **[CoNET Chat SDK](https://github.com/CoNET-project/chat-sdk)** | The messaging model Beamio UI follows. See the [chat developer guide](../../l0/chat-developer-guide.md). |
| **Smart contracts** | Consumer Smart Wallets, merchant programs, and Reward PT live on CoNET L1; see [beamio-APP/BeamioContract](https://github.com/beamio-APP/BeamioContract). |

## History

Until November 2026, the Consumer PWA was developed on the `cashtree` branch
of [CoNET-project/SilentPassUI](https://github.com/CoNET-project/SilentPassUI/tree/cashtree).
That branch remains public as the historical source. The separate `cashtrees`
branch of the same repository holds Merchant OS and is not part of Beamio UI. Code references elsewhere
in this book that point to `SilentPassUI` `cashtree` describe that history; new
work happens in Beamio UI.
