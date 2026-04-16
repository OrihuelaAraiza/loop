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
            LoopCard(accentColor: .loopGold) {
                Text("Leaderboard y retos semanales")
                    .font(LoopFont.bold(18))
                    .foregroundColor(.textPrimary)
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
                    Circle()
                        .fill(LinearGradient(colors: [.amethyst, .cerulean], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 90, height: 90)
                        .overlay(Text(initials).font(LoopFont.bold(26)).foregroundColor(.white))
                    Text(appState.userProfile.name.isEmpty ? "Loop Learner" : appState.userProfile.name)
                        .font(LoopFont.bold(22))
                        .foregroundColor(.textPrimary)
                    LoopCard {
                        Text("Nivel \(appState.gameState.level) · \(appState.gameState.totalXP) XP")
                            .font(LoopFont.semiBold(15))
                            .foregroundColor(.textSecond)
                    }
                }
                .padding(Spacing.lg)
                .padding(.bottom, 90)
            }
        }
    }

    private var initials: String {
        let name = appState.userProfile.name.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return "L" }
        return String(name.prefix(1)).uppercased()
    }
}
