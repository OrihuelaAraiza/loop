import Combine
import SkeletonUI
import SwiftUI

struct PlanGeneratingOverlay: View {
    @State private var rotate = false
    @State private var pulse = false
    @State private var dotPhase = 0
    @State private var stepIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let steps = [
        "Analizando tus respuestas",
        "Ajustando módulos iniciales",
        "Calibrando tu ritmo",
        "Armando tu plan"
    ]

    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    private let stepTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.loopBG.opacity(0.82)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)

            VStack(spacing: Spacing.lg) {
                ring
                VStack(spacing: 6) {
                    Text("Generando tu plan")
                        .font(LoopFont.bold(18))
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 4) {
                        Text(steps[min(stepIndex, steps.count - 1)])
                            .font(LoopFont.regular(13))
                            .foregroundColor(.textSecond)
                            .contentTransition(.opacity)
                            .id(stepIndex)
                        Text(String(repeating: ".", count: dotPhase + 1))
                            .font(LoopFont.regular(13))
                            .foregroundColor(.textSecond)
                            .frame(width: 18, alignment: .leading)
                    }
                }

                skeletonRoutes
                    .padding(.top, Spacing.sm)
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .fill(Color.loopSurf1.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .stroke(Color.borderMid, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
            .padding(.horizontal, Spacing.xl)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                rotate = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onReceive(timer) { _ in
            dotPhase = (dotPhase + 1) % 3
        }
        .onReceive(stepTimer) { _ in
            if stepIndex < steps.count - 1 {
                withAnimation(.easeInOut(duration: 0.25)) {
                    stepIndex += 1
                }
            }
        }
    }

    private var skeletonRoutes: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(0 ..< 3, id: \.self) { _ in
                HStack(spacing: Spacing.md) {
                    Circle()
                        .skeleton(with: true)
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("")
                            .skeleton(with: true)
                            .shape(type: .rounded(.radius(6)))
                            .frame(width: 120, height: 12)
                        Text("")
                            .skeleton(with: true)
                            .shape(type: .rounded(.radius(5)))
                            .frame(width: 80, height: 10)
                    }
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(Color.loopSurf2.opacity(0.6))
                )
            }
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.trackInactive, lineWidth: 6)
                .frame(width: 72, height: 72)

            Circle()
                .trim(from: 0, to: 0.28)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.coral, Color.amethyst, Color.coral.opacity(0)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(rotate ? 360 : 0))

            Circle()
                .fill(Color.coral.opacity(0.18))
                .frame(width: 28, height: 28)
                .scaleEffect(pulse ? 1.15 : 0.9)

            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.coral)
        }
    }
}

#Preview {
    ZStack {
        Color.loopBG.ignoresSafeArea()
        PlanGeneratingOverlay()
    }
}
