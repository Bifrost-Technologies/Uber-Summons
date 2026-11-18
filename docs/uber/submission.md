# Uber 0.4.0-beta.1 — submission worksheet

Prepared 2026-11-17. The previous file received “Failed to verify archive.” Its packaging portability defect has been repaired; this new feature release has not been uploaded by the agent. Update the existing project rather than creating a duplicate.

## Form entries

| Field | Entry |
|---|---|
| Game | World of Warcraft |
| Project name | Uber (author-requested name; moderator/name-similarity clearance remains separate) |
| Summary | Book summons and portals with reviewed providers, advance reservations, setup tracking and receipt/delivery timelines. |
| Class | Addons |
| Main category | Guild |
| Additional categories | Warlock; Mage; Map & Minimap, where available |
| License | MIT |
| Required dependencies / related projects | None; leave empty |
| Optional integration | TranquilityLFG, if installed; Uber works without it |
| File | Uber-0.4.0-beta.1.zip — upload this file alone |
| File display name | Uber 0.4.0-beta.1 |
| Release type | Beta |
| Game version/flavor | Exact tested Forever build / Interface 16001; select its actual tag, never unrelated Retail/Classic tags |
| Description | Paste DESCRIPTION.md from the same release folder |
| Changelog | Paste the 0.4.0-beta.1 section of CHANGELOG.md |
| Logo | uber-logo-400.png — exactly 400×400, AI-generated fantasy branding |
| Screenshots | Author's real in-game captures; design previews are not screenshots |
| Comments | Enable, or supply a working support channel |
| Source/support URLs | Actual public URLs only; omit unavailable links |
| Project ID | Use the assigned project ID; do not invent one |

## Reviewer overview

Standalone readable Lua, no companion executable or required third-party library. Ordinary addon packets coordinate customer/provider records without using chat input or movement hooks. Native visible whispers and friend/guild requests are clicked actions. Spell casts and native mail transfers remain player-controlled.

Administration.lua fixes creator/reviewer identity to accented Bîfrost Titan, validates native sender and policy revisions, manages rates/hours/moderation and paginates the reviewed directory. Reservations.lua retains offline requests locally and delivers them only when fresh provider availability is observed. Delivery.lua separates cast, native summon-offer, party, customer travel and mailbox evidence. AdminUI.lua supplies creator, schedule and searchable/paged evidence panels. Other modules handle core transport, quotes, presence, roster and five-tab UI.

Unaccented Bifrost Titan remains the separate default house-payment recipient. Additional service/priority fees split 20/80; the Mage retains the configured 22s portal minimum and the provider retains tips. The addon does not automatically send money, provide escrow or guarantee receipt/refund. The commission model requires platform-policy clarification; this worksheet does not certify it as accepted.

Logs include service-related character identities, timestamps, requests, schedules, pricing/review revisions and receipt/cast/travel evidence, with bounded retention. Remote observations are client-reported, not server-certified delivery. No private chat or keystrokes are recorded. See ADMIN-AND-DELIVERY.md for exact observations, limitations, retention and pending live checks.

## Archive repair evidence

The Windows ZIP builder previously emitted backslashes in raw entry headers. It now emits forward slashes and verifies local/central paths, decompression, CRCs, manifest declarations and per-file hashes. The new ZIP contains a single Uber root with 18 whitelisted files. It contains no private guild combat code, executable helpers, credentials, SavedVariables or mock screenshot assets. PREFLIGHT.txt and the SHA-256 file record the build results. See ARCHIVE-REPAIR.md.

## Publication checks

Record live results for native mail/application import, two-client quotes/reservations, supported portal/summon spell/map coverage, party/cast/arrival correlation, founder offline/online reports, policy refresh and UI scales. Capture real screenshots. Confirm name/assets and exact version tag. Resolve commission-policy questions with the platform. If archive verification still fails, send support the existing project/file IDs, exact error, chosen game tag and new ZIP hash and ask for the processor's specific diagnostic. No acceptance or download-count guarantee is made.

References:

- https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies
- https://support.curseforge.com/support/solutions/articles/9000209856
- https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534
- https://us.forums.blizzard.com/en/wow/t/policy-update-for-organized-in-game-services-january-2022/1176836
