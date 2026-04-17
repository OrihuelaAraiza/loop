import SwiftUI

struct CelebrationView: View {
    @StateObject private var viewModel = CelebrationViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayXP: Int = 0
    let onNext: () -> Void

    var body: some View {
        ZStack {
            LoopMeshBackground()

            ConfettiLayer()
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    celebratingLoopy

                    Text("Leccion completada")
                        .font(LoopFont.black(28))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    ChipView(icon: "star.fill", text: "+\(displayXP) XP", tint: .amethyst)
                        .contentTransition(.numericText())
                        .animation(LoopAnimation.springMedium, value: displayXP)

                    badgeGrid
                    streakBar

                    LoopCTA(title: "Siguiente leccion") {
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
            withAnimation(.easeOut(duration: 0.9)) {
                displayXP = viewModel.xpGained
            }
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
            ForEach(Array(viewModel.badges.enumerated()), id: \.offset) { idx, badge in
                LoopCard(accentColor: idx < 2 ? .amethyst : .clear) {
                    Text(badge)
                        .font(LoopFont.semiBold(13))
                        .foregroundColor(idx < 2 ? .textPrimary : .textMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(minHeight: 40)
                        .padding(.vertical, Spacing.sm)
                }
                .opacity(idx < 2 ? 1 : 0.45)
            }
        }
    }

    private var streakBar: some View {
        LoopCard(accentColor: .loopGold) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Racha de 10 dias")
                    .font(LoopFont.bold(14))
                    .foregroundColor(.textPrimary)
                HStack(spacing: Spacing.xs) {
                    ForEach(Array(viewModel.streakDays.enumerated()), id: \.offset) { _, done in
                        RoundedRectangle(cornerRadius: Radius.pill)
                            .fill(done ? Color.loopGold : Color.loopSurf3)
                            .frame(height: 8)
                    }
                }
            }
        }
    }
}

