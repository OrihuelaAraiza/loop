import SwiftUI

struct RoutesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.isJuniorMode) private var isJuniorMode
    @State private var revealCards = false
    @State private var showComposer = false

    private var currentCourse: CourseStatusPayload? {
        appState.currentCourse
    }

    private var createdRoutes: [CustomRouteRecord] {
        appState.customRoutes
    }

    private var totalLessons: Int {
        max(currentCourse?.totalLessons ?? 0, 0)
    }

    private var availableLessons: Int {
        min(currentCourse?.resolvedAvailableLessons ?? 0, max(totalLessons, 0))
    }

    private var completedLessons: Int {
        if let currentCourse, !currentCourse.lessons.isEmpty {
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

    private var courseProgressLabel: String {
        guard totalLessons > 0 else { return "Sin lecciones disponibles" }
        return "\(completedLessons) de \(totalLessons) completadas"
    }

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    routeBuilderCard

                    if !createdRoutes.isEmpty {
                        customRoutesSection
                            .scaleEffect(revealCards ? 1 : 0.98)
                            .opacity(revealCards ? 1 : 0)
                    }

                    LoopCard(accentColor: .coral.opacity(0.55), showsSceneAccent: true, usesGlassSurface: true) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            sectionHeader(
                                title: "Ruta activa",
                                subtitle: "La app sincroniza una ruta principal desde el backend y guarda tu progreso local."
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
        .sheet(isPresented: $showComposer) {
            NewRouteComposerSheet(initialRequest: CourseGenerationRequest.suggested(from: appState.userProfile))
                .environmentObject(appState)
        }
    }

    private var header: some View {
        ViewThatFits(in: .vertical) {
            HStack(alignment: .top, spacing: Spacing.md) {
                headerCopy
                createRouteButton
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                headerCopy
                createRouteButton
            }
        }
    }

    private var headerCopy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LoopCopy.routesTitle(junior: isJuniorMode))
                .font(LoopFont.black(28))
                .foregroundColor(.textPrimary)
            Text("Crea varias rutas con lenguaje, framework y un brief propio. El backend actual sigue sincronizando una ruta activa, pero la app ya guarda y muestra todas tus solicitudes.")
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var createRouteButton: some View {
        Button {
            showComposer = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("Nueva ruta")
                    .font(LoopFont.bold(13))
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.coral, Color.amethyst],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color.coral.opacity(0.28), radius: 12, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var routeBuilderCard: some View {
        LoopCard(accentColor: .periwinkle, showsSceneAccent: true, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                sectionHeader(
                    title: "Diseña tu siguiente curso",
                    subtitle: "Elige stack y describe el tipo de proyecto o skill que quieres practicar."
                )

                ViewThatFits(in: .vertical) {
                    HStack(spacing: Spacing.sm) {
                        ChipView(icon: "chevron.left.forwardslash.chevron.right", text: "Lenguaje a medida", tint: .periwinkle)
                        ChipView(icon: "square.stack.3d.up.fill", text: "Framework opcional", tint: .mint)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ChipView(icon: "chevron.left.forwardslash.chevron.right", text: "Lenguaje a medida", tint: .periwinkle)
                        ChipView(icon: "square.stack.3d.up.fill", text: "Framework opcional", tint: .mint)
                    }
                }

                if let lastRoute = createdRoutes.first {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ultima creada")
                            .font(LoopFont.bold(12))
                            .foregroundColor(.textPrimary)
                        Text(lastRoute.request.summaryLine)
                            .font(LoopFont.regular(13))
                            .foregroundColor(.textSecond)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showComposer = true
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

    private var customRoutesSection: some View {
        LoopCard(accentColor: .loopGold, showsSceneAccent: true, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                sectionHeader(
                    title: "Rutas creadas",
                    subtitle: "Estas solicitudes quedan guardadas aunque el backend actual solo exponga una ruta activa."
                )

                ForEach(createdRoutes) { route in
                    customRouteRow(route)
                }
            }
        }
    }

    private func customRouteRow(_ route: CustomRouteRecord) -> some View {
        LoopCard(accentColor: badgeTint(for: route), usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.title)
                            .font(LoopFont.bold(15))
                            .foregroundColor(.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(route.request.summaryLine)
                            .font(LoopFont.regular(12))
                            .foregroundColor(.textSecond)
                    }

                    Spacer(minLength: 0)

                    routeBadge(for: route)
                }

                if !route.request.trimmedFocus.isEmpty {
                    infoLine(title: "Enfoque", value: route.request.trimmedFocus)
                }

                if let backendCourseID = route.backendCourseID, !backendCourseID.isEmpty {
                    infoLine(title: "Backend ID", value: backendCourseID)
                }
            }
        }
    }

    private func routeRow(course: CourseStatusPayload) -> some View {
        LoopCard(accentColor: .coral, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    routeLeading(course: course)
                    Spacer(minLength: 0)
                    routeStatus
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: Spacing.sm) {
                        ChipView(icon: "chevron.left.forwardslash.chevron.right", text: course.language, tint: .periwinkle)
                        ChipView(icon: "checkmark.circle.fill", text: courseProgressLabel, tint: .mint)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ChipView(icon: "chevron.left.forwardslash.chevron.right", text: course.language, tint: .periwinkle)
                        ChipView(icon: "checkmark.circle.fill", text: courseProgressLabel, tint: .mint)
                    }
                }

                LoopProgressBar(progress: courseProgress, height: 10)

                if let lesson = appState.todayLesson {
                    Text("Siguiente acceso: \(lesson.title) · \(lesson.estimatedMinutes) min")
                        .font(LoopFont.regular(12))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
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
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .layoutPriority(1)
    }

    private var routeStatus: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("\(Int(courseProgress * 100))%")
                .font(LoopFont.bold(16))
                .foregroundColor(.coral)

            Text("Disponibles \(availableLessons)/\(totalLessons)")
                .font(LoopFont.regular(11))
                .foregroundColor(.textSecond)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func routeBadge(for route: CustomRouteRecord) -> some View {
        let descriptor = routeBadgeDescriptor(for: route)

        return HStack(spacing: 6) {
            Image(systemName: descriptor.icon)
                .font(.system(size: 10, weight: .bold))
            Text(descriptor.label)
                .font(LoopFont.bold(11))
        }
        .foregroundColor(descriptor.tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(descriptor.tint.opacity(0.16))
        .clipShape(Capsule())
    }

    private func badgeTint(for route: CustomRouteRecord) -> Color {
        routeBadgeDescriptor(for: route).tint
    }

    private func routeBadgeDescriptor(for route: CustomRouteRecord) -> (label: String, tint: Color, icon: String) {
        switch route.status {
        case .requesting:
            return ("Enviando", .amethyst, "paperplane.fill")
        case .queued:
            return ("En cola", .loopGold, "clock.fill")
        case .active:
            return ("Activa", .mint, "checkmark.circle.fill")
        case .failed:
            return ("Error", .coral, "exclamationmark.triangle.fill")
        }
    }

    private func infoLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(LoopFont.bold(11))
                .foregroundColor(.loopGold)
            Text(value)
                .font(LoopFont.regular(13))
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(appState.isGeneratingCourse ? "Tu curso se esta generando" : "Todavia no hay rutas activas")
                .font(LoopFont.bold(16))
                .foregroundColor(.textPrimary)
            Text(appState.courseSyncErrorMessage ?? "En cuanto el backend publique tu curso, aparecera aqui con progreso real y acceso directo.")
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.sm)
    }
}

private struct NewRouteComposerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var request: CourseGenerationRequest
    @State private var isSubmitting = false

    init(initialRequest: CourseGenerationRequest) {
        _request = State(initialValue: initialRequest.normalized())
    }

    private var normalizedRequest: CourseGenerationRequest {
        request.normalized()
    }

    private var availableFrameworks: [CourseFramework] {
        CourseFramework.options(for: request.language)
    }

    private var canSubmit: Bool {
        normalizedRequest.isValid && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(topColor: .coral, bottomColor: .amethyst)

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        LoopCard(accentColor: .coral, showsSceneAccent: true, usesGlassSurface: true) {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Nueva ruta")
                                    .font(LoopFont.black(26))
                                    .foregroundColor(.textPrimary)
                                Text("Describe el curso que quieres y el enfoque que te importa. Puedes crear varias solicitudes; mientras tanto el backend actual sigue activando una ruta a la vez.")
                                    .font(LoopFont.regular(14))
                                    .foregroundColor(.textSecond)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        optionSection(
                            title: "Lenguaje",
                            subtitle: "Elige la base principal del curso."
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(ProgrammingLanguage.allCases) { language in
                                        SelectionPill(
                                            title: language.rawValue,
                                            icon: "chevron.left.forwardslash.chevron.right",
                                            isSelected: request.language == language,
                                            tint: .periwinkle
                                        ) {
                                            request.language = language
                                        }
                                    }
                                }
                            }
                        }

                        optionSection(
                            title: "Framework",
                            subtitle: "Opcional. Filtramos solo frameworks compatibles con el lenguaje elegido."
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(availableFrameworks) { framework in
                                        SelectionPill(
                                            title: framework.rawValue,
                                            icon: framework.iconName,
                                            isSelected: request.framework == framework,
                                            tint: .mint
                                        ) {
                                            request.framework = framework
                                        }
                                    }
                                }
                            }
                        }

                        PromptEditorCard(
                            title: "Que curso quieres",
                            subtitle: "Ejemplo: quiero un curso para crear una app de gastos con React y autenticacion.",
                            text: $request.prompt
                        )

                        PromptEditorCard(
                            title: "Enfocado a",
                            subtitle: "Ejemplo: enfocado a portfolio, entrevistas tecnicas o lanzar un MVP real.",
                            text: $request.focus
                        )

                        if let errorMessage = appState.courseSyncErrorMessage, !errorMessage.isEmpty {
                            LoopCard(accentColor: .coral, usesGlassSurface: true) {
                                Text(errorMessage)
                                    .font(LoopFont.regular(13))
                                    .foregroundColor(.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        LoopCTA(
                            title: isSubmitting ? "Creando ruta..." : "Crear ruta",
                            trailingIcon: isSubmitting ? nil : "sparkles",
                            isDisabled: !canSubmit,
                            style: .solid(.coral)
                        ) {
                            submit()
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onChange(of: request.language) { _, _ in
                if !availableFrameworks.contains(request.framework) {
                    request.framework = .none
                }
            }
        }
    }

    private func optionSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let sectionContent = content()

        return LoopCard(accentColor: .clear, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(LoopFont.bold(18))
                        .foregroundColor(.textPrimary)
                    Text(subtitle)
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }

                sectionContent
            }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        isSubmitting = true

        Task {
            let didCreate = await appState.createCustomCourse(request: normalizedRequest)

            await MainActor.run {
                isSubmitting = false
                if didCreate {
                    dismiss()
                }
            }
        }
    }
}

private struct PromptEditorCard: View {
    let title: String
    let subtitle: String
    @Binding var text: String

    var body: some View {
        LoopCard(accentColor: .clear, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(LoopFont.bold(18))
                        .foregroundColor(.textPrimary)
                    Text(subtitle)
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.loopSurf2.opacity(0.84))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(Color.borderSoft, lineWidth: 1)
                    )
                    .font(LoopFont.regular(14))
                    .foregroundColor(.textPrimary)
            }
        }
    }
}

private struct SelectionPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(LoopFont.bold(12))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : .textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? tint : Color.loopSurf2.opacity(0.84))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? tint.opacity(0.2) : Color.borderSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
