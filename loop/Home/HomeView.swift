import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var revealCards = false

    private let dayLabels = ["L", "M", "X", "J", "V", "S", "D"]

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    topBar
                        .padding(.top, Spacing.sm)
                    loopyCard
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    streakTracker
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    dailyGoal
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    progressSplit
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    courseList
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 130)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(0.05)) {
                revealCards = true
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            Text("loop")
                .font(LoopFont.black(34))
                .foregroundColor(.textPrimary)
                .overlay(alignment: .trailing) {
                    Circle().fill(Color.coral).frame(width: 9, height: 9).offset(x: 8, y: 4)
                }
            Spacer()
            ChipView(icon: "flame.fill", text: "\(appState.gameState.currentStreak)", tint: .loopGold)
            ChipView(icon: "star.fill", text: "\(appState.gameState.totalXP) XP", tint: .periwinkle)
        }
    }

    private var loopyCard: some View {
        LoopCard(accentColor: .amethyst) {
            HStack(alignment: .center, spacing: Spacing.md) {
                LoopyView(mood: .idle)
                    .scaleEffect(0.46)
                    .frame(width: 72, height: 72)
                    .clipped()
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("LOOPY")
                        .font(LoopFont.bold(12))
                        .foregroundColor(.amethyst)
                    Text("Hola \(appState.userProfile.name.isEmpty ? "coder" : appState.userProfile.name), llevas \(appState.gameState.currentStreak) dias seguidos.")
                        .font(LoopFont.bold(15))
                        .foregroundColor(.textPrimary)
                    Text("Hoy termina el modulo de listas.")
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 90)
        }
    }

    private var streakTracker: some View {
        LoopCard(accentColor: .loopGold.opacity(0.6)) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("RACHA SEMANAL")
                        .font(LoopFont.bold(14))
                        .foregroundColor(.textSecond)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.loopGold)
                        Text("\(appState.gameState.currentStreak) dias")
                            .font(LoopFont.bold(18))
                            .foregroundColor(.loopGold)
                    }
                }
                HStack {
                    ForEach(Array(dayLabels.enumerated()), id: \.offset) { idx, label in
                        Spacer(minLength: 0)
                        DayNode(label: label, state: viewModel.weeklyStates[idx])
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var dailyGoal: some View {
        LoopCard(accentColor: .cerulean) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Meta de hoy")
                        .font(LoopFont.bold(16))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("\(appState.gameState.dailyXP) / \(appState.gameState.dailyGoal) XP")
                        .font(LoopFont.bold(14))
                        .foregroundColor(.mint)
                }
                LoopProgressBar(progress: Double(appState.gameState.dailyXP) / Double(appState.gameState.dailyGoal), height: 12)
            }
        }
    }

    private var progressSplit: some View {
        HStack(spacing: Spacing.md) {
            ProgressMetricCard(
                title: "Completado",
                value: "56%",
                icon: "chart.pie.fill",
                tint: .mint
            )
            ProgressMetricCard(
                title: "Lecciones",
                value: "21/23",
                icon: "book.fill",
                tint: .periwinkle
            )
        }
    }

    private var courseList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Rutas activas")
                .font(LoopFont.bold(20))
                .foregroundColor(.textPrimary)

            ForEach(viewModel.courses) { course in
                LoopCard(accentColor: course.isActive ? .coral : .clear) {
                    HStack {
                        Circle().fill(course.isActive ? Color.coral.opacity(0.2) : Color.loopSurf3).frame(width: 40, height: 40)
                            .overlay(Image(systemName: "chevron.right").foregroundColor(course.isActive ? .coral : .periwinkle))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.title).font(LoopFont.bold(14)).foregroundColor(.textPrimary)
                            Text(course.module).font(LoopFont.regular(12)).foregroundColor(.textSecond)
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(0 ..< 3, id: \.self) { index in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(index < course.stars ? .loopGold : .textMuted)
                            }
                        }
                    }
                }
                .scaleEffect(revealCards ? 1 : 0.98)
                .opacity(revealCards ? 1 : 0)
            }
        }
    }
}
