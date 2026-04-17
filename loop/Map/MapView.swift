import SwiftUI

enum RoadmapNodeState {
    case completed
    case active
    case locked
}

struct RoadmapNode: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let state: RoadmapNodeState
}

struct RoadmapRoute: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let tint: Color
    let progress: Double
    let nodes: [RoadmapNode]
}

struct MapView: View {
    @State private var reveal = false
    @State private var selectedRouteID: UUID?

    private let routes: [RoadmapRoute] = [
        RoadmapRoute(
            title: "Python Foundations",
            subtitle: "Variables, flujo y funciones",
            tint: .coral,
            progress: 0.42,
            nodes: [
                .init(title: "Intro a Python", icon: "play.fill", state: .completed),
                .init(title: "Variables", icon: "number", state: .completed),
                .init(title: "Condicionales", icon: "arrow.triangle.branch", state: .active),
                .init(title: "Loops", icon: "arrow.clockwise", state: .locked),
                .init(title: "Funciones", icon: "function", state: .locked),
                .init(title: "Proyecto final", icon: "star.fill", state: .locked)
            ]
        ),
        RoadmapRoute(
            title: "JavaScript Start",
            subtitle: "Base del web moderno",
            tint: .periwinkle,
            progress: 0.18,
            nodes: [
                .init(title: "Sintaxis", icon: "curlybraces", state: .completed),
                .init(title: "DOM", icon: "doc.richtext", state: .active),
                .init(title: "Eventos", icon: "hand.tap.fill", state: .locked),
                .init(title: "Fetch", icon: "network", state: .locked),
                .init(title: "Proyecto web", icon: "star.fill", state: .locked)
            ]
        ),
        RoadmapRoute(
            title: "Web Core",
            subtitle: "HTML y CSS semantico",
            tint: .mint,
            progress: 0,
            nodes: [
                .init(title: "HTML", icon: "chevron.left.slash.chevron.right", state: .locked),
                .init(title: "CSS", icon: "paintpalette.fill", state: .locked),
                .init(title: "Layout", icon: "rectangle.3.group.fill", state: .locked),
                .init(title: "Responsive", icon: "iphone", state: .locked)
            ]
        )
    ]

    var body: some View {
        ZStack {
            LoopMeshBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    routeSelector

                    if let route = currentRoute {
                        routeSummary(route: route)
                        roadmap(for: route)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xl)
                .padding(.bottom, 140)
            }
        }
        .onAppear {
            if selectedRouteID == nil {
                selectedRouteID = routes.first?.id
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86).delay(0.05)) {
                reveal = true
            }
        }
    }

    private var currentRoute: RoadmapRoute? {
        routes.first(where: { $0.id == selectedRouteID }) ?? routes.first
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mapa")
                .font(LoopFont.black(30))
                .foregroundColor(.textPrimary)
            Text("Avanza nodo por nodo. Cada leccion desbloquea la siguiente en tu mapa.")
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var routeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(routes) { route in
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            selectedRouteID = route.id
                        }
                    } label: {
                        routeChip(route: route, isSelected: route.id == selectedRouteID)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func routeChip(route: RoadmapRoute, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(route.tint)
                .frame(width: 8, height: 8)
            Text(route.title)
                .font(LoopFont.bold(13))
                .foregroundColor(isSelected ? .textPrimary : .textSecond)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(isSelected ? Color.loopSurf2.opacity(0.92) : Color.loopSurf1.opacity(0.62))
        )
        .overlay(
            Capsule()
                .stroke(isSelected ? route.tint.opacity(0.6) : Color.borderSoft, lineWidth: 1)
        )
    }

    private func routeSummary(route: RoadmapRoute) -> some View {
        LoopCard(accentColor: route.tint, showsSceneAccent: true, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.title)
                            .font(LoopFont.bold(18))
                            .foregroundColor(.textPrimary)
                        Text(route.subtitle)
                            .font(LoopFont.regular(12))
                            .foregroundColor(.textSecond)
                    }
                    Spacer()
                    Text("\(Int(route.progress * 100))%")
                        .font(LoopFont.bold(16))
                        .foregroundColor(route.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(route.tint.opacity(0.16))
                        .clipShape(Capsule())
                }
                LoopProgressBar(progress: route.progress, height: 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func roadmap(for route: RoadmapRoute) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Roadmap")
                .font(LoopFont.bold(16))
                .foregroundColor(.textPrimary)
                .textCase(.uppercase)
                .tracking(0.8)

            LoopCard(accentColor: .clear, usesGlassSurface: true) {
                VStack(spacing: 0) {
                    ForEach(Array(route.nodes.enumerated()), id: \.element.id) { index, node in
                        RoadmapRow(
                            node: node,
                            tint: route.tint,
                            index: index,
                            total: route.nodes.count
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

private struct RoadmapRow: View {
    let node: RoadmapNode
    let tint: Color
    let index: Int
    let total: Int

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
            let delay = Double(index) * 0.1
            withAnimation(.easeOut(duration: 0.9).delay(delay)) {
                connectorProgress = 1
            }
            if node.state == .active, !reduceMotion {
                withAnimation(LoopAnimation.pulseSlow) {
                    pulse = true
                }
            }
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
        case .active: return "Continua aqui"
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
