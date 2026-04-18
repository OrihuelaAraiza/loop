import SwiftUI

struct LoopMeshBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.loopCloudMotionEnabled) private var cloudMotionEnabled

    var body: some View {
        ZStack {
            Group {
                if #available(iOS 18, *) {
                    if reduceMotion || !cloudMotionEnabled {
                        staticMesh
                    } else {
                        animatedMesh
                    }
                } else {
                    fallbackGradient
                }
            }

            Color.clear
                .loopGrain(intensity: 0.020)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    @available(iOS 18, *)
    private var animatedMesh: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let cx = Float(0.5 + 0.08 * sin(t * 0.3))
            let cy = Float(0.5 + 0.06 * sin(t * 0.5))

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    SIMD2<Float>(0, 0), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 0),
                    SIMD2<Float>(0, 0.5), SIMD2<Float>(cx, cy), SIMD2<Float>(1, 0.5),
                    SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 1), SIMD2<Float>(1, 1)
                ],
                colors: [
                    .loopBG, .loopBG, .loopBG,
                    .loopBG, Color.amethyst.opacity(0.22), .loopBG,
                    .loopBG, Color.coral.opacity(0.14), .loopBG
                ]
            )
        }
        .drawingGroup()
    }

    @available(iOS 18, *)
    private var staticMesh: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2<Float>(0, 0), SIMD2<Float>(0.5, 0), SIMD2<Float>(1, 0),
                SIMD2<Float>(0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1, 0.5),
                SIMD2<Float>(0, 1), SIMD2<Float>(0.5, 1), SIMD2<Float>(1, 1)
            ],
            colors: [
                .loopBG, .loopBG, .loopBG,
                .loopBG, Color.amethyst.opacity(0.18), .loopBG,
                .loopBG, Color.coral.opacity(0.10), .loopBG
            ]
        )
        .drawingGroup()
    }

    private var fallbackGradient: some View {
        ZStack {
            Color.loopBG
            RadialGradient(
                colors: [Color.amethyst.opacity(0.20), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 280
            )
            RadialGradient(
                colors: [Color.coral.opacity(0.12), .clear],
                center: .bottom,
                startRadius: 0,
                endRadius: 260
            )
        }
    }
}

#Preview {
    LoopMeshBackground()
}
