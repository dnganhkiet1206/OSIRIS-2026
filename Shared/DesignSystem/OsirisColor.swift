import SwiftUI

/// OSIRIS Design Language V1 — the single source of truth for colour.
///
/// Dark only. Emphasis comes from spacing, hierarchy and contrast, never from
/// colour: one near-white accent, grayscale surfaces, no gradients, glow, neon
/// or glassmorphism. This enum is data (the palette); it is applied where the
/// design system already reaches (the standardised card and the chat bubble in
/// M9-1) and rolls out to the remaining surfaces over later M9 Consistency
/// steps. UI-only (SwiftUI) → compiled in the app target, verified by CI macOS.
enum OsirisColor {
    // Surfaces (darkest → lightest)
    static let background = Color(hex: 0x090909) // app chrome / base
    static let elevated   = Color(hex: 0x121212) // elevated surfaces
    static let card       = Color(hex: 0x181818) // cards
    static let border     = Color(hex: 0x2B2B2B) // hairline separators

    // Text
    static let textPrimary   = Color(hex: 0xF4F4F4)
    static let textSecondary = Color(hex: 0xA8A8A8)
    // Nudged from the spec's #6D6D6D (3.85:1, below WCAG AA) to #7C7C7C
    // (4.77:1) so tertiary body text stays AA-legible — M8-6 is inviolable.
    static let textTertiary  = Color(hex: 0x7C7C7C)

    // Accent — deliberately the same near-white as primary text: prominence is
    // earned through contrast, not a second hue.
    static let accent = Color(hex: 0xF4F4F4)
}

private extension Color {
    /// 0xRRGGBB literal → opaque sRGB colour. Keeps the palette readable as hex.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
