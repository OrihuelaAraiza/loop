import SwiftUI

struct LoopSceneAccent: View {
    var tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.34), tint.opacity(0.08), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 62
                    )
                )

            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(tint.opacity(0.24), lineWidth: 1)
                .frame(width: 58, height: 58)
                .rotationEffect(.degrees(18))

            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                .frame(width: 38, height: 38)

            Circle()
                .fill(tint)
                .frame(width: 10, height: 10)
                .offset(x: 18, y: -20)
                .shadow(color: tint.opacity(0.38), radius: 10, y: 0)
        }
        .frame(width: 92, height: 92)
        .allowsHitTesting(false)
    }
}
