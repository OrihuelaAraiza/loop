import SwiftUI

struct LoopProgressBar: View {
    var progress: Double
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let safeProgress = progress.clamped(to: 0 ... 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.loopSurf3)
                    .overlay(Capsule().stroke(Color.borderSoft, lineWidth: 1))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.cerulean, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * safeProgress)
                Circle()
                    .fill(Color.mint.opacity(0.9))
                    .frame(width: height + 2, height: height + 2)
                    .shadow(color: Color.mint.opacity(0.3), radius: 6, y: 1)
                    .offset(x: max(0, width * safeProgress - height))
            }
        }
        .frame(height: height)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
