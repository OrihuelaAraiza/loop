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
        didSet {
            observeGameState()
            persistGameState()
        }
    }

    @Published var authSession: AuthSession? {
        didSet { persistAuth() }
    }

    @Published var currentCourse: CourseStatusPayload?
    @Published var todayLesson: LessonPayload?
    @Published var isGeneratingCourse = false
    @Published var isLoadingTodayLesson = false
    @Published var courseSyncErrorMessage: String?
    @Published var lastLessonCompletion: LessonCompletionSummary?
    @Published private(set) var lessonProgressByID: [String: LessonResumeState] = [:]
    @Published private(set) var customRoutes: [CustomRouteRecord] = []

    private let profileKey = "loop.userProfile"
    private let gameKey = "loop.gameState"
    private let onboardingKey = "loop.hasCompletedOnboarding"
    private let authKey = "loop.authSession"
    private let lessonProgressKey = "loop.lessonProgress"
    private let customRoutesKey = "loop.customRoutes"
    private let legacyPendingCourseRequestKey = "loop.pendingCourseRequest"
    private var gameStateObservation: AnyCancellable?

    init() {
        loadFromStorage()
        observeGameState()
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
        lessonProgressByID = [:]
        persistLessonProgress()
        customRoutes = []
        persistCustomRoutes()
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

    func lessonProgress(for lessonID: String?) -> LessonResumeState? {
        guard let lessonID, !lessonID.isEmpty else { return nil }
        return lessonProgressByID[lessonID]
    }

    func saveTheoryProgress(lessonID: String, stepIndex: Int, totalSteps: Int) {
        guard !lessonID.isEmpty else { return }

        var progress = lessonProgressByID[lessonID] ?? LessonResumeState(lessonID: lessonID)
        progress.stage = .theory
        progress.theoryStepIndex = clamp(stepIndex, upperBound: max(totalSteps - 1, 0))
        progress.totalTheorySteps = max(totalSteps, 0)
        progress.updatedAt = Date()

        lessonProgressByID[lessonID] = progress
        persistLessonProgress()
    }

    func savePracticeProgress(lessonID: String, exerciseIndex: Int, totalExercises: Int) {
        guard !lessonID.isEmpty else { return }

        var progress = lessonProgressByID[lessonID] ?? LessonResumeState(lessonID: lessonID)
        progress.stage = .practice
        progress.exerciseIndex = clamp(exerciseIndex, upperBound: max(totalExercises - 1, 0))
        progress.totalExercises = max(totalExercises, 0)
        progress.updatedAt = Date()

        lessonProgressByID[lessonID] = progress
        persistLessonProgress()
    }

    func clearLessonProgress(lessonID: String) {
        guard !lessonID.isEmpty else { return }
        lessonProgressByID.removeValue(forKey: lessonID)
        persistLessonProgress()
    }

    func recordLessonCompletionLocally(
        lessonID: String,
        lessonTitle: String?,
        xpGained: Int,
        heartsRemaining: Int
    ) {
        lastLessonCompletion = LessonCompletionSummary(
            lessonID: lessonID,
            lessonTitle: lessonTitle,
            xpGained: xpGained,
            heartsRemaining: heartsRemaining,
            completedAt: Date()
        )
        gameState.applyLessonCompletion(
            lessonID: lessonID,
            xpGained: xpGained,
            heartsRemaining: heartsRemaining
        )
        clearLessonProgress(lessonID: lessonID)
    }

    @MainActor
    func createCustomCourse(request: CourseGenerationRequest) async -> Bool {
        guard let token = authSession?.apiToken else {
            courseSyncErrorMessage = "Necesitas iniciar sesion para crear una nueva ruta."
            return false
        }

        let normalizedRequest = request.normalized()
        guard normalizedRequest.isValid else {
            courseSyncErrorMessage = "Describe el curso o el enfoque antes de generarlo."
            return false
        }

        let record = CustomRouteRecord.draft(from: normalizedRequest)
        customRoutes.insert(record, at: 0)
        persistCustomRoutes()
        courseSyncErrorMessage = nil
        todayLesson = nil
        isGeneratingCourse = true

        var updatedProfile = userProfile
        let basePlan = updatedProfile.generatedPlan ?? PlanGenerator.generatePlan(from: updatedProfile)
        updatedProfile.generatedPlan = LearningPlan(
            language: normalizedRequest.language,
            startModule: basePlan.startModule,
            weeksEstimated: basePlan.weeksEstimated,
            dailyLessons: basePlan.dailyLessons,
            milestoneWeek: basePlan.milestoneWeek,
            aiReasons: basePlan.aiReasons
        )
        userProfile = updatedProfile

        do {
            let api = OnboardingAPIClient()
            let generated: GenerateCourseResponsePayload

            do {
                generated = try await api.generateCourse(token: token, request: normalizedRequest)
            } catch {
                generated = try await api.generateCourse(token: token)
            }

            updateCustomRoute(recordID: record.id) { route in
                route.backendCourseID = generated.course.id
                route.status = generated.course.shouldPresentGeneratingState ? .queued : .active
            }

            await ensureCourseAndLessonLoaded()
            reconcileCustomRoutes(with: currentCourse)
            return true
        } catch {
            updateCustomRoute(recordID: record.id) { route in
                route.status = .failed
            }
            courseSyncErrorMessage = "No pudimos crear la nueva ruta. Intentalo de nuevo."
            isGeneratingCourse = false
            return false
        }
    }

    /// Completes a lesson on the backend and refreshes local state.
    /// Used from ExerciseView when the user finishes the full exercise sequence.
    func completeLesson(lessonID: String, lessonTitle: String?) async {
        guard let token = authSession?.apiToken else { return }

        do {
            let response = try await OnboardingAPIClient().completeLesson(token: token, lessonID: lessonID)

            await MainActor.run {
                let wasAlreadyCompletedLocally = self.gameState.completedLessons.contains(lessonID)
                if !wasAlreadyCompletedLocally {
                    self.gameState.applyLessonCompletion(
                        lessonID: lessonID,
                        xpGained: response.xpGained,
                        heartsRemaining: response.heartsRemaining
                    )
                }
                self.lastLessonCompletion = LessonCompletionSummary(
                    lessonID: lessonID,
                    lessonTitle: lessonTitle,
                    xpGained: response.xpGained,
                    heartsRemaining: response.heartsRemaining,
                    completedAt: Date()
                )
                self.clearLessonProgress(lessonID: lessonID)
            }

            await ensureCourseAndLessonLoaded()
        } catch {
            // Silently fail; UI still advances with locally-known XP estimate.
        }
    }

    /// Borra absolutamente todo el estado local (defaults, sesión, widget, memoria).
    /// Usar solo para pruebas de dev.
    func resetForTesting() {
        if let token = authSession?.apiToken {
            Task {
                try? await OnboardingAPIClient().logout(token: token)
            }
        }

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: profileKey)
        defaults.removeObject(forKey: gameKey)
        defaults.removeObject(forKey: onboardingKey)
        defaults.removeObject(forKey: authKey)
        defaults.removeObject(forKey: lessonProgressKey)
        defaults.removeObject(forKey: customRoutesKey)
        defaults.removeObject(forKey: legacyPendingCourseRequestKey)

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
        currentCourse = nil
        todayLesson = nil
        isGeneratingCourse = false
        isLoadingTodayLesson = false
        courseSyncErrorMessage = nil
        lastLessonCompletion = nil
        lessonProgressByID = [:]
        customRoutes = []
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
        lessonProgressByID = [:]
        persistLessonProgress()
        customRoutes = []
        persistCustomRoutes()
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

        if let data = defaults.data(forKey: lessonProgressKey),
           let decoded = try? JSONDecoder().decode([String: LessonResumeState].self, from: data) {
            lessonProgressByID = decoded
        }

        if let data = defaults.data(forKey: customRoutesKey),
           let decoded = try? JSONDecoder().decode([CustomRouteRecord].self, from: data) {
            customRoutes = decoded
        } else if let data = defaults.data(forKey: legacyPendingCourseRequestKey),
                  let decoded = try? JSONDecoder().decode(CourseGenerationRequest.self, from: data) {
            customRoutes = [CustomRouteRecord.draft(from: decoded)]
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

    private func persistLessonProgress() {
        guard let data = try? JSONEncoder().encode(lessonProgressByID) else { return }
        UserDefaults.standard.set(data, forKey: lessonProgressKey)
    }

    private func persistCustomRoutes() {
        let defaults = UserDefaults.standard
        guard !customRoutes.isEmpty else {
            defaults.removeObject(forKey: customRoutesKey)
            defaults.removeObject(forKey: legacyPendingCourseRequestKey)
            return
        }
        guard let data = try? JSONEncoder().encode(customRoutes) else { return }
        defaults.set(data, forKey: customRoutesKey)
        defaults.removeObject(forKey: legacyPendingCourseRequestKey)
    }

    private func persistAuth() {
        if let session = authSession,
           let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: authKey)
        } else {
            UserDefaults.standard.removeObject(forKey: authKey)
        }
    }

    private func observeGameState() {
        gameStateObservation = gameState.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.persistGameState()
            }
        }
    }

    private func clamp(_ value: Int, upperBound: Int) -> Int {
        min(max(value, 0), max(upperBound, 0))
    }

    private func updateCustomRoute(recordID: String, mutate: (inout CustomRouteRecord) -> Void) {
        guard let index = customRoutes.firstIndex(where: { $0.id == recordID }) else { return }
        mutate(&customRoutes[index])
        customRoutes[index].updatedAt = Date()
        customRoutes.sort { $0.updatedAt > $1.updatedAt }
        persistCustomRoutes()
    }

    private func reconcileCustomRoutes(with course: CourseStatusPayload?) {
        guard !customRoutes.isEmpty else { return }

        let activeCourseID = course?.id
        var didChange = false

        for index in customRoutes.indices {
            let nextStatus: CustomRouteStatus

            if let activeCourseID, customRoutes[index].backendCourseID == activeCourseID {
                nextStatus = .active
            } else if customRoutes[index].status == .active || customRoutes[index].status == .requesting {
                nextStatus = .queued
            } else {
                continue
            }

            if customRoutes[index].status != nextStatus {
                customRoutes[index].status = nextStatus
                customRoutes[index].updatedAt = Date()
                didChange = true
            }
        }

        guard didChange else { return }
        customRoutes.sort { $0.updatedAt > $1.updatedAt }
        persistCustomRoutes()
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
                    self.isGeneratingCourse = currentCourse.course?.shouldPresentGeneratingState ?? true
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
                self.reconcileCustomRoutes(with: resolvedCourse)
                self.isLoadingTodayLesson = false
                self.isGeneratingCourse = resolvedCourse?.shouldPresentGeneratingState ?? (today.lesson == nil)
                self.courseSyncErrorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.isLoadingTodayLesson = false
                self.courseSyncErrorMessage = "No se pudo conectar con el servidor. Intentaremos de nuevo."
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

    fileprivate func generateCourse(
        token: String,
        request customRequest: CourseGenerationRequest? = nil
    ) async throws -> GenerateCourseResponsePayload {
        var request = makeRequest(path: "courses/generate", method: "POST", token: token)
        if let customRequest {
            request.httpBody = try JSONEncoder().encode(GenerateCourseRequestPayload.from(customRequest))
        }

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

private struct GenerateCourseRequestPayload: Encodable {
    let language: String
    let framework: String?
    let prompt: String?
    let focus: String?

    static func from(_ request: CourseGenerationRequest) -> GenerateCourseRequestPayload {
        let normalized = request.normalized()
        return GenerateCourseRequestPayload(
            language: normalized.language.rawValue,
            framework: normalized.frameworkName,
            prompt: normalized.trimmedPrompt.isEmpty ? nil : normalized.trimmedPrompt,
            focus: normalized.trimmedFocus.isEmpty ? nil : normalized.trimmedFocus
        )
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
    let lessons: [LessonSummary]
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
        case lessons
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
        lessons = try container.decodeIfPresent([LessonSummary].self, forKey: .lessons) ?? []
        generatedCourseTitle = try container.decodeIfPresent(String.self, forKey: .generatedCourseTitle)
        generatedDescription = try container.decodeIfPresent(String.self, forKey: .generatedDescription)
        generatedObjectives = try container.decodeIfPresent([String].self, forKey: .generatedObjectives) ?? []
        generatedModulesCount = try container.decodeIfPresent(Int.self, forKey: .generatedModulesCount)
    }

    // MARK: - Derived UI helpers

    var resolvedTitle: String {
        if let generated = generatedCourseTitle,
           !generated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           generated.lowercased() != "generando curso..." {
            return generated
        }
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }
        return "Curso personalizado"
    }

    var resolvedSummary: String {
        if let description = generatedDescription,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }
        if !generatedObjectives.isEmpty {
            return generatedObjectives.prefix(2).joined(separator: " · ")
        }
        switch status {
        case "draft", "generating":
            return "Generando tu curso personalizado..."
        case "ready_first_lesson":
            return "Tu primera lección está lista. Sigue avanzando."
        case "ready_full":
            return "Ruta completa. Avanza módulo por módulo."
        case "failed":
            return "Hubo un problema generando el curso. Toca para reintentar."
        default:
            return "Tu ruta personalizada de aprendizaje."
        }
    }

    var resolvedReadyLessons: Int {
        if !lessons.isEmpty {
            return lessons.filter { $0.status == "ready" }.count
        }
        return lessonStatusCounts["ready"] ?? 0
    }

    var resolvedAvailableLessons: Int {
        if !lessons.isEmpty {
            let availableStatuses = Set(["ready", "available", "active", "in_progress", "completed", "done"])
            return min(lessons.filter { availableStatuses.contains($0.status.lowercased()) }.count, max(totalLessons, 0))
        }

        let availableStatuses = ["ready", "available", "active", "in_progress", "completed", "done"]
        let total = availableStatuses.reduce(0) { partialResult, status in
            partialResult + (lessonStatusCounts[status] ?? 0)
        }
        return min(total, max(totalLessons, 0))
    }

    var shouldPresentGeneratingState: Bool {
        let normalizedStatus = status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalizedStatus {
        case "ready_first_lesson", "ready_full":
            return false
        case "draft", "generating", "queued", "pending":
            return true
        case "failed":
            return false
        default:
            return resolvedAvailableLessons == 0
        }
    }
}

struct LessonSummary: Decodable, Identifiable, Equatable {
    let id: String
    let title: String
    let orderIndex: Int
    let status: String
    let estimatedMinutes: Int?
    let xpReward: Int?
    let difficulty: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case orderIndex = "order_index"
        case status
        case estimatedMinutes = "estimated_minutes"
        case xpReward = "xp_reward"
        case difficulty
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

struct LessonCompletionSummary: Equatable {
    let lessonID: String
    let lessonTitle: String?
    let xpGained: Int
    let heartsRemaining: Int
    let completedAt: Date
}
