import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var revealCards = false

    var onStartLesson: () -> Void = {}

    private let dayLabels = ["L", "M", "X", "J", "V", "S", "D"]
    private var learnerName: String {
        appState.userProfile.name.isEmpty ? "coder" : appState.userProfile.name
    }

    private var lessonSubtitle: String {
        if appState.isLoadingTodayLesson {
            return "Cargando tu lección personalizada..."
        }

        if let lesson = appState.todayLesson {
            return "\(lesson.title) · \(lesson.estimatedMinutes) min"
        }

        if appState.isGeneratingCourse {
            return "Estamos preparando tu ruta de aprendizaje."
        }

        return "Empieza tu práctica de hoy"
    }

    private var totalLessons: Int {
        max(appState.currentCourse?.totalLessons ?? 0, 0)
    }

    private var availableLessons: Int {
        min(appState.currentCourse?.resolvedAvailableLessons ?? 0, max(totalLessons, 0))
    }

    private var completedLessons: Int {
        if let currentCourse = appState.currentCourse, !currentCourse.lessons.isEmpty {
            let completedStatuses = Set(["completed", "done"])
            let count = currentCourse.lessons.filter { summary in
                appState.gameState.completedLessons.contains(summary.id) || completedStatuses.contains(summary.status.lowercased())
            }.count
            return min(count, max(totalLessons, 0))
        }

        return min(appState.gameState.completedLessons.count, max(totalLessons, 0))
    }

    private var courseProgress: Double {
        guard totalLessons > 0 else { return 0 }
        return min(max(Double(completedLessons) / Double(totalLessons), 0), 1)
    }

    private var weeklyStates: [DayNode.DayState] {
        let dayCount = dayLabels.count
        guard dayCount > 0 else { return [] }

        let todayIndex = ((Calendar.current.component(.weekday, from: Date()) + 5) % 7)
        let completedCount = max(min(appState.gameState.currentStreak - 1, dayCount - 1), 0)

        return dayLabels.indices.map { index in
            if index == todayIndex {
                return .today
            }

            let distanceFromToday = (todayIndex - index + dayCount) % dayCount
            return distanceFromToday > 0 && distanceFromToday <= completedCount ? .done : .pending
        }
    }

    var body: some View {
        ZStack {
            LoopMeshBackground()
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    topBar
                        .padding(.top, Spacing.sm)
                    if revealCards {
                        loopyCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .loopScrollReveal()
                        lessonCTA
                             .transition(.move(edge: .bottom).combined(with: .opacity))
                            .loopScrollReveal()
                        dashboardSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .loopScrollReveal()
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 130)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(0.05)) {
                revealCards = true
            }
            appState.refreshTodayLesson()
        }
    }

    private var topBar: some View {
        ViewThatFits(in: .vertical) {
            HStack(alignment: .center) {
                brandLockup
                Spacer()
                statsCluster
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                brandLockup
                statsCluster
            }
        }
    }

    private var loopyCard: some View {
        LoopCard(accentColor: .amethyst, showsSceneAccent: true, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    homePill(icon: "sparkles", text: "Mentor del día")
                    Spacer()
                    Text("Racha \(appState.gameState.currentStreak)")
                        .font(LoopFont.bold(12))
                        .foregroundColor(.loopGold)
                }

                HStack(alignment: .center, spacing: Spacing.md) {
                    LoopyView(mood: .idle)
                        .scaleEffect(0.46)
                        .frame(width: 72, height: 72)
                        .clipped()
                    LoopySpeechBubble(
                        primary: "Hola \(learnerName), llevas \(appState.gameState.currentStreak) días seguidos.",
                        secondary: appState.todayLesson == nil ? "Estamos preparando una lección para ti." : "Tu lección del día está lista, cuando quieras empezar."
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var lessonCTA: some View {
        LoopCard(accentColor: .coral, showsSceneAccent: true, usesGlassSurface: true) {
            HStack(alignment: .center, spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.coral.opacity(0.22))
                        .frame(width: 52, height: 52)
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.coral)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Lección del día")
                        .font(LoopFont.bold(17))
                        .foregroundColor(.textPrimary)
                    Text(lessonSubtitle)
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.coral)
                    .padding(10)
                    .background(Color.coral.opacity(0.16))
                    .clipShape(Circle())
            }
        }
        .contentShape(Rectangle())
        .rippleOnTap(fireDelay: 0.4) {
            guard appState.todayLesson != nil else {
                appState.refreshTodayLesson()
                return
            }
            HapticManager.shared.impact(.medium)
            onStartLesson()
        }
        .accessibilityElement(children: AccessibilityChildBehavior.combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Empezar lección del día")
    }

    private var streakTracker: some View {
        LoopCard(accentColor: .loopGold.opacity(0.6), usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .center) {
                    Text("Racha semanal")
                        .font(LoopFont.bold(14))
                        .foregroundColor(.textSecond)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.loopGold)
                        Text("\(appState.gameState.currentStreak) días")
                            .font(LoopFont.bold(16))
                            .foregroundColor(.loopGold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Spacing.xs) {
                    ForEach(Array(dayLabels.enumerated()), id: \.offset) { idx, label in
                        DayNode(label: label, state: weeklyStates[idx])
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dailyGoal: some View {
        LoopCard(accentColor: .cerulean, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Meta de hoy")
                        .font(LoopFont.bold(16))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    HStack(spacing: 2) {
                        XPBounceText(
                            value: appState.gameState.dailyXP,
                            font: LoopFont.bold(14),
                            color: Color.mint
                        )
                        Text(" / \(appState.gameState.dailyGoal) XP")
                            .font(LoopFont.bold(14))
                            .foregroundColor(Color.mint)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                LoopProgressBar(progress: safeDailyGoalProgress, height: 12)

                Text("Con una sesión más completas el objetivo del día.")
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var progressSplit: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: Spacing.md) {
                ProgressMetricCard(
                    title: "Completado",
                    value: totalLessons > 0 ? "\(Int(courseProgress * 100))%" : "--",
                    icon: "chart.pie.fill",
                    tint: .mint
                )
                ProgressMetricCard(
                    title: "Lecciones",
                    value: totalLessons > 0 ? "\(availableLessons)/\(totalLessons)" : "--",
                    icon: "book.fill",
                    tint: .periwinkle
                )
            }

            VStack(spacing: Spacing.md) {
                ProgressMetricCard(
                    title: "Completado",
                    value: totalLessons > 0 ? "\(Int(courseProgress * 100))%" : "--",
                    icon: "chart.pie.fill",
                    tint: .mint
                )
                ProgressMetricCard(
                    title: "Lecciones",
                    value: totalLessons > 0 ? "\(availableLessons)/\(totalLessons)" : "--",
                    icon: "book.fill",
                    tint: .periwinkle
                )
            }
        }
    }

    private var safeDailyGoalProgress: Double {
        let goal = max(appState.gameState.dailyGoal, 1)
        let progress = Double(appState.gameState.dailyXP) / Double(goal)
        return min(max(progress, 0), 1)
    }

    private var dashboardSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(
                title: "Resumen de hoy",
                subtitle: "Tu racha, avance diario y progreso del sprint en un solo bloque."
            )

            streakTracker
            dailyGoal
            progressSplit
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(LoopFont.bold(20))
                .foregroundColor(.textPrimary)
            Text(subtitle)
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var brandLockup: some View {
        Text("loop")
            .font(LoopFont.black(34))
            .foregroundColor(.textPrimary)
            .overlay(alignment: .trailing) {
                Circle().fill(Color.coral).frame(width: 9, height: 9).offset(x: 8, y: 4)
            }
    }

    private var statsCluster: some View {
        HStack(spacing: Spacing.sm) {
            ChipView(icon: "flame.fill", text: "\(appState.gameState.currentStreak)", tint: .loopGold)
            xpChip
        }
    }

    private var xpChip: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Circle()
                .fill(Color.periwinkle.opacity(0.18))
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.periwinkle)
                )
            XPBounceText(
                value: appState.gameState.totalXP,
                font: LoopFont.bold(12),
                color: Color.textPrimary,
                suffix: " XP"
            )
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.loopSurf2.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Color.borderSoft, lineWidth: 1)
        )
    }

    private func homePill(icon: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(LoopFont.bold(12))
                .lineLimit(1)
        }
        .foregroundColor(.periwinkle)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(Color.loopSurf2.opacity(0.72))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.borderSoft, lineWidth: 1))
    }
}
