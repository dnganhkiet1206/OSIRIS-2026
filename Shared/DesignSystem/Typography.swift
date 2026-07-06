import SwiftUI

/// Semantic text roles — the app's typography hierarchy in one place. Built on
/// SwiftUI's Dynamic-Type fonts (never fixed sizes), so Dynamic Type and
/// VoiceOver are preserved exactly. Views name the role, not the size, so the
/// hierarchy stays consistent and can be tuned in one place.
///
/// Font only — colour stays per-site (M9-3 changes no colours). Styles that are
/// deliberately one-off (the empty-state hero title, the monospaced skill id,
/// the capsule badge) stay literal; system-styled text (navigation titles,
/// section headers, LabeledContent) is already uniform and is left to the
/// system.
extension Font {
    /// Prominent item/card title.
    static let osirisTitle = Font.headline
    /// Primary supporting text — the main readable secondary line.
    static let osirisSecondary = Font.subheadline
    /// Metadata, snippets, quiet notes.
    static let osirisCaption = Font.caption
}
