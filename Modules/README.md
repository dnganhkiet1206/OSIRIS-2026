# Modules

Business domains live here as plugins. None exist yet by design — the first
module (YouTube, the reference implementation) is Milestone 4.

Module contract (AD-21): each module is self-contained
(`Manifest / UI / Skills / Templates / Config / Docs / Tests`), registers its
skills into the Core Skill Registry with capability tags, communicates via
Event Bus + capabilities (never names another module), and reuses the Core
100%. A module that needs a Core change is an architecture red flag.
