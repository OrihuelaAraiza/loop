import Foundation

struct LearningPlan: Codable {
    var language: ProgrammingLanguage
    var startModule: Int
    var weeksEstimated: Int
    var dailyLessons: Int
    var milestoneWeek: Int
    var aiReasons: [String]
}
