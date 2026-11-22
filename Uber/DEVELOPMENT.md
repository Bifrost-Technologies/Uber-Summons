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

