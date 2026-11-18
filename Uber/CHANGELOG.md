# 0.5.0-beta.1

- Added observed network user counts, creator-only private presence census, public-stat opt-out and explicit privacy disclosure.
- Added real-traffic connection indicator, available/occupied provider counts, destination/session browser and normal camp join requests with full-session checks.
- Added native raid-conversion attempts for an active warlock leading a party; combat, native permissions and confirmations remain respected. Party conversion/disband stays manual.
- Prioritized order/receipt packets over bounded background discovery/statistics and expired stale observations.

# 0.4.0-beta.2

- Added one star-only rating per corroborated completed order, without comments or seeded reviews.
- Show native-confirmed Tranquility providers in gold; unknown remote membership remains unknown.
- Provider-reported rating summaries are labeled explicitly.

# Uber changelog

## 0.4.0-beta.1 — November 17, 2026

- Fixed creator/admin identity to accented Bîfrost Titan; retained the separate unaccented house-payment recipient.
- Added creator provider controls: manual add/approve, remove, ban/unban, managed base/priority pricing, regular hours/timezone and moderation audit reasons. Revisioned policy packets reject forged senders and stale changes.
- Added native-mail driver application drafts and creator mailbox import for manual review. Sending remains an explicit WoW mailbox action.
- Kept approved providers listed offline, with the creator pinned first, gray offline cards, live freshness and provider map positions even without an active camp.
- Added advance reservations up to 30 days ahead, explicit local-only offline storage, online handoff, provider reservation confirmation and near-time setup flow.
- Added a searchable/paged receipt and delivery timeline. Native matching mailbox receipts are archived independently of local quote availability; rescans deduplicate matching headers.
- Recorded recognized portal/summon casts, including instant casts, spell IDs, timestamps, available cast/caster identifiers and targets while service is open.
- Added automatic single-person delivery completion from exact order + party + cast + matching customer arrival. Warlock detection additionally matches the native summon-offer caster. Casts alone and one rider in a group never prove full delivery.
- Added bounded, acknowledged creator evidence reports over the silent addon channel, queued locally while the creator is offline. Remote observations remain labeled client-reported.
- Refreshed recruitment, creator control, scheduling and evidence panels. Addon communications never open chat or intercept movement keys.
- Fixed ZIP entry separators at the raw-header level after CurseForge reported “Failed to verify archive”; added decompression/CRC/path validation to every standalone build.
- Beta: live mailbox, party/cast/arrival, spell/map coverage and UI-scale checks remain required. Corroborated client evidence is not server-certified proof; commission-policy clarification remains separate.

## 0.3.0-beta.1 — November 17, 2026

### Added
- Unified Uber branding for Warlock summons and Mage portals.
- Driver-hosted availability and price updates, including when no camp is active. Existing synced clients can continue while the dispatcher/house character is offline.
- Active-driver filtering, stale-presence expiry, and a no-drivers-available message for the client's known realm directory.
- Per-character, per-realm base extras and priority surcharges, plus optional customer tips.
- A fixed **22-silver minimum per Mage portal cast**, separate from party size. The full supply charge goes to the Mage.
- Itemized quotes with exact recipients, totals and acknowledged customer acceptance.
- A **Price, priority & optional tip** panel, quote/payment controls in Track & map, and driver pricing controls.
- Priority request badges and explicit driver acceptance of setup.
- Native mailbox draft preparation for house and driver payments. Players enter the money and confirm sends through WoW; Uber does not automatically transfer gold.
- Separate states for buyer-reported sends, client-observed mail submission and matching recipient inbox observations.
- Payment-notice acknowledgements and bounded retries that never resend gold.
- An explicit driver option to begin setup from sent notices without labeling those notices confirmed payment.
- Completed quote-history cleanup while retaining pending and cancelled records.

### Changed
- Additional base/priority fees split **20% house / 80% driver**. Portal supply charges and optional tips go entirely to the driver.
- Warlock standard service can remain free with a zero base rate; optional tips do not block free service.
- The house mail recipient defaults to unaccented **Bifrost Titan** on the current realm. Normal mail and realm restrictions still apply.
- New bookings require a fresh active-driver presence record.
- Quote acceptance, payment notifications and closure are bound to exact order/quote identifiers.
- Duplicate quote delivery preserves acceptance state; cancelled quotes cannot prepare new payment drafts.
- Offline directory probes do not produce routine visible chat spam.
- Updated the listing description, player/driver guide, submission notes and screenshot checklist.

### Validation and beta limits
- Passed **44 unit/UI assertions**, **39 multi-client integration assertions**, and **42 presence/pricing/mail-flow assertions**: **125 Uber assertions total**.
- Public guild package passed **849 assertions** across 22 module configurations.
- Verified archive contents and per-file source hashes.
- All participants must update for the current presence, quote and payment protocols.
- Fresh clients still need an initial trusted approval roster. Availability is not a complete server-wide scan.
- Real mailbox/protected-API behavior, live multiplayer delivery and screenshots still need verification. Buyer reports are not proof of receipt, and Uber does not provide escrow or guaranteed refunds.
- The commission-based dispatch model requires policy clarification before public-compliance claims are made.

## 0.2.0-beta.2

- Added dispatcher-reviewed Mage portal providers alongside Warlock summoners.
- Added class-aware roster icons and **Portal now!** requests.
- Improved handling of unavailable, invalid and restricted map data.
- Added multi-client regression coverage and moderation-review materials.

## 0.2.0-beta.1

- Added the shared customer, driver and dispatcher interface.
- Added approved-driver cards with portraits/class-icon fallbacks, Order Uber buttons and contextual friend/guild-request tools.
- Added customizable destinations, group size, preparation requests and notes.
- Added setup status, ETA and map-location tracking.
- Added driver applications, manual review, approval and revocation.

## 0.1.0

- Introduced standalone summons requests, a saved inbox, active camps and customer joins.
- Added integration entry points for the guild addons.
