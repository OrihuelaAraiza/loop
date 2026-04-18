import SwiftUI
import Combine

enum RoadmapNodeState {
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
        .fullScreenCover(item: $theoryLesson) { lesson in
            LessonTheoryView(
                lesson: lesson,
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
                onCompleted: {
                    practiceLesson = nil
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
        let status = appState.currentCourse?.status ?? "draft"
        return status != "ready_full"
    }

    private var courseTitle: String {
        appState.currentCourse?.resolvedTitle ??
            "Generando curso..."
    }

    private var totalLessons: Int {
        max(rawTotalLessons, rawReadyLessons, todayOrderIndex ?? 0, 0)
    }

    private var rawTotalLessons: Int {
        max(appState.currentCourse?.totalLessons ?? 0, 0)
    }

    private var rawReadyLessons: Int {
        appState.currentCourse?.resolvedReadyLessons ?? 0
    }

    private var rawCompletedLessons: Int {
        appState.currentCourse?.resolvedCompletedLessons ?? 0
    }

    private var rawReadyOnlyLessons: Int {
        appState.currentCourse?.resolvedReadyOnlyLessons ?? 0
    }

    private var readyLessons: Int {
        min(max(rawReadyLessons, 0), max(totalLessons, 0))
    }

    private var completedLessons: Int {
        min(max(rawCompletedLessons, 0), max(totalLessons, 0))
    }

    private var readyOnlyLessons: Int {
        min(max(rawReadyOnlyLessons, 0), max(totalLessons - completedLessons, 0))
    }

    private var routeProgress: Double {
        guard totalLessons > 0 else { return 0 }
        return min(max(Double(readyLessons) / Double(totalLessons), 0), 1)
    }

    private var generatedDescription: String {
        if let description = appState.currentCourse?.generatedDescription,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }

        if isStillGenerating {
            return "Tu ruta se va construyendo en vivo. Apenas se genera una lección, se desbloquea aquí."
        }

        return "Ruta lista. Avanza teoría + práctica para desbloquear nuevas lecciones."
    }

    private var todayOrderIndex: Int? {
        guard let order = appState.todayLesson?.orderIndex else { return nil }
        return max(order, 1)
    }

    private var activeRoadmapOrder: Int? {
        if let todayOrderIndex {
            return min(max(todayOrderIndex, 1), totalLessons)
        }

        guard readyOnlyLessons > 0, totalLessons > 0 else { return nil }
        return min(completedLessons + 1, totalLessons)
    }

    private var usesReachabilityFallback: Bool {
        guard let activeOrder = todayOrderIndex, totalLessons > 0 else { return false }
        let minimumReachableOrder = min(completedLessons + 1, totalLessons)
        let maximumReachableOrder = min(completedLessons + max(readyOnlyLessons, 1), totalLessons)
        return activeOrder < minimumReachableOrder || activeOrder > maximumReachableOrder
    }

    private var hasRoadmapDataIssues: Bool {
        if totalLessons == 0 {
            return appState.todayLesson != nil || rawReadyLessons > 0
        }

        if rawCompletedLessons > rawReadyLessons {
            return true
        }

        if rawTotalLessons > 0 && rawReadyLessons > rawTotalLessons {
            return true
        }

        if rawTotalLessons > 0 && rawCompletedLessons > rawTotalLessons {
            return true
        }

        if let todayOrderIndex, rawTotalLessons > 0, todayOrderIndex > rawTotalLessons {
            return true
        }

        if usesReachabilityFallback {
            return true
        }

        return false
    }

    private var roadmapStatusMessage: String? {
        if let backendError = appState.courseSyncErrorMessage {
            return backendError
        }

        if usesReachabilityFallback {
            return "El backend devolvió una lección activa fuera del progreso confirmado. No marcaremos módulos como completados hasta resincronizar."
        }

        guard hasRoadmapDataIssues else { return nil }
        return "El roadmap se está resincronizando con el backend. Mostramos una versión segura mientras llegan todos los nodos."
    }

    private var roadmapAnimationsEnabled: Bool {
        !hasRoadmapDataIssues && appState.courseSyncErrorMessage == nil
    }

    private var roadmapNodes: [RoadmapNode] {
        guard totalLessons > 0 else { return [] }

        let activeOrder = activeRoadmapOrder
        let readyRangeStart = min(completedLessons + 1, totalLessons)
        let readyRangeEnd = min(completedLessons + readyOnlyLessons, totalLessons)
        let canShowReadyRange = readyOnlyLessons > 0 && !usesReachabilityFallback

        return (1 ... totalLessons).map { index in
            let state: RoadmapNodeState
            if index <= completedLessons {
                state = .completed
            } else if let activeOrder, index == activeOrder {
                state = .active
            } else if canShowReadyRange, index >= readyRangeStart, index <= readyRangeEnd {
                state = .active
            } else {
                state = .locked
            }

            let title: String
            if index == todayOrderIndex, let lessonTitle = appState.todayLesson?.title {
                title = lessonTitle
            } else {
                title = "Lección \(index)"
            }

            let isInteractive = index == todayOrderIndex && appState.todayLesson != nil

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
            Text("Tu curso se construye en vivo. Cada nodo desbloquea teoría y luego ejercicios.")
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
                    Text("Lecciones listas: \(readyLessons)/\(totalLessons)")
                        .font(LoopFont.regular(12))
                        .foregroundColor(.textSecond)
                    Spacer()
                    if isStillGenerating {
                        Text("Generando...")
                            .font(LoopFont.bold(11))
                            .foregroundColor(.loopGold)
                    }
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

            if let roadmapStatusMessage {
                LoopCard(accentColor: .loopGold, usesGlassSurface: true) {
                    Text(roadmapStatusMessage)
                        .font(LoopFont.regular(12))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            LoopCard(accentColor: .clear, usesGlassSurface: true) {
                if roadmapNodes.isEmpty {
                    Text(isStillGenerating ? "Estamos esperando el roadmap real del backend." : "Todavía no hay nodos disponibles para este curso.")
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Spacing.sm)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(roadmapNodes.enumerated()), id: \.element.id) { index, node in
                            RoadmapRow(
                                node: node,
                                tint: .coral,
                                index: index,
                                total: roadmapNodes.count,
                                animationsEnabled: roadmapAnimationsEnabled,
                                onTap: {
                                    guard node.isInteractive, let lesson = appState.todayLesson else { return }
                                    theoryLesson = lesson
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
    }
}

private struct RoadmapRow: View {
    let node: RoadmapNode
    let tint: Color
    let index: Int
    let total: Int
    let animationsEnabled: Bool
    var onTap: (() -> Void)? = nil

    @State private var pulse = false
    @State private var connectorProgress: CGFloat = 0
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
        .opacity(node.state == .locked ? 0.4 : 1)
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
            updateAnimationState()
        }
        .onChange(of: node.state) { _, _ in
            updateAnimationState()
        }
        .onChange(of: animationsEnabled) { _, _ in
            updateAnimationState()
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
        case .active: return node.isInteractive ? "Empieza teoría" : "Disponible"
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

    private func updateAnimationState() {
        if animationsEnabled {
            let delay = Double(index) * 0.1
            connectorProgress = isLast ? 1 : 0
            if !isLast {
                withAnimation(.easeOut(duration: 0.9).delay(delay)) {
                    connectorProgress = 1
                }
            }

            if node.state == .active, !reduceMotion {
                withAnimation(LoopAnimation.pulseSlow) {
                    pulse = true
                }
            } else {
                pulse = false
            }
        } else {
            connectorProgress = 1
            pulse = false
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
