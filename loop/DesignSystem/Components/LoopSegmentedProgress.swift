//
//  LoopSegmentedProgress.swift
//  loop
//
//  Barra de progreso del onboarding (7 segmentos).
//

import SwiftUI

struct LoopSegmentedProgress: View {
    /// Paso actual 1...7
    let currentStep: Int
    let totalSteps: Int = 7

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1 ... totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? LoopPalette.coral : LoopPalette.periwinkle.opacity(0.25))
                    .frame(height: 6)
            }
        }
        .accessibilityLabel("Paso \(currentStep) de \(totalSteps)")
    }
}
