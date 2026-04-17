import SwiftUI

/// Wrapper que aplica XPBounceRenderer al cambiar el valor.
/// En iOS <17 cae a un Text normal (sin renderer).
struct XPBounceText: View {
    let value: Int
    var font: Font = LoopFont.bold(14)
    var color: Color = Color.mint
    var suffix: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounceAmount: Double = 0

    var body: some View {
        Group {
            if #available(iOS 17, *), !reduceMotion {
                content
                    .textRenderer(XPBounceRenderer(bounceAmount: bounceAmount))
                    .onChange(of: value) { _, _ in
                        bounceAmount = 0
                        withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
                            bounceAmount = 1
                        }
                    }
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack(spacing: 2) {
            Text("\(value)")
                .contentTransition(.numericText(countsDown: false))
            if let suffix {
                Text(suffix)
            }
        }
        .font(font)
        .foregroundColor(color)
        .animation(LoopAnimation.springMedium, value: value)
    }
}
