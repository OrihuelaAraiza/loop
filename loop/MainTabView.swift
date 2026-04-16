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

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Perfil")
                            .font(LoopFont.black(28))
                            .foregroundColor(.textPrimary)
                        Text("Tu tarjeta responde al movimiento del telefono. Tocala para girarla.")
                            .font(LoopFont.regular(13))
                            .foregroundColor(.textSecond)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    LoopIdentityCard(userProfile: appState.userProfile, gameState: appState.gameState)

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
}
