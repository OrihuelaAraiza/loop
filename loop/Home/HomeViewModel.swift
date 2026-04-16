import Foundation
import Combine

struct CourseItem: Identifiable {
    let id = UUID()
    let title: String
    let module: String
    let stars: Int
    let isActive: Bool
}

final class HomeViewModel: ObservableObject {
    @Published var weeklyStates: [DayNode.DayState] = [.done, .done, .done, .today, .pending, .pending, .pending]
    @Published var courses: [CourseItem] = [
        .init(title: "Python Foundations", module: "Variables y flujo", stars: 3, isActive: true),
        .init(title: "JavaScript Start", module: "Funciones", stars: 2, isActive: false),
        .init(title: "Web Core", module: "HTML semántico", stars: 1, isActive: false),
    ]
}
