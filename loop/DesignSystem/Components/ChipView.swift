import SwiftUI

struct ChipView: View {
    let icon: String
    let text: String
    var tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(tint)
                )
            Text(text)
                .font(LoopFont.bold(12))
                .foregroundColor(.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.loopSurf3.opacity(0.95), Color.loopSurf1.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [tint.opacity(0.18), Color.white.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: tint.opacity(0.12), radius: 10, y: 4)
    }
}
