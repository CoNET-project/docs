# Web3 Browser + Wallet

**Maturity: Under development (Phase 0 scaffold).** None of the capabilities on this page is implemented yet; all of them are planned. Cross-platform **native shell + local PWA**
that browses and publishes `web3://` applications, can run a TypeScript SI
subset (entry / forward / storage / SaaS), and can attach as a CoNET-DLE
**L2 on-demand** miner. Capability **④** is not yet product-locked.

**One-line definition:** a wallet-first Web3 browser that hosts local sites
and DePIN runtimes over a native socket bridge, without Electron.

Source scaffold: `src/web3-browser/` in the Beamio monorepo  
Protocol: [`web3://`](web3-url.md) · [Application Protocol](../l0/web3-application-protocol.md)  
L2: [CoNET-DLE / L2](../l2/README.md) (on-demand miner role only)

## Product model

```text
┌─────────────────────────────────────┐
│ PWA UI (English) + Wallet           │
├─────────────────────────────────────┤
│ TypeScript: SI · web3Host · L2 miner│
├─────────────────────────────────────┤
│ IndexedDB (site files)              │
├─────────────────────────────────────┤
│ Native bridge: TCP/UDP · host bind  │
├─────────────────────────────────────┤
│ iOS / Android / Desktop WebView     │
└─────────────────────────────────────┘
```

| Role | Behavior |
|---|---|
| **Browse** | Open `web3://wallet:port` apps via Layer Minus |
| **Publish** | Store site files in IndexedDB; bind host via native bridge |
| **SI** | Optional entry / forward / storage / SaaS → earn GB |
| **L2 on-demand** | Wait-hooks to archives; **not** archive BFT producer |

## Platform choices

| Platform | Shape |
|---|---|
| **Mobile / desktop** | Native WebView shell + embedded PWA + OTA |
| **Linux server** | Prefer [`conet-l0d`](../developers/conet-l0d.md) for gateway/proxy |
| **Not used** | Electron as the primary product container |

## Trust boundary

- Intermediate nodes must not read application plaintext.
- Local site files are trusted until the user replaces them; network failure
  must not wipe IndexedDB.
- Wallet secrets follow Consumer IndexedDB rules; never Local Storage keys.
- Product maturity is not an audit or uptime SLA.

## Related

- [`web3://` applications](web3-url.md)
- [Beamio](beamio.md)
- [CoNET Chat](depin-chat.md)
- Whitepaper (repo): `src/web3-browser/docs/whitepaper/web3-browser.md`
- MVP roadmap (repo): `src/web3-browser/docs/mvp/roadmap.md`
