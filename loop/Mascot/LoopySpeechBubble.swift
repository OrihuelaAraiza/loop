import SwiftUI

/// Bubble de Loopy: primero muestra los typing dots y despues el texto
/// con WordByWordRenderer (o texto plano si iOS <17 / reduceMotion).
struct LoopySpeechBubble: View {
    let primary: String
    var secondary: String? = nil
    var dotsDuration: TimeInterval = 0.6
    var textDuration: TimeInterval = 1.2

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showText: Bool = false
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !showText {
                LoopyTypingDots()
                    .transition(.opacity)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    textBody(primary)
                        .font(LoopFont.bold(16))
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let secondary {
                        textBody(secondary)
                            .font(LoopFont.regular(13))
                            .foregroundColor(.textSecond)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            if reduceMotion {
                showText = true
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + dotsDuration) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showText = true
                }
                withAnimation(.linear(duration: textDuration)) {
                    elapsed = textDuration
                }
            }
        }
    }

    @ViewBuilder
    private func textBody(_ string: String) -> some View {
        if #available(iOS 17, *), !reduceMotion {
            Text(string)
                .textRenderer(WordByWordRenderer(
                    elapsedTime: elapsed,
                    totalDuration: textDuration
                ))
        } else {
            Text(string)
        }
    }
}
