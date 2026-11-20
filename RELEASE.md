# Uber Summons 0.5.0-beta.8 release

ZIP: WoW-Addons/dist/Public-Release-Ready/Uber-0.5.0-beta.8.zip. Tests skipped at owner request; no live validation or publication performed.

Missing locally: .github/workflows and .pkgmeta. Old RELEASE.md described manual uploads. Workflow now prepared: every branch push packages the public Uber folder as an Actions artifact; version tags additionally upload to CurseForge after configuration.

Required GitHub setup in BifrostTitan/Uber-Summons:
1. Review/commit/push this source and workflow.
2. Settings > Secrets and variables > Actions: add secret CF_API_TOKEN from your CurseForge author account. Never paste the token into source or chat.
3. Add repository variable CF_PROJECT_ID with the actual numeric Uber Summons project ID.
4. Push annotated tag v0.5.0-beta.8 matching the TOC version. Beta tag retains beta classification. Missing credentials cause an explicit workflow failure.

The alternative native CurseForge packager requires a repository webhook; no GitHub workflow is required for that system. Confirm the connected repository, branch/addon-root and whether all commits or only tags are packaged. Native all-commit builds are alpha. Configure only one upload route to avoid duplicates. Official instructions: https://support.curseforge.com/support/solutions/articles/9000197281

Remote hooks/settings/secrets were not accessible for verification here. No push, tag or upload was performed. Original source was backed up under dist/Archive before the Git checkout update. The install ZIP has Uber as its sole root; never upload the whole author repository or private helpers.

Features: realm/faction booking gates, realm filtering, summon-click helper requests, phase keeper invitation popups and rolling host budget, and default-open driver service with optional remembered ON/OFF after restart. Layer labels remain manual/unverified; invitations do not prove phase transfer. Phase hosting remains opt-in independently of default-open driver availability.
