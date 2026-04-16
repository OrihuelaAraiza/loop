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
}
