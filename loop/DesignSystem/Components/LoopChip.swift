import Pow
import SwiftUI

struct LoopChip: View {
    let title: String
    var icon: String? = nil
    var subtitle: String? = nil
    let isSelected: Bool
    var tint: Color = .coral
    var fullWidth: Bool = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isSelected ? .white : tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LoopFont.bold(14))
                        .foregroundColor(isSelected ? .white : .periwinkle)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let subtitle {
                        Text(subtitle)
                            .font(LoopFont.regular(11))
                            .foregroundColor(isSelected ? Color.white.opacity(0.78) : .textSecond)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                if fullWidth { Spacer(minLength: 0) }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 12)
            .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.18) : Color(hex: "1E2240"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? tint : Color.periwinkle.opacity(0.3), lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? tint.opacity(0.28) : .clear, radius: 10, y: 4)
            .scaleEffect(isSelected ? 1.02 : 1)
            .animation(reduceMotion ? nil : LoopAnimation.springFast, value: isSelected)
        }
        .buttonStyle(.plain)
        .changeEffect(.spray(origin: UnitPoint.center) {
            Image(systemName: "sparkle")
                .foregroundColor(tint)
        }, value: isSelected, isEnabled: isSelected && !reduceMotion)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}
