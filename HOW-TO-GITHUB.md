# Publish with GitHub Desktop

This folder contains prepared source files, not an initialized Git repository. No commit, remote, tag or push has been created for you.

## First publication

1. Open GitHub Desktop and choose **File → Add local repository**. Choose this exact folder, not the mixed parent workspace.
2. If Desktop reports that it is not a Git repository, use its **create a repository here** option. Check the destination carefully: it must remain this folder, without an extra nested folder of the same name.
3. If using **New repository** instead, use this folder's existing name and select its **parent** as Local path. Desktop creates the name inside that path. README, `.gitignore` and MIT LICENSE already exist; do not replace them with generated versions.
4. Review the Changes list. Source Lua/TOCs, documentation, build scripts, tests, license, `.gitignore`, `.gitattributes` and `.editorconfig` should be present. Release ZIPs, `.env`, account data, dependencies and desktop helpers should not appear.
5. Commit with a message such as **Prepare initial public beta source**.
6. Select **Publish repository**, confirm the intended owner/name, and choose the visibility you want. A public repository exposes all committed files and history.
7. After publication, use the actual repository URL in the CurseForge Source field. Enable GitHub Issues or another real support channel. Do not invent project URLs or IDs.

The prepared README is the repository homepage. The addon README inside its runtime folder is still included in game release packages. GitHub's automatic Source code ZIP is a developer source snapshot, not necessarily the correctly arranged addon installation ZIP.

## Later changes

Work in this repository, create a branch in Desktop when appropriate, edit source, run the documented checks, inspect the diff, commit and **Push origin**. Update the changelog and all relevant manifests for a new release. Keep generic/Camelot manifests aligned. Do not run the original workspace export over a repository after you start maintaining it here.

## Release uploads

Run `Build.ps1` from the repository root. Review the generated test/hash record and complete live client checks. Commit the source first, then create a GitHub Release for that commit and attach the named installable ZIP from the generated output. ZIPs/checksums stay ignored in source and are uploaded as release assets. Follow RELEASE.md for the project's exact output/version.

Upload the same reviewed addon ZIP to the existing CurseForge project, with the appropriate tested version and Beta/Release label. Publishing on GitHub does not submit or approve a CurseForge file.

## If something is already tracked

`.gitignore` applies to untracked files; it does not remove an already committed secret or account file. Do not publish such a history. Remove it from tracking/history as appropriate, rotate exposed credentials, and review before publishing. No credentials are needed to build these addons.

References:

- https://docs.github.com/en/desktop/adding-and-cloning-repositories/adding-a-repository-from-your-local-computer-to-github-desktop
- https://docs.github.com/en/desktop/overview/creating-your-first-repository-using-github-desktop
- https://docs.github.com/en/get-started/git-basics/ignoring-files
