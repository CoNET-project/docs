# Beamio UI (open source)

**Beamio UI** is the open-source consumer interface of Beamio. It is the
application behind the [Consumer PWA](consumer.md) at
[https://beamio.ca/app/](https://beamio.ca/app/), and the same interface runs
inside the Beamio iOS and Android shells.

| | |
|---|---|
| Repository | [beamio-APP/beamio-UI](https://github.com/beamio-APP/beamio-UI) |
| Default branch | `main` |
| License | MIT |
| Product chapter | [Consumer PWA](consumer.md) |

## What the repository contains

The repository holds the Consumer PWA source: the self-custody wallet, Discover,
merchant programs and coupons, Store Credit and Reward PT, USDC payments, and
CoNET Chat messaging. It is a React and TypeScript application built with
Create React App and CRACO. It uses Ethers for chain reads and local signing,
PouchDB and IndexedDB for device-local data, and OpenPGP for CoNET messaging.

Wallet material stays on the customer device. The repository contains no
operator keys, signing secrets, or service configuration.

## Build

Requirements: Node.js 20 and Yarn.

```bash
nvm use
yarn install
yarn start          # development server
yarn build          # production build for the /app/ path
yarn build:embedded # root-path build used by the native shells
yarn test
```

A local build is for development and review. Official web releases and the
package embedded in the native shells are produced by the Beamio release
process; a local `build/` directory is not a release.

## Contributing

- Open an issue or a pull request against `main` in
  [beamio-APP/beamio-UI](https://github.com/beamio-APP/beamio-UI).
- Follow the contribution guide in the repository.
- Never include private keys, mnemonics, access passwords, or service secrets
  in issues, pull requests, logs, or screenshots.

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
That branch remains public as the historical source. Code references elsewhere
in this book that point to `SilentPassUI` `cashtree` describe that history; new
work happens in Beamio UI.
