import Combine
import Foundation

struct LessonInteractionEvaluation: Hashable {
    let isCorrect: Bool
    let title: String
    let message: String
}

struct LessonStepRenderState: Hashable {
    let isVisited: Bool
    let isRevealed: Bool
    let isCompleted: Bool
    let selectedChoiceIDs: Set<String>
    let evaluation: LessonInteractionEvaluation?
}

@MainActor
final class LessonTheoryViewModel: ObservableObject {
    @Published private(set) var lesson: LessonUIModel
    @Published var currentStepIndex: Int = 0
    @Published private var visitedStepIDs: Set<String> = []
    @Published private var revealedStepIDs: Set<String> = []
    @Published private var selectedChoiceIDsByStep: [String: Set<String>] = [:]
    @Published private var confirmedStepIDs: Set<String> = []
    @Published private var evaluationsByStepID: [String: LessonInteractionEvaluation] = [:]

    init(
        backendLesson: BackendLessonDTO,
        courseLanguage: String,
        initialStepIndex: Int? = nil,
        difficultyHint: String? = nil
    ) {
        lesson = LessonTheoryMapper(
            courseLanguage: courseLanguage,
            difficultyHint: difficultyHint
        ).map(backendLesson)
        if let initialStepIndex {
            currentStepIndex = min(max(initialStepIndex, 0), max(lesson.steps.count - 1, 0))
        }
        markVisitedCurrentStep()
    }

    var steps: [LessonStepUIModel] { lesson.steps }

    var currentStep: LessonStepUIModel? {
        guard steps.indices.contains(currentStepIndex) else { return nil }
        return steps[currentStepIndex]
    }

    var totalSteps: Int { max(steps.count, 1) }

    var isLastStep: Bool {
        currentStepIndex >= steps.count - 1
    }

    var progressFraction: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(currentStepIndex + 1) / Double(steps.count)
    }

    func handlePageChange(to index: Int) {
        guard steps.indices.contains(index) else { return }
        currentStepIndex = index
        markVisitedCurrentStep()
    }

    func goToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        markVisitedCurrentStep()
    }

    func goToNextStep() {
        guard currentStepIndex < steps.count - 1 else { return }
        currentStepIndex += 1
        markVisitedCurrentStep()
    }

    func jump(to stepIndex: Int) {
        guard steps.indices.contains(stepIndex) else { return }
        currentStepIndex = stepIndex
        markVisitedCurrentStep()
    }

    func renderState(for step: LessonStepUIModel) -> LessonStepRenderState {
        let selectedChoices = selectedChoiceIDsByStep[step.stepId] ?? []
        let evaluation = evaluationsByStepID[step.stepId]

        let completed: Bool
        if let interaction = step.interaction {
            switch interaction.kind {
            case .checklist:
                completed = !interaction.correctChoiceIDs.isEmpty &&
                    selectedChoices.isSuperset(of: interaction.correctChoiceIDs)
            case .tapToReveal:
                completed = revealedStepIDs.contains(step.stepId)
            case .quickConfirm:
                completed = confirmedStepIDs.contains(step.stepId)
            case .multipleChoice, .trueFalse, .codePrediction:
                completed = evaluation?.isCorrect == true
            case .dragMatch:
                completed = confirmedStepIDs.contains(step.stepId)
            }
        } else {
            completed = visitedStepIDs.contains(step.stepId)
        }

        return LessonStepRenderState(
            isVisited: visitedStepIDs.contains(step.stepId),
            isRevealed: revealedStepIDs.contains(step.stepId),
            isCompleted: completed,
            selectedChoiceIDs: selectedChoices,
            evaluation: evaluation
        )
    }

    func triggerPrimaryInteraction(for step: LessonStepUIModel) {
        guard let interaction = step.interaction else { return }

        switch interaction.kind {
        case .tapToReveal:
            revealedStepIDs.insert(step.stepId)
            evaluationsByStepID[step.stepId] = LessonInteractionEvaluation(
                isCorrect: true,
                title: "Revelado",
                message: interaction.revealText ?? "Contenido desbloqueado."
            )
        case .quickConfirm:
            confirmedStepIDs.insert(step.stepId)
            if let feedback = interaction.feedback {
                evaluationsByStepID[step.stepId] = LessonInteractionEvaluation(
                    isCorrect: true,
                    title: feedback.successTitle,
                    message: feedback.successMessage
                )
            }
        case .dragMatch:
            confirmedStepIDs.insert(step.stepId)
            evaluationsByStepID[step.stepId] = LessonInteractionEvaluation(
                isCorrect: true,
                title: "Base lista",
                message: "La estructura ya soporta drag & match cuando llegue la logica real."
            )
        case .checklist, .multipleChoice, .trueFalse, .codePrediction:
            break
        }
    }

    func selectChoice(_ choiceID: String, for step: LessonStepUIModel) {
        guard let interaction = step.interaction else { return }

        switch interaction.kind {
        case .checklist:
            var selected = selectedChoiceIDsByStep[step.stepId] ?? []
            if selected.contains(choiceID) {
                selected.remove(choiceID)
            } else {
                selected.insert(choiceID)
            }
            selectedChoiceIDsByStep[step.stepId] = selected

            if !interaction.correctChoiceIDs.isEmpty && selected.isSuperset(of: interaction.correctChoiceIDs) {
                if let feedback = interaction.feedback {
                    evaluationsByStepID[step.stepId] = LessonInteractionEvaluation(
                        isCorrect: true,
                        title: feedback.successTitle,
                        message: feedback.successMessage
                    )
                }
            } else {
                evaluationsByStepID[step.stepId] = nil
            }
        case .multipleChoice, .trueFalse, .codePrediction:
            selectedChoiceIDsByStep[step.stepId] = [choiceID]
            let isCorrect = interaction.correctChoiceIDs.contains(choiceID)
            if let feedback = interaction.feedback {
                evaluationsByStepID[step.stepId] = LessonInteractionEvaluation(
                    isCorrect: isCorrect,
                    title: isCorrect ? feedback.successTitle : "Sigue mirando",
                    message: isCorrect ? feedback.successMessage : (feedback.retryMessage ?? "Intenta otra vez.")
                )
            } else {
                evaluationsByStepID[step.stepId] = LessonInteractionEvaluation(
                    isCorrect: isCorrect,
                    title: isCorrect ? "Correcto" : "Revisa otra vez",
                    message: isCorrect ? "Elegiste bien." : "Mira de nuevo el contenido y vuelve a intentarlo."
                )
            }

            if isCorrect, interaction.kind == .codePrediction {
                revealedStepIDs.insert(step.stepId)
            }
        case .tapToReveal, .dragMatch, .quickConfirm:
            break
        }
    }

    private func markVisitedCurrentStep() {
        guard let currentStep else { return }
        visitedStepIDs.insert(currentStep.stepId)
    }
}
