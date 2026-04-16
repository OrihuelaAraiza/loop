import Foundation
import Combine

final class ExerciseViewModel: ObservableObject {
    @Published var progress: Double = 0.4
    @Published var hearts = 3
    @Published var selectedIndex: Int?
    @Published var isCorrect: Bool?

    let exercise = Exercise(
        id: UUID(),
        type: .fillInBlank,
        question: "Completa el espacio para imprimir el nombre del usuario.",
        codeSnippet: """
        name = "Ana"
        print(_____)
        """,
        blankPosition: 1,
        choices: ["name", "\"name\"", "Name()", "input()"],
        correctIndex: 0,
        explanation: "La variable se llama name y debe pasarse directamente a print."
    )

    func submit(choice index: Int) {
        selectedIndex = index
        isCorrect = index == exercise.correctIndex
    }
}
