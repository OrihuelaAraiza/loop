import Foundation
import Combine

enum OnboardingStep: String {
    case welcome = "Inicio"
    case name = "Perfil"
    case age = "Edad"
    case goal = "Objetivo"
    case level = "Nivel"
    case placement = "Placement"
    case time = "Rutina"
    case plan = "Plan"
}

struct PlacementQuestion: Identifiable, Hashable {
    struct Option: Identifiable, Hashable {
        let id: String
        let text: String
    }

    let id: String
    let title: String
    let prompt: String
    let options: [Option]
    let correctOptionID: String

    var correctOptionText: String {
        options.first(where: { $0.id == correctOptionID })?.text ?? ""
    }

    static let onboardingDefaults: [PlacementQuestion] = [
        PlacementQuestion(
            id: "syntax",
            title: "Sintaxis",
            prompt: "En Python, ¿cómo guardas el número 5 en una variable llamada `edad`?",
            options: [
                Option(id: "a", text: "edad = 5"),
                Option(id: "b", text: "let edad = 5"),
                Option(id: "c", text: "edad := 5"),
                Option(id: "d", text: "int edad = 5")
            ],
            correctOptionID: "a"
        ),
        PlacementQuestion(
            id: "logic",
            title: "Lógica",
            prompt: "Si `contador = 2` y luego ejecutas `contador = contador + 3`, ¿qué valor queda en `contador`?",
            options: [
                Option(id: "a", text: "2"),
                Option(id: "b", text: "3"),
                Option(id: "c", text: "5"),
                Option(id: "d", text: "23")
            ],
            correctOptionID: "c"
        ),
        PlacementQuestion(
            id: "reading",
            title: "Lectura de código",
            prompt: "¿Qué imprime este código?\n\nfor i in range(3):\n    print(i)",
            options: [
                Option(id: "a", text: "1 2 3"),
                Option(id: "b", text: "0 1 2"),
                Option(id: "c", text: "0 1 2 3"),
                Option(id: "d", text: "3")
            ],
            correctOptionID: "b"
        )
    ]
}

final class OnboardingViewModel: ObservableObject {
    @Published var step: Int = 0
    @Published var userProfile = UserProfile()
    @Published var wantsPlacementTest = false
    @Published var placementScore = 0
    @Published private(set) var placementAnswers: [String: String] = [:]

    let placementQuestions = PlacementQuestion.onboardingDefaults

    var steps: [OnboardingStep] {
        var flow: [OnboardingStep] = [.welcome, .name, .age, .goal, .level]
        if wantsPlacementTest {
            flow.append(.placement)
        }
        flow.append(contentsOf: [.time, .plan])
        return flow
    }

    var currentStep: OnboardingStep {
        let safeIndex = min(step, max(steps.count - 1, 0))
        return steps[safeIndex]
    }

    var totalSteps: Int {
        steps.count
    }

    var hasCompletedPlacementTest: Bool {
        placementAnswers.count == placementQuestions.count
    }

    func next() {
        if step < totalSteps - 1 { step += 1 }
    }

    func previous() {
        if step > 0 { step -= 1 }
    }

    func setPlacementTestEnabled(_ isEnabled: Bool) {
        wantsPlacementTest = isEnabled
        if !isEnabled {
            placementScore = 0
            placementAnswers = [:]
        }
        if step >= totalSteps {
            step = max(totalSteps - 1, 0)
        }
    }

    func answerPlacementQuestion(_ questionID: String, with optionID: String) {
        placementAnswers[questionID] = optionID
    }

    func selectedPlacementOptionID(for questionID: String) -> String? {
        placementAnswers[questionID]
    }

    func placementResultLevel() -> Level? {
        guard hasCompletedPlacementTest else { return nil }
        return level(forPlacementScore: currentPlacementScore())
    }

    func completePlacementTest() {
        guard wantsPlacementTest else { return }
        let score = currentPlacementScore()
        placementScore = score
        userProfile.knowledgeLevel = level(forPlacementScore: score)
    }

    func generatePlan() {
        userProfile.generatedPlan = PlanGenerator.generatePlan(from: userProfile)
    }

    private func currentPlacementScore() -> Int {
        placementQuestions.reduce(into: 0) { partialResult, question in
            if placementAnswers[question.id] == question.correctOptionID {
                partialResult += 1
            }
        }
    }

    private func level(forPlacementScore score: Int) -> Level {
        switch score {
        case ..<1:
            return .zero
        case 1:
            return .someReading
        case 2:
            return .basicKnows
        default:
            return .hasPractice
        }
    }
}
