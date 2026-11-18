# Uber payment and priority design

Status: proposal, 2026-11-17. No money-sending code has been added to the public runtime. No fees are charged by the existing build. This document is not a promise that the proposed house/dispatch commission is permitted by Blizzard or CurseForge.

## Recommended booking flow

Keep free order drafts and price enquiries available anywhere. Require an OPEN mailbox interaction only for the mail checkout action. Merely standing near a mailbox is neither sufficient interaction access nor a remote-verifiable payment condition. If desired, Mail checkout only can be a local UI preference, but the driver must still verify receipt: modified clients can forge any addon-originated near-mailbox or paid claim.

1. Customer chooses a driver, destination, group size, notes and Standard/Priority request.
2. Driver reviews the request and issues an itemized quote. Quote includes exact recipients, base fee, priority premium, total, split, deadline, estimated start/ready times and refund terms.
3. Customer explicitly accepts this quote and its version before any gold moves. A driver or recipient change invalidates acceptance.
4. Customer opens a mailbox. Checkout prepares recipient, order reference, subject and amount where supported. Customer reviews the native mail UI and confirms each send. Never silently click confirmations, bypass protected APIs, overwrite an occupied mail draft, attach items or send C.O.D.
5. Native MAIL_SEND_SUCCESS records Submitted for the specific pending draft. It is not recipient payment confirmation. Failure, closing the mailbox, reload or interrupted sends must stop, never automatically resend gold.
6. Each recipient checks their own inbox at a mailbox and confirms the expected sender, order/quote reference and amount. One recipient cannot verify the other's mailbox. A buyer's addon Paid message is only a claim, not proof.
7. Setup begins after the driver accepts the order and the required receipts are confirmed, or after an explicit driver waiver recorded separately. Show which share remains unpaid.
8. Complete or cancel the order. Track any required refunds separately; do not claim a refund occurred merely because someone clicked Refund.

A simpler first release is a direct player-to-driver quote/payment with manual recipient confirmation. It avoids making the driver wait for a separate house account. The proposed house split remains a policy-dependent extension, not an assumed approved business model.

## Fee calculation

All calculations use integer copper. Example: 1 gold = 10,000 copper = 100 silver.

| Service | Customer total | House 20% | Driver 80% |
|---|---:|---:|---:|
| Standard example | 1g | 20s | 80s |
| Priority example: +50s | 1g 50s | 30s | 1g 20s |

The 50s premium is an example, not an adopted price. Recommended default rule: apply the same 20/80 split to the quoted total, including priority. Compute house = floor(totalCopper * 20 / 100), driver = totalCopper - house, so no copper is lost. Postage is separate and shown by the native mail UI. If house and driver are the same character, combine into one payment to avoid duplicate sends/postage.

The house character, percentage and driver amount must be visible before acceptance. No real-money payments, addon access fees, premium software unlocks, hidden commissions or donation prompts are part of this design. A price quote is an in-game service agreement, not a guarantee of delivery.

## Mail limitations

- Two recipients mean two independent letters, not one atomic split. One may be submitted or received while the other fails.
- Delivery may be delayed according to client/server mail rules. Do not market mail prepayment as instant checkout or instant priority delivery; measure the actual target client.
- Recipients cannot read inboxes remotely through an addon. A driver already at camp may need another way to confirm payment, or choose direct trade instead.
- Native success confirms submission, not irrevocable receipt, withdrawal, service performance or refund.
- No addon has authoritative custody of gold. SavedVariables and whisper packets can be edited; they are not a secure financial ledger or escrow system.
- Account/faction/realm/trial restrictions and postage can prevent sends. Fail closed and show actionable instructions.

## Quote and payment states

Keep booking state separate from payment state.

Booking: Requested -> Quote offered -> Accepted -> Scheduled -> Travelling -> Setting up -> Ready -> Complete, with Cancelled/Declined alternatives.

Payment: Unquoted -> Awaiting customer approval -> Awaiting payment -> Partially submitted -> Submitted -> Partially received -> Recipient-confirmed, with Mismatch/Failed/Refund due/Refund submitted/Refund confirmed alternatives.

Each record includes order ID, quote ID/revision, buyer, driver, house recipient, amounts, delivery route, priority acceptance, deadlines and receipt records. Cap history and provide export/clear controls. Never infer money movement from a normal status update. Preserve a pending/uncertain state across reload; never auto-repeat a previous transfer.

## Priority rules

Priority is a REQUEST until the driver explicitly accepts the premium and supplies a revised ETA. Charge it only after capacity/route review. Never interrupt an active ritual, abandon paid customers or guarantee immediate arrival. If the driver cannot deliver the accepted priority terms, premium becomes Refund due according to the disclosed agreement. Show priority offers separately from normal FIFO orders; reordering requires a driver decision and must be visible.

## Cancellation and refunds

Recommended terms for discussion: cancel before setup starts -> full service refund; driver cancels/cannot provide service -> full service refund; missed priority commitment -> refund premium. Postage and refund postage are separately disclosed. Agree any earned setup/deposit deduction explicitly in the quote; do not invent it after payment. House and driver refund their own receipts directly. There is no automatic clawback or guaranteed recovery.

## UI changes required

- Customer: itemized Quote card, Standard/Priority request, Accept quote, mailbox-required Checkout, native-send instructions, split progress, refund status.
- Driver: Quote action on a selected order, editable base/premium/ETA, accept/decline priority, verify own receipt, waive payment with a recorded reason, settlement history.
- House: receipt reconciliation and acknowledgement, without controlling another character's funds.
- Shared: explicitly distinguish Submitted, Recipient-confirmed and Unverified claim; no generic Paid badge backed only by a client packet.

## Other missing features surfaced by review

- Reliable version handshake, acknowledgement/retry and segmented-message completion checks before new protocol fields are enabled.
- Sender/recipient-bound quote revisions and exact order IDs (destination-name matching alone is inadequate for payment).
- Cancellation/decline and customer withdrawal controls beyond active camp closure.
- Driver capacity, scheduling and priority acceptance rather than a promised speed-up toggle.
- Basic portal destination/capability information and reagent/helper availability reported by the provider.
- Block/report/opt-out and bounded history/cleanup controls suitable for a public network.
- Live multi-client and money-transfer tests on the supported client, using informed test users and tiny test amounts.

## Public release decision

Keep the current public addon coordination-only until the house commission model is clarified with Blizzard. Their organized-services policy permits individual/guild sales for gold while restricting organizations offering matchmaking/escrow and other non-traditional services. The proposed commission-based dispatch setup needs a specific clarification; this review cannot label it approved or definitively prohibited. Ask about a same-realm guild travel service with optional provider priority, explicit direct player payments and a 20% guild/house commission. Do not describe the addon as escrow or imply guaranteed protection.

References:
- https://us.forums.blizzard.com/en/wow/t/policy-update-for-organized-in-game-services-january-2022/1176836
- https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua
