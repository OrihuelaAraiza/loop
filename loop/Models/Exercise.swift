import Foundation

struct Exercise: Identifiable, Codable {
    var id: UUID
    var type: ExerciseType
    var question: String
    var codeSnippet: String?
    var blankPosition: Int?
    var choices: [String]?
    var correctIndex: Int?
    var explanation: String
}
