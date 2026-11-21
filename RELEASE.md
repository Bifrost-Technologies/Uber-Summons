# Uber Summons — release form

Prepared November 21, 2026. Current package **0.5.0-beta.11**. Files are prepared locally; no submission, approval, remote workflow run or live-client certification is claimed.

## Project fields

| Field | Value |
| --- | --- |
| Game | World of Warcraft |
| Project name | Uber Summons |
| Proposed slug | uber (use the existing project's slug when updating) |
| Summary | Coordinate player-run summons, portals and layer-keeper requests with availability controls. |
| Class | Addons |
| Main / additional categories | Chat & Communication; Travel; Map & Minimap — select matching labels available in the form |
| License | MIT, matching bundled source LICENSE notices; retain third-party asset notices |
| Logo/avatar | Uber-avatar.png (existing project artwork; retain author ownership confirmation). |
| Allow comments | Enabled |
| Listing visibility | Public; do not enable experimental/unlisted unless deliberately desired |
| Description format | Markdown; paste the description below |
| Author / members | Your actual CurseForge publishing account and actual contributors |
| Project ID | Use this addon's assigned numeric CurseForge ID; not available from local source |
| Source URL | https://github.com/BifrostTitan/Uber-Summons |
| Issues / wiki | Use actual published URLs; otherwise leave blank and use CurseForge comments |
| Donation / social links | Optional; leave blank unless you supply real links |
| Screenshots | Add real addon screenshots; no new screenshots are included in this handoff |

## Description — copy/paste

Offer or request Warlock summoning, Mage portal and layer-keeper services through a shared directory. Realm/faction compatibility controls requests; native party invites, spell requirements and game restrictions remain authoritative. Driver availability defaults to open unless a saved restart preference explicitly keeps service closed. Layer service pauses during its tracked cooldown and resumes when eligible; reported layers and tracked swap estimates are not a guaranteed server layer or exact server limit. Summon helpers can prepare editable requests for nearby players; exact-town WHO results are used only when the client actually reports that town. Public presence/session counts and provider listings depend on fresh addon messages. The addon uses in-game communications; read the bundled README for identity/admin-presence disclosure. No C++ helper or game movement automation is included.

Built for **Forever WoW 1.60.1 / Interface 16001**. Open `/uber`. Other Retail/Classic clients are not certified by this release. Native game restrictions and unavailable APIs still apply.

## File upload fields

| Field | Value |
| --- | --- |
| Upload file | `Uber-0.5.0-beta.11.zip` — upload this ZIP alone |
| Display name | Uber Summons 0.5.0-beta.11 |
| Release type | Beta |
| Release options | Release after moderation approval, or choose manual scheduling in your account |
| Supported client / version | Forever WoW 1.60.1, Interface 16001. Select its actual supported entry if offered; do not relabel it as another client. Confirm with CurseForge support if this client is not listed. |
| Related projects | None. |
| SHA-256 | `108B0204E4080337C3CF981D689323762D7DF659F867BDE0AEC6766C230EE834` (built `Uber-0.5.0-beta.11.zip`) |
| ZIP root addon folders (1) | `Uber` |

### Changelog — copy/paste

Beta.11 includes the first-run 768×512 splash with proportional supplied artwork, minimap-icon onboarding, and founder-online gating for private network status reports. Preserve documented limitations on town precision, layer identity and cooldown estimates.

The local build verifies tests, direct addon-root layout, manifest-declared files, runtime assets, matching generic/Camelot manifests, ZIP decompression/CRC and SHA-256. Automated checks do not replace live-client validation.

## GitHub commit packaging

The repository's `.github/workflows/release.yml` builds an artifact on pushes. In GitHub Settings → Secrets and variables → Actions, set secret `CF_API_TOKEN`, variable `CF_PROJECT_ID`, and variable `CF_GAME_VERSION_IDS` with real supported numeric version IDs. No account tokens are stored in this document. Default-branch commits upload Alpha files when configured; a tag `v0.5.0-beta.11` uploads this Beta version. Generated ZIPs remain local build artifacts; commit source/configuration instead. Do not use duplicate CurseForge webhooks and Actions upload for the same commit.

Remote publication/configuration has not been performed. Missing logo, project ID, real supported-version selection or unpublished source URLs are author/account fields to complete before submitting. Private toolkit/helpers/recorders and private development reports are excluded.

## Official field references

- [Creating and submitting a project](https://support.curseforge.com/support/solutions/articles/9000197241)
- [Submission fields, original logo and project links](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips)
- [Upload API](https://support.curseforge.com/support/solutions/articles/9000197321)
