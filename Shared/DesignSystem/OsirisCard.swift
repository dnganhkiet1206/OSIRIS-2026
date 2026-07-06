import SwiftUI

extension View {
    /// The one card surface: a filled, hairline-bordered rounded rectangle.
    /// Replaces three inconsistent `.background(.quaternary.opacity(…), in:
    /// RoundedRectangle(cornerRadius: 8|14))` call sites (M9-0 audit Q4) with a
    /// single token-driven treatment. Prominence stays quiet — surface + a
    /// 1-pt border, no shadow, no glow.
    func osirisCard(
        _ surface: Color = OsirisColor.card,
        radius: CGFloat = Radius.card
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background(surface, in: shape)
            .overlay(shape.strokeBorder(OsirisColor.border, lineWidth: 1))
    }
}
