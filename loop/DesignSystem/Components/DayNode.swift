import SwiftUI

struct DayNode: View {
    let label: String
    let state: DayState

    enum DayState { case done, today, pending }
    @State private var pulse = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(fill)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(border, lineWidth: 1.5))
                    .shadow(color: state == .today ? Color.coral.opacity(0.4) : .clear, radius: pulse ? 11 : 8)
                    .shadow(color: state == .today ? Color.coral.opacity(0.15) : .clear, radius: pulse ? 22 : 16)
                iconView
            }
            .scaleEffect(state == .today && pulse ? 1.06 : 1)

            Text(label)
                .font(LoopFont.bold(10))
                .foregroundColor(state == .today ? .coral : .textMuted)
        }
        .onAppear {
            if state == .today, !reduceMotion {
                withAnimation(LoopAnimation.pulseFast) {
                    pulse = true
                }
            }
        }
    }

    private var fill: Color {
        switch state {
        case .done: return Color.loopGold.opacity(0.16)
        case .today: return .coral
        case .pending: return .trackInactive
        }
    }

    private var border: Color {
        switch state {
        case .done: return Color.loopGold.opacity(0.3)
        case .today: return .coral
        case .pending: return .borderSoft
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch state {
        case .done:
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.loopGold)
        case .today:
            if reduceMotion {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            } else {
                PhaseAnimator([1.0, 1.2, 1.0]) { scale in
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                } animation: { _ in
                    .easeInOut(duration: 0.9)
                }
            }
        case .pending:
            EmptyView()
        }
    }
}
