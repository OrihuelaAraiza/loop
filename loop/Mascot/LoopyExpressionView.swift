import SwiftUI

enum LoopyExpression {
    case idle
    case happy
    case thinking
    case sad
    case excited
    case celebrating

    var eyeScale: CGFloat {
        switch self {
        case .happy, .excited, .celebrating:
            return 1.2
        case .sad:
            return 0.7
        case .thinking:
            return 0.9
        case .idle:
            return 1
        }
    }

    var bodyBounce: CGFloat {
        switch self {
        case .excited, .celebrating:
            return -12
        case .happy:
            return -6
        default:
            return 0
        }
    }

    var color: Color {
        switch self {
        case .happy, .excited, .celebrating:
            return .amethyst
        case .sad:
            return .loopSurf2
        case .thinking:
            return .cerulean
        case .idle:
            return .amethyst.opacity(0.9)
        }
    }
}

struct LoopyExpressionView: View {
    let expression: LoopyExpression
    var size: CGFloat = 80

    var body: some View {
        LoopyRiveAvatar(state: expression.riveState, variant: .compact) {
            LoopyLegacyExpressionView(expression: expression, size: size)
        }
        .frame(width: size, height: size)
        .clipped()
    }
}

private struct LoopyLegacyExpressionView: View {
    let expression: LoopyExpression
    var size: CGFloat = 80

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false
    @State private var isBlinking = false
    @State private var blinkTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(expression.color)
                .frame(width: size, height: size * 0.85)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )

            VStack(spacing: size * 0.08) {
                HStack(spacing: size * 0.18) {
                    ForEach(0..<2, id: \.self) { _ in
                        Circle()
                            .fill(.white)
                            .frame(
                                width: size * 0.18,
                                height: isBlinking ? 2 : size * 0.18
                            )
                            .scaleEffect(expression.eyeScale)
                    }
                }

                mouthView
            }

            VStack(spacing: 0) {
                Circle()
                    .fill(Color.coral)
                    .frame(width: size * 0.08, height: size * 0.08)
                Rectangle()
                    .fill(Color.periwinkle.opacity(0.6))
                    .frame(width: 2, height: size * 0.15)
            }
            .offset(y: -(size * 0.55))
        }
        .offset(y: animatedYOffset)
        .animation(floatingAnimation, value: isFloating)
        .onAppear {
            guard !reduceMotion else { return }
            isFloating = true
            startBlinking()
        }
        .onDisappear {
            blinkTask?.cancel()
        }
        .onChange(of: reduceMotion) { _, newValue in
            if newValue {
                blinkTask?.cancel()
                isFloating = false
                isBlinking = false
            } else {
                isFloating = true
                startBlinking()
            }
        }
    }

    private var animatedYOffset: CGFloat {
        if reduceMotion {
            return expression.bodyBounce
        }
        return isFloating ? expression.bodyBounce - 4 : expression.bodyBounce
    }

    private var floatingAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .easeInOut(duration: expression == .excited ? 0.6 : 1.8)
            .repeatForever(autoreverses: true)
    }

    @ViewBuilder
    private var mouthView: some View {
        switch expression {
        case .happy, .excited, .celebrating:
            Arc(startAngle: .degrees(0), endAngle: .degrees(180))
                .stroke(Color.white, lineWidth: 2)
                .frame(width: size * 0.3, height: size * 0.12)
        case .sad:
            Arc(startAngle: .degrees(180), endAngle: .degrees(360))
                .stroke(Color.white.opacity(0.7), lineWidth: 2)
                .frame(width: size * 0.25, height: size * 0.1)
        case .thinking:
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: size * 0.25, height: 2)
                .cornerRadius(1)
        case .idle:
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.6))
                .frame(width: size * 0.28, height: size * 0.06)
        }
    }

    private func startBlinking() {
        blinkTask?.cancel()
        blinkTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3...5)))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.08)) {
                        isBlinking = true
                    }
                }
                try? await Task.sleep(for: .seconds(0.12))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.08)) {
                        isBlinking = false
                    }
                }
            }
        }
    }
}

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
