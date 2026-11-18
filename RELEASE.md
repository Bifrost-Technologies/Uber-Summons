# Uber release how-to

Current prepared source: **0.4.0-beta.1**. Keep Beta until the relevant live-client checks and review work are complete.

1. Update both `Uber/Uber.toc` and `Uber/Uber_Camelot.toc` together when the version changes. Preserve the supported Interface declaration; do not add untested flavors to pass an upload form.
2. Update `Uber/CHANGELOG.md`, the root changelog and player/submission documentation. Preserve MIT notices and distinguish observed receipts, reported payments and client delivery evidence.
3. Run `Build.ps1`. A successful build requires final PASS markers, all four Lua suites, public source scope, manifest checks, raw ZIP header/CRC/decompression checks and per-file hashes.
4. Record affected live checks from `docs/uber/TESTING.md`, including actual spell/map coverage, native mail, party arrival, moderation and UI. Supply real screenshots separately.
5. In GitHub Desktop, review/commit the source changes and push your chosen branch. Generated output stays ignored.
6. Create a release for the reviewed commit/tag. Attach `dist/Uber-<version>.zip` and its SHA-256 sidecar as release assets. The install ZIP has a single `Uber/` root; GitHub's automatic source archive has a different purpose.
7. Use the prepared listing and form text under `share/Uber-submission/release-<version>/` to update the existing CurseForge project. Upload the addon ZIP alone, not the entire author folder. Keep approval/version statements accurate.

Build outputs and metadata are local until you upload them. Neither a successful build nor GitHub publication submits the file to CurseForge. Service-commission policy review and real-client validation remain separate from ZIP verification.
