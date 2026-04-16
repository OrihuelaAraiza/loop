//
//  OnboardingCoordinator.swift
//  loop
//
//  Estado del flujo de onboarding (7 pasos).
//

import Foundation
import Observation

@Observable
@MainActor
final class OnboardingCoordinator {
    /// Paso visible 1...7
    var step: Int = 1
    /// Datos del usuario; se irá llenando en pasos siguientes.
    var profile = UserLearningProfile()

    func goToNextStep() {
        guard step < 7 else { return }
        step += 1
    }

    func goToPreviousStep() {
        guard step > 1 else { return }
        step -= 1
    }
}
