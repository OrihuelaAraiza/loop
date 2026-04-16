import Foundation
import Combine

final class OnboardingViewModel: ObservableObject {
    @Published var step: Int = 0
    @Published var userProfile = UserProfile()
    @Published var wantsPlacementTest = false
    @Published var placementScore = 0

    let totalSteps = 7

    func next() {
        if step < totalSteps - 1 { step += 1 }
    }

    func previous() {
        if step > 0 { step -= 1 }
    }

    func generatePlan() {
        userProfile.generatedPlan = PlanGenerator.generatePlan(from: userProfile)
    }
}
