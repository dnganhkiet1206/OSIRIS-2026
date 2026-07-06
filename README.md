# OSIRIS

Personal AI Executive Operating System for iOS. The user states a goal;
OSIRIS produces a usable deliverable. Conversation is the interface,
execution is the product.

## Build

- Core platform (any OS): `swift build && swift test`
- iOS app (macOS): `xcodegen generate` then open `OSIRIS.xcodeproj`

## Release

Current version: **0.1.0-alpha** (marketing version `0.1.0`, build `1`; set in
`project.yml`). Release notes are in `CHANGELOG.md`. To cut the Alpha: verify CI
is green, then tag the release commit — `git tag v0.1.0-alpha && git push origin
v0.1.0-alpha` — and archive from Xcode (Release configuration, signed) for
TestFlight.

## Documentation

Start with `Docs/PROJECT_STATE.md` (always current), then
`Docs/PROJECT_BLUEPRINT.md` for the architecture. Task queue: `NEXT_TASK.md`.

## Contributing a module

New capabilities ship as modules — pure data, no Core changes. Everything
you need is in **`Docs/MODULE_GUIDE.md`** (self-contained: manifest,
keywords, composition, mandatory tests, built-in skill IDs, and a copyable
test harness). Verify with `swift test` on any OS, then open a PR.
