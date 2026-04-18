import SkeletonUI
import SwiftUI

struct RoutesView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.isJuniorMode) private var isJuniorMode

    @State private var revealCards = false
    @State private var showComposer = false
    @State private var carouselPositionID: String?

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

    private var carouselItems: [RouteCarouselItem] {
        var items: [RouteCarouselItem] = []

        if let currentCourse {
            items.append(
                RouteCarouselItem(
                    id: "focus-\(currentCourse.id)",
                    kind: .focus,
                    title: currentCourse.resolvedTitle,
                    subtitle: currentCourse.resolvedSummary,
                    language: ProgrammingLanguage(rawValue: currentCourse.language),
                    frameworkName: nil,
                    status: .focus,
                    progress: routeProgress,
                    moduleLabel: currentModuleLabel,
                    difficultyStars: currentDifficultyStars,
                    showsSkeleton: false
                )
            )
        }

        items += createdRoutes.map { route in
            RouteCarouselItem(
                id: route.id,
                kind: .created,
                title: route.title,
                subtitle: route.subtitle,
                language: route.request.language,
                frameworkName: route.request.frameworkName,
                status: route.status.displayStatus,
                progress: progress(for: route),
                moduleLabel: moduleLabel(for: route),
                difficultyStars: route.request.level?.stars ?? 1,
                showsSkeleton: route.status == .generating
            )
        }

        items.append(.addCard)
        return items
    }

    private var routeProgress: Double {
        guard totalLessons > 0 else { return 0 }
        return min(max(Double(completedLessons) / Double(max(totalLessons, 1)), 0), 1)
    }

    private var currentModuleLabel: String {
        let modules = max(currentCourse?.generatedModulesCount ?? 1, 1)
        let lessonOrder = max(appState.todayLesson?.orderIndex ?? (completedLessons + 1), 1)
        let lessonsPerModule = max(Int(ceil(Double(max(totalLessons, 1)) / Double(modules))), 1)
        let moduleIndex = min(max(Int(ceil(Double(lessonOrder) / Double(lessonsPerModule))), 1), modules)
        return "Modulo \(moduleIndex)"
    }

    private var currentDifficultyStars: Int {
        difficultyStars(from: appState.todayLesson?.difficulty ?? appState.currentCourse?.lessons.first?.difficulty)
    }

    private var currentCarouselIndex: Int {
        guard let carouselPositionID,
              let index = carouselItems.firstIndex(where: { $0.id == carouselPositionID }) else {
            return 0
        }
        return index
    }

    private var headerCopy: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LoopCopy.routesTitle(junior: isJuniorMode))
                .font(.custom("Nunito-Bold", size: 28))
                .foregroundColor(.white)

            Text("Crea varias rutas con IA y conserva el curso en foco mientras las nuevas se generan y se encolan.")
                .font(.custom("Nunito-Regular", size: 14))
                .foregroundColor(RoutePalette.periwinkle.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = max(proxy.size.width * 0.85, 280)
            let horizontalInset = max((proxy.size.width - cardWidth) / 2, 20)

            ZStack {
                AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        carouselSection(cardWidth: cardWidth, horizontalInset: horizontalInset)
                        routeSummary
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            appState.refreshTodayLesson()
            if carouselPositionID == nil {
                carouselPositionID = carouselItems.first?.id
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(0.05)) {
                revealCards = true
            }
        }
        .onChange(of: carouselItems.map(\.id)) { _, ids in
            guard !ids.isEmpty else { return }
            if let carouselPositionID, ids.contains(carouselPositionID) {
                return
            }
            self.carouselPositionID = ids.first
        }
        .sheet(isPresented: $showComposer) {
            NewRouteComposerSheet()
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            headerCopy
            Spacer(minLength: 0)

            Button {
                showComposer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Nueva ruta")
                        .font(.custom("Nunito-Bold", size: 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoutePalette.coral)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private func carouselSection(cardWidth: CGFloat, horizontalInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rutas activas")
                .font(.custom("Nunito-Bold", size: 18))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(carouselItems) { item in
                        Group {
                            switch item.kind {
                            case .add:
                                AddRouteCard(action: { showComposer = true })
                            case .focus, .created:
                                RouteCarouselCard(
                                    item: item,
                                    availableLessons: availableLessons,
                                    totalLessons: totalLessons
                                )
                            }
                        }
                        .frame(width: cardWidth)
                        .id(item.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, horizontalInset)
            }
            .scrollPosition(id: $carouselPositionID)
            .scrollTargetBehavior(.viewAligned)

            HStack(spacing: 6) {
                ForEach(Array(carouselItems.enumerated()), id: \.element.id) { index, item in
                    Circle()
                        .fill(currentCarouselIndex == index ? RoutePalette.coral : RoutePalette.periwinkle.opacity(0.3))
                        .frame(width: currentCarouselIndex == index ? 8 : 6, height: currentCarouselIndex == index ? 8 : 6)
                        .animation(.spring(duration: 0.2), value: currentCarouselIndex)
                        .accessibilityHidden(item.kind == .add)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(revealCards ? 1 : 0)
        .offset(y: revealCards ? 0 : 10)
    }

    private var routeSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En foco")
                .font(.custom("Nunito-Bold", size: 18))
                .foregroundColor(.white)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(RoutePalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(RoutePalette.periwinkle.opacity(0.12), lineWidth: 1)
                )
                .overlay(alignment: .topTrailing) {
                    if appState.isGeneratingCourse {
                        statusBadge(label: "Generando", tint: RoutePalette.amethyst, icon: "sparkles")
                            .padding(16)
                    }
                }
                .overlay {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(currentCourse?.resolvedTitle ?? "Todavia no hay ruta activa")
                            .font(.custom("Nunito-Bold", size: 18))
                            .foregroundColor(.white)

                        Text(currentCourse?.resolvedSummary ?? "Crea una nueva ruta desde el carousel para empezar a poblar tu mapa.")
                            .font(.custom("Nunito-Regular", size: 14))
                            .foregroundColor(RoutePalette.periwinkle.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)

                        if currentCourse != nil {
                            HStack(spacing: 12) {
                                miniMetric(title: "Progreso", value: "\(Int(routeProgress * 100))%")
                                miniMetric(title: "Modulo", value: currentModuleLabel)
                                miniMetric(title: "Disponibles", value: "\(availableLessons)/\(max(totalLessons, 1))")
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 156)
        }
        .padding(.horizontal, 20)
        .opacity(revealCards ? 1 : 0)
        .offset(y: revealCards ? 0 : 10)
    }

    private func miniMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.custom("Nunito-Bold", size: 11))
                .foregroundColor(RoutePalette.periwinkle.opacity(0.7))
            Text(value)
                .font(.custom("Nunito-Bold", size: 15))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func progress(for route: CustomRouteRecord) -> Double? {
        switch route.status {
        case .generating:
            return nil
        case .queued:
            return 0.08
        case .active:
            if route.backendCourseID == currentCourse?.id {
                return routeProgress
            }
            return 0.16
        case .failed:
            return 0
        }
    }

    private func moduleLabel(for route: CustomRouteRecord) -> String {
        switch route.status {
        case .generating:
            return "Sincronizando roadmap"
        case .queued:
            return "En cola para activarse"
        case .active:
            if route.backendCourseID == currentCourse?.id {
                return currentModuleLabel
            }
            return "Lista para empezar"
        case .failed:
            return "Necesita reintento"
        }
    }

    private func difficultyStars(from rawDifficulty: String?) -> Int {
        let normalized = rawDifficulty?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch normalized {
        case "advanced", "hard", "alto", "avanzado":
            return 3
        case "intermediate", "medium", "medio", "intermedio":
            return 2
        default:
            return 1
        }
    }

    private func statusBadge(label: String, tint: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(label)
                .font(.custom("Nunito-Bold", size: 11))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.24))
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

private struct NewRouteComposerSheet: View {
    private enum Phase: Equatable {
        case form
        case generating
        case success(routeID: String)
    }

    private enum ComposerField: Hashable {
        case focus
        case prompt
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @FocusState private var focusedField: ComposerField?

    @State private var selectedLanguage: ProgrammingLanguage?
    @State private var selectedFramework: CourseFramework = .none
    @State private var focusText = ""
    @State private var promptText = ""
    @State private var selectedLevel: CourseSkillLevel?
    @State private var phase: Phase = .form

    private let supportedLanguages: [ProgrammingLanguage] = [.python, .javascript, .typescript, .swift, .kotlin, .rust, .go]

    private var isGenerating: Bool {
        switch phase {
        case .form:
            return false
        case .generating, .success:
            return true
        }
    }

    private var availableFrameworks: [CourseFramework] {
        guard let selectedLanguage else { return [] }

        switch selectedLanguage {
        case .python:
            return [.none, .django, .flask, .fastAPI]
        case .javascript:
            return [.none, .react, .vue, .node, .nextJS]
        case .typescript:
            return [.none, .react, .angular, .nestJS]
        case .swift:
            return [.none, .swiftUI, .uiKit, .vapor]
        case .kotlin:
            return [.none, .android, .ktor, .spring]
        case .rust:
            return [.none, .actix, .tokio]
        case .go:
            return [.none, .gin, .echo, .fiber]
        case .html:
            return [.none]
        }
    }

    private var canSubmit: Bool {
        selectedLanguage != nil && !isGenerating
    }

    var body: some View {
        ZStack {
            Color.loopBG
                .ignoresSafeArea()

            VStack(spacing: 0) {
                handlePill
                header

                ScrollView {
                    VStack(spacing: 16) {
                        languageSection
                        frameworkSection
                        focusSection
                        promptSection
                        levelSection

                        if let errorMessage = appState.courseSyncErrorMessage, !errorMessage.isEmpty, phase == .form {
                            composerCard {
                                Text(errorMessage)
                                    .font(.custom("Nunito-Regular", size: 14))
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .disabled(isGenerating)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .interactiveDismissDisabled(isGenerating)
        .onChange(of: selectedLanguage) { _, newValue in
            guard let newValue else {
                selectedFramework = .none
                return
            }

            if !availableFrameworks.contains(selectedFramework) {
                selectedFramework = .none
            }

            if newValue == .html {
                selectedLanguage = nil
            }
        }
    }

    private var handlePill: some View {
        Capsule()
            .fill(RoutePalette.periwinkle.opacity(0.25))
            .frame(width: 42, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 12)
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(RoutePalette.periwinkle)
                    .frame(width: 36, height: 36)
                    .background(RoutePalette.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isGenerating)

            Spacer()

            Text("Nueva ruta")
                .font(.custom("Nunito-Bold", size: 20))
                .foregroundColor(.white)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var languageSection: some View {
        composerCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel(
                    title: "Lenguaje",
                    icon: "chevron.left.forwardslash.chevron.right",
                    tint: RoutePalette.coral
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(supportedLanguages) { language in
                            SelectionChip(
                                title: language.rawValue,
                                icon: language.symbolName,
                                isSelected: selectedLanguage == language,
                                primaryTint: RoutePalette.coral,
                                secondaryTint: RoutePalette.celadon
                            ) {
                                selectedLanguage = language
                            }
                        }
                    }
                }
            }
        }
    }

    private var frameworkSection: some View {
        composerCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel(
                    title: "Framework",
                    icon: "square.stack.3d.up.fill",
                    tint: RoutePalette.celadon
                )

                if selectedLanguage == nil {
                    Text("Elige un lenguaje primero")
                        .font(.custom("Nunito-Regular", size: 13))
                        .foregroundColor(RoutePalette.periwinkle.opacity(0.72))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableFrameworks) { framework in
                                SelectionChip(
                                    title: framework.rawValue,
                                    icon: framework.iconName,
                                    isSelected: selectedFramework == framework,
                                    primaryTint: RoutePalette.celadon,
                                    secondaryTint: RoutePalette.coral
                                ) {
                                    selectedFramework = framework
                                }
                            }
                        }
                    }
                }
            }
            .opacity(selectedLanguage == nil ? 0.4 : 1)
        }
    }

    private var focusSection: some View {
        composerCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    sectionLabel(
                        title: "Enfoque del curso",
                        icon: "sparkles",
                        tint: RoutePalette.amethyst
                    )

                    Spacer()

                    Text("Opcional")
                        .font(.custom("Nunito-Regular", size: 11))
                        .foregroundColor(RoutePalette.periwinkle)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoutePalette.prussian)
                        .clipShape(Capsule())
                }

                Text("Describe qué quieres construir o aprender.")
                    .font(.custom("Nunito-Regular", size: 13))
                    .foregroundColor(RoutePalette.periwinkle.opacity(0.7))

                TextField("Ej: una app de gastos con autenticación", text: $focusText, axis: .vertical)
                    .lineLimit(3...5)
                    .font(.custom("Nunito-Regular", size: 15))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(RoutePalette.prussian)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                focusedField == .focus ? RoutePalette.coral.opacity(0.6) : RoutePalette.periwinkle.opacity(0.15),
                                lineWidth: focusedField == .focus ? 2 : 1
                            )
                    )
                    .focused($focusedField, equals: .focus)
            }
        }
    }

    private var promptSection: some View {
        composerCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    sectionLabel(
                        title: "Descripción libre",
                        icon: "text.alignleft",
                        tint: RoutePalette.coral
                    )
                    Spacer()
                    Text("Opcional")
                        .font(.custom("Nunito-Regular", size: 11))
                        .foregroundColor(RoutePalette.periwinkle)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoutePalette.prussian)
                        .clipShape(Capsule())
                }

                Text("Cuéntanos en tus propias palabras qué quieres aprender, qué proyecto tienes en mente o cualquier detalle extra.")
                    .font(.custom("Nunito-Regular", size: 13))
                    .foregroundColor(RoutePalette.periwinkle.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                ZStack(alignment: .topLeading) {
                    if promptText.isEmpty {
                        Text("Ej: Quiero crear una API REST con autenticación JWT, conexión a Postgres y tests automáticos.")
                            .font(.custom("Nunito-Regular", size: 14))
                            .foregroundColor(RoutePalette.periwinkle.opacity(0.35))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $promptText)
                        .font(.custom("Nunito-Regular", size: 15))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .focused($focusedField, equals: .prompt)
                        .frame(minHeight: 96)
                }
                .padding(10)
                .background(RoutePalette.prussian)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            focusedField == .prompt ? RoutePalette.coral.opacity(0.6) : RoutePalette.periwinkle.opacity(0.15),
                            lineWidth: focusedField == .prompt ? 2 : 1
                        )
                )
            }
        }
    }

    private var levelSection: some View {
        composerCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    sectionLabel(
                        title: "Nivel",
                        icon: "chart.line.uptrend.xyaxis",
                        tint: RoutePalette.cerulean
                    )
                    Spacer()
                    Text("Opcional")
                        .font(.custom("Nunito-Regular", size: 11))
                        .foregroundColor(RoutePalette.periwinkle)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CourseSkillLevel.allCases) { level in
                            SelectionChip(
                                title: level.rawValue,
                                icon: "star.fill",
                                isSelected: selectedLevel == level,
                                primaryTint: RoutePalette.cerulean,
                                secondaryTint: RoutePalette.celadon
                            ) {
                                selectedLevel = selectedLevel == level ? nil : level
                            }
                        }
                    }
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(RoutePalette.periwinkle.opacity(0.08))

            switch phase {
            case .form:
                VStack(spacing: 12) {
                    if let selectedLanguage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(RoutePalette.celadon)

                            Text(summaryLine(for: selectedLanguage))
                                .font(.custom("Nunito-SemiBold", size: 14))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }

                    Button {
                        generateCourse()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Generar curso")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LoopCTAButton(tint: RoutePalette.coral))
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }

            case .generating:
                generationStateCard(
                    expression: .thinking,
                    title: "Creando tu curso con IA...",
                    subtitle: "Esto toma unos segundos"
                )

            case .success:
                successStateCard
            }
        }
        .background(RoutePalette.prussian)
        .ignoresSafeArea(.keyboard)
    }

    private var successStateCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RoutePalette.celadon.opacity(0.18))
                    .frame(width: 84, height: 84)

                LoopyExpressionView(expression: .happy, size: 60)
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(RoutePalette.celadon)
                Text("Listo")
                    .font(.custom("Nunito-Bold", size: 18))
                    .foregroundColor(.white)
            }

            Text("Tu nueva ruta ya se agregó al roadmap.")
                .font(.custom("Nunito-Regular", size: 14))
                .foregroundColor(RoutePalette.periwinkle)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private func generationStateCard(expression: LoopyExpression, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            LoopyExpressionView(expression: expression, size: 60)

            Text(title)
                .font(.custom("Nunito-Bold", size: 18))
                .foregroundColor(.white)

            Text(subtitle)
                .font(.custom("Nunito-Regular", size: 14))
                .foregroundColor(RoutePalette.periwinkle)

            ProgressView()
                .progressViewStyle(.linear)
                .tint(RoutePalette.coral)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private func summaryLine(for language: ProgrammingLanguage) -> String {
        if selectedFramework == .none {
            return "Curso de \(language.rawValue)"
        }
        return "Curso de \(language.rawValue) · \(selectedFramework.rawValue)"
    }

    private func sectionLabel(title: String, icon: String, tint: Color) -> some View {
        Label {
            Text(title)
                .font(.custom("Nunito-Bold", size: 16))
                .foregroundColor(.white)
        } icon: {
            Image(systemName: icon)
                .foregroundColor(tint)
        }
    }

    private func composerCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .background(RoutePalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func generateCourse() {
        guard let selectedLanguage else { return }

        let request = CourseGenerationRequest(
            language: selectedLanguage,
            framework: selectedFramework,
            prompt: promptText.trimmingCharacters(in: .whitespacesAndNewlines),
            focus: focusText.trimmingCharacters(in: .whitespacesAndNewlines),
            level: selectedLevel
        )

        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
            phase = .generating
        }

        Task {
            let createdRouteID = await appState.createCustomCourse(request: request)

            await MainActor.run {
                guard let createdRouteID else {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                        phase = .form
                    }
                    return
                }

                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    phase = .success(routeID: createdRouteID)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        appState.selectedMainTab = .map
                        appState.mapFocusedRouteID = createdRouteID
                        LoopToast.routeReady()
                    }
                }
            }
        }
    }
}

private struct RouteCarouselCard: View {
    let item: RouteCarouselItem
    let availableLessons: Int
    let totalLessons: Int

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        titleBlock
                        technologyPills
                    }

                    Spacer(minLength: 0)

                    badge
                }

                Spacer(minLength: 0)

                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        moduleInfo
                        difficultyInfo
                    }

                    Spacer(minLength: 0)

                    progressBlock
                }
            }
            .padding(22)
        }
        .frame(minHeight: 250)
        .shadow(color: accentColor.opacity(0.18), radius: 18, y: 12)
    }

    private var accentColor: Color {
        switch item.status {
        case .focus:
            return RoutePalette.celadon
        case .generating:
            return RoutePalette.amethyst
        case .queued:
            return RoutePalette.gold
        case .active:
            return RoutePalette.celadon
        case .failed:
            return RoutePalette.coral
        }
    }

    private var gradient: LinearGradient {
        let leading: Color

        switch item.language {
        case .python:
            leading = RoutePalette.cerulean
        case .javascript:
            leading = RoutePalette.gold.opacity(0.92)
        case .swift:
            leading = RoutePalette.coral
        case .typescript:
            leading = RoutePalette.amethyst
        default:
            leading = RoutePalette.card
        }

        return LinearGradient(
            colors: [leading.opacity(0.92), RoutePalette.prussian],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var titleBlock: some View {
        if item.showsSkeleton {
            VStack(alignment: .leading, spacing: 10) {
                Text("")
                    .skeleton(with: true)
                    .shape(type: .rounded(.radius(6)))
                    .frame(width: 180, height: 22)

                Text("")
                    .skeleton(with: true)
                    .shape(type: .rounded(.radius(6)))
                    .frame(width: 120, height: 14)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.custom("Nunito-Bold", size: 24))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(item.subtitle)
                    .font(.custom("Nunito-Regular", size: 14))
                    .foregroundColor(RoutePalette.periwinkle.opacity(0.88))
                    .lineLimit(3)
            }
        }
    }

    private var technologyPills: some View {
        HStack(spacing: 8) {
            if let language = item.language {
                pill(text: language.rawValue, icon: language.symbolName)
            }

            if let frameworkName = item.frameworkName, !frameworkName.isEmpty {
                pill(text: frameworkName, icon: "square.stack.3d.up.fill")
            }
        }
    }

    private func pill(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.custom("Nunito-SemiBold", size: 12))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
    }

    private var badge: some View {
        HStack(spacing: 6) {
            Image(systemName: badgeDescriptor.icon)
                .font(.system(size: 10, weight: .bold))
            Text(badgeDescriptor.title)
                .font(.custom("Nunito-Bold", size: 11))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(badgeDescriptor.tint.opacity(0.22))
        .clipShape(Capsule())
    }

    private var badgeDescriptor: (title: String, tint: Color, icon: String) {
        switch item.status {
        case .focus:
            return ("En foco", RoutePalette.celadon, "scope")
        case .generating:
            return ("Generando", RoutePalette.amethyst, "sparkles")
        case .queued:
            return ("En cola", RoutePalette.gold, "clock.fill")
        case .active:
            return ("Activa", RoutePalette.celadon, "checkmark.circle.fill")
        case .failed:
            return ("Error", RoutePalette.coral, "exclamationmark.triangle.fill")
        }
    }

    @ViewBuilder
    private var moduleInfo: some View {
        if item.showsSkeleton {
            VStack(alignment: .leading, spacing: 8) {
                Text("")
                    .skeleton(with: true)
                    .shape(type: .rounded(.radius(5)))
                    .frame(width: 88, height: 12)
                Text("")
                    .skeleton(with: true)
                    .shape(type: .rounded(.radius(5)))
                    .frame(width: 132, height: 16)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Modulo actual")
                    .font(.custom("Nunito-Regular", size: 12))
                    .foregroundColor(RoutePalette.periwinkle.opacity(0.76))

                Text(item.moduleLabel)
                    .font(.custom("Nunito-Bold", size: 16))
                    .foregroundColor(.white)
            }
        }
    }

    private var difficultyInfo: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < item.difficultyStars ? "star.fill" : "star")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(index < item.difficultyStars ? RoutePalette.gold : RoutePalette.periwinkle.opacity(0.36))
            }
        }
    }

    @ViewBuilder
    private var progressBlock: some View {
        if item.showsSkeleton {
            VStack(spacing: 10) {
                ProgressView()
                    .tint(.white)
                Text("Generando...")
                    .font(.custom("Nunito-SemiBold", size: 12))
                    .foregroundColor(RoutePalette.periwinkle.opacity(0.8))
            }
        } else if let progress = item.progress {
            RouteProgressRing(progress: progress, tint: accentColor)
        }
    }
}

private struct AddRouteCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(RoutePalette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                RoutePalette.periwinkle.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [8, 8])
                            )
                    )

                VStack(spacing: 14) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(RoutePalette.coral)

                    Text("Nueva ruta")
                        .font(.custom("Nunito-Bold", size: 20))
                        .foregroundColor(RoutePalette.periwinkle)

                    Text("Genera otro curso sin perder los que ya tienes en cola.")
                        .font(.custom("Nunito-Regular", size: 14))
                        .foregroundColor(RoutePalette.periwinkle.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
            .frame(minHeight: 250)
        }
        .buttonStyle(.plain)
    }
}

private struct RouteProgressRing: View {
    let progress: Double
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 8)
                .frame(width: 76, height: 76)

            Circle()
                .trim(from: 0, to: max(min(progress, 1), 0))
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 76, height: 76)

            Text("\(Int(progress * 100))%")
                .font(.custom("Nunito-Bold", size: 15))
                .foregroundColor(.white)
        }
    }
}

private struct SelectionChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let primaryTint: Color
    let secondaryTint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.custom("Nunito-SemiBold", size: 14))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(backgroundStyle)
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: isSelected ? 0 : 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var backgroundStyle: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [primaryTint, secondaryTint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }

        return AnyShapeStyle(RoutePalette.prussian)
    }

    private var borderColor: Color {
        RoutePalette.periwinkle.opacity(0.14)
    }
}

private struct RouteCarouselItem: Identifiable, Equatable {
    enum Kind: Equatable {
        case focus
        case created
        case add
    }

    enum Status: Equatable {
        case focus
        case generating
        case queued
        case active
        case failed
    }

    static let addCard = RouteCarouselItem(
        id: "add-route",
        kind: .add,
        title: "",
        subtitle: "",
        language: nil,
        frameworkName: nil,
        status: .active,
        progress: nil,
        moduleLabel: "",
        difficultyStars: 1,
        showsSkeleton: false
    )

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String
    let language: ProgrammingLanguage?
    let frameworkName: String?
    let status: Status
    let progress: Double?
    let moduleLabel: String
    let difficultyStars: Int
    let showsSkeleton: Bool
}

private enum RoutePalette {
    static let prussian = Color.loopBG
    static let coral = Color.coral
    static let celadon = Color.mint
    static let periwinkle = Color.periwinkle
    static let cerulean = Color.cerulean
    static let amethyst = Color.amethyst
    static let gold = Color.loopGold
    static let card = Color.loopSurf2
}

private extension ProgrammingLanguage {
    var symbolName: String {
        switch self {
        case .python, .javascript, .typescript:
            return "chevron.left.forwardslash.chevron.right"
        case .swift:
            return "swift"
        case .kotlin:
            return "k.square"
        case .rust:
            return "gear"
        case .go:
            return "g.square"
        case .html:
            return "curlybraces"
        }
    }
}

private extension CustomRouteStatus {
    var displayStatus: RouteCarouselItem.Status {
        switch self {
        case .generating:
            return .generating
        case .queued:
            return .queued
        case .active:
            return .active
        case .failed:
            return .failed
        }
    }
}
