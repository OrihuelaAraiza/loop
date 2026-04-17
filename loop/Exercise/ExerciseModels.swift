import Foundation

struct ExerciseResponse: Identifiable, Hashable {
    let id: UUID
    let type: ExerciseType
    let prompt: String
    let explanation: String
    let xpReward: Int
    let hints: [String]
    let codeTemplate: String?
    let options: [String]?
    let correctAnswer: String
    let correctAnswerDisplay: String?
    let language: String

    init(
        id: UUID = UUID(),
        type: ExerciseType,
        prompt: String,
        explanation: String,
        xpReward: Int,
        hints: [String] = [],
        codeTemplate: String? = nil,
        options: [String]? = nil,
        correctAnswer: String,
        correctAnswerDisplay: String? = nil,
        language: String = "python"
    ) {
        self.id = id
        self.type = type
        self.prompt = prompt
        self.explanation = explanation
        self.xpReward = xpReward
        self.hints = hints
        self.codeTemplate = codeTemplate
        self.options = options
        self.correctAnswer = correctAnswer
        self.correctAnswerDisplay = correctAnswerDisplay
        self.language = language
    }
}

struct AnswerResponse: Hashable {
    let isCorrect: Bool
    let xpEarned: Int
    let correctAnswerDisplay: String?
}
