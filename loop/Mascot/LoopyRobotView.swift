import SwiftUI

struct LoopyView: View {
    var mood: LoopyMood = .idle

    var body: some View {
        LoopyRiveAvatar(state: mood.riveState, variant: .hero) {
            LoopyLegacyRobotView(mood: mood)
        }
    }
}

private struct LoopyLegacyRobotView: View {
    var mood: LoopyMood = .idle
    @State private var bob = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.xl)
                .fill(Color.amethyst.opacity(0.15))
                .frame(width: 170, height: 190)

            VStack(spacing: 0) {
                antenna
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .fill(
                            LinearGradient(
                                colors: [Color.amethyst, Color.cerulean],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 118, height: 94)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.xl)
                                .stroke(Color.periwinkle.opacity(0.35), lineWidth: 1)
                        )

                    HStack(spacing: 16) {
                        robotEye
                        robotEye
                    }
                    .scaleEffect(mood == .speaking ? 1.08 : 1)
                    .offset(y: -6)

                    mouth
                        .offset(y: 20)
                }

                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(Color.loopSurf3.opacity(0.6))
                    .frame(width: 124, height: 74)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(Color.borderMid, lineWidth: 1)
                    )
                    .overlay(alignment: .center) {
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .fill(Color.mint.opacity(0.25))
                            .frame(width: 62, height: 28)
                    }
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .fill(Color.amethyst.opacity(0.9))
                            .frame(width: 14, height: 48)
                            .offset(x: -16)
                    }
                    .overlay(alignment: .trailing) {
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .fill(Color.amethyst.opacity(0.9))
                            .frame(width: 14, height: 48)
                            .offset(x: 16)
                    }
                    .padding(.top, 8)
            }
        }
        .offset(y: bob ? -2 : 2)
        .shadow(color: Color.amethyst.opacity(0.18), radius: bob ? 14 : 8, y: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                bob.toggle()
            }
        }
        .animation(.spring(response: 0.4), value: mood)
    }

    private var antenna: some View {
        ZStack {
            Rectangle()
                .fill(Color.periwinkle.opacity(0.85))
                .frame(width: 6, height: 26)
            Circle()
                .fill(Color.coral)
                .frame(width: 14, height: 14)
                .offset(y: -16)
        }
        .rotationEffect(.degrees(mood == .celebrating ? 15 : 0))
        .offset(y: 10)
    }

    private var robotEye: some View {
        ZStack {
            Circle().fill(.white).frame(width: 24, height: 24)
            Circle().fill(Color.amethyst).frame(width: 13, height: 13)
            Circle().fill(.white).frame(width: 5, height: 5)
        }
        .overlay(eyelid)
    }

    @ViewBuilder
    private var eyelid: some View {
        switch mood {
        case .celebrating:
            Capsule()
                .stroke(Color.loopBG, lineWidth: 2)
                .frame(width: 16, height: 7)
                .offset(y: -4)
        case .sad:
            Rectangle()
                .fill(Color.loopBG.opacity(0.6))
                .frame(width: 16, height: 3)
                .rotationEffect(.degrees(12))
                .offset(x: 2, y: -6)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var mouth: some View {
        switch mood {
        case .idle:
            RoundedRectangle(cornerRadius: 3)
                .fill(.white)
                .frame(width: 34, height: 6)
        case .speaking:
            Capsule()
                .fill(.white)
                .frame(width: 28, height: 10)
        case .celebrating:
            SmileShape()
                .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 30, height: 18)
        case .sad:
            SadMouthShape()
                .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 30, height: 18)
        }
    }
}

private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 3, y: rect.midY - 2))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - 3, y: rect.midY - 2),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return p
    }
}

private struct SadMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 3, y: rect.midY + 4))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - 3, y: rect.midY + 4),
            control: CGPoint(x: rect.midX, y: rect.minY - 3)
        )
        return p
    }
}
