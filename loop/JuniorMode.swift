import Observation
import SwiftUI

@Observable
final class JuniorModeManager {
    static let shared = JuniorModeManager()

    private let storageKey = "loop.juniorMode"

    var isActive: Bool {
        didSet {
            UserDefaults.standard.set(isActive, forKey: storageKey)
        }
    }

    private init() {
        isActive = UserDefaults.standard.bool(forKey: storageKey)
    }

    func configure(forAge age: Int) {
        isActive = age < 13
    }
}

private struct JuniorModeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isJuniorMode: Bool {
        get { self[JuniorModeKey.self] }
        set { self[JuniorModeKey.self] = newValue }
    }
}

struct LoopCopy {
    static func goalName(_ goal: LearningGoal, junior: Bool) -> String {
        switch goal {
        case .createApps:
            return junior ? "Crear mis propios juegos" : "Crear apps"
        case .getJob:
            return junior ? "Aprender a programar" : "Conseguir trabajo"
        case .passClasses:
            return junior ? "Mejorar en la escuela" : "Pasar clases"
        case .curiosity:
            return junior ? "Explorar y divertirme" : "Por curiosidad"
        }
    }

    static func streakMessage(days: Int, junior: Bool) -> String {
        if junior {
            return days == 0
                ? "Hola! Hoy es tu primer dia. Vamos a aprender algo cool."
                : "Llevas \(days) dias seguidos. Eso es increible!"
        } else {
            return days == 0
                ? "Tu leccion del dia esta lista."
                : "Llevas \(days) dias seguidos. No pares ahora."
        }
    }

    static func correctMessage(junior: Bool) -> String {
        junior
            ? ["Perfecto!", "Lo lograste!", "Eres increible!", "Asi se hace!"].randomElement()!
            : ["Correcto.", "Exacto.", "Bien hecho."].randomElement()!
    }

    static func incorrectMessage(junior: Bool) -> String {
        junior
            ? "Casi! Intentalo de nuevo, tu puedes."
            : "No es correcto. Revisa la explicacion."
    }

    static func routesTitle(junior: Bool) -> String {
        junior ? "Mis aventuras" : "Rutas"
    }

    static func mapTitle(junior: Bool) -> String {
        junior ? "Mi mapa de aprendizaje" : "Mapa"
    }

    static func profileTitle(junior: Bool) -> String {
        junior ? "Mi perfil" : "Perfil"
    }

    static func xpLabel(junior: Bool) -> String {
        junior ? "Puntos" : "XP"
    }

    static func streakLabel(junior: Bool) -> String {
        junior ? "Dias seguidos" : "Racha"
    }

    static func focusLabel(junior: Bool) -> String {
        junior ? "Mi aventura actual" : "En foco"
    }

    static func queueLabel(junior: Bool) -> String {
        junior ? "Siguiente aventura" : "En cola"
    }

    static func completedLabel(junior: Bool) -> String {
        junior ? "Lo logre!" : "Completado"
    }

    static func lockedLabel(junior: Bool) -> String {
        junior ? "Aun no disponible" : "Bloqueado"
    }

    static func continueHereLabel(junior: Bool) -> String {
        junior ? "Tu mision actual" : "Continua aqui"
    }
}

struct LoopLayout {
    static func fontSize(base: CGFloat, junior: Bool) -> CGFloat {
        junior ? base + 2 : base
    }

    static func cornerRadius(junior: Bool) -> CGFloat {
        junior ? 20 : 16
    }

    static func iconSize(junior: Bool) -> CGFloat {
        junior ? 28 : 22
    }
}

extension IdentityCardBadge {
    static func normalizedForJunior(_ badge: IdentityCardBadge, junior: Bool) -> IdentityCardBadge {
        junior && badge == .creador ? .mentor : badge
    }

    static func availableBadges(junior: Bool) -> [IdentityCardBadge] {
        junior ? allCases.filter { $0 != .creador } : allCases
    }
}
