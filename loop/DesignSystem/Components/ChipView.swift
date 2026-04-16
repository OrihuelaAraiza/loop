import SwiftUI

struct ChipView: View {
    let icon: String
    let text: String
    var tint: Color

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(tint)
                )
            Text(text).font(LoopFont.bold(12))
        }
        .foregroundColor(tint)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .background(Color.loopSurf2.opacity(0.82))
                .clipShape(Capsule())
        )
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.borderSoft, lineWidth: 1))
        .shadow(color: tint.opacity(0.08), radius: 8, y: 3)
    }
}
