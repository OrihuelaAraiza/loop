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

    init(client: LoopMockClient = .shared) {
        self.client = client
        exercises = client.lessonOfTheDay()
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
}
