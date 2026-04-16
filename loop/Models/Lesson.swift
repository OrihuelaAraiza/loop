import Foundation

enum ExerciseType: String, Codable {
    case fillInBlank
    case dragDrop
    case debug
    case trivia
    case project
}

struct Lesson: Identifiable, Codable {
    var id: UUID
    var moduleNumber: Int
    var title: String
    var concept: String
    var exerciseType: ExerciseType
    var xpReward: Int
    var exercises: [Exercise]
}
