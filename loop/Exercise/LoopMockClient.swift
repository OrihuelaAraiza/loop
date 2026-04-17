import Foundation

final class LoopMockClient {
    static let shared = LoopMockClient()
    static let timedOutAnswer = "__loop_timeout__"

    private let exercises: [ExerciseResponse]

    private init() {
        exercises = [
            ExerciseResponse(
                type: .fillInBlank,
                prompt: "Completa el espacio para imprimir el nombre del usuario.",
                explanation: "La variable ya se llama name, asi que debes pasarla directo a print sin comillas extra.",
                xpReward: 10,
                hints: [
                    "Ya existe una variable creada arriba.",
                    "No necesitas escribir un string nuevo.",
                ],
                codeTemplate: """
                name = "Ana"
                print(___)
                """,
                correctAnswer: "name",
                correctAnswerDisplay: "name"
            ),
            ExerciseResponse(
                type: .trivia,
                prompt: "Que palabra usas en Python para repetir algo sobre una lista?",
                explanation: "for recorre cada elemento de una lista o secuencia. switch y case ni siquiera existen como palabras clave de Python.",
                xpReward: 8,
                hints: [
                    "Se usa mucho con listas.",
                    "Empieza con f.",
                ],
                options: ["for", "while", "switch", "case"],
                correctAnswer: "for",
                correctAnswerDisplay: "for"
            ),
            ExerciseResponse(
                type: .dragAndDrop,
                prompt: "Ordena las piezas para construir un print valido.",
                explanation: "La llamada correcta abre con print, luego parentesis, despues el texto y al final cierra parentesis.",
                xpReward: 12,
                hints: [
                    "Empieza con la funcion.",
                    "El texto va dentro de parentesis.",
                ],
                options: ["print", "(", "\"Hola Loop\"", ")"],
                correctAnswer: "print|(|\"Hola Loop\"|)",
                correctAnswerDisplay: "print(\"Hola Loop\")"
            ),
            ExerciseResponse(
                type: .debug,
                prompt: "Encuentra la linea que tiene el error.",
                explanation: "En Python, para comparar usas ==. Un solo = sirve para asignar un valor.",
                xpReward: 10,
                hints: [
                    "El problema esta en una condicion.",
                    "Revisa el operador de comparacion.",
                ],
                codeTemplate: """
                score = 10
                if score = 10:
                    print("Perfect")
                """,
                correctAnswer: "line:2",
                correctAnswerDisplay: "Linea 2: if score = 10:"
            ),
            ExerciseResponse(
                type: .miniProject,
                prompt: "Escribe un programa que imprima Hola Loop.",
                explanation: "Solo necesitabas una llamada a print con el texto correcto. El objetivo era practicar la sintaxis completa.",
                xpReward: 15,
                hints: [
                    "Usa print.",
                    "El texto exacto debe ser Hola Loop.",
                ],
                codeTemplate: """
                # Escribe tu solucion aqui
                print("")
                """,
                correctAnswer: "print(\"Hola Loop\")",
                correctAnswerDisplay: "print(\"Hola Loop\")"
            ),
        ]
    }

    func lessonOfTheDay() -> [ExerciseResponse] {
        exercises
    }

    func submit(answer: String, for exercise: ExerciseResponse) async -> AnswerResponse {
        try? await Task.sleep(for: .milliseconds(350))

        let isCorrect = switch exercise.type {
        case .fillInBlank, .trivia:
            normalizePlain(answer) == normalizePlain(exercise.correctAnswer)
        case .dragAndDrop:
            normalizeTokens(answer) == normalizeTokens(exercise.correctAnswer)
        case .debug:
            normalizePlain(answer) == normalizePlain(exercise.correctAnswer)
        case .miniProject:
            normalizeCode(answer) == normalizeCode(exercise.correctAnswer)
        }

        return AnswerResponse(
            isCorrect: isCorrect,
            xpEarned: isCorrect ? exercise.xpReward : 0,
            correctAnswerDisplay: exercise.correctAnswerDisplay ?? exercise.correctAnswer
        )
    }

    private func normalizePlain(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func normalizeTokens(_ value: String) -> String {
        value
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: "|")
    }

    private func normalizeCode(_ value: String) -> String {
        value
            .replacingOccurrences(of: "'", with: "\"")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .lowercased()
    }
}
