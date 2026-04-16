import SwiftUI

struct ProgressMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.loopSurf2.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .stroke(Color.borderSoft, lineWidth: 1)
                )

            Circle()
                .fill(tint.opacity(0.14))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(tint)
                )
                .padding(Spacing.md)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(LoopFont.semiBold(13))
                    .foregroundColor(.textSecond)
                Text(value)
                    .font(LoopFont.black(34))
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
        }
        .frame(height: 138)
    }
}
