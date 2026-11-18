# Test record and manual release checklist

Automated tests: run scripts/build-uber-release.ps1. This requires a final PASS marker because the Fengari runner can return zero after a Lua error. Assertions cover request/receipt handling, duplicated requests, invalid ETA, camp joins, provider authority, invalid map data, closed-on-login state, driver approval/revocation authority, sender-owned segmented notes, group-size bounds and tab initialization.

Final offline check includes tests/uber-integration.lua: independent customer, driver and dispatcher instances exchange real protocol packets in a simulated transport. It covers applications, approval/revocation, accented 480-byte notes, receipts, ETA/location, Ready/join ordering, clicked whispers and invalid/restricted map data.

Pending live tests (not replaced by mocked tests):
- Two online clients exchange a request and all three note segments without truncation; inbox shows group size and supplies.
- Non-Warlock cannot apply/open service. Unapproved Warlock cannot open service. Real dispatcher approves only after review.
- Forged status/roster senders are ignored. Revocation reaches online clients; offline client refreshes on return.
- Approved roster renders portraits for available party/self units, class icons otherwise. Right-click/ellipsis menus open and close correctly.
- Add friend and ask-to-join-guild operate only on user clicks; guild request does not self-join or auto-invite.
- Driver accepts request, chooses ETA and walks through accepted/travel/setup/Ready/paused/complete/cancelled.
- Customer joins current camp. Summon now works only for a received Ready order and is rate limited. No automatic ritual is executed.
- Map opens correct zone/waypoint, coordinates match driver, unavailable position is clear, updates go stale after two minutes.
- Reload starts service closed and preserves records. Offline target remains unconfirmed; no offline delivery promise.
- Full inbox/outbox/queue limits fail gracefully. Long and accented notes reassemble correctly.
- Test 1080p and smaller display/UI scales, multiline editing, right-click menu at screen edges and ESC behavior. Capture screenshots/README.md views.

Publish as beta until live checks are recorded with exact client build. Report actual measured CPU/network behavior before making benchmark claims.





## 0.3 payment/presence coverage
The services suite simulates house-offline operation, driver prices and stale expiry, realm filtering, quote acceptance and replay handling, 20/80 extras with tips retained by drivers, explicit sent-notice authorization, bounded notification retries/acknowledgements, separate recipient observations, free Warlock service and 22s-per-cast Mage minimums. Native mail preparation is asserted not to call SendMail. Real protected mailbox behavior remains untested.


## Current 0.4 tests

The release builder also requires tests/uber-admin.lua. It exercises fixed founder identity, forged/stale admin packets, approval/ban/unban and managed prices, founder offline listing, local reservations and online handoff/acceptance, instant portal casts, party exclusion, wrong destination/login/reload rejection, native summon-offer caster matching, single-rider completion, multi-person non-completion, customer delivery acknowledgement, native mailbox deduplication and application import, creator report acknowledgement/replay handling, restricted-value rejection and creation of the new modal panels.

The older isolated protocol tests retain legacy dispatcher behavior as backward-protocol coverage; current authority is tested with all modules loaded in uber-admin.lua. Both reviewed Mages and Warlocks can apply; the earlier Non-Warlock bullet should be read as neither Mage nor Warlock.

Live requirements: validate recognized spell IDs and arrival maps on Forever, instant casts, customer/provider in the same party, native summon-offer API, wrong/no arrival staying unconfirmed, all group riders, creator offline reporting, mailbox UI/send results, scheduled local-time conversion and reconnect/reload persistence. Test the four new panels at small/default UI scale. The SVG design previews are mocked renderings, not actual screenshots.