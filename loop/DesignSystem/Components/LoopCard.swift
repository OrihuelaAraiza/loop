import SwiftUI

struct LoopCard<Content: View>: View {
    var accentColor: Color = .clear
    var showsSceneAccent = false
    var usesGlassSurface = false
    @Environment(\.loopCloudMotionEnabled) private var cloudMotionEnabled
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(
                    LinearGradient(
                        colors: usesGlassSurface
                            ? [Color.loopSurf2.opacity(0.56), Color.loopSurf1.opacity(0.48)]
                            : [Color.loopSurf2.opacity(0.92), Color.loopSurf1.opacity(0.94)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .fill(Color.loopSurf1.opacity(usesGlassSurface ? 0.18 : 0.42))
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
                .shadow(color: Color.black.opacity(0.22), radius: 20, y: 14)

            if cloudMotionEnabled, accentColor != .clear {
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(usesGlassSurface ? 0.12 : 0.18), .clear, accentColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: usesGlassSurface ? 10 : 2)
            }

            VStack {
                LinearGradient(
                    colors: [.white.opacity(usesGlassSurface ? 0.02 : 0.03), .white.opacity(usesGlassSurface ? 0.08 : 0.12), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 36)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                Spacer()
            }

            if showsSceneAccent, accentColor != .clear {
                LoopSceneAccent(tint: accentColor)
                    .padding(.top, -4)
                    .padding(.trailing, -2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                content()
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
