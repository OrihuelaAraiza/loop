import SPAlert
import SwiftUI
import UIKit

/// Toasts globales de Loop. El sistema de haptics existente (HapticManager)
    /// se encarga del feedback táctil; SPAlert siempre con haptic: .none.
enum LoopToast {
    static func xpGained(_ amount: Int) {
        present(
            title: "+\(amount) XP",
            message: "Sigue así",
            image: UIImage(systemName: "star.fill")
        )
    }

    static func streakSaved(days: Int) {
        present(
            title: "Racha: \(days) días",
            message: "No pares ahora",
            image: UIImage(systemName: "flame.fill")
        )
    }

    static func planReady() {
        SPAlert.present(
            title: "Plan listo",
            message: "Tu ruta está generada",
            preset: .done,
            haptic: .none
        )
    }

    static func routeReady() {
        SPAlert.present(
            title: "Ruta lista",
            message: "Tu nuevo curso está listo",
            preset: .done,
            haptic: .none
        )
    }

    static func lessonComplete(xp: Int) {
        SPAlert.present(
            title: "Lección completa",
            message: "+\(xp) XP ganados",
            preset: .done,
            haptic: .none
        )
    }

    static func error(_ message: String) {
        SPAlert.present(
            title: "Algo salió mal",
            message: message,
            preset: .error,
            haptic: .none
        )
    }

    private static func present(title: String, message: String?, image: UIImage?) {
        if let image {
            SPAlert.present(
                title: title,
                message: message,
                preset: .custom(image),
                haptic: .none
            )
        } else {
            SPAlert.present(
                title: title,
                message: message,
                preset: .done,
                haptic: .none
            )
        }
    }
}
