# Archive verification repair — 2026-11-17

Reported upload: Uber-0.3.0-beta.1.zip. CurseForge banner: “Failed to verify archive.” This is not a specific finding against pricing, branding or addon features.

## Confirmed defect

The Windows Compress-Archive output stored backslashes in raw ZIP local and central entry names, for example `Uber\Billing.lua`. Local archive tools normalized these separators when displaying paths. Our earlier audit also normalized paths, concealing this portability defect. This is a plausible explanation of the verification failure; only CurseForge can confirm its internal failure reason.

## Repair and evidence

- The build script now creates ZIP entries explicitly as `Uber/Billing.lua` using forward slashes.
- A separate raw-header verifier rejects backslashes, duplicate paths, mismatched local names, encryption, unsupported compression, bad sizes and bad CRC checksums.
- The previous-format ZIP fails the new check at its first backslash path. The repaired ZIP passes all 13 entries, decompression and CRC checks.
- All 125 existing Lua assertions pass. File contents are unchanged by this packaging repair; the addon version remains 0.3.0-beta.1.
- ZIP file list and each decompressed file's SHA-256 are also compared with the source.

## Upload

Use the rebuilt `dist/Uber-0.3.0-beta.1.zip` or its identical copy in `share/Uber-submission`. Do not upload the whole handoff directory or the `before-path-fix` diagnostic backup. The author has already submitted a file; earlier “not submitted” notes describe agent actions only and are not the project's current moderation status.

Use the existing project and the upload/replacement action offered in the failed file notice. Select the actual supported Forever version. Do not delete/recreate the project. If the corrected archive still fails, give CurseForge support the exact banner, project/file IDs, selected game version and the new ZIP SHA-256; ask for the archive processor's specific diagnostic.

Project-description, payment-policy, screenshots and live-client validation checks remain separate from this archive repair. This does not claim approval of those features.

References:

- https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies
- https://support.curseforge.com/support/solutions/articles/9000209856
