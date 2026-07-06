# Shared

Cross-cutting UI and utilities (DesignSystem, Components, Extensions,
Utilities). Never business logic, never Core logic.

## DesignSystem (M9-1)

The OSIRIS Design Language V1 tokens — the single source of truth for the
app's look:

- `OsirisColor` — dark-only grayscale palette; one near-white accent.
- `Radius` — corner-radius tokens (`small`, `card`).
- `OsirisCard` — the `.osirisCard()` surface modifier.

These are SwiftUI-only (compiled in the app target, verified by CI macOS),
plain data + one `ViewModifier` — no Theme/Style/Component engine or manager.
The palette rolls out across surfaces over the M9 Consistency steps; M9-1
establishes the tokens and applies them to the card surfaces and the chat
bubble.
