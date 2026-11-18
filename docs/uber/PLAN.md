# Implementation plan and release gates

## Flow
Discover approved driver -> customize camp request -> receipt -> driver inspects notes -> accept/ETA -> travel -> setup -> summons open -> clicked summon request -> complete.

One addon contains all roles. Five tabs separate discovery, booking, tracking, operations and recruitment. Cards use dark surfaces and mint highlights. Primary actions are explicit; unknown or stale data is shown. Requested preparation is not represented as confirmed inventory. Portraits are genuine unit portraits where available, otherwise labeled Warlock icons.

## Protocol and performance
UBERSUM1 uses bounded flat fields. Notes are three sender-linked 160-byte segments. Incoming state authority is the selected provider; approval authority is the guild-configured dispatcher. No executable deserialization. Roster revisions reject older records; offline clients refresh to obtain revocations.

Four addon packets/second maximum, 100 queued packets, 100 requests per inbox/outbox, 40 riders/camp. UI updates at most once/second while visible. Open unfinished camps publish location around every 30 seconds and defer when queues back up. SavedVariables use normal WoW persistence.

## Release gates
1. Offline protocol, trust and panel tests pass.
2. ZIP contains only declared source, TOCs, license, README and changelog.
3. Confirm exact client metadata and select only tested upload versions.
4. Complete two-client driver/customer/dispatcher tests: details, status/ETA, offline delivery, stale map, revoke, pause, reload.
5. Capture actual screenshots for every tab, context menu and world map.
6. Check distinct title and original icon. Fill real account/source/support details. Submit through author's account, then address moderation feedback.

Live-client and screenshot gates are still open. Package preparation is not publication or a moderation guarantee.
