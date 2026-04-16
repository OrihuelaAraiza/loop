import SwiftUI

struct LoopSegmentedProgress: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.coral : Color.borderSoft)
                    .frame(height: 6)
            }
        }
        .accessibilityLabel("Paso \(currentStep) de \(totalSteps)")
    }
}
