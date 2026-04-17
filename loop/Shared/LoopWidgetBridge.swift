import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Bridge ligero entre la app y el widget: escribe un snapshot mini en el
/// App Group "group.com.loop.shared". NO migra la persistencia principal
/// (UserDefaults.standard) para no romper datos existentes.
///
/// Para activar: anade el App Group a ambos targets en Xcode (ver LoopWidget.swift).
enum LoopWidgetBridge {
    private static let suite = "group.com.loop.shared"
    private static let keyStreak = "loop.widget.streak"
    private static let keyDailyXP = "loop.widget.dailyXP"
    private static let keyTargetXP = "loop.widget.targetXP"
    private static let keyUserName = "loop.widget.userName"

    static func write(streak: Int, dailyXP: Int, targetXP: Int, userName: String) {
        guard let defaults = UserDefaults(suiteName: suite) else { return }
        defaults.set(streak, forKey: keyStreak)
        defaults.set(dailyXP, forKey: keyDailyXP)
        defaults.set(targetXP, forKey: keyTargetXP)
        defaults.set(userName, forKey: keyUserName)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
