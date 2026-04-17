import Combine
import SwiftUI

struct LoopyTypingDots: View {
    @State private var phase: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let timer = Timer.publish(every: 0.22, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 3, id: \.self) { index in
                Circle()
                    .fill(Color.periwinkle.opacity(phase == index ? 1 : 0.35))
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == index ? 1.15 : 1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .fill(Color.loopSurf2.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .stroke(Color.borderMid, lineWidth: 1)
        )
        .onReceive(timer) { _ in
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                phase = (phase + 1) % 3
            }
        }
    }
}
