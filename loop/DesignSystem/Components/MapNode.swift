import SwiftUI

struct MapNode: View {
    let state: NodeState
    let number: Int

    enum NodeState { case done, current, next, locked }

    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: 54, height: 54)
                .overlay(Circle().stroke(border, lineWidth: 2.5))
                .shadow(color: glowColor.opacity(0.45), radius: pulse ? 14 : 10)
                .shadow(color: glowColor.opacity(0.12), radius: pulse ? 24 : 16)
            icon
        }
        .scaleEffect(state == .current && pulse ? 1.04 : 1)
        .onAppear {
            if state == .current {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    private var fill: Color {
        switch state {
        case .done: return .mint.opacity(0.2)
        case .current: return .coral
        case .next: return .loopSurf2
        case .locked: return .loopSurf1.opacity(0.6)
        }
    }

    private var border: Color {
        switch state {
        case .done: return .mint
        case .current: return .coral
        case .next: return .periwinkle.opacity(0.7)
        case .locked: return .borderSoft
        }
    }

    private var glowColor: Color {
        switch state {
        case .done: return .mint
        case .current: return .coral
        case .next: return .clear
        case .locked: return .clear
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.mint)
        case .current:
            Text("\(number)")
                .font(LoopFont.bold(16))
                .foregroundColor(.white)
        case .next:
            Text("\(number)")
                .font(LoopFont.bold(16))
                .foregroundColor(.periwinkle)
        case .locked:
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.textMuted)
        }
    }
}
