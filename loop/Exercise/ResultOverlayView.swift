import SwiftUI
import Vortex

struct ResultOverlayView: View {
    let result: AnswerResponse?
    let exercise: ExerciseResponse
    let headline: String
    let isJuniorMode: Bool
    let isShowingCorrectAnswer: Bool
    var onNext: (() -> Void)? = nil
    var onRetry: (() -> Void)? = nil
    var onShowCorrectAnswer: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var xpBounce = 0.0

    private var isCorrect: Bool { result?.isCorrect ?? false }
    private var explanationTitle: String { isJuniorMode ? "Por que?" : "Explicacion" }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {}

            if isCorrect && !reduceMotion {
                VortexView(.confetti) {
                    Circle().fill(Color.coral).frame(width: 8, height: 8).tag("coral")
                    Circle().fill(Color.loopGold).frame(width: 8, height: 8).tag("gold")
                    Circle().fill(Color.amethyst).frame(width: 8, height: 8).tag("amethyst")
                    Circle().fill(Color.cerulean).frame(width: 8, height: 8).tag("cerulean")
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    LoopyExpressionView(
                        expression: isCorrect ? (isJuniorMode ? .excited : .celebrating) : .sad,
                        size: isJuniorMode ? 100 : 80
                    )

                    VStack(spacing: 8) {
                        Text(headline)
                            .font(LoopFont.bold(LoopLayout.fontSize(base: 24, junior: isJuniorMode)))
                            .foregroundColor(isCorrect ? .coral : .periwinkle)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                        if isCorrect, let result {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.loopGold)
                                xpChipText(for: result.xpEarned)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.loopGold.opacity(0.15))
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.periwinkle)
                                .font(.system(size: 13))
                            Text(explanationTitle)
                                .font(LoopFont.bold(13))
                                .foregroundColor(.periwinkle)
                        }

                        Text(exercise.explanation)
                            .font(LoopFont.regular(LoopLayout.fontSize(base: 14, junior: isJuniorMode)))
                            .foregroundColor(.textSecond)
                            .fixedSize(horizontal: false, vertical: true)

                        if !isCorrect, isShowingCorrectAnswer {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(isJuniorMode ? "Respuesta correcta" : "Respuesta correcta")
                                    .font(LoopFont.bold(12))
                                    .foregroundColor(.coral)
                                Text(result?.correctAnswerDisplay ?? exercise.correctAnswerDisplay ?? exercise.correctAnswer)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.textPrimary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.loopSurf1)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(16)
                    .background(Color.loopSurf2)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(spacing: 12) {
                        Button {
                            if isCorrect {
                                onNext?()
                            } else {
                                onRetry?()
                            }
                            HapticManager.shared.impact(.medium)
                        } label: {
                            Text(isCorrect
                                 ? (isJuniorMode ? "Siguiente aventura" : "Continuar")
                                 : (isJuniorMode ? "Intentarlo de nuevo" : "Reintentar"))
                                .font(LoopFont.bold(17))
                        }
                        .buttonStyle(LoopCTAButton())

                        if !isCorrect {
                            Button {
                                onShowCorrectAnswer?()
                                HapticManager.shared.impact(.light)
                            } label: {
                                Text(isJuniorMode ? "Ver la respuesta" : "Ver respuesta correcta")
                                    .font(LoopFont.semiBold(15))
                                    .foregroundColor(.periwinkle)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(24)
                .background(Color.loopBG)
                .clipShape(RoundedRectangle(cornerRadius: LoopLayout.cornerRadius(junior: isJuniorMode) + 8))
                .padding(.horizontal, 16)
                .offset(y: appeared ? 0 : 60)
                .opacity(appeared ? 1 : 0)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                appeared = true
            }

            if isCorrect {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
                        xpBounce = 1
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func xpChipText(for value: Int) -> some View {
        let label = "\(LoopCopy.xpLabel(junior: isJuniorMode))"

        if #available(iOS 17, *), !reduceMotion {
            Text("+\(value) \(label)")
                .font(LoopFont.bold(18))
                .foregroundColor(.loopGold)
                .textRenderer(XPBounceRenderer(bounceAmount: xpBounce))
                .contentTransition(.numericText(countsDown: false))
        } else {
            Text("+\(value) \(label)")
                .font(LoopFont.bold(18))
                .foregroundColor(.loopGold)
        }
    }
}
