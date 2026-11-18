# Uber 0.4 — creator, reservations and delivery evidence

## Creator and provider review

The fixed creator/reviewer is **Bîfrost Titan**, with the î accent. The identity is compared with the native character name, qualified to the current realm. The unaccented **Bifrost Titan** remains the separate default house-payment mail recipient. Do not interchange these names.

Recruitment prepares an application addressed to the creator at a native mailbox. It never sends the letter automatically, attaches money, or overwrites another draft. The applicant must use WoW's Send button. Applications can arrive through ordinary mail while the creator is offline. Inspect the creator's open inbox to import application sender/class/notes, then read the original letter before reviewing. The sender's actual character name is used; a name typed into the letter cannot grant approval. A claimed class is still subject to manual verification.

Recruitment → Creator: manage providers opens the control room for the creator character. Enter a native provider name, choose Mage or Warlock, set additional base/priority rates in gold, publish regular hours **including timezone**, and enter a review/moderation reason. Add/approve also reverses a ban. Remove and Ban revoke directory access and close the recipient's service when the update reaches it. Existing accepted quotes retain their amounts. New managed-provider quotes must match the client's cached admin policy. The creator remains an approved Warlock provider and cannot be removed or banned through these controls.

Changes carry increasing revisions and are accepted only from the native founder sender, never a name asserted inside the payload. Online guild/subscribed clients receive updates; clients can explicitly request the founder's roster when he is online. Cached policies are not a central online authorization server: an offline client needs a later refresh for changes. Editable Lua and SavedVariables are not cryptographic certification. The creator identity is realm-scoped; the addon cannot reserve a character name across realms or enforce account ownership remotely.

## Availability and map

Approved providers stay in the directory while offline. The creator appears first. Gray cards mean service is offline or freshness expired; they remain selectable for advance reservations. Service opens explicitly after each login/reload. LIVE means a fresh provider-advertised service session, not independently verified activity, AFK state or permanent availability. Public location packets publish only while service is open, roughly every 30 seconds. Fresh provider position can be shown without an active camp. Stale locations are not presented as live.

## Advance reservations

Book a summon → Schedule ahead opens the reservation panel. Enter `YYYY-MM-DD HH:MM` in **your computer's local time**, at least five minutes and at most 30 days in the future. The network sends an absolute timestamp; the receiving provider displays it in their own local time. Consult the driver's published timezone and wait for confirmation.

Offline requests are **local only, not delivered or accepted**. Keep the customer addon running; it probes the known directory once per minute and sends when the provider advertises fresh availability. A sent request waits for a receipt and manual reservation acceptance. The provider accepts far-future bookings into Reserved status without opening a camp. Select the reservation again within 15 minutes of its requested time to begin normal quote/payment/setup flow. Reserving a slot does not pay for or start a service. Future rates require a fresh quote rather than accepting a price days in advance.

Cancel a local, unsent reservation from the schedule panel. Already transmitted bookings require contacting the provider; the addon does not falsely retract an order remotely. Requests that remain undelivered near their start time expire locally. Limits: 100 pending reservations/outbox requests. SavedVariables survive ordinary logout/reload; a crash before WoW writes SavedVariables can lose recent changes.

## Delivery evidence, strongest available signals

Uber does not assume that a successful cast means a customer traveled. It records separate evidence steps:

1. **Provider cast:** native UNIT_SPELLCAST_SUCCEEDED for an explicitly recognized portal/summon spell while approved service is open. Instant casts count. Cast GUID deduplicates events. When available, UNIT_SPELLCAST_SENT supplies the intended target and UnitGUID supplies the caster GUID. Spell ID, time, target, source map and coordinates are stored. Recognized casts are recorded even without an active order; unrelated spells are ignored.
2. **Party and order:** the customer must be in the provider's party/raid and have an exact linked request/camp. Automatic observations do not search arbitrary players or assign another customer's cast by matching destination text alone.
3. **Warlock summon offer:** the customer reads the native C_SummonInfo.GetSummonConfirmSummoner value and verifies that the summon offer names the booked provider. The addon does not accept the summon on the player's behalf. This extra step is required for automatic Warlock delivery evidence.
4. **Customer arrival:** the customer's addon observes a substantial map/position change within 180 seconds of the provider's cast. Mage arrival must match a recognized destination map for that portal spell. Warlock arrival must be near the provider's recorded cast position. Initial login and UI reload events do not themselves count as travel.
5. **Corroboration:** the provider checks the native addon-message sender, rider membership, current party, cast ID, time window and destination again. It records the named customer and timestamp as Delivered — customer travel reported, and acknowledges the customer. A single-rider/single-person camp can then complete automatically. A party-size booking is not all delivered because one customer traveled; the camp remains open for the driver to verify everyone.

There is no general provider-side API used here that lists everyone who clicked a Mage portal. The API signals are not proof of which physical portal object was used. Cast + party + matching customer travel is **corroborated client evidence**, not server-certified proof. Modified clients can lie. Unsupported spells/maps, secret/unavailable values, non-addon riders, same-position travel or missing party/summon data stay unconfirmed for manual review. No restricted data is bypassed. The spell/map allowlist must be tested on the target client before claiming complete coverage.

## Receipts and admin reporting

Inspecting an open mailbox records native letters whose subjects match `UBER3:<quote-id>:H` or `:D`, including sender, recipient, amount, reference, first observed time and visible copy count. A receipt can be archived even when this character never held the quote. Arbitrary mail contents and unrelated conversations are not collected. Identical matching headers are deduplicated on rescan; without a unique game mail ID, identical letters received at different times cannot always be distinguished. Mailbox observations are not a bank ledger or a guarantee of refund.

Provider/customer evidence reports queue locally for the creator. A silent addon-channel handshake checks creator availability before transmission; reports wait while he is offline and are removed only after acknowledgement. These reports are separate from physical mailbox receipts and are labeled client-reported. Remote send notices never become recipient-confirmed receipts. The addon cannot inspect anyone else's mailbox or silently mail an audit report.

Receipts & delivery timeline supports character/order filtering, paging and native inbox inspection. Retention is bounded: 2,000 audit events, 2,000 delivery events, 2,000 receipt-header groups, 3,000 report deduplication IDs and 300 pending admin reports per character. If a retention/queue cap is reached, old events may be evicted or new reports may not queue. This is not unlimited guaranteed financial storage. Export/long-term backups are not implemented.

## Chat and controls

Protocol updates use C_ChatInfo.SendAddonMessage on the Uber addon prefix. They do not open a chat edit box, paste text, press Enter, block movement keys or lock the player's chat. Player-clicked readiness/guild requests use the normal whisper API directly. No keyboard interception or C++ helper is required for Uber. Native money transfers and spell casts remain explicit player actions.

## Live release checks

Test with founder, approved Mage/Warlock and customer on the exact target build: application mailbox sender import, moderation refresh/reconnect, pricing revision/replayed quote, offline reservation after reload, local-time conversion, recognized instant portal cast, party exclusion, native summon offer, correct/wrong arrival, party-size order, receipt rescan, founder offline/online report acknowledgement, map freshness and all modal layouts at normal and small UI scales. Mock tests verify protocol/state, not actual server API behavior. Screenshots must be real gameplay; generated layout previews are not screenshots.

API references inspected:

- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SummonInfoDocumentation.lua

These are client-source documentation for the available observations, not a claim of official approval of the service business model.

### Walk-up party services

Recognized casts are also announced to other current party members running Uber, even when no formal order exists. The customer checks the approved provider, party, destination transition and (for Warlocks) native summon offer. The provider records the named arrival as **PARTY_TRAVEL_CORROBORATED — no order/payment claim**. This captures observed walk-up services without manufacturing a purchase, paid receipt or completed order. Party members without Uber cannot provide these customer-side observations. All recognized provider casts are still recorded locally.

Cast records include available spell/cast/caster identifiers, target, provider class, current policy revision, associated quote reference and source map/coordinates. Arrival records link the cast and named customer's reported destination/time. Creator report notifications appear locally in chat without opening its edit box or sending a visible whisper.
