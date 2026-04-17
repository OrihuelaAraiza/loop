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

    @Published var currentCourse: CourseStatusPayload?
    @Published var todayLesson: LessonPayload?
    @Published var isGeneratingCourse = false
    @Published var isLoadingTodayLesson = false

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

            if resolvedOnboarding, session.apiToken != nil {
                await ensureCourseAndLessonLoaded()
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
            await ensureCourseAndLessonLoaded()
        }
    }

    @MainActor
    func refreshTodayLesson() {
        Task {
            await ensureCourseAndLessonLoaded()
        }
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
    }

    private func persistAuth() {
        if let session = authSession,
           let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: authKey)
        } else {
            UserDefaults.standard.removeObject(forKey: authKey)
        }
    }

    private func ensureCourseAndLessonLoaded() async {
        guard let token = authSession?.apiToken else { return }

        let shouldStartLoad = await MainActor.run { () -> Bool in
            guard !self.isLoadingTodayLesson else { return false }
            self.isLoadingTodayLesson = true
            return true
        }
        guard shouldStartLoad else { return }

        do {
            let api = OnboardingAPIClient()
            let currentCourse = try await api.fetchCurrentCourse(token: token)
            var resolvedCourse = currentCourse.course

            if currentCourse.course == nil {
                await MainActor.run {
                    self.isGeneratingCourse = true
                }
                let generated = try await api.generateCourse(token: token)
                resolvedCourse = generated.course
            } else {
                await MainActor.run {
                    self.currentCourse = currentCourse.course
                    self.isGeneratingCourse =
                        !(currentCourse.course?.status == "ready_first_lesson" || currentCourse.course?.status == "ready_full")
                }

                let failedCount = currentCourse.course?.lessonStatusCounts["failed"] ?? 0
                let courseFailed = currentCourse.course?.status == "failed"

                if failedCount > 0 || courseFailed {
                    let retried = try await api.generateCourse(token: token)
                    resolvedCourse = retried.course
                }
            }

            let today = try await api.fetchTodayLesson(token: token)

            await MainActor.run {
                self.todayLesson = today.lesson
                if let course = resolvedCourse {
                    self.currentCourse = course
                }
                self.isLoadingTodayLesson = false
                self.isGeneratingCourse = today.lesson == nil
            }
        } catch {
            await MainActor.run {
                self.isLoadingTodayLesson = false
            }
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

struct OnboardingAPIClient {
    private let baseURL = AuthConfig.apiBaseURL

    private func makeRequest(path: String, method: String, token: String? = nil) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue("LoopiOS/1.0", forHTTPHeaderField: "User-Agent")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    fileprivate func upsertOnboardingProfile(token: String, profile: UserProfile, wantsPlacementTest: Bool) async throws {
        var request = makeRequest(path: "onboarding/profile", method: "PUT", token: token)
        let payload = OnboardingPayload.from(profile: profile, wantsPlacementTest: wantsPlacementTest)
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    fileprivate func logout(token: String) async throws {
        let request = makeRequest(path: "auth/logout", method: "DELETE", token: token)
        _ = try await URLSession.shared.data(for: request)
    }

    fileprivate func fetchMe(token: String) async throws -> MeResponsePayload {
        let request = makeRequest(path: "me", method: "GET", token: token)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(MeResponsePayload.self, from: data)
    }

    fileprivate func fetchCurrentCourse(token: String) async throws -> CurrentCourseResponsePayload {
        let request = makeRequest(path: "courses/current", method: "GET", token: token)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(CurrentCourseResponsePayload.self, from: data)
    }

    fileprivate func generateCourse(token: String) async throws -> GenerateCourseResponsePayload {
        let request = makeRequest(path: "courses/generate", method: "POST", token: token)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(GenerateCourseResponsePayload.self, from: data)
    }

    fileprivate func fetchTodayLesson(token: String) async throws -> TodayLessonResponsePayload {
        let request = makeRequest(path: "lessons/today", method: "GET", token: token)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(TodayLessonResponsePayload.self, from: data)
    }

    func completeLesson(token: String, lessonID: String) async throws -> CompleteLessonResponsePayload {
        let request = makeRequest(path: "lessons/\(lessonID)/complete", method: "POST", token: token)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(CompleteLessonResponsePayload.self, from: data)
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

struct CourseStatusPayload: Decodable {
    let id: String
    let status: String
    let title: String
    let language: String
    let totalLessons: Int
    let lessonStatusCounts: [String: Int]
    let generatedCourseTitle: String?
    let generatedDescription: String?
    let generatedObjectives: [String]
    let generatedModulesCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case status
        case title
        case language
        case totalLessons = "total_lessons"
        case lessonStatusCounts = "lesson_status_counts"
        case generatedCourseTitle = "generated_course_title"
        case generatedDescription = "generated_description"
        case generatedObjectives = "generated_objectives"
        case generatedModulesCount = "generated_modules_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        status = try container.decode(String.self, forKey: .status)
        title = try container.decode(String.self, forKey: .title)
        language = try container.decode(String.self, forKey: .language)
        totalLessons = try container.decode(Int.self, forKey: .totalLessons)
        lessonStatusCounts = try container.decodeIfPresent([String: Int].self, forKey: .lessonStatusCounts) ?? [:]
        generatedCourseTitle = try container.decodeIfPresent(String.self, forKey: .generatedCourseTitle)
        generatedDescription = try container.decodeIfPresent(String.self, forKey: .generatedDescription)
        generatedObjectives = try container.decodeIfPresent([String].self, forKey: .generatedObjectives) ?? []
        generatedModulesCount = try container.decodeIfPresent(Int.self, forKey: .generatedModulesCount)
    }
}

struct LessonPayload: Decodable, Identifiable {
    let id: String
    let title: String
    let orderIndex: Int
    let estimatedMinutes: Int
    let xpReward: Int
    let blocks: [LessonBlockPayload]
    let exercises: [LessonExercisePayload]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case orderIndex = "order_index"
        case estimatedMinutes = "estimated_minutes"
        case xpReward = "xp_reward"
        case blocks
        case exercises
    }
}

struct LessonBlockPayload: Decodable, Identifiable {
    let id: String
    let type: String
    let title: String?
    let text: String
    let examples: [String]
    let keyPoints: [String]
    let codeSnippet: String?
    let language: String?
    let orderIndex: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case content
        case orderIndex = "order_index"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        orderIndex = try container.decode(Int.self, forKey: .orderIndex)

        if let contentString = try? container.decode(String.self, forKey: .content) {
            text = contentString
            examples = []
            keyPoints = []
            codeSnippet = nil
            language = nil
        } else if let rawContent = try? container.decode(LessonBlockContent.self, forKey: .content) {
            text = rawContent.text ?? ""
            examples = rawContent.examples ?? []
            keyPoints = rawContent.keyPoints ?? []
            codeSnippet = rawContent.codeSnippet
            language = rawContent.language
        } else {
            text = ""
            examples = []
            keyPoints = []
            codeSnippet = nil
            language = nil
        }
    }
}

private struct LessonBlockContent: Decodable {
    let text: String?
    let examples: [String]?
    let keyPoints: [String]?
    let codeSnippet: String?
    let language: String?

    private enum CodingKeys: String, CodingKey {
        case text
        case examples
        case keyPoints = "key_points"
        case codeSnippet = "code_snippet"
        case language
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        examples = Self.decodeStringArray(container: container, forKey: .examples)
        keyPoints = Self.decodeStringArray(container: container, forKey: .keyPoints)
        codeSnippet = try container.decodeIfPresent(String.self, forKey: .codeSnippet)
        language = try container.decodeIfPresent(String.self, forKey: .language)
    }

    private static func decodeStringArray(container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> [String]? {
        if let values = try? container.decodeIfPresent([String].self, forKey: key) {
            return values
        }
        return nil
    }
}

struct LessonExercisePayload: Decodable {
    let id: String
    let type: String
    let question: String
    let codeSnippet: String?
    let codeTemplate: String?
    let blankPosition: Int?
    let choices: [String]
    let options: [String]
    let correctIndex: Int?
    let correctAnswer: String?
    let correctAnswerDisplay: String?
    let hints: [String]
    let explanation: String
    let difficulty: String?
    let language: String?
    let xpReward: Int?
    let orderIndex: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case question
        case codeSnippet = "code_snippet"
        case codeTemplate = "code_template"
        case blankPosition = "blank_position"
        case choices
        case options
        case correctIndex = "correct_index"
        case correctAnswer = "correct_answer"
        case correctAnswerDisplay = "correct_answer_display"
        case hints
        case explanation
        case difficulty
        case language
        case xpReward = "xp_reward"
        case orderIndex = "order_index"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(String.self, forKey: .type)
        question = try c.decode(String.self, forKey: .question)
        codeSnippet = try c.decodeIfPresent(String.self, forKey: .codeSnippet)
        codeTemplate = try c.decodeIfPresent(String.self, forKey: .codeTemplate)
        blankPosition = try c.decodeIfPresent(Int.self, forKey: .blankPosition)
        choices = (try? c.decode([String].self, forKey: .choices)) ?? []
        options = (try? c.decode([String].self, forKey: .options)) ?? []
        correctIndex = try c.decodeIfPresent(Int.self, forKey: .correctIndex)
        correctAnswer = try c.decodeIfPresent(String.self, forKey: .correctAnswer)
        correctAnswerDisplay = try c.decodeIfPresent(String.self, forKey: .correctAnswerDisplay)
        hints = (try? c.decode([String].self, forKey: .hints)) ?? []
        explanation = try c.decode(String.self, forKey: .explanation)
        difficulty = try c.decodeIfPresent(String.self, forKey: .difficulty)
        language = try c.decodeIfPresent(String.self, forKey: .language)
        xpReward = try c.decodeIfPresent(Int.self, forKey: .xpReward)
        orderIndex = try c.decodeIfPresent(Int.self, forKey: .orderIndex)
    }
}

private struct CurrentCourseResponsePayload: Decodable {
    let course: CourseStatusPayload?
}

private struct GenerateCourseResponsePayload: Decodable {
    let ok: Bool
    let course: CourseStatusPayload
}

private struct TodayLessonResponsePayload: Decodable {
    let status: String
    let lesson: LessonPayload?
}

struct CompleteLessonResponsePayload: Decodable {
    let ok: Bool
    let xpGained: Int
    let heartsRemaining: Int

    private enum CodingKeys: String, CodingKey {
        case ok
        case xpGained = "xp_gained"
        case heartsRemaining = "hearts_remaining"
    }
}
