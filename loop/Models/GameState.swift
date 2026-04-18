import Foundation
import Combine

final class GameState: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var totalXP: Int = 0
    @Published var level: Int = 1
    @Published var hearts: Int = 3
    @Published var dailyXP: Int = 0
    @Published var dailyGoal: Int = 20
    @Published var completedLessons: Set<String> = []
    @Published var earnedBadges: Set<String> = []

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

    func applyLessonCompletion(lessonID: String, xpGained: Int, heartsRemaining: Int) {
        hearts = heartsRemaining

        guard completedLessons.insert(lessonID).inserted else { return }

        let earnedXP = max(xpGained, 0)
        totalXP += earnedXP
        dailyXP += earnedXP
        currentStreak += 1
        level = Self.level(for: totalXP)

        if currentStreak >= 3 {
            earnedBadges.insert("consistencia")
        }
        if totalXP >= 100 {
            earnedBadges.insert("100_xp")
        }
    }

    private static func level(for totalXP: Int) -> Int {
        max(1, (max(totalXP, 0) / 100) + 1)
    }
}

struct GameStateSnapshot: Codable {
    var currentStreak: Int
    var totalXP: Int
    var level: Int
    var hearts: Int
    var dailyXP: Int
    var dailyGoal: Int
    var completedLessons: Set<String>
    var earnedBadges: Set<String>

    private enum CodingKeys: String, CodingKey {
        case currentStreak
        case totalXP
        case level
        case hearts
        case dailyXP
        case dailyGoal
        case completedLessons
        case earnedBadges
    }

    init(
        currentStreak: Int,
        totalXP: Int,
        level: Int,
        hearts: Int,
        dailyXP: Int,
        dailyGoal: Int,
        completedLessons: Set<String>,
        earnedBadges: Set<String>
    ) {
        self.currentStreak = currentStreak
        self.totalXP = totalXP
        self.level = level
        self.hearts = hearts
        self.dailyXP = dailyXP
        self.dailyGoal = dailyGoal
        self.completedLessons = completedLessons
        self.earnedBadges = earnedBadges
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        totalXP = try container.decodeIfPresent(Int.self, forKey: .totalXP) ?? 0
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        hearts = try container.decodeIfPresent(Int.self, forKey: .hearts) ?? 3
        dailyXP = try container.decodeIfPresent(Int.self, forKey: .dailyXP) ?? 0
        dailyGoal = try container.decodeIfPresent(Int.self, forKey: .dailyGoal) ?? 20

        if let stringIDs = try? container.decodeIfPresent(Set<String>.self, forKey: .completedLessons) {
            completedLessons = stringIDs
        } else if let uuidIDs = try? container.decodeIfPresent(Set<UUID>.self, forKey: .completedLessons) {
            completedLessons = Set(uuidIDs.map(\.uuidString))
        } else {
            completedLessons = []
        }

        earnedBadges = try container.decodeIfPresent(Set<String>.self, forKey: .earnedBadges) ?? []
    }
}
