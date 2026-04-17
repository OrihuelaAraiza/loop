import Combine
import Foundation

@MainActor
final class ExerciseViewModel: ObservableObject {
    private let client: LoopMockClient

    @Published private(set) var exercises: [ExerciseResponse]
    @Published private(set) var currentIndex = 0
    @Published var userAnswer = ""
    @Published private(set) var isSubmitting = false
    @Published private(set) var showResult = false
    @Published private(set) var answerResult: AnswerResponse?
    @Published private(set) var feedbackTitle = ""
    @Published private(set) var hintsRevealed = 0
    @Published private(set) var revealedCorrectAnswer = false

    let lessonID: String?

    init(lesson: LessonPayload? = nil, client: LoopMockClient? = nil) {
        let resolvedClient = client ?? LoopMockClient.shared
        self.client = resolvedClient
        self.lessonID = lesson?.id

        let mapped = lesson.map(Self.buildExercises(from:)) ?? []
        self.exercises = mapped.isEmpty ? resolvedClient.lessonOfTheDay() : mapped
    }

    var currentExercise: ExerciseResponse {
        exercises[currentIndex]
    }

    var moduleProgress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(exercises.count)
    }

    var isLastExercise: Bool {
        currentIndex == exercises.count - 1
    }

    var hasMoreHints: Bool {
        hintsRevealed < currentExercise.hints.count
    }

    var currentHint: String? {
        currentExercise.hints.prefix(hintsRevealed).last
    }

    var revealedHints: [String] {
        Array(currentExercise.hints.prefix(hintsRevealed))
    }

    func revealNextHint() {
        guard hasMoreHints else { return }
        hintsRevealed += 1
    }

    func submitAnswer(isJuniorMode: Bool) async {
        guard !isSubmitting else { return }

        isSubmitting = true
        revealedCorrectAnswer = false

        let result = await client.submit(answer: userAnswer, for: currentExercise)
        answerResult = result
        feedbackTitle = result.isCorrect
            ? LoopCopy.correctMessage(junior: isJuniorMode)
            : LoopCopy.incorrectMessage(junior: isJuniorMode)
        showResult = true
        isSubmitting = false

        if result.isCorrect {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.error()
        }
    }

    func retryCurrentExercise() {
        showResult = false
        answerResult = nil
        revealedCorrectAnswer = false
    }

    func revealCorrectAnswer() {
        revealedCorrectAnswer = true
    }

    @discardableResult
    func advanceToNextExercise() -> Bool {
        guard !isLastExercise else { return false }
        currentIndex += 1
        resetTransientState()
        return true
    }

    private func resetTransientState() {
        userAnswer = ""
        isSubmitting = false
        showResult = false
        answerResult = nil
        feedbackTitle = ""
        hintsRevealed = 0
        revealedCorrectAnswer = false
    }

    // MARK: - Backend bridge

    private static func buildExercises(from lesson: LessonPayload) -> [ExerciseResponse] {
        let sorted = lesson.exercises.sorted { lhs, rhs in
            (lhs.orderIndex ?? lhs.blankPosition ?? 0) < (rhs.orderIndex ?? rhs.blankPosition ?? 0)
        }
        return sorted.compactMap { Self.response(from: $0, fallbackXP: lesson.xpReward) }
    }

    private static func response(from payload: LessonExercisePayload, fallbackXP: Int) -> ExerciseResponse? {
        let type = mapExerciseType(payload.type)
        let correct = correctAnswer(for: payload, type: type)
        guard !correct.isEmpty else { return nil }

        let template = payload.codeTemplate ?? payload.codeSnippet
        let resolvedTemplate = (template?.isEmpty == false) ? template : nil
        let display = payload.correctAnswerDisplay?.isEmpty == false
            ? payload.correctAnswerDisplay!
            : correctAnswerDisplay(for: payload, type: type, correct: correct)

        let optionsForType: [String]? = {
            switch type {
            case .dragAndDrop:
                let source = payload.options.isEmpty ? payload.choices : payload.options
                return source.isEmpty ? nil : source
            case .trivia, .fillInBlank:
                return payload.choices.isEmpty ? nil : payload.choices
            default:
                return nil
            }
        }()

        return ExerciseResponse(
            id: UUID(),
            type: type,
            prompt: payload.question,
            explanation: payload.explanation,
            xpReward: payload.xpReward ?? fallbackXP,
            hints: payload.hints,
            codeTemplate: resolvedTemplate,
            options: optionsForType,
            correctAnswer: correct,
            correctAnswerDisplay: display,
            language: payload.language ?? "python"
        )
    }

    private static func correctAnswer(for payload: LessonExercisePayload, type: ExerciseType) -> String {
        if let explicit = payload.correctAnswer, !explicit.isEmpty {
            return explicit
        }

        switch type {
        case .fillInBlank, .trivia:
            if let index = payload.correctIndex, payload.choices.indices.contains(index) {
                return payload.choices[index]
            }
            return payload.choices.first ?? ""

        case .dragAndDrop:
            let tokens = payload.options.isEmpty ? payload.choices : payload.options
            return tokens.joined(separator: "|")

        case .debug:
            if let index = payload.correctIndex {
                return "line:\(index + 1)"
            }
            return "line:1"

        case .miniProject:
            return payload.codeTemplate ?? payload.codeSnippet ?? ""
        }
    }

    private static func correctAnswerDisplay(for payload: LessonExercisePayload, type: ExerciseType, correct: String) -> String {
        switch type {
        case .dragAndDrop:
            let tokens = payload.options.isEmpty ? payload.choices : payload.options
            return tokens.joined()
        case .debug:
            return correct
        default:
            return correct
        }
    }

    private static func mapExerciseType(_ raw: String) -> ExerciseType {
        switch raw.lowercased() {
        case "fillinblank", "fill_in_blank":
            return .fillInBlank
        case "draganddrop", "drag_and_drop":
            return .dragAndDrop
        case "debug":
            return .debug
        case "trivia", "mcq", "multiple_choice":
            return .trivia
        case "miniproject", "project", "mini_project":
            return .miniProject
        default:
            return .fillInBlank
        }
    }
}
