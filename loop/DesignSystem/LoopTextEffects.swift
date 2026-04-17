import SwiftUI

// MARK: - WordByWord renderer (speech bubble de Loopy)

@available(iOS 17, *)
struct WordByWordRenderer: TextRenderer, Animatable {
    var elapsedTime: TimeInterval
    var totalDuration: TimeInterval
    var wordDuration: TimeInterval = 0.18

    var animatableData: Double {
        get { elapsedTime }
        set { elapsedTime = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        var total = 0
        for line in layout {
            for run in line {
                for _ in run {
                    total += 1
                }
            }
        }
        guard total > 0 else { return }

        var index = 0
        for line in layout {
            for run in line {
                for glyph in run {
                    let delay = Double(index) / Double(total) * totalDuration
                    let localTime = max(0, elapsedTime - delay)
                    let progress = min(1.0, localTime / wordDuration)
                    let yOffset = (1.0 - progress) * 8.0

                    var copy = context
                    copy.opacity = progress
                    copy.translateBy(x: 0, y: yOffset)
                    copy.draw(glyph)
                    index += 1
                }
            }
        }
    }
}

// MARK: - Loopy text transition

@available(iOS 17, *)
struct LoopyTextTransition: Transition {
    static var properties: TransitionProperties {
        TransitionProperties(hasMotion: true)
    }

    func body(content: Content, phase: TransitionPhase) -> some View {
        let duration: TimeInterval = 1.2
        let elapsed: TimeInterval = phase.isIdentity ? duration : 0
        content
            .textRenderer(WordByWordRenderer(
                elapsedTime: elapsed,
                totalDuration: duration
            ))
    }
}

// MARK: - XPBounce renderer (contador de XP)

@available(iOS 17, *)
struct XPBounceRenderer: TextRenderer, Animatable {
    var bounceAmount: Double

    var animatableData: Double {
        get { bounceAmount }
        set { bounceAmount = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                var glyphIndex = 0
                for glyph in run {
                    let delay = Double(glyphIndex) * 0.05
                    glyphIndex += 1
                    let local = max(0, bounceAmount - delay)
                    let envelope = max(0, 1 - local)
                    let wave = sin(local * .pi * 2)
                    let offset = wave * envelope * 12.0
                    var copy = context
                    copy.translateBy(x: 0, y: -max(0, offset))
                    copy.draw(glyph)
                }
            }
        }
    }
}
