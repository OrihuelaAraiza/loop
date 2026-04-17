import SwiftUI

enum LoopAnimation {
    static let springFast = Animation.spring(duration: 0.25, bounce: 0.4)
    static let springMedium = Animation.spring(duration: 0.35, bounce: 0.5)
    static let springBouncy = Animation.spring(duration: 0.4, bounce: 0.65)
    static let springSoft = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let meshBreath = Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true)
    static let pulseSlow = Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)
    static let pulseFast = Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
}
