import SwiftUI

struct AmbientBackground: View {
    var topColor: Color = .amethyst
    var bottomColor: Color = .cerulean
    @State private var drift = false

    var body: some View {
        ZStack {
            Color.loopBG.ignoresSafeArea()
            RadialGradient(
                colors: [topColor.opacity(0.12), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 240
            )
            .ignoresSafeArea()
            .offset(x: drift ? -10 : 14, y: drift ? 8 : -16)
            .blur(radius: drift ? 0 : 1.2)

            RadialGradient(
                colors: [bottomColor.opacity(0.10), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 220
            )
            .ignoresSafeArea()
            .offset(x: drift ? 12 : -14, y: drift ? -10 : 14)
            .blur(radius: drift ? 1 : 0.2)

            // Capa de grano sutil para evitar look plano.
            LinearGradient(
                colors: [
                    Color.white.opacity(0.02),
                    Color.clear,
                    Color.black.opacity(0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.softLight)
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                drift.toggle()
            }
        }
    }
}
