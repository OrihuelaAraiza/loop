import Foundation

enum AgeRange: String, Codable, CaseIterable, Identifiable {
    case age10to12 = "10-12"
    case age13to15 = "13-15"
    case age16to18 = "16-18"
    case age19to22 = "19-22"
    case age23to28 = "23-28"
    case age29Plus = "29+"
    var id: String { rawValue }
}

enum LearningGoal: String, Codable, CaseIterable, Identifiable {
    case createApps = "Crear apps"
    case getJob = "Conseguir trabajo"
    case passClasses = "Pasar clases"
    case curiosity = "Curiosidad"
    var id: String { rawValue }
}

enum Level: String, Codable, CaseIterable, Identifiable {
    case zero = "Desde cero"
    case someReading = "He leído algo"
    case basicKnows = "Conozco lo básico"
    case hasPractice = "Ya practico"
    var id: String { rawValue }
}

enum Weekday: String, Codable, CaseIterable, Identifiable {
    case l = "L", m = "M", x = "X", j = "J", v = "V", s = "S", d = "D"
    var id: String { rawValue }
}

enum ProgrammingLanguage: String, Codable, CaseIterable, Identifiable {
    case python = "Python"
    case javascript = "JavaScript"
    case html = "HTML"
    var id: String { rawValue }
}

struct UserProfile: Codable {
    var name: String = ""
    var avatarIndex: Int = 0
    var ageRange: AgeRange = .age16to18
    var goal: LearningGoal = .createApps
    var knowledgeLevel: Level = .zero
    var minutesPerDay: Int = 10
    var activeDays: Set<Weekday> = [.l, .m, .x, .j, .v]
    var generatedPlan: LearningPlan?
}
