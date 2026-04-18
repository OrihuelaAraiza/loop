import Foundation

enum CourseFramework: String, Codable, CaseIterable, Identifiable {
    case none = "Sin framework"
    case swiftUI = "SwiftUI"
    case uiKit = "UIKit"
    case vapor = "Vapor"
    case react = "React"
    case nextJS = "Next.js"
    case vue = "Vue"
    case angular = "Angular"
    case nestJS = "NestJS"
    case express = "Express"
    case node = "Node.js"
    case django = "Django"
    case flask = "Flask"
    case fastAPI = "FastAPI"
    case android = "Android"
    case jetpackCompose = "Jetpack Compose"
    case ktor = "Ktor"
    case spring = "Spring"
    case actix = "Actix"
    case tokio = "Tokio"
    case gin = "Gin"
    case echo = "Echo"
    case fiber = "Fiber"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .none:
            return "square.stack.3d.up"
        case .swiftUI, .uiKit, .vapor:
            return "iphone"
        case .react, .nextJS, .vue, .angular, .nestJS:
            return "sparkles.rectangle.stack"
        case .express, .node:
            return "server.rack"
        case .django, .flask, .fastAPI:
            return "bolt.horizontal.circle"
        case .android, .jetpackCompose, .ktor, .spring:
            return "app.connected.to.app.below.fill"
        case .actix, .tokio:
            return "gearshape.2.fill"
        case .gin, .echo, .fiber:
            return "shippingbox.fill"
        }
    }

    var supportedLanguages: Set<ProgrammingLanguage> {
        switch self {
        case .none:
            return Set(ProgrammingLanguage.allCases)
        case .swiftUI, .uiKit, .vapor:
            return [.swift]
        case .react:
            return [.javascript, .typescript]
        case .vue, .express, .node, .nextJS:
            return [.javascript]
        case .angular, .nestJS:
            return [.typescript]
        case .django, .flask, .fastAPI:
            return [.python]
        case .android, .jetpackCompose, .ktor, .spring:
            return [.kotlin]
        case .actix, .tokio:
            return [.rust]
        case .gin, .echo, .fiber:
            return [.go]
        }
    }

    static func options(for language: ProgrammingLanguage) -> [CourseFramework] {
        allCases.filter { $0.supportedLanguages.contains(language) }
    }
}

enum CourseSkillLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Desde cero"
    case intermediate = "Intermedio"
    case advanced = "Avanzado"

    var id: String { rawValue }

    var stars: Int {
        switch self {
        case .beginner:
            return 1
        case .intermediate:
            return 2
        case .advanced:
            return 3
        }
    }
}

struct CourseGenerationRequest: Codable, Equatable {
    var language: ProgrammingLanguage
    var framework: CourseFramework
    var prompt: String
    var focus: String
    var level: CourseSkillLevel?
    var createdAt: Date

    init(
        language: ProgrammingLanguage,
        framework: CourseFramework = .none,
        prompt: String = "",
        focus: String = "",
        level: CourseSkillLevel? = nil,
        createdAt: Date = Date()
    ) {
        self.language = language
        self.framework = framework
        self.prompt = prompt
        self.focus = focus
        self.level = level
        self.createdAt = createdAt
    }

    var trimmedPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedFocus: String {
        focus.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedPrompt.isEmpty || !trimmedFocus.isEmpty
    }

    var frameworkName: String? {
        framework == .none ? nil : framework.rawValue
    }

    var summaryLine: String {
        if let frameworkName {
            return "\(language.rawValue) · \(frameworkName)"
        }
        return language.rawValue
    }

    func normalized() -> CourseGenerationRequest {
        CourseGenerationRequest(
            language: language,
            framework: CourseFramework.options(for: language).contains(framework) ? framework : .none,
            prompt: trimmedPrompt,
            focus: trimmedFocus,
            level: level,
            createdAt: createdAt
        )
    }

    static func suggested(from profile: UserProfile) -> CourseGenerationRequest {
        let preferredLanguage = profile.generatedPlan?.language ?? .python
        return CourseGenerationRequest(language: preferredLanguage)
    }
}

struct RouteLessonSnapshot: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let orderIndex: Int
    let status: String
    let estimatedMinutes: Int?
    let xpReward: Int?
    let difficulty: String?
}

struct RouteCourseSnapshot: Codable, Equatable {
    let id: String
    let status: String
    let title: String
    let language: String
    let totalLessons: Int
    let lessonStatusCounts: [String: Int]
    let lessons: [RouteLessonSnapshot]
    let generatedCourseTitle: String?
    let generatedDescription: String?
    let generatedObjectives: [String]
    let generatedModulesCount: Int?

    var resolvedTitle: String {
        if let generatedCourseTitle,
           !generatedCourseTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           generatedCourseTitle.lowercased() != "generando curso..." {
            return generatedCourseTitle
        }
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }
        return "Curso personalizado"
    }

    var resolvedSummary: String {
        if let generatedDescription,
           !generatedDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return generatedDescription
        }
        if !generatedObjectives.isEmpty {
            return generatedObjectives.prefix(2).joined(separator: " · ")
        }

        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "draft", "generating":
            return "Generando tu curso personalizado..."
        case "ready_first_lesson":
            return "Tu primera lección está lista. Sigue avanzando."
        case "ready_full":
            return "Ruta completa. Avanza módulo por módulo."
        case "failed":
            return "Hubo un problema generando el curso."
        default:
            return "Tu ruta personalizada de aprendizaje."
        }
    }

    var resolvedAvailableLessons: Int {
        if !lessons.isEmpty {
            let availableStatuses = Set(["ready", "available", "active", "in_progress", "completed", "done"])
            return min(lessons.filter { availableStatuses.contains($0.status.lowercased()) }.count, max(totalLessons, 0))
        }

        let availableStatuses = Set(["ready", "available", "active", "in_progress", "completed", "done"])
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

enum CustomRouteStatus: String, Codable, Equatable {
    case generating
    case queued
    case active
    case failed

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "requesting":
            self = .generating
        default:
            self = CustomRouteStatus(rawValue: rawValue) ?? .generating
        }
    }
}

struct CustomRouteRecord: Codable, Equatable, Identifiable {
    let id: String
    var request: CourseGenerationRequest
    var backendCourseID: String?
    var courseSnapshot: RouteCourseSnapshot?
    var status: CustomRouteStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        request: CourseGenerationRequest,
        backendCourseID: String? = nil,
        courseSnapshot: RouteCourseSnapshot? = nil,
        status: CustomRouteStatus,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.request = request
        self.backendCourseID = backendCourseID
        self.courseSnapshot = courseSnapshot
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var title: String {
        if let snapshot = courseSnapshot {
            return snapshot.resolvedTitle
        }
        if !request.trimmedPrompt.isEmpty {
            return request.trimmedPrompt
        }
        return "Ruta \(request.summaryLine)"
    }

    var subtitle: String {
        if let snapshot = courseSnapshot {
            return snapshot.resolvedSummary
        }
        if !request.trimmedFocus.isEmpty {
            return request.trimmedFocus
        }
        return request.summaryLine
    }

    static func draft(from request: CourseGenerationRequest) -> CustomRouteRecord {
        CustomRouteRecord(
            request: request.normalized(),
            status: .generating
        )
    }
}
