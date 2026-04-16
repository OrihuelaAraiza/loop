import SwiftUI

enum MainTab: Int, CaseIterable {
    case home
    case map
    case challenges
    case profile

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .map: return "map.fill"
        case .challenges: return "trophy.fill"
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
                    selected = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(selected == tab ? .coral : .textMuted)
                            .shadow(color: selected == tab ? Color.coral.opacity(0.25) : .clear, radius: 10)
                        Capsule()
                            .fill(selected == tab ? Color.coral : .clear)
                            .frame(width: 20, height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
        .background(Color.loopSurf1.opacity(0.92))
        .overlay(Rectangle().fill(Color.borderSoft).frame(height: 1), alignment: .top)
    }
}
