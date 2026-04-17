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
        if let token = authSession?.apiToken {
            Task {
                try? await OnboardingAPIClient().logout(token: token)
            }
        }
        hasCompletedOnboarding = false
        userProfile = UserProfile()
        authSession = nil
    }

    func completeSignIn(with session: AuthSession) {
        Task {
            var resolvedProfile: UserProfile?
            var resolvedOnboarding = false

            if let token = session.apiToken {
                do {
                    let me = try await OnboardingAPIClient().fetchMe(token: token)
                    if let profilePayload = me.onboardingProfile {
                        resolvedProfile = profilePayload.toUserProfile()
                        resolvedOnboarding = true
                    }
                } catch {
                    resolvedOnboarding = false
                }
            }

            await MainActor.run {
                if let resolvedProfile {
                    self.userProfile = resolvedProfile
                } else if self.userProfile.name.isEmpty, let name = session.displayName {
                    self.userProfile.name = name
                }

                self.hasCompletedOnboarding = resolvedOnboarding
                self.authSession = session
            }
        }
    }

    func syncOnboardingProfile(profile: UserProfile, wantsPlacementTest: Bool) {
        guard let token = authSession?.apiToken else { return }

        Task {
            try? await OnboardingAPIClient().upsertOnboardingProfile(
                token: token,
                profile: profile,
                wantsPlacementTest: wantsPlacementTest
            )
        }
    }

    /// Cierra la sesion y limpia todo el progreso local para probar el flujo completo de nuevo.
    func resetForOnboarding() {
        hasCompletedOnboarding = false
        JuniorModeManager.shared.isActive = false
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
    var apiToken: String?
    var provider: Provider

    enum Provider: String, Codable {
        case apple
        case password
        case mockApple
    }
}

private struct OnboardingAPIClient {
    private let baseURL = AuthConfig.apiBaseURL

    func upsertOnboardingProfile(token: String, profile: UserProfile, wantsPlacementTest: Bool) async throws {
        let url = baseURL.appendingPathComponent("onboarding/profile")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let payload = OnboardingPayload.from(profile: profile, wantsPlacementTest: wantsPlacementTest)
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func logout(token: String) async throws {
        let url = baseURL.appendingPathComponent("auth/logout")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        _ = try await URLSession.shared.data(for: request)
    }

    func fetchMe(token: String) async throws -> MeResponsePayload {
        let url = baseURL.appendingPathComponent("me")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(MeResponsePayload.self, from: data)
    }
}

private struct OnboardingPayload: Encodable {
    let name: String
    let avatarIndex: Int
    let age: Int
    let ageRange: String
    let goal: String
    let knowledgeLevel: String
    let wantsPlacementTest: Bool
    let minutesPerDay: Int
    let activeDays: [String]
    let plan: PlanPayload?

    static func from(profile: UserProfile, wantsPlacementTest: Bool) -> OnboardingPayload {
        OnboardingPayload(
            name: profile.name.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarIndex: profile.avatarIndex,
            age: profile.age,
            ageRange: profile.ageRange.rawValue,
            goal: profile.goal.rawValue,
            knowledgeLevel: profile.knowledgeLevel.rawValue,
            wantsPlacementTest: wantsPlacementTest,
            minutesPerDay: profile.minutesPerDay,
            activeDays: profile.activeDays.map(\.rawValue).sorted(),
            plan: profile.generatedPlan.map(PlanPayload.from)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case avatarIndex = "avatar_index"
        case age
        case ageRange = "age_range"
        case goal
        case knowledgeLevel = "knowledge_level"
        case wantsPlacementTest = "wants_placement_test"
        case minutesPerDay = "minutes_per_day"
        case activeDays = "active_days"
        case plan
    }
}

private struct PlanPayload: Encodable {
    let language: String
    let startModule: Int
    let weeksEstimated: Int
    let dailyLessons: Int
    let milestoneWeek: Int
    let aiReasons: [String]

    static func from(_ plan: LearningPlan) -> PlanPayload {
        PlanPayload(
            language: plan.language.rawValue,
            startModule: plan.startModule,
            weeksEstimated: plan.weeksEstimated,
            dailyLessons: plan.dailyLessons,
            milestoneWeek: plan.milestoneWeek,
            aiReasons: plan.aiReasons
        )
    }

    private enum CodingKeys: String, CodingKey {
        case language
        case startModule = "start_module"
        case weeksEstimated = "weeks_estimated"
        case dailyLessons = "daily_lessons"
        case milestoneWeek = "milestone_week"
        case aiReasons = "ai_reasons"
    }
}

private struct MeResponsePayload: Decodable {
    let onboardingProfile: StoredOnboardingProfile?

    private enum CodingKeys: String, CodingKey {
        case onboardingProfile = "onboarding_profile"
    }
}

private struct StoredOnboardingProfile: Decodable {
    let name: String?
    let avatarIndex: Int
    let age: Int
    let ageRange: String
    let goal: String
    let knowledgeLevel: String
    let wantsPlacementTest: Bool
    let minutesPerDay: Int
    let activeDays: [String]
    let plan: StoredPlan?

    private enum CodingKeys: String, CodingKey {
        case name
        case avatarIndex = "avatar_index"
        case age
        case ageRange = "age_range"
        case goal
        case knowledgeLevel = "knowledge_level"
        case wantsPlacementTest = "wants_placement_test"
        case minutesPerDay = "minutes_per_day"
        case activeDays = "active_days"
        case plan
    }

    func toUserProfile() -> UserProfile {
        var profile = UserProfile()
        profile.name = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        profile.avatarIndex = avatarIndex
        profile.age = age
        profile.ageRange = AgeRange(rawValue: ageRange) ?? .from(age: age)
        profile.goal = LearningGoal(rawValue: goal) ?? .createApps
        profile.knowledgeLevel = Level(rawValue: knowledgeLevel) ?? .zero
        profile.minutesPerDay = minutesPerDay
        profile.activeDays = Set(activeDays.compactMap { Weekday(rawValue: $0) })
        if profile.activeDays.isEmpty {
            profile.activeDays = [.l, .m, .x, .j, .v]
        }
        profile.generatedPlan = plan?.toLearningPlan() ?? profile.generatedPlan
        return profile
    }
}

private struct StoredPlan: Decodable {
    let language: String
    let startModule: Int
    let weeksEstimated: Int
    let dailyLessons: Int
    let milestoneWeek: Int
    let aiReasons: [String]

    private enum CodingKeys: String, CodingKey {
        case language
        case startModule = "start_module"
        case weeksEstimated = "weeks_estimated"
        case dailyLessons = "daily_lessons"
        case milestoneWeek = "milestone_week"
        case aiReasons = "ai_reasons"
    }

    func toLearningPlan() -> LearningPlan {
        LearningPlan(
            language: ProgrammingLanguage(rawValue: language) ?? .python,
            startModule: startModule,
            weeksEstimated: weeksEstimated,
            dailyLessons: dailyLessons,
            milestoneWeek: milestoneWeek,
            aiReasons: aiReasons
        )
    }
}
