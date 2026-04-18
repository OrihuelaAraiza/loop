import Foundation

enum LessonResumeStage: String, Codable {
    case theory
    case practice
}

struct LessonResumeState: Codable, Equatable {
    let lessonID: String
    var stage: LessonResumeStage
    var theoryStepIndex: Int
    var totalTheorySteps: Int
    var exerciseIndex: Int
    var totalExercises: Int
    var updatedAt: Date

    init(
        lessonID: String,
        stage: LessonResumeStage = .theory,
        theoryStepIndex: Int = 0,
        totalTheorySteps: Int = 0,
        exerciseIndex: Int = 0,
        totalExercises: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.lessonID = lessonID
        self.stage = stage
        self.theoryStepIndex = theoryStepIndex
        self.totalTheorySteps = totalTheorySteps
        self.exerciseIndex = exerciseIndex
        self.totalExercises = totalExercises
        self.updatedAt = updatedAt
    }
}
