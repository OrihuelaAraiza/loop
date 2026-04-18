import Foundation

enum CourseFramework: String, Codable, CaseIterable, Identifiable {
    case none = "Sin framework"
    case swiftUI = "SwiftUI"
    case uiKit = "UIKit"
    case react = "React"
    case nextJS = "Next.js"
    case vue = "Vue"
    case express = "Express"
    case node = "Node.js"
    case django = "Django"
    case flask = "Flask"
    case fastAPI = "FastAPI"
    case jetpackCompose = "Jetpack Compose"
    case ktor = "Ktor"
    case gin = "Gin"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .none:
            return "square.stack.3d.up"
        case .swiftUI, .uiKit:
            return "iphone"
        case .react, .nextJS, .vue:
            return "sparkles.rectangle.stack"
        case .express, .node:
            return "server.rack"
        case .django, .flask, .fastAPI:
            return "bolt.horizontal.circle"
        case .jetpackCompose, .ktor:
            return "app.connected.to.app.below.fill"
        case .gin:
            return "shippingbox.fill"
        }
    }

    var supportedLanguages: Set<ProgrammingLanguage> {
        switch self {
        case .none:
            return Set(ProgrammingLanguage.allCases)
        case .swiftUI, .uiKit:
            return [.swift]
        case .react, .nextJS, .vue, .express, .node:
            return [.javascript, .typescript]
        case .django, .flask, .fastAPI:
            return [.python]
        case .jetpackCompose, .ktor:
            return [.kotlin]
        case .gin:
            return [.go]
        }
    }

    static func options(for language: ProgrammingLanguage) -> [CourseFramework] {
        allCases.filter { $0.supportedLanguages.contains(language) }
    }
}

struct CourseGenerationRequest: Codable, Equatable {
    var language: ProgrammingLanguage
    var framework: CourseFramework
    var prompt: String
    var focus: String
    var createdAt: Date

    init(
        language: ProgrammingLanguage,
        framework: CourseFramework = .none,
        prompt: String = "",
        focus: String = "",
        createdAt: Date = Date()
    ) {
        self.language = language
        self.framework = framework
        self.prompt = prompt
        self.focus = focus
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
            createdAt: createdAt
        )
    }

    static func suggested(from profile: UserProfile) -> CourseGenerationRequest {
        let preferredLanguage = profile.generatedPlan?.language ?? .python
        return CourseGenerationRequest(language: preferredLanguage)
    }
}

enum CustomRouteStatus: String, Codable, Equatable {
    case requesting
    case queued
    case active
    case failed
}

struct CustomRouteRecord: Codable, Equatable, Identifiable {
    let id: String
    var request: CourseGenerationRequest
    var backendCourseID: String?
    var status: CustomRouteStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        request: CourseGenerationRequest,
        backendCourseID: String? = nil,
        status: CustomRouteStatus,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.request = request
        self.backendCourseID = backendCourseID
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var title: String {
        if !request.trimmedPrompt.isEmpty {
            return request.trimmedPrompt
        }
        return "Ruta \(request.summaryLine)"
    }

    var subtitle: String {
        if !request.trimmedFocus.isEmpty {
            return request.trimmedFocus
        }
        return request.summaryLine
    }

    static func draft(from request: CourseGenerationRequest) -> CustomRouteRecord {
        CustomRouteRecord(
            request: request.normalized(),
            status: .requesting
        )
    }
}
