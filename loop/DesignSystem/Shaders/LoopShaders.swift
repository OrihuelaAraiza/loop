import SwiftUI

// MARK: - Shimmer (nodos bloqueados del roadmap)

@available(iOS 17, *)
struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let startDate = Date()

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                content
                    .colorEffect(
                        ShaderLibrary.shimmer(
                            .float2(200, 200),
                            .float(elapsed)
                        )
                    )
            }
        }
    }
}

extension View {
    @ViewBuilder
    func loopShimmer() -> some View {
        if #available(iOS 17, *) {
            self.modifier(ShimmerModifier())
        } else {
            self
        }
    }
}

// MARK: - Noise Grain (textura sutil en backgrounds)

@available(iOS 17, *)
struct NoiseGrainModifier: ViewModifier {
    let intensity: Float
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let startDate = Date()

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                content
                    .colorEffect(
                        ShaderLibrary.noiseGrain(
                            .float(elapsed),
                            .float(intensity)
                        )
                    )
            }
        }
    }
}

extension View {
    @ViewBuilder
    func loopGrain(intensity: Float = 0.020) -> some View {
        if #available(iOS 17, *) {
            self.modifier(NoiseGrainModifier(intensity: intensity))
        } else {
            self
        }
    }
}

// MARK: - Ripple (tap effect en botones/cards)

@available(iOS 17, *)
struct RippleModifier: ViewModifier {
    var origin: CGPoint
    var elapsedTime: TimeInterval
    var amplitude: Float = 12
    var frequency: Float = 15
    var decay: Float = 8
    var speed: Float = 600
    var duration: TimeInterval = 0.8

    func body(content: Content) -> some View {
        let isEnabled = elapsedTime > 0 && elapsedTime < duration
        content.layerEffect(
            ShaderLibrary.ripple(
                .float2(origin),
                .float(elapsedTime),
                .float(amplitude),
                .float(frequency),
                .float(decay),
                .float(speed)
            ),
            maxSampleOffset: CGSize(width: 24, height: 24),
            isEnabled: isEnabled
        )
    }
}

@available(iOS 17, *)
struct RippleTrigger: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var origin: CGPoint = .zero
    @State private var startDate: Date = .distantPast
    var onFired: (() -> Void)? = nil
    var fireDelay: TimeInterval = 0.4
    var duration: TimeInterval = 0.8

    func body(content: Content) -> some View {
        if reduceMotion {
            content.onTapGesture {
                onFired?()
            }
        } else {
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                content
                    .modifier(RippleModifier(
                        origin: origin,
                        elapsedTime: elapsed,
                        duration: duration
                    ))
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 1, coordinateSpace: .local) { location in
                origin = location
                startDate = Date()
                if let onFired {
                    DispatchQueue.main.asyncAfter(deadline: .now() + fireDelay) {
                        onFired()
                    }
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func rippleOnTap(
        fireDelay: TimeInterval = 0.4,
        onFired: (() -> Void)? = nil
    ) -> some View {
        if #available(iOS 17, *) {
            self.modifier(RippleTrigger(onFired: onFired, fireDelay: fireDelay))
        } else {
            self.onTapGesture { onFired?() }
        }
    }
}
