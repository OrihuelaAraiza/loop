import Foundation
import WidgetKit

struct LoopWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LoopWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (LoopWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LoopWidgetEntry>) -> Void) {
        let entry = currentEntry()
        // Refresca cada 30 min; WidgetCenter.shared.reloadAllTimelines() desde la app
        // fuerza actualizacion inmediata tras guardar progreso.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> LoopWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.loop.shared") ?? .standard
        let streak = defaults.integer(forKey: "loop.widget.streak")
        let dailyXP = defaults.integer(forKey: "loop.widget.dailyXP")
        let targetXP = defaults.integer(forKey: "loop.widget.targetXP")
        let name = defaults.string(forKey: "loop.widget.userName") ?? "coder"

        return LoopWidgetEntry(
            date: Date(),
            streak: streak,
            dailyXP: dailyXP,
            targetXP: targetXP == 0 ? 20 : targetXP,
            userName: name.isEmpty ? "coder" : name
        )
    }
}
