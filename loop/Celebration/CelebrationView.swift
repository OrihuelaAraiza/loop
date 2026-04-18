import SwiftUI

struct CelebrationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayXP: Int = 0
    let onNext: () -> Void

    private var completionXP: Int {
        appState.lastLessonCompletion?.xpGained ?? 0
    }

    private var readyLessons: Int {
        min(appState.currentCourse?.resolvedReadyLessons ?? 0, max(totalLessons, 0))
    }

    private var totalLessons: Int {
        max(appState.currentCourse?.totalLessons ?? 0, 0)
    }

    private var celebrationHighlights: [String] {
        var highlights: [String] = []

        if let lessonTitle = appState.lastLessonCompletion?.lessonTitle,
           !lessonTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            highlights.append(lessonTitle)
        }

        if let course = appState.currentCourse {
            highlights.append(course.resolvedTitle)
            if totalLessons > 0 {
                highlights.append("\(readyLessons) de \(totalLessons) lecciones listas")
            }
        }

        highlights.append("\(appState.gameState.hearts) corazones disponibles")
        return Array(highlights.prefix(4))
    }

    private var streakSegments: [Bool] {
        let total = max(min(10, max(appState.gameState.currentStreak, 1)), 1)
        let done = min(appState.gameState.currentStreak, total)
        return (0 ..< total).map { $0 < done }
    }

    var body: some View {
        ZStack {
            LoopMeshBackground()

            ConfettiLayer()
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    celebratingLoopy

                    Text("Lección completada")
                        .font(LoopFont.black(28))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    ChipView(icon: "star.fill", text: "+\(displayXP) XP", tint: .amethyst)
                        .contentTransition(.numericText())
                        .animation(LoopAnimation.springMedium, value: displayXP)

                    badgeGrid
                    streakBar

                    LoopCTA(title: "Siguiente lección") {
                        HapticManager.shared.impact(.medium)
                        onNext()
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 90)
            }
        }
        .onAppear {
            HapticManager.shared.success()
            animateXP(to: completionXP)
            presentCompletionToastIfNeeded(xp: completionXP)
        }
        .onChange(of: completionXP) { _, newXP in
            animateXP(to: newXP)
            presentCompletionToastIfNeeded(xp: newXP)
        }
    }

    @ViewBuilder
    private var celebratingLoopy: some View {
        if reduceMotion {
            LoopyView(mood: .celebrating)
        } else {
            PhaseAnimator([0.92, 1.08, 1.0]) { phase in
                LoopyView(mood: .celebrating)
                    .scaleEffect(phase)
            } animation: { _ in
                .spring(response: 0.6, dampingFraction: 0.55)
            }
        }
    }

    private var badgeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            ForEach(Array(celebrationHighlights.enumerated()), id: \.offset) { idx, highlight in
                LoopCard(accentColor: idx == 0 ? .amethyst : .clear) {
                    Text(highlight)
                        .font(LoopFont.semiBold(13))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(minHeight: 40)
                        .padding(.vertical, Spacing.sm)
                }
            }
        }
    }

    private var streakBar: some View {
        LoopCard(accentColor: .loopGold) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Racha actual: \(appState.gameState.currentStreak) días")
                    .font(LoopFont.bold(14))
                    .foregroundColor(.textPrimary)
                HStack(spacing: Spacing.xs) {
                    ForEach(Array(streakSegments.enumerated()), id: \.offset) { _, done in
                        RoundedRectangle(cornerRadius: Radius.pill)
                            .fill(done ? Color.loopGold : Color.loopSurf3)
                            .frame(height: 8)
                    }
                }
            }
        }
    }

    private func animateXP(to value: Int) {
        withAnimation(.easeOut(duration: 0.9)) {
            displayXP = value
        }
    }

    private func presentCompletionToastIfNeeded(xp: Int) {
        guard xp > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            LoopToast.lessonComplete(xp: xp)
        }
    }
}
