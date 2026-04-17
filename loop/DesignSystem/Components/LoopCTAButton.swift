import SwiftUI

struct LoopCTAButton: ButtonStyle {
    enum Size {
        case regular
        case compact

        var minHeight: CGFloat {
            switch self {
            case .regular: return 52
            case .compact: return 40
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .regular: return Spacing.lg
            case .compact: return Spacing.md
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .regular: return 16
            case .compact: return 12
            }
        }
    }

    var size: Size = .regular
    var tint: Color = .coral
    var foreground: Color = .white
    var isCircular: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        CTAButtonContent(
            configuration: configuration,
            size: size,
            tint: tint,
            foreground: foreground,
            isCircular: isCircular
        )
    }
}

private struct CTAButtonContent: View {
    let configuration: ButtonStyle.Configuration
    let size: LoopCTAButton.Size
    let tint: Color
    let foreground: Color
    let isCircular: Bool

    var body: some View {
        configuration.label
            .font(LoopFont.bold(size == .regular ? 16 : 14))
            .foregroundColor(foreground)
            .padding(.horizontal, isCircular ? 0 : size.horizontalPadding)
            .frame(minWidth: isCircular ? size.minHeight : nil)
            .frame(minHeight: size.minHeight)
            .frame(maxWidth: isCircular ? nil : .infinity)
            .background(
                Group {
                    if isCircular {
                        Circle().fill(tint)
                    } else {
                        RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                            .fill(tint)
                    }
                }
            )
            .overlay(
                Group {
                    if isCircular {
                        Circle().stroke(Color.white.opacity(0.14), lineWidth: 1)
                    } else {
                        RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    }
                }
            )
            .shadow(color: tint.opacity(configuration.isPressed ? 0.15 : 0.32), radius: configuration.isPressed ? 6 : 14, y: configuration.isPressed ? 3 : 8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(LoopAnimation.springFast, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticManager.shared.impact(.light)
                }
            }
    }
}
