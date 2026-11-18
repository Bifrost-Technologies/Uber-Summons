# Uber

Book Warlock summons and Mage portals, customize your setup, and follow your provider from reservation to arrival. Uber puts customers, reviewed providers and creator administration in one addon. Open **/uber**.

## Find your provider

Browse named provider cards with portraits when a native unit is available, class icons otherwise, prices, regular hours and live/offline status. Bîfrost Titan is the creator, reviewer and permanent founder provider. His card remains visible offline. Gray cards can take advance requests; they do not imply that the provider is online or has accepted your order.

Approved providers publish fresh service status and location while their service is open. Track setup stages, a chosen ETA and the current reported map position, even before a camp starts. Stale data is labeled. An open service session does not certify that the player is actively at their keyboard.

## Customize and schedule

Choose a dungeon, zone or custom camp, group size, preparation needs and notes. Request food, water, campfire, buffs, quests or PvP FOB support. Ask for priority or add an optional tip. Priority requires acceptance and does not guarantee immediate travel. Mages can only open destinations supported by their real portal spells; they cannot remotely summon to arbitrary locations.

Reserve up to 30 days ahead using a date/time in your computer's local timezone. Consult the provider's published hours/timezone. Offline requests are saved locally and are explicitly **not delivered or accepted**. Keep Uber running to send when the provider returns; wait for their reservation confirmation. Far-future acceptance holds a reservation without starting a camp. Prices require a current quote before service begins.

## Clear prices

Each provider has an additional base rate and optional priority surcharge. The creator can manage reviewed provider rates. Warlock standard service can be free. Mage orders include a configured **22-silver minimum per portal cast**, plus additional base, priority and optional tip. The 22s is Uber's configured floor, not a universal vendor-price assertion.

The Mage keeps the entire portal minimum. Additional base/priority charges split 20% to the house and 80% to the provider. Tips go entirely to the provider. The itemized quote names recipients before the customer accepts. Accepted quote amounts do not silently change when a rate changes.

## Player-controlled payments

At an open mailbox, Uber prepares house/provider payment text drafts. Players enter money, review the native mailbox and explicitly send. No gold is transferred automatically. The default house-payment recipient is unaccented **Bifrost Titan** on the current realm; the creator/reviewer is accented **Bîfrost Titan**. Native delivery, postage, faction and realm restrictions apply. There is no cross-realm gold routing, escrow or guaranteed refund.

Mail-send notices are not proof that money arrived. Recipients can inspect matching receipt letters only in their own open inbox. Receipt records preserve sender, recipient, reference, amount and observation time. Matching receipts can be recorded even without a local quote. Identical headers are deduplicated on rescans, with the limitations of the game's exposed mail identifiers.

## Delivery timeline

Recognized portal and summon casts are timestamped while provider service is open, including instant casts. Successful casts alone do not complete a purchase. Automatic delivery combines exact order linkage, party membership, the provider's successful cast and the customer's matching arrival report. Warlock detection also checks that the native summon offer names the booked provider. Portal destination checks use an explicit supported-spell/map list.

Walk-up party services can also record named arrivals when both sides run Uber, without inventing an order or payment. The provider records who arrived and when. A single-person, single-rider camp can complete automatically; one player's jump does not complete an entire group booking. Unsupported spells/maps, missing addon/party data and unavailable or restricted API values remain unconfirmed for manual review.

These are corroborated client observations, not server-certified proof. The addon does not have a general API that reveals everyone who used a Mage portal. Modified clients can misreport observations. The timeline keeps native mailbox observations separate from remote reports and supports character/order filtering. Reports wait locally while the creator is offline and transmit over the addon channel when he responds.

## Reviewed providers and moderation

Mage and Warlock applicants prepare an in-game mail application to Bîfrost Titan. They review it and use WoW's Send button; the creator manually reviews the original letter. The creator control room adds, approves, removes, bans or reinstates providers, updates rates/hours and records moderation reasons. Only native messages from the fixed creator identity authorize policy changes. Offline clients need a later roster refresh to learn new approvals or revocations. This is realm-scoped character identity, not immutable global certification.

## Quiet communication

Order, map, policy and evidence packets use WoW's addon-message channel. They never open the chat edit box or intercept movement/typing. Readiness and guild-request whispers are player-clicked and use the native whisper API directly. Spells, travel, grouping and money transfers remain player-operated. No C++ app, automatic gameplay, required third-party addon or external account is included. Optional Guild LFG integration opens TranquilityLFG when installed.

## Installation, data and beta scope

Install the **Uber** folder under Interface/AddOns, enable it and run **/uber**. Refresh the founder's approved directory when he is online. Both participants need this release for current reservations/delivery protocols. Cached reviewed providers can host without an always-online house character. Initial discovery is limited to the known directory, not a scan of every player on a server. Reload starts provider service closed.

This beta targets **Forever Interface 16001**. Other game flavors are not claimed as tested. Real-client mailbox, multiplayer, spell/destination coverage and UI screenshots still require validation. The commission model requires platform-policy clarification; this release is not described as officially approved.

Local SavedVariables hold character names, requests, schedules, notes, provider reviews, prices and receipt/delivery evidence. Logs are bounded; the addon does not read private chat or keystrokes. Do not put sensitive information in notes. Ordinary WoW logout/reload writes SavedVariables; a crash may lose recent changes. Remote reporting is not a guaranteed permanent financial archive.

Free readable Lua under MIT. No real-money payment, paid software unlock, ads or companion executable. Independent community addon; no affiliation with Uber Technologies, Blizzard Entertainment or CurseForge. The fantasy logo is AI-generated branding, not gameplay. Design previews are labeled; real screenshots are separate.