import Foundation

enum PlanGenerator {
    static func generatePlan(from profile: UserProfile) -> LearningPlan {
        let language: ProgrammingLanguage = {
            switch profile.goal {
            case .createApps, .curiosity: return .python
            case .getJob: return .python
            case .passClasses: return .python
            }
        }()

        let startModule: Int = {
            switch profile.knowledgeLevel {
            case .zero, .someReading: return 1
            case .basicKnows: return 3
            case .hasPractice: return 5
            }
        }()

        let estimatedWeeks = weeksNeeded(profile)
        let reasons = [
            reasonForLanguage(profile),
            reasonForRhythm(profile),
            reasonForMilestone(profile),
        ]

        return LearningPlan(
            language: language,
            startModule: startModule,
            weeksEstimated: estimatedWeeks,
            dailyLessons: lessonsPerDay(profile),
            milestoneWeek: max(1, estimatedWeeks / 2),
            aiReasons: reasons
        )
    }

    private static func weeksNeeded(_ profile: UserProfile) -> Int {
        switch profile.minutesPerDay {
        case 5: return 14
        case 10: return 10
        case 15: return 8
        case 20: return 7
        default: return 6
        }
    }

    private static func lessonsPerDay(_ profile: UserProfile) -> Int {
        profile.minutesPerDay >= 20 ? 2 : 1
    }

    private static func reasonForLanguage(_ profile: UserProfile) -> String {
        "Priorizamos \(ProgrammingLanguage.python.rawValue) para darte una curva de aprendizaje amigable según tu objetivo \(profile.goal.rawValue.lowercased())."
    }

    private static func reasonForRhythm(_ profile: UserProfile) -> String {
        "Tu rutina de \(profile.minutesPerDay) minutos por día se traduce en sesiones breves y sostenibles para mantener constancia real."
    }

    private static func reasonForMilestone(_ profile: UserProfile) -> String {
        "Colocamos un mini proyecto a mitad del plan para reforzar motivación y medir progreso con evidencia práctica."
    }
}
