import Combine
import SwiftUI

enum RoadmapNodeState: Equatable {
    case completed
    case active
    case locked
}

struct RoadmapNode: Identifiable {
    let id: String
    let order: Int
    let title: String
    let icon: String
    let state: RoadmapNodeState
    let isInteractive: Bool
}

private struct MapCourseEntry: Identifiable {
    enum MapCourseStatus { case active, queued, generating, failed }
    let id: String
    let title: String
    let language: String
    let mapStatus: MapCourseStatus
    let coursePayload: CourseStatusPayload?
    let courseSnapshot: RouteCourseSnapshot?

    var roadmapSnapshot: RouteCourseSnapshot? {
        if let coursePayload {
            return RouteCourseSnapshot(payload: coursePayload)
        }
        return courseSnapshot
    }
}

private struct MapLessonNodeData {
    let id: String
    let title: String
    let orderIndex: Int
    let status: String
    let difficulty: String?
}

struct MapView: View {
    @EnvironmentObject var appState: AppState
    @State private var revealByID: [String: Bool] = [:]
    @State private var selectedCourseID: String? = nil
    @State private var theoryLesson: LessonPayload?
    @State private var practiceLesson: LessonPayload?
    @State private var pendingOpenLessonOrder: Int?

    private let refreshTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            LoopMeshBackground()
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, Spacing.sm)

                if courseEntries.count > 1 {
                    routeTabs
                        .padding(.bottom, Spacing.sm)
                }

                if courseEntries.count > 1 {
                    pageIndicator
                        .padding(.bottom, Spacing.sm)
                }

                TabView(selection: $selectedCourseID) {
                    ForEach(courseEntries) { entry in
                        coursePageView(for: entry)
                            .tag(entry.id as String?)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .onAppear {
            appState.refreshTodayLesson()
            autoSelectCourse()
        }
        .onChange(of: appState.mapFocusedRouteID) { _, id in
            guard let id else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedCourseID = id
            }
            appState.mapFocusedRouteID = nil
        }
        .onChange(of: appState.customRoutes) { _, _ in
            if selectedCourseID == nil { autoSelectCourse() }
        }
        .onChange(of: courseEntries.map(\.id)) { _, ids in
            guard !ids.isEmpty else {
                selectedCourseID = nil
                return
            }
            if let selectedCourseID, ids.contains(selectedCourseID) {
                return
            }
            self.selectedCourseID = ids.first(where: { id in
                courseEntries.first(where: { $0.id == id })?.mapStatus == .active
            }) ?? ids.first
        }
        .onReceive(refreshTimer) { _ in
            guard isAnyGenerating else { return }
            appState.refreshTodayLesson()
        }
        .onChange(of: appState.todayLesson?.id) { _, _ in
            guard let pendingOpenLessonOrder, let lesson = appState.todayLesson else { return }
            guard lesson.orderIndex == pendingOpenLessonOrder else { return }
            self.pendingOpenLessonOrder = nil
            openLesson(lesson)
        }
        .fullScreenCover(item: $theoryLesson) { lesson in
            LessonTheoryView(
                lesson: lesson,
                courseLanguage: focusedEntry?.language ?? appState.currentCourse?.language ?? "Python",
                initialStepIndex: appState.lessonProgress(for: lesson.id)?.theoryStepIndex,
                onStartPractice: {
                    theoryLesson = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        practiceLesson = lesson
                    }
                },
                onClose: { theoryLesson = nil }
            )
        }
        .fullScreenCover(item: $practiceLesson) { lesson in
            ExerciseView(
                lesson: lesson,
                initialExerciseIndex: appState.lessonProgress(for: lesson.id)?.exerciseIndex,
                onCompleted: {
                    practiceLesson = nil
                    appState.refreshTodayLesson()
                },
                onClose: {
                    practiceLesson = nil
                }
            )
            .environmentObject(appState)
        }
    }

    // MARK: - Course entries

    private var courseEntries: [MapCourseEntry] {
        var entries: [MapCourseEntry] = []
        let currentID = appState.currentCourse?.id
        let currentTrackedInRoutes = currentID.map { id in
            appState.customRoutes.contains(where: { $0.backendCourseID == id })
        } ?? false

        if let current = appState.currentCourse, !currentTrackedInRoutes {
            entries.append(MapCourseEntry(
                id: current.id,
                title: current.resolvedTitle,
                language: current.language,
                mapStatus: current.shouldPresentGeneratingState ? .generating : .active,
                coursePayload: current,
                courseSnapshot: RouteCourseSnapshot(payload: current)
            ))
        }

        for route in appState.customRoutes {
            let isActive = route.status == .active
            let status: MapCourseEntry.MapCourseStatus
            switch route.status {
            case .generating: status = .generating
            case .queued:     status = .queued
            case .active:     status = isActive ? .active : .queued
            case .failed:     status = .failed
            }
            let livePayload = isActive && route.backendCourseID == currentID ? appState.currentCourse : nil
            let snapshot = livePayload.map(RouteCourseSnapshot.init(payload:)) ?? route.courseSnapshot
            entries.append(MapCourseEntry(
                id: route.id,
                title: snapshot?.resolvedTitle ?? route.title,
                language: snapshot?.language ?? route.request.language.rawValue,
                mapStatus: status,
                coursePayload: livePayload,
                courseSnapshot: snapshot
            ))
        }

        return entries
    }

    private var focusedEntry: MapCourseEntry? {
        if let id = selectedCourseID, let entry = courseEntries.first(where: { $0.id == id }) {
            return entry
        }
        return courseEntries.first(where: { $0.mapStatus == .active }) ?? courseEntries.first
    }

    private func autoSelectCourse() {
        guard selectedCourseID == nil else { return }
        selectedCourseID = courseEntries.first(where: { $0.mapStatus == .active })?.id
            ?? courseEntries.first?.id
    }

    private var isAnyGenerating: Bool {
        courseEntries.contains { $0.mapStatus == .generating } ||
            (focusedEntry?.mapStatus == .active && appState.isGeneratingCourse)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mapa")
                .font(LoopFont.black(30))
                .foregroundColor(.textPrimary)
            Text(courseEntries.count > 1
                 ? "Desliza entre tus rutas y revisa cada roadmap en su propia pestaña."
                 : "Tu curso se construye en vivo. Cada nodo desbloquea teoria y luego ejercicios.")
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var routeTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(courseEntries) { entry in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            selectedCourseID = entry.id
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                                .font(LoopFont.bold(13))
                                .lineLimit(1)
                            Text(routeTabSubtitle(for: entry))
                                .font(LoopFont.regular(11))
                                .lineLimit(1)
                        }
                        .foregroundColor(focusedEntry?.id == entry.id ? .white : .textSecond)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .fill(focusedEntry?.id == entry.id ? Color.coral.opacity(0.24) : Color.loopSurf2.opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .stroke(focusedEntry?.id == entry.id ? Color.coral.opacity(0.5) : Color.borderSoft, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Page indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(courseEntries) { entry in
                Capsule()
                    .fill(focusedEntry?.id == entry.id ? Color.coral : Color.periwinkle.opacity(0.3))
                    .frame(width: focusedEntry?.id == entry.id ? 20 : 6, height: 6)
                    .animation(.spring(duration: 0.3), value: focusedEntry?.id)
            }
        }
    }

    // MARK: - Course page

    private func coursePageView(for entry: MapCourseEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                routeSummaryCard(for: entry)
                roadmapSection(for: entry, revealed: revealByID[entry.id] ?? false)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, 140)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(0.05)) {
                revealByID[entry.id] = true
            }
        }
    }

    // MARK: - Summary card

    private func routeSummaryCard(for entry: MapCourseEntry) -> some View {
        let total = totalLessons(for: entry)
        let completed = completedLessonsCount(for: entry)
        let available = availableLessons(for: entry)
        let progress = routeProgress(for: entry)
        let generating = isGenerating(for: entry)
        return LoopCard(accentColor: .coral, showsSceneAccent: true, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(LoopFont.bold(18))
                            .foregroundColor(.textPrimary)
                        Text(generatedDescription(for: entry))
                            .font(LoopFont.regular(12))
                            .foregroundColor(.textSecond)
                            .lineLimit(3)
                    }
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(LoopFont.bold(16))
                        .foregroundColor(.coral)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.coral.opacity(0.16))
                        .clipShape(Capsule())
                }
                LoopProgressBar(progress: progress, height: 10)
                HStack {
                    Text("Completadas: \(completed)/\(total)")
                        .font(LoopFont.regular(12))
                        .foregroundColor(.textSecond)
                    Spacer()
                    Text("Disponibles: \(available)/\(total)")
                        .font(LoopFont.bold(11))
                        .foregroundColor(generating ? .loopGold : .coral)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Roadmap section

    private func roadmapSection(for entry: MapCourseEntry, revealed: Bool) -> some View {
        let nodes = roadmapNodes(for: entry)
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Roadmap")
                .font(LoopFont.bold(16))
                .foregroundColor(.textPrimary)
                .textCase(.uppercase)
                .tracking(0.8)

            LoopCard(accentColor: .clear, usesGlassSurface: true) {
                VStack(spacing: 0) {
                    ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                        RoadmapRow(
                            node: node,
                            tint: .coral,
                            index: index,
                            total: nodes.count,
                            onTap: { handleNodeTap(node) }
                        )
                        .scaleEffect(revealed ? 1 : 0.96)
                        .opacity(revealed ? 1 : 0)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.85).delay(Double(index) * 0.06),
                            value: revealed
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Per-entry computed values

    private var completedLessonIDs: Set<String> {
        appState.gameState.completedLessons
    }

    private var todayOrderIndex: Int? {
        appState.todayLesson?.orderIndex
    }

    private func totalLessons(for entry: MapCourseEntry) -> Int {
        max(entry.roadmapSnapshot?.totalLessons ?? 0, 0)
    }

    private func availableLessons(for entry: MapCourseEntry) -> Int {
        let total = totalLessons(for: entry)
        return min(entry.roadmapSnapshot?.resolvedAvailableLessons ?? 0, max(total, 0))
    }

    private func completedLessonsCount(for entry: MapCourseEntry) -> Int {
        let total = totalLessons(for: entry)
        if let payload = entry.coursePayload, !payload.lessons.isEmpty {
            let completedStatuses = Set(["completed", "done"])
            return min(
                payload.lessons.filter { completedLessonIDs.contains($0.id) || completedStatuses.contains($0.status.lowercased()) }.count,
                max(total, 0)
            )
        }
        if let snapshot = entry.roadmapSnapshot, !snapshot.lessons.isEmpty {
            let completedStatuses = Set(["completed", "done"])
            return min(
                snapshot.lessons.filter {
                    completedStatuses.contains($0.status.lowercased()) ||
                    (entry.mapStatus == .active && completedLessonIDs.contains($0.id))
                }.count,
                max(total, 0)
            )
        }
        return min(completedLessonIDs.count, max(total, 0))
    }

    private func routeProgress(for entry: MapCourseEntry) -> Double {
        let total = totalLessons(for: entry)
        guard total > 0 else { return 0 }
        return min(max(Double(completedLessonsCount(for: entry)) / Double(total), 0), 1)
    }

    private func isGenerating(for entry: MapCourseEntry) -> Bool {
        entry.mapStatus == .generating ||
            (entry.mapStatus == .active && appState.isGeneratingCourse)
    }

    private func generatedDescription(for entry: MapCourseEntry) -> String {
        switch entry.mapStatus {
        case .generating:
            if let summary = entry.roadmapSnapshot?.resolvedSummary,
               !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return summary
            }
            return "Tu ruta se va construyendo en vivo. Apenas se genera una leccion, se desbloquea aqui."
        case .queued:
            if let summary = entry.roadmapSnapshot?.resolvedSummary,
               !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "\(summary) Esta ruta permanece visible mientras espera turno."
            }
            return "Este curso está en cola. Cuando el activo avance, este se activará automáticamente."
        case .failed:
            return "Hubo un problema generando este curso. Intenta crear una nueva ruta."
        case .active:
            if let desc = entry.coursePayload?.generatedDescription,
               !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return desc
            }
            if let summary = entry.roadmapSnapshot?.resolvedSummary,
               !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return summary
            }
            return "Ruta lista. Avanza teoria + practica para desbloquear nuevas lecciones."
        }
    }

    // MARK: - Roadmap nodes

    private func roadmapNodes(for entry: MapCourseEntry) -> [RoadmapNode] {
        if entry.mapStatus == .failed {
            return []
        }

        let lessonData = roadmapLessonData(for: entry)
        if !lessonData.isEmpty {
            return buildRoadmapNodes(from: lessonData, for: entry)
        }

        switch entry.mapStatus {
        case .generating:
            return (1...6).map { i in
                RoadmapNode(id: "gen-\(entry.id)-\(i)", order: i, title: "Generando módulo \(i)...", icon: "sparkles", state: .locked, isInteractive: false)
            }
        case .queued:
            return (1...max(totalLessons(for: entry), 5)).map { i in
                RoadmapNode(id: "queued-\(entry.id)-\(i)", order: i, title: "Módulo \(i)", icon: "lock.fill", state: .locked, isInteractive: false)
            }
        case .failed:
            return []
        case .active:
            break
        }

        let total = totalLessons(for: entry)
        guard total > 0 else { return [] }
        let completedCount = min(completedLessonIDs.count, total)
        let activeOrder = completedCount < total ? completedCount + 1 : nil

        return (1...total).map { index in
            let state: RoadmapNodeState
            if let activeOrder {
                if index < activeOrder || completedCount >= index {
                    state = .completed
                } else if index == activeOrder {
                    state = .active
                } else {
                    state = .locked
                }
            } else {
                state = completedCount >= index ? .completed : .locked
            }
            let title: String
            if index == todayOrderIndex, let lessonTitle = appState.todayLesson?.title {
                title = lessonTitle
            } else {
                title = "Leccion \(index)"
            }
            let isInteractive = state == .active
            return RoadmapNode(
                id: "lesson-\(index)",
                order: index,
                title: title,
                icon: "book.fill",
                state: state,
                isInteractive: isInteractive
            )
        }
    }

    private func roadmapLessonData(for entry: MapCourseEntry) -> [MapLessonNodeData] {
        if let payload = entry.coursePayload, !payload.lessons.isEmpty {
            return payload.lessons.map {
                MapLessonNodeData(
                    id: $0.id,
                    title: $0.title,
                    orderIndex: $0.orderIndex,
                    status: $0.status,
                    difficulty: $0.difficulty
                )
            }
        }

        if let snapshot = entry.roadmapSnapshot, !snapshot.lessons.isEmpty {
            return snapshot.lessons.map {
                MapLessonNodeData(
                    id: $0.id,
                    title: $0.title,
                    orderIndex: $0.orderIndex,
                    status: $0.status,
                    difficulty: $0.difficulty
                )
            }
        }

        return []
    }

    private func buildRoadmapNodes(from lessons: [MapLessonNodeData], for entry: MapCourseEntry) -> [RoadmapNode] {
        let orderedLessons = lessons.sorted { $0.orderIndex < $1.orderIndex }
        var activeNodeAssigned = false

        return orderedLessons.map { lesson in
            let completed = entry.mapStatus == .active ? isCompleted(lesson) : isPreviewCompleted(lesson)
            let canActivate = !activeNodeAssigned && (entry.mapStatus == .active ? isActivatable(lesson) : isPreviewReady(lesson))

            let state: RoadmapNodeState
            if completed {
                state = .completed
            } else if canActivate {
                state = .active
                activeNodeAssigned = true
            } else {
                state = .locked
            }

            let isInteractive = entry.mapStatus == .active && state == .active

            return RoadmapNode(
                id: lesson.id.isEmpty ? "lesson-\(entry.id)-\(lesson.orderIndex)" : lesson.id,
                order: lesson.orderIndex,
                title: lesson.title.isEmpty ? "Leccion \(lesson.orderIndex)" : lesson.title,
                icon: "book.fill",
                state: state,
                isInteractive: isInteractive
            )
        }
    }

    // MARK: - Lesson interaction

    private func openLesson(_ lesson: LessonPayload) {
        let resumeState = appState.lessonProgress(for: lesson.id)
        if resumeState?.stage == .practice {
            practiceLesson = lesson
        } else {
            theoryLesson = lesson
        }
    }

    private func handleNodeTap(_ node: RoadmapNode) {
        guard node.isInteractive else { return }
        if let lesson = appState.todayLesson,
           lesson.orderIndex == node.order || lesson.id == node.id {
            openLesson(lesson)
            return
        }
        pendingOpenLessonOrder = node.order
        appState.refreshTodayLesson()
    }

    private func routeTabSubtitle(for entry: MapCourseEntry) -> String {
        switch entry.mapStatus {
        case .active:
            return "En foco"
        case .queued:
            return "En cola"
        case .generating:
            return "Generando"
        case .failed:
            return "Error"
        }
    }

    private func isCompleted(_ summary: MapLessonNodeData) -> Bool {
        let normalizedStatus = summary.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return completedLessonIDs.contains(summary.id) ||
            normalizedStatus == "completed" ||
            normalizedStatus == "done"
    }

    private func isActivatable(_ summary: MapLessonNodeData) -> Bool {
        let normalizedStatus = summary.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return matchesToday(summary) ||
            normalizedStatus == "ready" ||
            normalizedStatus == "available" ||
            normalizedStatus == "active" ||
            normalizedStatus == "in_progress"
    }

    private func isPreviewCompleted(_ summary: MapLessonNodeData) -> Bool {
        let normalizedStatus = summary.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedStatus == "completed" || normalizedStatus == "done"
    }

    private func isPreviewReady(_ summary: MapLessonNodeData) -> Bool {
        let normalizedStatus = summary.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedStatus == "ready" ||
            normalizedStatus == "available" ||
            normalizedStatus == "active" ||
            normalizedStatus == "in_progress"
    }

    private func matchesToday(_ summary: MapLessonNodeData) -> Bool {
        summary.id == appState.todayLesson?.id ||
            summary.orderIndex == todayOrderIndex
    }
}

private struct RoadmapRow: View {
    let node: RoadmapNode
    let tint: Color
    let index: Int
    let total: Int
    var onTap: (() -> Void)? = nil

    @State private var pulse = false
    @State private var connectorProgress: CGFloat = 0
    @State private var hasAnimatedOnAppear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLeft: Bool { index % 2 == 0 }
    private var isLast: Bool { index == total - 1 }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if !isLeft { Spacer(minLength: 0) }
            content
            if isLeft { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .opacity(node.state == .locked ? 0.58 : 1)
        .overlay(alignment: .center) {
            if !isLast {
                RoadmapConnector(
                    fromLeft: isLeft,
                    tint: tint,
                    isCompleted: nextNodeIsReachable,
                    progress: connectorProgress
                )
                .frame(height: 42)
                .offset(y: 38)
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            updateAnimationState(animated: !hasAnimatedOnAppear)
            hasAnimatedOnAppear = true
        }
        .onChange(of: node.state) { _, _ in
            updateAnimationState(animated: true)
        }
        .onChange(of: reduceMotion) { _, _ in
            updateAnimationState(animated: false)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard node.isInteractive else { return }
            HapticManager.shared.impact(.medium)
            onTap?()
        }
    }

    private var nextNodeIsReachable: Bool {
        node.state == .completed
    }

    private func updateAnimationState(animated: Bool) {
        let targetConnectorProgress: CGFloat = nextNodeIsReachable ? 1 : 0

        if nextNodeIsReachable && animated {
            connectorProgress = 0
            withAnimation(.easeOut(duration: 0.9).delay(Double(index) * 0.1)) {
                connectorProgress = 1
            }
        } else {
            connectorProgress = targetConnectorProgress
        }

        guard node.state == .active, !reduceMotion else {
            pulse = false
            return
        }

        if !pulse {
            if animated {
                withAnimation(LoopAnimation.pulseSlow) {
                    pulse = true
                }
            } else {
                pulse = true
            }
        }
    }

    private var content: some View {
        HStack(spacing: Spacing.sm) {
            if isLeft {
                nodeCircle
                nodeLabel(alignment: .leading)
            } else {
                nodeLabel(alignment: .trailing)
                nodeCircle
            }
        }
        .frame(maxWidth: 260, alignment: isLeft ? .leading : .trailing)
    }

    private var nodeCircle: some View {
        ZStack {
            Circle()
                .fill(fillGradient)
                .frame(width: 66, height: 66)
                .overlay(
                    Circle()
                        .stroke(strokeColor, lineWidth: node.state == .active ? 3 : node.state == .completed ? 2 : 1.5)
                )
                .shadow(color: shadowColor, radius: node.state == .active ? (pulse ? 22 : 14) : node.state == .completed ? 8 : 4, y: node.state == .active ? 6 : 2)
                .scaleEffect(node.state == .active && pulse ? 1.06 : 1)
                .modifier(LockedShimmerModifier(isLocked: node.state == .locked))

            Image(systemName: iconName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(iconColor)

            if node.state == .locked {
                lockedBadge
                    .offset(x: 22, y: 22)
            }

            if node.state == .active {
                Circle()
                    .stroke(tint.opacity(pulse ? 0.65 : 0.3), lineWidth: 2)
                    .frame(width: pulse ? 88 : 78, height: pulse ? 88 : 78)
                    .blur(radius: 0.5)
            }
        }
    }

    private func nodeLabel(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(node.title)
                .font(LoopFont.bold(14))
                .foregroundColor(.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
            Text(stateLabel)
                .font(LoopFont.bold(11))
                .foregroundColor(stateLabelColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(stateLabelColor.opacity(0.16))
                .clipShape(Capsule())

            if let lockedHint {
                Text(lockedHint)
                    .font(LoopFont.regular(11))
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var iconName: String {
        switch node.state {
        case .completed: return "checkmark"
        case .active: return node.icon
        case .locked: return "lock.fill"
        }
    }

    private var fillGradient: LinearGradient {
        switch node.state {
        case .completed:
            return LinearGradient(colors: [tint.opacity(0.9), tint.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .active:
            return LinearGradient(colors: [tint, tint.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .locked:
            return LinearGradient(colors: [Color.loopSurf2.opacity(0.9), Color.loopSurf1.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var strokeColor: Color {
        switch node.state {
        case .completed: return .coral
        case .active: return .white.opacity(0.9)
        case .locked: return Color.borderMid
        }
    }

    private var shadowColor: Color {
        switch node.state {
        case .active: return tint.opacity(0.55)
        case .completed: return tint.opacity(0.3)
        case .locked: return .black.opacity(0.2)
        }
    }

    private var iconColor: Color {
        switch node.state {
        case .completed, .active: return .white
        case .locked: return .textMuted
        }
    }

    private var stateLabel: String {
        switch node.state {
        case .completed: return "Completado"
        case .active: return node.isInteractive ? "Empieza teoria" : "Disponible"
        case .locked: return "Bloqueado"
        }
    }

    private var stateLabelColor: Color {
        switch node.state {
        case .completed: return .mint
        case .active: return tint
        case .locked: return .textMuted
        }
    }

    private var lockedHint: String? {
        guard node.state == .locked else { return nil }
        return "Completa la anterior para desbloquearla"
    }

    private var lockedBadge: some View {
        ZStack {
            Circle()
                .fill(Color.loopBG.opacity(0.92))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(Color.borderMid, lineWidth: 1)
                )

            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textPrimary)
        }
    }
}

private struct RoadmapConnector: View {
    let fromLeft: Bool
    let tint: Color
    let isCompleted: Bool
    var progress: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            let path = Path { path in
                let w = geo.size.width
                let h = geo.size.height
                let startX = fromLeft ? w * 0.32 : w * 0.68
                let endX = fromLeft ? w * 0.68 : w * 0.32
                path.move(to: CGPoint(x: startX, y: 0))
                path.addCurve(
                    to: CGPoint(x: endX, y: h),
                    control1: CGPoint(x: startX, y: h * 0.55),
                    control2: CGPoint(x: endX, y: h * 0.45)
                )
            }

            ZStack {
                path
                    .stroke(
                        Color.trackInactive.opacity(0.7),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: isCompleted ? [] : [5, 6])
                    )

                if isCompleted {
                    path
                        .trim(from: 0, to: progress)
                        .stroke(
                            tint.opacity(0.85),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                }
            }
        }
    }
}

private struct LockedShimmerModifier: ViewModifier {
    let isLocked: Bool

    func body(content: Content) -> some View {
        if isLocked {
            content.loopShimmer()
        } else {
            content
        }
    }
}
