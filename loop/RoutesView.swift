import SwiftUI

struct RoutesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var revealCards = false

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
                                subtitle: "Lo que tienes en foco ahora y lo que sigue en la cola."
                            )

                            ForEach(viewModel.courses) { course in
                                routeRow(course: course)
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(0.05)) {
                revealCards = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rutas")
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

    private func routeRow(course: CourseItem) -> some View {
        LoopCard(accentColor: course.isActive ? .coral : .clear, usesGlassSurface: true) {
            ViewThatFits(in: .vertical) {
                HStack(alignment: .center, spacing: Spacing.md) {
                    routeLeading(course: course)
                    Spacer()
                    routeStars(course: course)
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    routeLeading(course: course)
                    routeStars(course: course)
                }
            }
        }
    }

    private func routeLeading(course: CourseItem) -> some View {
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

                Text(course.module)
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textSecond)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .layoutPriority(1)
    }

    private func routeStars(course: CourseItem) -> some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 3, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(index < course.stars ? .loopGold : .textMuted)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
