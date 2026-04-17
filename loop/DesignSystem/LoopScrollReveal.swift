import SwiftUI

/// scrollTransition reusable para cards dentro de ScrollViews.
/// Hace fade + scale + blur sutil segun la posicion en el viewport.
extension View {
    @ViewBuilder
    func loopScrollReveal() -> some View {
        if #available(iOS 17, *) {
            modifier(LoopScrollRevealModifier())
        } else {
            self
        }
    }
}

@available(iOS 17, *)
private struct LoopScrollRevealModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.scrollTransition(
                .animated(.spring(duration: 0.35, bounce: 0.2))
            ) { view, phase in
                view
                    .opacity(phase.isIdentity ? 1.0 : 0.5)
                    .scaleEffect(
                        x: phase.isIdentity ? 1.0 : 0.95,
                        y: phase.isIdentity ? 1.0 : 0.95
                    )
                    .blur(radius: phase.isIdentity ? 0 : 3)
                    .offset(y: phase.isIdentity ? 0 : 12)
            }
        }
    }
}
