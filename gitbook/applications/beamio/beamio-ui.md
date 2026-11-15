# Beamio UI (open source)

**Beamio UI** is the open-source consumer web application of Beamio: a React
and TypeScript progressive web app. It is the application behind the
[Consumer PWA](consumer.md) at [https://beamio.ca/app/](https://beamio.ca/app/),
and the same UI is embedded in the Beamio iOS and Android shells.

| | |
|---|---|
| Repository | [CoNET-project/beamio-UI](https://github.com/CoNET-project/beamio-UI) |
| Default branch | `main` |
| Referenced commit | [`2df450beb695063c60a33a04f83bd59d37894a24`](https://github.com/CoNET-project/beamio-UI/commit/2df450beb695063c60a33a04f83bd59d37894a24) (initial public snapshot, PWA version 0.53.0) |
| Status | **QA candidate source. NOT FROZEN.** Not a production release |
| License | MIT for the project's own source code and text ([MIT_LICENSE](https://github.com/CoNET-project/beamio-UI/blob/main/MIT_LICENSE)); see [License](#license) |
| Product chapter | [Consumer PWA](consumer.md) |

## What the repository contains

The repository contains the consumer PWA and the UI that the iOS and Android
shells load: wallet creation, recovery and account management; USDC payments
and merchant-issued store credit; merchant discovery, memberships, vouchers and
rewards; messaging through the CoNET Chat SDK (vendored in
`vendor/conet-chat-sdk`) with OpenPGP-based message handling; and voice call
screens and signalling through the CoNET Chat transport. CoNET Chat does not
use WebRTC. Feature availability depends on the deployed version, the native
bridge, and the service configuration.

It does **not** contain Beamio POS, Merchant OS, the native iOS and Android
shell projects, backend services, operator tooling, or smart contracts. Those
components have their own release processes.

The application is built with React 18, TypeScript, Create React App and CRACO.
It uses Ethers v6, IndexedDB and PouchDB for local persistence, web workers,
OpenPGP 6, and the CoNET Chat SDK as a local package. Local development needs
no production secrets.

## Build

The repository README records its checks with Node.js 22.23.3 and npm, using
`package-lock.json`. `.nvmrc` names Node.js 20, which the README marks as not
verified. `yarn.lock` is also present because `package.json` declares
`packageManager: yarn@1.22.22`; the README marks the yarn route as not verified
and uses npm.

```bash
git clone https://github.com/CoNET-project/beamio-UI.git
cd beamio-UI
nvm install 22.23.3
nvm use 22.23.3
npm ci --legacy-peer-deps
npm start
```

Without `--legacy-peer-deps`, `npm ci` stops with `ERESOLVE` on the locked
dependency set.

Tests and type check:

```bash
CI=true npm test -- --watchAll=false
npx tsc --noEmit -p .
```

The first public snapshot omits some test files and fixtures, so its test
coverage is lower than that of the internal source revision. The README lists
what is omitted and how it will be added.

Builds (script names as in `package.json`):

| Command | Output | Use |
|---|---|---|
| `npm run build` | Browser build, public path `/app` | Web deployment of the PWA |
| `npm run build:shell-embedded` | Embedded build, public path `/`, shell flag on | UI package for an iOS or Android shell |
| `npm run build:shell-qa-embedded` | Embedded build with QA identity creation enabled | QA candidate for shells; not a production build |

A local build is for development and review. Source publication, QA
acceptance, device acceptance, web deployment, and store submission are
separate stages; a public commit or a successful build does not establish any
of the later stages. For a shell release, iOS and Android embed the same UI
package; the README describes the packaging steps.

## Contributing

- Open an issue with the runtime (browser or shell), the application version,
  the expected and actual behavior, and reproduction steps.
- Submit focused changes against `main` in
  [CoNET-project/beamio-UI](https://github.com/CoNET-project/beamio-UI), and run
  the tests and the type check before you open a pull request.
- Do not include wallet secrets, recovery codes, test-account credentials,
  signing keys, or private service configuration in issues, pull requests, or
  commits. Automated tests must not use real account data, keys, or recovery
  material.

## How it relates to other Beamio components

| Component | Relationship |
|---|---|
| **Consumer app** (iOS, Android, web) | Beamio UI *is* the consumer interface. The native shells load the same UI in a WebView and reach native features through a bridge. Changing this repository alone does not replace a native SDK or a store binary. |
| **[Beamio POS](pos.md)** | A separate terminal application for authorized merchant staff. It is not part of Beamio UI. Consumers present cards, coupons, and payment requests that POS reads. |
| **[Merchant OS](merchant-os.md)** | A separate merchant control plane at [biz.beamio.ca](https://biz.beamio.ca). Merchant programs created there appear to consumers in Beamio UI. |
| **Beamio API** | Beamio UI calls the application API for gas-sponsored relays, search, and program data. The API source is listed on [Open source](../../open-source.md#beamio). |
| **[CoNET Chat SDK](https://github.com/CoNET-project/chat-sdk)** | Vendored in the repository under `vendor/conet-chat-sdk`. See the [chat developer guide](../../l0/chat-developer-guide.md). |
| **Smart contracts** | Consumer Smart Wallets, merchant programs, and Reward PT live on CoNET L1; see [beamio-APP/BeamioContract](https://github.com/beamio-APP/BeamioContract). |

## License

The project's own source code and text are licensed under the MIT License; the
full text with the existing copyright notice is in `MIT_LICENSE`. Image files
in the repository are not covered by the MIT License. Third-party files keep
their own notices, as listed in the repository README.

## History

The repository was published as a clean snapshot of the reviewed consumer PWA
source, without its git history; `PROVENANCE.md` in the repository records the
source revision and file scope. Until November 2026, the Consumer PWA was
developed on the `cashtree` branch of
[CoNET-project/SilentPassUI](https://github.com/CoNET-project/SilentPassUI/tree/cashtree).
That branch remains public as the historical source. The separate `cashtrees`
branch of the same repository holds Merchant OS and is not part of Beamio UI.
Code references elsewhere in this book that point to `SilentPassUI` `cashtree`
describe that history; new work happens in Beamio UI.
