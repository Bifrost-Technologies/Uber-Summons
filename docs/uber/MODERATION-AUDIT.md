# Public submission moderation audit

Reviewed 2026-11-17 against CurseForge Moderation Policies (modified 2026-10-22) and Blizzard UI Add-On Development Policy.

**Result: corrected beta candidate; not certified or submitted.** Scope: standalone Uber public ZIP and its listing materials. Private tools are excluded. Real-client testing and author-supplied screenshots remain pending.

## Findings and actions

| Area | Result / action |
|---|---|
| Functional value | Order, status, location, application and review features are implemented in readable Lua. |
| Description and summary | English functional description, bounded preparation requests and explicit portal limits. No claimed global authorization server, offline email or automated gameplay. |
| Mage feature accuracy | Fixed Warlock-only gate. Reviewed Mages can apply/open portal service; signed roster data carries class, icons reflect class, and Ready action says Portal now. Dispatcher still verifies class and capabilities manually. |
| Packaging | Single Uber root, declared Lua/TOCs, MIT license and changelog. Archive file list and per-file hashes checked. No private combat code, C++ executable, SavedVariables or credentials included. |
| Avatar | Stricter moderation page specifies exactly 400×400. uber-logo-400.png is the selected fantasy logo exported at exactly 400×400. The generated branding is not an in-game screenshot. |
| AI/showcase accuracy | Fantasy logo is AI-generated branding, not a game screenshot. Mocked layout previews are labeled. Listing disclosure added; use real author screenshots for UI evidence. |
| Assets and rights | Code references native game UI textures rather than bundling ripped art. MIT attribution is preserved. AI branding is newly generated, but this review does not guarantee trademark clearance or originality against every existing work. |
| Project identity | Requested listing title is Uber; that alone does not distinguish it from existing similarly named addons. Confirm final name availability and similarity in CurseForge; avoid official ride-sharing company branding. |
| Traffic and player impact | Bounded addon packets and request cooldowns; no unsolicited visible guild recruitment. Normal whispers/friend requests are user-clicked. Approval revisions require refresh for offline clients. |
| Developer rules | No premium software unlocks, advertisements, automatic rituals or external executable dependency. The package includes native-mail payment drafts and a house commission; those features require separate policy review. Final ToS decisions belong to the platforms. |
| External downloads | Public description contains no external file-download links. Use CurseForge-hosted files; do not add file mirrors to the listing. |
| Variants and updates | One shared host/client addon serves both classes. Do not create separate cosmetic Warlock/Mage projects or re-upload unchanged builds for visibility. Beta.2 contains functional class-aware changes. |
| Support | Enable Comments and a working issue channel. Source/support URLs must be real if supplied; leave absent instead of publishing placeholders. |

## Release evidence

Run scripts/build-uber-release.ps1. PREFLIGHT.txt records actual assertion totals, SHA-256 and archive audit results. Simulated clients exercise request, approval, long notes, Ready/join ordering, Mage portal requests, revocation and map failures. Those tests do not validate the real client's protected APIs, server delivery or every screen size.

## Remaining author/release checks

- Confirm title availability/branding rights and the exact supported client build/version tag.
- Exercise customer, Mage, Warlock and dispatcher flows in the real client, including actual portal/summon interaction, map and whisper behavior.
- Supply real screenshots; do not imply the generated logo or mock layout images are rendered gameplay.
- Upload the exact checked beta ZIP and 400×400 avatar; review all form text and keep license/support metadata consistent.
- Submit once and respond to moderation feedback. If changes are requested, update the existing submission rather than deleting/recreating to evade review.

## References

- https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies
- https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534

These notes record an engineering review and preparation, not legal advice, official approval or a guaranteed moderation outcome.


## Superseding 0.3 payment scope
Earlier coordination-only conclusions do not certify the new commission features. Billing.lua observes native mail and prepares text drafts; no automatic SendMail transfer is invoked. Buyer reports are explicitly unverified. This release adds financial claims and needs fresh live-client and policy review. See the current DESCRIPTION.md and README for exact pricing, 22s portal minimum, direct-recipient mail and offline-house limitations.
