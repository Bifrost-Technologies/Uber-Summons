# Uber Summons — development must read

Updated 2026-11-21. This is an engineering handoff, not proof of native acceptance.

## Purpose and ownership

Public rider/provider coordination through native addon messages, prefix UBERSUM1. Uber.lua owns dispatch/queues; Orders, Drivers, Presence, Billing, Reservations and Delivery own their named states; RealmScope validates native realm/faction freshness; Roster/Interface/ServiceUI render; Notifications/ServicePreferences are preferences; PhaseKeepers is separate peer evidence; PeerDiscovery is loaded LAST and wraps older Send/Receive behavior.

## P2P and authority contracts

- Rider and selected online provider communicate directly. Background operation must not require the founder online or whisper offline cached founder/provider names.
- PeerReachable uses recent authenticated addon traffic (75s), native online guild/friend/group evidence. The peer cache is bounded (200 entries; old observations expire). Preserve gates on all background packet families, not just HELLO.
- Native GUILD/PARTY/RAID discovery may elicit direct replies. Do not assume unsupported custom addon CHANNEL transport. Explicit manual provider probes are distinct from silent recurring probes.
- Booking needs matching fresh realm/faction scope (90s). An offline scheduled reservation can use matching cached authenticated scope, but actual delivery still requires a fresh bookable provider. Never interpret unknown realm/faction as matching.
- Founder-approved roster/policy authority must come from the authenticated native sender. A peer relaying a founder-looking payload is not founder authority. Cached approvals let known clients work founder-offline; brand-new clients still need an authentic roster for newly approved drivers.
- Public IsDispatcher is false. Creator provider approvals, pricing/moderation/admin UI belong in a separate PRIVATE companion. Public files named Administration/AdminUI/NetworkStats are not permission to reinsert those methods. Public ZIP checks reject creator management methods.
- Recruitment applications use a native mailbox draft; the player clicks Send. Opening a draft is not mail delivery. Existing mail must be inspected before acting on it. Do not reintroduce automated offline applicant whispers.
- Validate/repair malformed UberDB root and bounded providers/orders/inbox/outbox/drivers/applications/policies/audit/reservations. Preserve request identity, duplicate prevention, ownership and evidence for billing/delivery.

## Validation and limitations

Use uber, uber-services, uber-notifications, uber-public-private and public-runtime-regressions in the integration workspace. Load full manifests for public/private boundary tests, not a convenient subset. Native acceptance remains required with two independent clients, founder logged out, offline reservations, mailbox application, native identity authorization and real travel evidence. A simulation or local receipt is not a completed summon or payment.

## Manifest snapshot (2026-11-21)

Primary: Uber.toc; compare Uber_Camelot.toc. Header values and file lists below are a source snapshot; the current TOC wins after a later change.

```text
## Interface: 16001
## Version: 0.5.0-beta.13
## SavedVariables: UberDB, SummonClickHelpersDB
```

Runtime load order:

- Uber.lua
- Orders.lua
- Drivers.lua
- Presence.lua
- Billing.lua
- Administration.lua
- Reservations.lua
- Delivery.lua
- Interface.lua
- Roster.lua
- ServiceUI.lua
- AdminUI.lua
- NetworkStats.lua
- Notifications.lua
- RealmScope.lua
- SummonHelpers.lua
- PhaseKeepers.lua
- ServicePreferences.lua
- PeerDiscovery.lua

## Development rules

Read this guide and the TOC before editing. Treat declared load order, saved-data structure, public/private boundaries and native API restrictions as contracts. Preserve explicit user settings; validate malformed saved data without wiping unrelated history. Never decode secret values or treat unavailable data as success. Do not register restricted raw combat-log events through pcall. Ordinary dashboards must remain closeable in combat; protected descendants stay in separate windows.

An input send, announcement, queued request or local receipt is not proof of native delivery, acceptance or completion. State claims must match their evidence. Bound peer caches, incoming payloads, work queues and retry loops; retain cancellation/request identity for asynchronous work. Add a regression check for a real failure, not a test that merely repeats the implementation.

Source changes are local until explicitly approved for GitHub/CurseForge publication. Keep install ZIPs manifest-driven, verify contents/CRC/hash and compare both client TOCs. Never package private companions or the whole checkout into a public release. Native gameplay and independent-client validation remain separate from offline simulations.

When learning a failure or changing behavior, update this guide with environment, symptom, evidence, fix, affected symbols/tests and remaining validation. User instructions supersede historical design notes.


## Send-failure burst follow-up

0.5.0-beta.14: old Tick used a partial packet suppression list, so background S/H3/SCOPE1/CAP7 replies could each print a generic failure. Peers could go offline between enqueue and dispatch. The screenshot alone does not prove an incoming ride or malicious sender. Centralize background classification, recheck dispatch reachability, back off the failed endpoint for 30 seconds and prune only its queued background packets. Keep critical request/receipt traffic intact; actionable failures are limited to one chat warning per 30 seconds. /uber network exposes 50 bounded in-memory metadata records (five displayed), native result enum and native sender/query provenance, never full payloads. Tests: uber-transport plus existing Uber suites. Native multiplayer/send-result acceptance remains pending. Do not remove authority checks or quiet real ride failures as a spam fix.


## Realm/faction directory and protocol review — 0.5.0-beta.15

Protocol.lua now loads LAST, after PeerDiscovery.lua, to validate packets before legacy wrappers mutate caches. Both client TOCs must retain this order. The boundary rejects unsupported channels/types, control characters, payloads over 240 bytes, invalid field counts, contradictory presence and nonfinite status fields. It retains legacy KEEP1 and SCOPE1 compatibility. Receive traffic is bounded per native sender (20/second, 120/10 seconds; 200 tracked senders with 120-second expiry). Rejections retain metadata only and never reply to malformed traffic. /uber network reports rejection counts; rejection does not prove malicious intent.

SCOPE2 adds native realm ID/region and sender timestamp to realm/faction announcements. Approved native senders must match their explicit realm suffix; stale/replayed versioned scopes and downgrade attempts are rejected. Fresh matching scope is required for immediate booking; cached matching scope can support offline reservations. Unknown faction is never inferred as matching. Pricing profiles and filter preferences are separated by realm/faction/IDs and native character. Existing same-character legacy price profiles are imported without deleting history.

The directory defaults to My realm + faction; its button toggles All known networks. All includes known/cached providers, including unknown scope, for browsing; it does not authorize incompatible bookings or provide a global registry. PvP, PvE and RP realm names use the same native identity checks; there is no realm-type exclusion. Native WoW transport still determines cross-realm/faction discovery and communication. Opposite-faction requests lacking authenticated scope cannot have faction invented from packet text. No cross-faction/cross-realm summon capability is claimed.

Regression coverage: uber-protocol exercises 42 faction/realm/replay/channel/flood cases; uber-public-private loads the final protocol and models the production four-packet/second dispatch cadence for paged-roster tests. The tracking panel tolerates missing ETA in incomplete cached orders. Full affected suites and native multiplayer acceptance are recorded separately; offline passes do not establish gameplay delivery.


## Blue theme — 0.5.0-beta.16
Navy window backgrounds, blue cards/borders, azure headings and online-provider accents replace the teal styling. Keep warning, connection and notification colors semantic. This is a visual-only change; protocol, booking rules and saved settings remain unchanged. Verify rendering in game after /reload; offline UI tests do not establish visual acceptance.


## Stable version preparation — 0.5.0
Both TOCs now declare 0.5.0. Stable publication requires tag v0.5.0: scripts/release.py marks untagged branch uploads alpha, beta-tagged versions beta, and plain version tags release. The workflow likewise marks branch GitHub downloads prerelease. Keep branch artifacts nonstable; renaming a local TOC does not publish or promote any remote file. Uber has no in-game available-version notifier. Addon-manager matching, release channel, compatible game version and moderation can affect available updates; the specific owner's manager issue remains unconfirmed. GitHub/tag/CurseForge publication still requires explicit owner approval. Native gameplay acceptance remains as documented above.


## Stable push releases — 2026-11-22 (supersedes tag-only guidance)

Owner requests stable public releases on default-branch pushes. Plain X.Y.Z TOC versions now produce CurseForge release and GitHub non-prerelease/latest downloads on default-branch pushes as well as matching version tags. Explicit beta/alpha versions retain their prerelease channels. Feature branches only build artifacts; existing publication gates remain. Branch ZIP/tag labels retain commit hashes to distinguish pushes. Increment the TOC version for subsequent user-facing updates. Both client TOCs must match. Local edits do not publish/promote old remote files; no push/upload was performed. Moderation, compatible game-version metadata and addon-manager matching still affect update availability. Stable channel classification is not proof that pending native acceptance checks passed.
