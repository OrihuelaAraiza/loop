//
//  OnboardingView.swift
//  loop
//
//  Contenedor del onboarding con barra de 7 segmentos.
//

import SwiftUI

struct OnboardingView: View {
    @State private var coordinator = OnboardingCoordinator()

    var body: some View {
        ZStack {
            LoopPalette.baseBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                stepContent
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            LoopSegmentedProgress(currentStep: coordinator.step)
                .padding(.horizontal, LoopSpacing.screenHorizontal)
                .padding(.top, 10)
        }
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(LoopPalette.prussian.opacity(0.94))
    }

    @ViewBuilder
    private var stepContent: some View {
        switch coordinator.step {
        case 1:
            OnboardingWelcomeContent {
                coordinator.goToNextStep()
            }
        default:
            // Placeholder hasta implementar pasos 2–7
            VStack(spacing: 20) {
                Text("Paso \(coordinator.step) de 7")
                    .font(LoopFont.nunito(.bold, size: 20, relativeTo: .title2))
                    .foregroundStyle(LoopPalette.periwinkle)
                Text("Contenido del paso en construcción.")
                    .font(LoopFont.nunito(.regular, size: 15, relativeTo: .body))
                    .foregroundStyle(LoopPalette.periwinkle.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LoopSpacing.screenHorizontal)

                Button {
                    coordinator.goToPreviousStep()
                } label: {
                    Text("Atrás")
                        .font(LoopFont.nunito(.semibold, size: 16, relativeTo: .body))
                        .foregroundStyle(LoopPalette.periwinkle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: LoopSpacing.buttonCornerRadius, style: .continuous)
                                .stroke(LoopPalette.periwinkle.opacity(0.45), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .disabled(coordinator.step <= 1)
                .opacity(coordinator.step <= 1 ? 0.4 : 1)
                .padding(.horizontal, LoopSpacing.screenHorizontal)

                Spacer(minLength: 0)
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

#Preview("Onboarding") {
    OnboardingView()
}
