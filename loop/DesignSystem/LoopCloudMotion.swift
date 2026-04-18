import SwiftUI

private struct LoopCloudMotionEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var loopCloudMotionEnabled: Bool {
        get { self[LoopCloudMotionEnabledKey.self] }
        set { self[LoopCloudMotionEnabledKey.self] = newValue }
    }
}

extension View {
    func loopCloudMotion(_ enabled: Bool) -> some View {
        environment(\.loopCloudMotionEnabled, enabled)
    }
}
