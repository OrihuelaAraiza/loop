import SwiftUI

struct RoutesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.isJuniorMode) private var isJuniorMode
    @State private var revealCards = false

    private var currentCourse: CourseStatusPayload? {
        appState.currentCourse
    }

    private var totalLessons: Int {
        max(currentCourse?.totalLessons ?? 0, 0)
    }

    private var readyLessons: Int {
        min(currentCourse?.resolvedReadyLessons ?? 0, max(totalLessons, 0))
    }

    private var courseProgressLabel: String {
        guard totalLessons > 0 else { return "Sin lecciones disponibles" }
        return "\(readyLessons) de \(totalLessons) listas"
    }

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header

                    LoopCard(accentColor: .coral.opacity(0.55), showsSceneAccent: true, usesGlassSurface: true) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            sectionHeader(
                                title: "Rutas activas",
                                subtitle: "Mostramos el curso real sincronizado desde el backend."
                            )

                            if let currentCourse {
                                routeRow(course: currentCourse)
                                    .scaleEffect(revealCards ? 1 : 0.98)
                                    .opacity(revealCards ? 1 : 0)
                            } else {
                                emptyState
                                    .scaleEffect(revealCards ? 1 : 0.98)
                                    .opacity(revealCards ? 1 : 0)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xl)
                .padding(.bottom, 130)
            }
        }
        .onAppear {
            appState.refreshTodayLesson()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(0.05)) {
                revealCards = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LoopCopy.routesTitle(junior: isJuniorMode))
                .font(LoopFont.black(28))
                .foregroundColor(.textPrimary)
            Text("Elige dónde continuar. Cada ruta guarda tu avance por módulo.")
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LoopFont.bold(20))
                .foregroundColor(.textPrimary)
            Text(subtitle)
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func routeRow(course: CourseStatusPayload) -> some View {
        LoopCard(accentColor: .coral, usesGlassSurface: true) {
            ViewThatFits(in: .vertical) {
                HStack(alignment: .center, spacing: Spacing.md) {
                    routeLeading(course: course)
                    Spacer()
                    routeStatus
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    routeLeading(course: course)
                    routeStatus
                }
            }
        }
    }

    private func routeLeading(course: CourseStatusPayload) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Circle()
                .fill(Color.coral.opacity(0.22))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: appState.isGeneratingCourse ? "sparkles" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(course.resolvedTitle)
                        .font(LoopFont.bold(14))
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(appState.isGeneratingCourse
                         ? "Generando"
                         : LoopCopy.focusLabel(junior: isJuniorMode))
                        .font(LoopFont.bold(10))
                        .foregroundColor(appState.isGeneratingCourse ? .loopGold : .coral)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background((appState.isGeneratingCourse ? Color.loopGold : Color.coral).opacity(0.16))
                        .clipShape(Capsule())
                }

                Text(course.resolvedSummary)
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textSecond)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .layoutPriority(1)
    }

    private var routeStatus: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(courseProgressLabel)
                .font(LoopFont.bold(12))
                .foregroundColor(.coral)

            if let lesson = appState.todayLesson {
                Text("Hoy: \(lesson.estimatedMinutes) min")
                    .font(LoopFont.regular(11))
                    .foregroundColor(.textSecond)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(appState.isGeneratingCourse ? "Tu curso se está generando" : "Todavía no hay rutas activas")
                .font(LoopFont.bold(16))
                .foregroundColor(.textPrimary)
            Text(appState.courseSyncErrorMessage ?? "En cuanto el backend publique tu curso, aparecerá aquí con progreso real.")
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.sm)
    }
}
