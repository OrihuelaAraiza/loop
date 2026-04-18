import SwiftUI

/// Animación de selección unificada para chips/cards: un pulso radial que nace
/// del propio contenedor cuando el elemento entra en estado `isSelected`.
/// No depende de Pow y no puede "desfasarse": se ancla al frame del elemento.
struct LoopSelectionBloom: ViewModifier {
    let isSelected: Bool
    var tint: Color = .coral
    var shape: BloomShape = .roundedRectangle(cornerRadius: 14)

    enum BloomShape {
        case circle
        case roundedRectangle(cornerRadius: CGFloat)
    }

    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if isSelected && !reduceMotion {
                    ZStack {
                        strokeView
                            .scaleEffect(animate ? 1.25 : 1)
                        fillView
                            .scaleEffect(animate ? 1.12 : 1)
                    }
                    .allowsHitTesting(false)
                }
            }
            .onChange(of: isSelected) { _, newValue in
                guard newValue, !reduceMotion else { return }
                animate = false
                withAnimation(.easeOut(duration: 0.55)) {
                    animate = true
                }
            }
    }

    @ViewBuilder
    private var strokeView: some View {
        switch shape {
        case .circle:
            Circle().stroke(tint.opacity(animate ? 0 : 0.55), lineWidth: animate ? 0 : 2)
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(tint.opacity(animate ? 0 : 0.55), lineWidth: animate ? 0 : 2)
        }
    }

    @ViewBuilder
    private var fillView: some View {
        switch shape {
        case .circle:
            Circle().fill(tint.opacity(animate ? 0 : 0.18))
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(tint.opacity(animate ? 0 : 0.18))
        }
    }
}

extension View {
    func loopSelectionBloom(
        isSelected: Bool,
        tint: Color = .coral,
        shape: LoopSelectionBloom.BloomShape = .roundedRectangle(cornerRadius: 14)
    ) -> some View {
        modifier(LoopSelectionBloom(isSelected: isSelected, tint: tint, shape: shape))
    }
}
