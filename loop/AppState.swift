import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var userProfile = UserProfile()
    @Published var gameState = GameState()
}
