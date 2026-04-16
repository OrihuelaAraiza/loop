import SwiftUI

struct ProgressMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        LoopCard(accentColor: tint, showsSceneAccent: true, usesGlassSurface: true) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(LoopFont.semiBold(13))
                        .foregroundColor(.textSecond)
                    Text(value)
                        .font(LoopFont.black(32))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: Spacing.md)

                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(tint)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 132)
    }
}
