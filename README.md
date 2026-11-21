# Uber

Warlock summons, Mage portals, & Server Phasing all in one World of Warcraft addon: reviewed provider cards, itemized prices, advance reservations, setup status, map positions and receipt/delivery timelines.

Current source: **0.5.0-beta.11**, targeting **Forever / Interface 16001**. Open **`/uber`** in game. This is a beta with live-client checks still required.

## Features

- Creator/provider administration, manual driver review, hours, managed rates and moderation controls.
- Live and offline provider cards; offline advance requests remain local until delivered and accepted.
- Custom destinations, party sizes, preparation notes, priority requests and optional tips.
- Player-controlled native-mail drafts and separate sent/received evidence.
- Recognized portal/summon cast records, party/customer arrival corroboration and walk-up observations.
- Native addon messages that do not open chat or intercept typing/movement.

Read [the addon guide](Uber/README.md) and [administration/delivery details](Uber/ADMIN-AND-DELIVERY.md). Client evidence is not server-certified delivery. Normal realm, faction, party, mail and spell rules apply. The commission-service model and public submission remain subject to platform review.

## Install

Use the named addon ZIP from a project release and extract the **Uber** folder directly into `Interface/AddOns`. From a source checkout, copy only the `Uber/` runtime folder. Restart after a fresh installation, enable it and run `/uber`. No desktop application or required third-party addon is needed.

## Repository layout

| Path | Purpose |
|---|---|
| Uber/ | Installable runtime source, manifests, MIT license and player guide |
| docs/uber/ | Listing text, selected logo, submission and live-test materials |
| tests/ | Legacy protocol, multi-client, service and current administration/delivery simulations |
| scripts/ | Reproducible checks, ZIP packaging and raw ZIP validation |
| Build.ps1 | Build entry point |

## Build and verify

On Windows, install a Lua 5.1+ compatible runner or LuaJIT/Fengari, plus Node.js for raw ZIP verification. In PowerShell at this repository root:

```powershell
.\Build.ps1
# Or select a runner explicitly:
.\Build.ps1 -LuaRunner 'C:\path\to\lua.exe'
```

The script checks all five Lua suites, manifest declarations, public source scope, raw ZIP paths/local headers/decompression/CRCs and source/archive hashes. Runtime TGA assets are tracked and packaged. Generated artifacts go to `dist/`, with author materials under `share/Uber-submission/`; these are intentionally ignored by Git. No game folder or account is changed by a build.

## GitHub and releases

[HOW-TO-GITHUB.md](HOW-TO-GITHUB.md) explains GitHub Desktop setup. [RELEASE.md](RELEASE.md) explains versioning and upload assets. Source and MIT notices belong in Git; generated ZIPs are release attachments. No repository has been initialized or published by this preparation.

For issues, include the addon version, exact game build, steps, expected/actual behavior and full Lua error with private information removed. See [CONTRIBUTING.md](CONTRIBUTING.md).

MIT License. Independent community project, not affiliated with Uber Technologies, Blizzard Entertainment or CurseForge. The selected fantasy logo is AI-generated branding, not a gameplay screenshot.


## Source-only tracking

Lua, manifests, Markdown, licenses, build/verification scripts and required runtime TGA assets are tracked. Generated releases, local settings, credentials and submission-only artwork are ignored. WoW loads Lua directly; no C++ compilation is required. Run Build.ps1 to validate and package in one step.


## Current release

Uber 0.5.0-beta.11 adds the first-run welcome splash and minimap guide, plus founder-online gating for private network status reports. The splash uses the supplied 1152×768 artwork at a proportional 768×512 display size. Run `./Build.ps1` to validate and package the addon without changing game folders or publishing.
