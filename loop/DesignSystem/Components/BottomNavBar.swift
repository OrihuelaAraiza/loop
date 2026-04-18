import SwiftUI

enum MainTab: Int, CaseIterable {
    case home
    case routes
    case map
    case profile

    var title: String {
        switch self {
        case .home: return "Inicio"
        case .routes: return "Rutas"
        case .map: return "Mapa"
        case .profile: return "Perfil"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .routes: return "bolt.fill"
        case .map: return "map.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct BottomNavBar: View {
    @Binding var selected: MainTab

    var body: some View {
        HStack {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selected = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(selected == tab ? .white : .textMuted)

                        if selected == tab {
                            Text(tab.title)
                                .font(LoopFont.bold(12))
                                .foregroundColor(.white)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                selected == tab
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [Color.coral, Color.amethyst.opacity(0.9)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    : AnyShapeStyle(Color.clear)
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(selected == tab ? Color.white.opacity(0.12) : .clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.xl)
                .fill(Color.loopSurf1.opacity(0.94))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.xl))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl)
                .stroke(Color.borderMid, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.24), radius: 20, y: 14)
        .padding(.horizontal, Spacing.lg)
    }
}
