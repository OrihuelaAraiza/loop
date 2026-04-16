import Lottie
import SwiftUI

struct CelebrationView: View {
    @StateObject private var viewModel = CelebrationViewModel()
    let onNext: () -> Void

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .coral, bottomColor: .amethyst)
            ConfettiLottieView()
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    LoopyView(mood: .celebrating)
                    Text("Leccion completada")
                        .font(LoopFont.black(28))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    ChipView(icon: "star.fill", text: "+\(viewModel.xpGained) XP", tint: .amethyst)

                    badgeGrid
                    streakBar

                    LoopCTA(title: "Siguiente leccion", action: onNext)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 90)
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

private struct ConfettiLottieView: UIViewRepresentable {
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: "confetti")
        animationView.loopMode = .playOnce
        animationView.play()
        animationView.contentMode = .scaleAspectFit
        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
