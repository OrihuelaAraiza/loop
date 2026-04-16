import Foundation
import Combine

final class CelebrationViewModel: ObservableObject {
    @Published var xpGained = 10
    @Published var streakDays: [Bool] = [true, true, true, true, false, false, false, false, false, false]
    @Published var badges: [String] = ["Consistencia", "Primer módulo", "Sin errores", "Racha 5"]
}
