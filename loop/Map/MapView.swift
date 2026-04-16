import SwiftUI

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .cerulean, bottomColor: .amethyst)
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    topBar
                    mapCanvas
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 90)
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ruta Python")
                    .font(LoopFont.black(24))
                    .foregroundColor(.textPrimary)
                Text("Modulo actual: Bucles")
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textSecond)
            }
            Spacer()
            VStack(spacing: Spacing.sm) {
                ChipView(icon: "flame.fill", text: "12", tint: .loopGold)
                ChipView(icon: "heart.fill", text: "4", tint: .coral)
            }
        }
    }

    private var mapCanvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.xl)
                .fill(Color.loopSurf1.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .stroke(Color.borderSoft, lineWidth: 1)
                )

            ZStack {
                // Camino principal estilo juego, pero adaptado al look dark de Loop.
                Path { path in
                    path.move(to: CGPoint(x: 86, y: 30))
                    path.addCurve(to: CGPoint(x: 272, y: 166), control1: CGPoint(x: 248, y: 26), control2: CGPoint(x: 146, y: 120))
                    path.addCurve(to: CGPoint(x: 82, y: 320), control1: CGPoint(x: 110, y: 214), control2: CGPoint(x: 244, y: 268))
                    path.addCurve(to: CGPoint(x: 268, y: 486), control1: CGPoint(x: 232, y: 356), control2: CGPoint(x: 138, y: 440))
                }
                .stroke(Color.loopGold.opacity(0.42), style: StrokeStyle(lineWidth: 26, lineCap: .round, lineJoin: .round))

                Path { path in
                    path.move(to: CGPoint(x: 86, y: 30))
                    path.addCurve(to: CGPoint(x: 272, y: 166), control1: CGPoint(x: 248, y: 26), control2: CGPoint(x: 146, y: 120))
                    path.addCurve(to: CGPoint(x: 82, y: 320), control1: CGPoint(x: 110, y: 214), control2: CGPoint(x: 244, y: 268))
                    path.addCurve(to: CGPoint(x: 268, y: 486), control1: CGPoint(x: 232, y: 356), control2: CGPoint(x: 138, y: 440))
                }
                .stroke(Color.loopSurf2, style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round))

                ForEach(Array(viewModel.concepts.enumerated()), id: \.offset) { idx, concept in
                    VStack(spacing: 6) {
                        MapNode(state: concept.state, number: idx + 1)
                        Text(concept.title)
                            .font(LoopFont.semiBold(12))
                            .foregroundColor(.textSecond)
                        if concept.state == .current {
                            Text("AQUI")
                                .font(LoopFont.bold(9))
                                .foregroundColor(.coral)
                        }
                    }
                    .position(nodePosition(index: idx))
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .frame(height: 560)
    }

    private func nodePosition(index: Int) -> CGPoint {
        let points = [
            CGPoint(x: 92, y: 38),
            CGPoint(x: 264, y: 148),
            CGPoint(x: 96, y: 274),
            CGPoint(x: 256, y: 402),
            CGPoint(x: 100, y: 516),
        ]
        return points[min(index, points.count - 1)]
    }
}
