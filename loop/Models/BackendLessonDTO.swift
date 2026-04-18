import Foundation

struct BackendLessonDTO: Decodable, Identifiable {
    let id: String
    let title: String
    let topic: String?
    let difficulty: String?
    let progressType: String?
    let orderIndex: Int
    let estimatedMinutes: Int
    let xpReward: Int
    let blocks: [BackendLessonBlockDTO]
    let exercises: [BackendLessonExerciseDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case topic
        case difficulty
        case progressType = "progress_type"
        case orderIndex = "order_index"
        case estimatedMinutes = "estimated_minutes"
        case xpReward = "xp_reward"
        case blocks
        case exercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeString(forKey: .id, default: UUID().uuidString)
        title = container.decodeString(forKey: .title, default: "Leccion")
        topic = container.decodeOptionalTrimmedString(forKey: .topic)
        difficulty = container.decodeOptionalTrimmedString(forKey: .difficulty)
        progressType = container.decodeOptionalTrimmedString(forKey: .progressType)
        orderIndex = container.decodeInt(forKey: .orderIndex, default: 0)
        estimatedMinutes = max(container.decodeInt(forKey: .estimatedMinutes, default: 5), 1)
        xpReward = max(container.decodeInt(forKey: .xpReward, default: 0), 0)
        blocks = container.decodeArray([BackendLessonBlockDTO].self, forKey: .blocks)
        exercises = container.decodeArray([BackendLessonExerciseDTO].self, forKey: .exercises)
    }
}

struct BackendLessonBlockDTO: Decodable, Identifiable {
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
        id = container.decodeString(forKey: .id, default: UUID().uuidString)
        type = container.decodeString(forKey: .type, default: "theory")
        title = container.decodeOptionalTrimmedString(forKey: .title)
        orderIndex = container.decodeInt(forKey: .orderIndex, default: 0)

        if let contentString = try? container.decode(String.self, forKey: .content) {
            text = contentString.trimmingCharacters(in: .whitespacesAndNewlines)
            examples = []
            keyPoints = []
            codeSnippet = nil
            language = nil
            return
        }

        if let rawContent = try? container.decode(BackendLessonBlockContentDTO.self, forKey: .content) {
            text = rawContent.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            examples = rawContent.examples ?? []
            keyPoints = rawContent.keyPoints ?? []
            codeSnippet = rawContent.codeSnippet?.trimmingCharacters(in: .whitespacesAndNewlines)
            language = rawContent.language?.trimmingCharacters(in: .whitespacesAndNewlines)
            return
        }

        text = ""
        examples = []
        keyPoints = []
        codeSnippet = nil
        language = nil
    }
}

private struct BackendLessonBlockContentDTO: Decodable {
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
        text = container.decodeOptionalTrimmedString(forKey: .text)
        examples = container.decodeFlexibleStringArray(forKey: .examples)
        keyPoints = container.decodeFlexibleStringArray(forKey: .keyPoints)
        codeSnippet = container.decodeOptionalTrimmedString(forKey: .codeSnippet)
        language = container.decodeOptionalTrimmedString(forKey: .language)
    }
}

struct BackendLessonExerciseDTO: Decodable {
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
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeString(forKey: .id, default: UUID().uuidString)
        type = container.decodeString(forKey: .type, default: "trivia")
        question = container.decodeString(forKey: .question, default: "")
        codeSnippet = container.decodeOptionalTrimmedString(forKey: .codeSnippet)
        codeTemplate = container.decodeOptionalTrimmedString(forKey: .codeTemplate)
        blankPosition = try? container.decodeIfPresent(Int.self, forKey: .blankPosition)
        choices = container.decodeFlexibleStringArray(forKey: .choices) ?? []
        options = container.decodeFlexibleStringArray(forKey: .options) ?? []
        correctIndex = try? container.decodeIfPresent(Int.self, forKey: .correctIndex)
        correctAnswer = container.decodeOptionalTrimmedString(forKey: .correctAnswer)
        correctAnswerDisplay = container.decodeOptionalTrimmedString(forKey: .correctAnswerDisplay)
        hints = container.decodeFlexibleStringArray(forKey: .hints) ?? []
        explanation = container.decodeString(forKey: .explanation, default: "")
        difficulty = container.decodeOptionalTrimmedString(forKey: .difficulty)
        language = container.decodeOptionalTrimmedString(forKey: .language)
        xpReward = try? container.decodeIfPresent(Int.self, forKey: .xpReward)
        orderIndex = try? container.decodeIfPresent(Int.self, forKey: .orderIndex)
    }
}

typealias LessonPayload = BackendLessonDTO
typealias LessonBlockPayload = BackendLessonBlockDTO
typealias LessonExercisePayload = BackendLessonExerciseDTO

extension BackendLessonDTO {
    var sortedTheoryBlocks: [BackendLessonBlockDTO] {
        blocks
            .filter(\.isTheoryLike)
            .sorted { lhs, rhs in
                if lhs.orderIndex == rhs.orderIndex {
                    return lhs.id < rhs.id
                }
                return lhs.orderIndex < rhs.orderIndex
            }
    }
}

extension BackendLessonBlockDTO {
    var isTheoryLike: Bool {
        let normalized = type.lowercased()
        if ["exercise", "practice", "quiz"].contains(normalized) {
            return false
        }

        if ["theory", "intro", "example", "concept", "summary", "explanation", "note"].contains(normalized) {
            return true
        }

        return hasRenderableContent
    }

    var hasRenderableContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !examples.isEmpty ||
            !keyPoints.isEmpty ||
            !(codeSnippet?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}

private extension KeyedDecodingContainer {
    func decodeString(forKey key: K, default defaultValue: String) -> String {
        let raw = (try? decodeIfPresent(String.self, forKey: key)) ?? defaultValue
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    func decodeOptionalTrimmedString(forKey key: K) -> String? {
        guard let raw = try? decodeIfPresent(String.self, forKey: key) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func decodeInt(forKey key: K, default defaultValue: Int) -> Int {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let stringValue = try? decodeIfPresent(String.self, forKey: key), let value = Int(stringValue) {
            return value
        }
        return defaultValue
    }

    func decodeArray<Element: Decodable>(_ type: [Element].Type, forKey key: K) -> [Element] {
        (try? decodeIfPresent(type, forKey: key)) ?? []
    }

    func decodeFlexibleStringArray(forKey key: K) -> [String]? {
        if let values = try? decodeIfPresent([String].self, forKey: key) {
            return values
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        if let single = try? decodeIfPresent(String.self, forKey: key) {
            let trimmed = single.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]
        }

        return nil
    }
}
