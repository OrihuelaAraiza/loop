import SwiftUI

struct LoopPlacementToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            HapticManager.shared.impact(.medium)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Color.cerulean : Color.trackInactive)
                    .frame(width: 52, height: 30)

                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                    .padding(3)
            }
            .overlay(
                Capsule()
                    .stroke(Color.borderMid, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Mini test de placement"))
        .accessibilityValue(Text(isOn ? "activado" : "desactivado"))
        .accessibilityAddTraits(.isButton)
    }
}
