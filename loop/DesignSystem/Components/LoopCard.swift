import SwiftUI

struct LoopCard<Content: View>: View {
    var accentColor: Color = .clear
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.clear)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .fill(Color.loopSurf1.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .stroke(Color.borderMid, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                        .blur(radius: 0.2)
                )

            VStack {
                LinearGradient(
                    colors: [.clear, Color.periwinkle.opacity(0.12), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                Spacer()
            }

            if accentColor != .clear {
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor)
                        .frame(width: 3)
                    Spacer()
                }
                .padding(.vertical, Spacing.sm)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                content()
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
