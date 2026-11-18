# Contributing

Use a branch and describe the concrete behavior your change fixes. Keep addon code readable, preserve MIT notices, and avoid adding required external services or dependencies without updating installation and submission documentation.

Run the documented build/checks before proposing a change. Tests use mocked clients; actual API permissions, multiplayer delivery and UI layout must also be verified in the supported game client where affected. Include the exact client build and relevant reproduction steps. Never use private account SavedVariables or credentials as test fixtures.

Keep player-controlled actions and restricted-data handling explicit. Missing observations stay unknown; client reports are not independently verified facts. Document changes to guild messaging, discovery, logging and persistence. Do not put names from private conversations, tokens, local account paths or executable helpers into this repository.

Update the changelog and affected documentation. Keep Lua/TOCs UTF-8 and generic/Camelot metadata consistent. Generated ZIPs, handoff folders, caches and personal settings remain untracked.
