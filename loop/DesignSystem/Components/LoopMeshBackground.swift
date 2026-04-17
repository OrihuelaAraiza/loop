import SwiftUI

struct LoopMeshBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let prussian = Color(hex: "191D32")
    private let amethyst = Color(hex: "9649CB")
    private let coral = Color(hex: "EE6352")

    var body: some View {
        Group {
            if #available(iOS 18, *) {
                if reduceMotion {
                    staticMesh
                } else {
                    animatedMesh
                }
            } else {
                fallbackGradient
            }
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
                    prussian, prussian, prussian,
                    prussian, amethyst.opacity(0.18), prussian,
                    prussian, coral.opacity(0.1), prussian
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
                prussian, prussian, prussian,
                prussian, amethyst.opacity(0.15), prussian,
                prussian, coral.opacity(0.08), prussian
            ]
        )
        .drawingGroup()
    }

    private var fallbackGradient: some View {
        ZStack {
            prussian
            RadialGradient(
                colors: [amethyst.opacity(0.18), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 280
            )
            RadialGradient(
                colors: [coral.opacity(0.1), .clear],
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
