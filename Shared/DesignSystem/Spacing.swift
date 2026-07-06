import CoreGraphics

/// Spacing scale — horizontal/vertical rhythm tokens, the single source of
/// truth for layout spacing. Grouped from the values already recurring across
/// the views (M9-2 audit) so spacing stops drifting per-view.
///
/// Values are unchanged from what shipped, with one consistency fix: the tight
/// metadata-stack spacing was 2pt in two views and 4pt in the reference
/// component — unified to `xs` (4).
///
/// Deliberately off this scale and kept as literals where they occur: the
/// intentional zero-gap detail stack, the chat bubble's own internal padding
/// (14/10, tied to its shape), the message-bubble width inset (40), the
/// empty-state top offset (80), and the capsule badge's micro-padding — these
/// are positional or component-internal, not page rhythm.
enum Spacing {
    static let xs: CGFloat = 4   // tight metadata stacks
    static let sm: CGFloat = 6   // grouped rows
    static let md: CGFloat = 8   // control rows, inset cards
    static let lg: CGFloat = 12  // section stacks
    static let xl: CGFloat = 16  // container padding
}
