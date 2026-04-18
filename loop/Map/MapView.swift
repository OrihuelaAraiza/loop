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

private struct MapScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MapView: View {
    @EnvironmentObject var appState: AppState
    @State private var reveal = false
    @State private var scrollOffset: CGFloat = 0
    @State private var theoryLesson: LessonPayload?
    @State private var practiceLesson: LessonPayload?
    @State private var pendingOpenLessonOrder: Int?

    private let refreshTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            LoopMeshBackground()
            ScrollView {
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: MapScrollOffsetKey.self,
                            value: -geo.frame(in: .named("mapScroll")).minY
                        )
                }
                .frame(height: 0)

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    routeSummary
                        .opacity(expandedHeaderOpacity)
                    roadmap
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xl)
                .padding(.bottom, 140)
            }
            .coordinateSpace(name: "mapScroll")
            .onPreferenceChange(MapScrollOffsetKey.self) { offset in
                scrollOffset = offset
            }
        }
        .onAppear {
            appState.refreshTodayLesson()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(0.05)) {
                reveal = true
            }
        }
        .onReceive(refreshTimer) { _ in
            guard isStillGenerating else { return }
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
                courseLanguage: appState.currentCourse?.language ?? "Python",
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

    private var expandedHeaderOpacity: Double {
        max(0, 1 - Double(scrollOffset) / 140)
    }

    private var isStillGenerating: Bool {
        appState.isGeneratingCourse
    }

    private var courseTitle: String {
        appState.currentCourse?.generatedCourseTitle ??
            appState.currentCourse?.title ??
            "Generando curso..."
    }

    private var totalLessons: Int {
        max(appState.currentCourse?.totalLessons ?? 1, 1)
    }

    private var availableLessons: Int {
        min(appState.currentCourse?.resolvedAvailableLessons ?? 0, max(totalLessons, 0))
    }

    private var completedLessonsCount: Int {
        if let currentCourse = appState.currentCourse, !currentCourse.lessons.isEmpty {
            let completedStatuses = Set(["completed", "done"])
            let count = currentCourse.lessons.filter { summary in
                completedLessonIDs.contains(summary.id) || completedStatuses.contains(summary.status.lowercased())
            }.count
            return min(count, max(totalLessons, 0))
        }

        return min(completedLessonIDs.count, max(totalLessons, 0))
    }

    private var routeProgress: Double {
        guard totalLessons > 0 else { return 0 }
        return min(max(Double(completedLessonsCount) / Double(max(totalLessons, 1)), 0), 1)
    }

    private var generatedDescription: String {
        if let description = appState.currentCourse?.generatedDescription,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }

        if isStillGenerating {
            return "Tu ruta se va construyendo en vivo. Apenas se genera una leccion, se desbloquea aqui."
        }

        return "Ruta lista. Avanza teoria + practica para desbloquear nuevas lecciones."
    }

    private var todayOrderIndex: Int? {
        appState.todayLesson?.orderIndex
    }

    private var completedLessonIDs: Set<String> {
        appState.gameState.completedLessons
    }

    private var roadmapNodes: [RoadmapNode] {
        let summaries = (appState.currentCourse?.lessons ?? []).sorted { $0.orderIndex < $1.orderIndex }

        // If backend already sent the real lesson list, use that.
        if !summaries.isEmpty {
            var activeNodeAssigned = false

            return summaries.map { summary in
                let completed = isCompleted(summary)
                let canActivate = !activeNodeAssigned && isActivatable(summary)
                let state: RoadmapNodeState

                if completed {
                    state = .completed
                } else if canActivate {
                    state = .active
                    activeNodeAssigned = true
                } else {
                    state = .locked
                }

                let isInteractive = state == .active

                return RoadmapNode(
                    id: summary.id.isEmpty ? "lesson-\(summary.orderIndex)" : summary.id,
                    order: summary.orderIndex,
                    title: summary.title.isEmpty ? "Leccion \(summary.orderIndex)" : summary.title,
                    icon: "book.fill",
                    state: state,
                    isInteractive: isInteractive
                )
            }
        }

        // Fallback: no lesson list (older server or course not yet built)
        let completedCount = min(completedLessonIDs.count, totalLessons)
        let activeOrder = completedCount < totalLessons ? completedCount + 1 : nil

        return (1 ... totalLessons).map { index in
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mapa")
                .font(LoopFont.black(30))
                .foregroundColor(.textPrimary)
            Text("Tu curso se construye en vivo. Cada nodo desbloquea teoria y luego ejercicios.")
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var routeSummary: some View {
        LoopCard(accentColor: .coral, showsSceneAccent: true, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(courseTitle)
                            .font(LoopFont.bold(18))
                            .foregroundColor(.textPrimary)
                        Text(generatedDescription)
                            .font(LoopFont.regular(12))
                            .foregroundColor(.textSecond)
                            .lineLimit(3)
                    }
                    Spacer()
                    Text("\(Int(routeProgress * 100))%")
                        .font(LoopFont.bold(16))
                        .foregroundColor(.coral)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.coral.opacity(0.16))
                        .clipShape(Capsule())
                }
                LoopProgressBar(progress: routeProgress, height: 10)
                HStack {
                    Text("Completadas: \(completedLessonsCount)/\(totalLessons)")
                        .font(LoopFont.regular(12))
                        .foregroundColor(.textSecond)
                    Spacer()
                    Text("Disponibles: \(availableLessons)/\(totalLessons)")
                        .font(LoopFont.bold(11))
                        .foregroundColor(isStillGenerating ? .loopGold : .coral)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var roadmap: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Roadmap")
                .font(LoopFont.bold(16))
                .foregroundColor(.textPrimary)
                .textCase(.uppercase)
                .tracking(0.8)

            LoopCard(accentColor: .clear, usesGlassSurface: true) {
                VStack(spacing: 0) {
                    ForEach(Array(roadmapNodes.enumerated()), id: \.element.id) { index, node in
                        RoadmapRow(
                            node: node,
                            tint: .coral,
                            index: index,
                            total: roadmapNodes.count,
                            onTap: {
                                handleNodeTap(node)
                            }
                        )
                        .scaleEffect(reveal ? 1 : 0.96)
                        .opacity(reveal ? 1 : 0)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.85).delay(Double(index) * 0.06),
                            value: reveal
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

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

    private func isCompleted(_ summary: LessonSummary) -> Bool {
        let normalizedStatus = summary.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return completedLessonIDs.contains(summary.id) ||
            normalizedStatus == "completed" ||
            normalizedStatus == "done"
    }

    private func isActivatable(_ summary: LessonSummary) -> Bool {
        let normalizedStatus = summary.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return matchesToday(summary) ||
            normalizedStatus == "ready" ||
            normalizedStatus == "available" ||
            normalizedStatus == "active" ||
            normalizedStatus == "in_progress"
    }

    private func matchesToday(_ summary: LessonSummary) -> Bool {
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
