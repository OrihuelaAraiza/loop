import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selected: MainTab = .home
    @State private var showExercise = false
    @State private var showCelebration = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .home:
                    HomeView()
                        .environmentObject(appState)
                        .onTapGesture(count: 2) { showExercise = true }
                case .map:
                    MapView()
                case .challenges:
                    ChallengesView()
                case .profile:
                    ProfileView()
                        .environmentObject(appState)
                }
            }

            BottomNavBar(selected: $selected)
        }
        .fullScreenCover(isPresented: $showExercise) {
            ExerciseView {
                showExercise = false
                showCelebration = true
            }
        }
        .fullScreenCover(isPresented: $showCelebration) {
            CelebrationView {
                showCelebration = false
            }
        }
    }
}

private struct ChallengesView: View {
    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)
            LoopCard(accentColor: .loopGold, usesGlassSurface: true) {
                Text("Leaderboard y retos semanales")
                    .font(LoopFont.bold(18))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.lg)
        }
    }
}

private struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showsCustomizer = false

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Perfil")
                                .font(LoopFont.black(28))
                                .foregroundColor(.textPrimary)
                            Text("Tu tarjeta vive aqui. Tocala para girarla o editala desde el boton interno.")
                                .font(LoopFont.regular(13))
                                .foregroundColor(.textSecond)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ZStack {
                            Color.clear
                                .frame(height: 328)

                            LoopIdentityCard(
                                userProfile: appState.userProfile,
                                gameState: appState.gameState,
                                isCustomizerPresented: showsCustomizer,
                                onCustomize: {
                                    withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                                        showsCustomizer.toggle()
                                    }
                                }
                            )
                            .padding(.horizontal, 4)
                            .padding(.top, 14)
                            .padding(.bottom, 24)
                        }
                        .padding(.top, 6)
                    }

                    ViewThatFits(in: .vertical) {
                        HStack(spacing: Spacing.md) {
                            statCard(title: "Nivel", value: "\(appState.gameState.level)", tint: .periwinkle)
                            statCard(title: "XP total", value: "\(appState.gameState.totalXP)", tint: .loopGold)
                        }

                        VStack(spacing: Spacing.md) {
                            statCard(title: "Nivel", value: "\(appState.gameState.level)", tint: .periwinkle)
                            statCard(title: "XP total", value: "\(appState.gameState.totalXP)", tint: .loopGold)
                        }
                    }

                    if showsCustomizer {
                        customizationPanel
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    LoopCard(accentColor: .cerulean, showsSceneAccent: true, usesGlassSurface: true) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Enfoque actual")
                                .font(LoopFont.bold(16))
                                .foregroundColor(.textPrimary)
                            Text(summaryLine)
                                .font(LoopFont.regular(14))
                                .foregroundColor(.textSecond)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(Spacing.lg)
                .padding(.top, Spacing.xl)
                .padding(.bottom, 90)
            }
        }
    }

    private func statCard(title: String, value: String, tint: Color) -> some View {
        LoopCard(accentColor: tint, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(LoopFont.bold(10))
                    .foregroundColor(.textMuted)
                Text(value)
                    .font(LoopFont.black(24))
                    .foregroundColor(.textPrimary)
            }
        }
    }

    private var summaryLine: String {
        let name = appState.userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = name.isEmpty ? "Loop Learner" : name
        let language = appState.userProfile.generatedPlan?.language.rawValue ?? "Python"
        return "\(displayName) esta en ruta de \(appState.userProfile.goal.rawValue.lowercased()), practicando \(appState.userProfile.minutesPerDay) minutos por sesion en \(language)."
    }

    private var customizationPanel: some View {
        LoopCard(accentColor: customizationTint, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                compactSection(title: "Paleta") {
                    HStack(spacing: Spacing.sm) {
                        ForEach(IdentityCardPalette.allCases) { palette in
                            Button {
                                appState.userProfile.cardPalette = palette
                            } label: {
                                paletteSwatch(palette)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                compactSection(title: "Badge") {
                    ViewThatFits {
                        HStack(spacing: Spacing.sm) {
                            ForEach(IdentityCardBadge.allCases) { badge in
                                Button {
                                    appState.userProfile.cardBadge = badge
                                } label: {
                                    capsuleOption(
                                        badge.rawValue,
                                        isSelected: appState.userProfile.cardBadge == badge,
                                        tint: badgeTint(for: badge)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            ForEach(IdentityCardBadge.allCases) { badge in
                                Button {
                                    appState.userProfile.cardBadge = badge
                                } label: {
                                    capsuleOption(
                                        badge.rawValue,
                                        isSelected: appState.userProfile.cardBadge == badge,
                                        tint: badgeTint(for: badge)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                HStack(spacing: Spacing.md) {
                    Text("Movimiento 3D")
                        .font(LoopFont.semiBold(13))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { appState.userProfile.cardMotionEnabled },
                            set: { appState.userProfile.cardMotionEnabled = $0 }
                        )
                    )
                    .labelsHidden()
                    .tint(customizationTint)
                }
            }
        }
    }

    private func compactSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(LoopFont.semiBold(12))
                .foregroundColor(.textSecond)
            content()
        }
    }

    private func paletteSwatch(_ palette: IdentityCardPalette) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(paletteTint(for: palette))
                .frame(width: 18, height: 18)
                .padding(6)
                .background(
                    Circle()
                        .fill(Color.loopSurf2.opacity(0.9))
                )
                .overlay(
                    Circle()
                        .stroke(appState.userProfile.cardPalette == palette ? paletteTint(for: palette) : Color.borderSoft, lineWidth: 1.4)
                )

            Text(palette.rawValue)
                .font(LoopFont.medium(12))
                .foregroundColor(appState.userProfile.cardPalette == palette ? .textPrimary : .textSecond)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private func capsuleOption(_ title: String, isSelected: Bool, tint: Color) -> some View {
        Text(title)
            .font(LoopFont.medium(12))
            .foregroundColor(isSelected ? .textPrimary : .textSecond)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? tint.opacity(0.18) : Color.loopSurf2.opacity(0.9))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? tint.opacity(0.4) : Color.borderSoft, lineWidth: 1)
            )
    }

    private func paletteTint(for palette: IdentityCardPalette) -> Color {
        switch palette {
        case .coral:
            return .coral
        case .aurora:
            return .mint
        case .midnight:
            return .periwinkle
        }
    }

    private func badgeTint(for badge: IdentityCardBadge) -> Color {
        switch badge {
        case .creador:
            return .coral
        case .enfoque:
            return .cerulean
        case .racha:
            return .loopGold
        }
    }

    private var customizationTint: Color {
        paletteTint(for: appState.userProfile.cardPalette)
    }
}
