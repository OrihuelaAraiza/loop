import SwiftUI

enum LoopCTAStyle {
    case gradient
    case solid(Color)
}

struct LoopCTA: View {
    let title: String
    var trailingIcon: String? = nil
    var isDisabled: Bool = false
    var style: LoopCTAStyle = .gradient
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title)
                    .font(LoopFont.bold(15))
                    .foregroundColor(isDisabled ? .textMuted : .white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isDisabled ? .textMuted : .white.opacity(0.92))
                }
            }
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(backgroundFill)

                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.white.opacity(isDisabled ? 0.03 : 0.05))

                    VStack {
                        LinearGradient(
                            colors: [Color.white.opacity(isDisabled ? 0.08 : 0.26), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        Spacer()
                    }

                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDisabled ? 0.04 : 0.2),
                                    Color.white.opacity(0.04),
                                    Color.white.opacity(isDisabled ? 0.02 : 0.12),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isPressed && !isDisabled ? 0.985 : 1)
            .shadow(color: isDisabled ? .clear : shadowTint.opacity(0.24), radius: isPressed ? 8 : 18, y: isPressed ? 4 : 10)
            .shadow(color: isDisabled ? .clear : secondaryShadowTint.opacity(0.18), radius: isPressed ? 10 : 24, y: 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled { isPressed = true }
                }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.75 : 1)
        .buttonStyle(.plain)
    }

    private var backgroundFill: AnyShapeStyle {
        if isDisabled {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.loopSurf3, Color.loopSurf2],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }

        switch style {
        case .gradient:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.coral, Color.amethyst.opacity(0.92)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case let .solid(color):
            return AnyShapeStyle(color)
        }
    }

    private var shadowTint: Color {
        switch style {
        case .gradient:
            return .coral
        case let .solid(color):
            return color
        }
    }

    private var secondaryShadowTint: Color {
        switch style {
        case .gradient:
            return .amethyst
        case let .solid(color):
            return color.opacity(0.8)
        }
    }
}
