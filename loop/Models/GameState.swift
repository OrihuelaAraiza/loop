import Foundation
import Combine

final class GameState: ObservableObject {
    @Published var currentStreak: Int = 4
    @Published var totalXP: Int = 120
    @Published var level: Int = 2
    @Published var hearts: Int = 3
    @Published var dailyXP: Int = 8
    @Published var dailyGoal: Int = 20
    @Published var completedLessons: Set<UUID> = []
    @Published var earnedBadges: Set<String> = ["consistencia", "primer_codigo"]

    func snapshot() -> GameStateSnapshot {
        GameStateSnapshot(
            currentStreak: currentStreak,
            totalXP: totalXP,
            level: level,
            hearts: hearts,
            dailyXP: dailyXP,
            dailyGoal: dailyGoal,
            completedLessons: completedLessons,
            earnedBadges: earnedBadges
        )
    }

    func apply(_ snapshot: GameStateSnapshot) {
        currentStreak = snapshot.currentStreak
        totalXP = snapshot.totalXP
        level = snapshot.level
        hearts = snapshot.hearts
        dailyXP = snapshot.dailyXP
        dailyGoal = snapshot.dailyGoal
        completedLessons = snapshot.completedLessons
        earnedBadges = snapshot.earnedBadges
    }
}

struct GameStateSnapshot: Codable {
    var currentStreak: Int
    var totalXP: Int
    var level: Int
    var hearts: Int
    var dailyXP: Int
    var dailyGoal: Int
    var completedLessons: Set<UUID>
    var earnedBadges: Set<String>
}
