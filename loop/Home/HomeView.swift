import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var revealCards = false

    private let dayLabels = ["L", "M", "X", "J", "V", "S", "D"]
    private var learnerName: String {
        appState.userProfile.name.isEmpty ? "coder" : appState.userProfile.name
    }

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
        VStack(alignment: .leading, spacing: Spacing.md) {
            ViewThatFits(in: .vertical) {
                HStack(alignment: .top) {
                    brandLockup
                    Spacer()
                    statsCluster
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    brandLockup
                    statsCluster
                }
            }

            ViewThatFits(in: .vertical) {
                HStack(spacing: Spacing.sm) {
                    homePill(icon: "bolt.fill", text: "Ruta activa")
                    homePill(icon: "clock.fill", text: "\(appState.userProfile.minutesPerDay)m")
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    homePill(icon: "bolt.fill", text: "Ruta activa")
                    homePill(icon: "clock.fill", text: "\(appState.userProfile.minutesPerDay)m")
                }
            }
        }
    }

    private var loopyCard: some View {
        LoopCard(accentColor: .amethyst, showsSceneAccent: true, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ViewThatFits(in: .vertical) {
                    HStack {
                        homePill(icon: "sparkles", text: "Mentor del dia")
                        Spacer()
                        Text("Racha \(appState.gameState.currentStreak)")
                            .font(LoopFont.bold(12))
                            .foregroundColor(.loopGold)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        homePill(icon: "sparkles", text: "Mentor del dia")
                        Text("Racha \(appState.gameState.currentStreak)")
                            .font(LoopFont.bold(12))
                            .foregroundColor(.loopGold)
                    }
                }

                HStack(alignment: .center, spacing: Spacing.md) {
                    LoopyView(mood: .idle)
                        .scaleEffect(0.46)
                        .frame(width: 72, height: 72)
                        .clipped()
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Hola \(learnerName), llevas \(appState.gameState.currentStreak) dias seguidos.")
                            .font(LoopFont.bold(16))
                            .foregroundColor(.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Hoy toca cerrar el modulo de listas y sumar una victoria rapida.")
                            .font(LoopFont.regular(13))
                            .foregroundColor(.textSecond)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: Spacing.sm) {
                        homePill(icon: "flag.fill", text: "Meta: modulo de listas")
                        homePill(icon: "arrow.right.circle.fill", text: "Doble tap para entrar")
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        homePill(icon: "flag.fill", text: "Meta: modulo de listas")
                        homePill(icon: "arrow.right.circle.fill", text: "Doble tap para entrar")
                    }
                }
            }
        }
    }

    private var streakTracker: some View {
        LoopCard(accentColor: .loopGold.opacity(0.6), usesGlassSurface: true) {
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
        LoopCard(accentColor: .cerulean, showsSceneAccent: true, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ViewThatFits(in: .vertical) {
                    HStack {
                        Text("Meta de hoy")
                            .font(LoopFont.bold(16))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(appState.gameState.dailyXP) / \(appState.gameState.dailyGoal) XP")
                            .font(LoopFont.bold(14))
                            .foregroundColor(.mint)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meta de hoy")
                            .font(LoopFont.bold(16))
                            .foregroundColor(.textPrimary)
                        Text("\(appState.gameState.dailyXP) / \(appState.gameState.dailyGoal) XP")
                            .font(LoopFont.bold(14))
                            .foregroundColor(.mint)
                    }
                }
                LoopProgressBar(progress: Double(appState.gameState.dailyXP) / Double(appState.gameState.dailyGoal), height: 12)
                Text("Con una sesion mas completas el objetivo del dia.")
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var progressSplit: some View {
        ViewThatFits(in: .vertical) {
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

            VStack(spacing: Spacing.md) {
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
    }

    private var courseList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Rutas activas")
                    .font(LoopFont.bold(20))
                    .foregroundColor(.textPrimary)
                Text("Lo que tienes en foco ahora y lo que sigue en la cola.")
                    .font(LoopFont.regular(13))
                    .foregroundColor(.textSecond)
            }

            ForEach(viewModel.courses) { course in
                LoopCard(accentColor: course.isActive ? .coral : .clear, usesGlassSurface: true) {
                    ViewThatFits(in: .vertical) {
                        HStack(alignment: .center, spacing: Spacing.md) {
                            courseLeading(course: course)
                            Spacer()
                            courseStars(course: course)
                        }

                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack(alignment: .center, spacing: Spacing.md) {
                                courseLeading(course: course)
                            }
                            courseStars(course: course)
                        }
                    }
                }
                .scaleEffect(revealCards ? 1 : 0.98)
                .opacity(revealCards ? 1 : 0)
            }
        }
    }

    private func courseLeading(course: CourseItem) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Circle()
                .fill(course.isActive ? Color.coral.opacity(0.22) : Color.loopSurf3)
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: course.isActive ? "play.fill" : "pause.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(course.isActive ? .white : .periwinkle)
                )

            VStack(alignment: .leading, spacing: 4) {
                ViewThatFits(in: .vertical) {
                    HStack(spacing: 6) {
                        Text(course.title)
                            .font(LoopFont.bold(14))
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(course.isActive ? "En foco" : "En cola")
                            .font(LoopFont.bold(10))
                            .foregroundColor(course.isActive ? .coral : .textSecond)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((course.isActive ? Color.coral : Color.loopSurf3).opacity(0.16))
                            .clipShape(Capsule())
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(course.title)
                            .font(LoopFont.bold(14))
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(course.isActive ? "En foco" : "En cola")
                            .font(LoopFont.bold(10))
                            .foregroundColor(course.isActive ? .coral : .textSecond)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((course.isActive ? Color.coral : Color.loopSurf3).opacity(0.16))
                            .clipShape(Capsule())
                    }
                }

                Text(course.module)
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func courseStars(course: CourseItem) -> some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 3, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(index < course.stars ? .loopGold : .textMuted)
            }
        }
    }

    private var brandLockup: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("loop")
                .font(LoopFont.black(34))
                .foregroundColor(.textPrimary)
                .overlay(alignment: .trailing) {
                    Circle().fill(Color.coral).frame(width: 9, height: 9).offset(x: 8, y: 4)
                }

            Text("Tu sprint de hoy")
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
        }
    }

    private var statsCluster: some View {
        HStack(spacing: Spacing.sm) {
            ChipView(icon: "flame.fill", text: "\(appState.gameState.currentStreak)", tint: .loopGold)
            ChipView(icon: "star.fill", text: "\(appState.gameState.totalXP) XP", tint: .periwinkle)
        }
    }

    private func homePill(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(LoopFont.bold(12))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .foregroundColor(.periwinkle)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(Color.loopSurf2.opacity(0.72))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.borderSoft, lineWidth: 1))
    }
}
