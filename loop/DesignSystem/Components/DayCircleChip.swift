import SwiftUI

struct DayCircleChip: View {
    let letter: String
    let isSelected: Bool
    var tint: Color = .coral
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [tint, Color.amethyst.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color.trackInactive)
                    )

                if isSelected {
                    Circle()
                        .strokeBorder(tint.opacity(0.7), lineWidth: 2)
                        .blur(radius: 2)
                }

                Text(letter)
                    .font(LoopFont.bold(15))
                    .foregroundColor(isSelected ? .white : .periwinkle)
            }
            .frame(width: 42, height: 42)
            .shadow(color: isSelected ? tint.opacity(0.45) : .clear, radius: 8, y: 3)
            .scaleEffect(isSelected ? 1.08 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            .loopSelectionBloom(isSelected: isSelected, tint: tint, shape: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Dia \(letter)"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}
