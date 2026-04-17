import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false {
        didSet { persistFlags() }
    }

    @Published var userProfile = UserProfile() {
        didSet { persistProfile() }
    }

    @Published var gameState = GameState() {
        didSet { persistGameState() }
    }

    @Published var authSession: AuthSession? {
        didSet { persistAuth() }
    }

    private let profileKey = "loop.userProfile"
    private let gameKey = "loop.gameState"
    private let onboardingKey = "loop.hasCompletedOnboarding"
    private let authKey = "loop.authSession"

    init() {
        loadFromStorage()
    }

    var isSignedIn: Bool { authSession != nil }

    func signOut() {
        authSession = nil
    }

    /// Cierra la sesion y limpia todo el progreso local para probar el flujo completo de nuevo.
    func resetForOnboarding() {
        hasCompletedOnboarding = false
        userProfile = UserProfile()
        gameState.apply(GameStateSnapshot(
            currentStreak: 0,
            totalXP: 0,
            level: 1,
            hearts: 3,
            dailyXP: 0,
            dailyGoal: 20,
            completedLessons: [],
            earnedBadges: []
        ))
        persistGameState()
        authSession = nil
    }

    private func loadFromStorage() {
        let defaults = UserDefaults.standard
        hasCompletedOnboarding = defaults.bool(forKey: onboardingKey)

        if let data = defaults.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = decoded
        }

        if let data = defaults.data(forKey: gameKey),
           let decoded = try? JSONDecoder().decode(GameStateSnapshot.self, from: data) {
            gameState.apply(decoded)
        }

        if let data = defaults.data(forKey: authKey),
           let decoded = try? JSONDecoder().decode(AuthSession.self, from: data) {
            authSession = decoded
        }
    }

    private func persistFlags() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey)
    }

    private func persistProfile() {
        guard let data = try? JSONEncoder().encode(userProfile) else { return }
        UserDefaults.standard.set(data, forKey: profileKey)
    }

    private func persistGameState() {
        guard let data = try? JSONEncoder().encode(gameState.snapshot()) else { return }
        UserDefaults.standard.set(data, forKey: gameKey)

        LoopWidgetBridge.write(
            streak: gameState.currentStreak,
            dailyXP: gameState.dailyXP,
            targetXP: gameState.dailyGoal,
            userName: userProfile.name.isEmpty ? "coder" : userProfile.name
        )
    }

    private func persistAuth() {
        if let session = authSession,
           let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: authKey)
        } else {
            UserDefaults.standard.removeObject(forKey: authKey)
        }
    }
}

struct AuthSession: Codable, Equatable {
    var userID: String
    var displayName: String?
    var email: String?
    var provider: Provider

    enum Provider: String, Codable {
        case apple
        case mockApple
    }
}
