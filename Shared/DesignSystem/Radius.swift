import CoreGraphics

/// Corner-radius tokens. Replaces the ad-hoc 8-vs-14 split found across the
/// card surfaces (M9-0 audit Q4): `small` for inset rows, `card` for the
/// container that holds them.
enum Radius {
    static let small: CGFloat = 8
    static let card: CGFloat = 14
}
