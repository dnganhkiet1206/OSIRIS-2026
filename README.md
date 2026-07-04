# OSIRIS

Personal AI Executive Operating System for iOS. The user states a goal;
OSIRIS produces a usable deliverable. Conversation is the interface,
execution is the product.

## Build

- Core platform (any OS): `swift build && swift test`
- iOS app (macOS): `xcodegen generate` then open `OSIRIS.xcodeproj`

## Documentation

Start with `Docs/PROJECT_STATE.md` (always current), then
`Docs/PROJECT_BLUEPRINT.md` for the architecture. Task queue: `NEXT_TASK.md`.

## Contributing a module

New capabilities ship as modules — pure data, no Core changes. Everything
you need is in **`Docs/MODULE_GUIDE.md`** (self-contained: manifest,
keywords, composition, mandatory tests, built-in skill IDs, and a copyable
test harness). Verify with `swift test` on any OS, then open a PR.
