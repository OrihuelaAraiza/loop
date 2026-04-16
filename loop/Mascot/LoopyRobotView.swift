//
//  LoopyRobotView.swift
//  loop
//
//  Loopy: robot geométrico con Path y formas (sin assets externos).
//

import SwiftUI

struct LoopyRobotView: View {
    var mood: LoopyMood = .idle

    var body: some View {
        ZStack {
            // Aura suave
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LoopPalette.amethyst.opacity(0.22))
                .frame(width: 132, height: 156)

            VStack(spacing: 0) {
                antennas
                head
                torso
            }
            .padding(.vertical, 10)
        }
        .frame(width: 132, height: 168)
        .accessibilityLabel("Loopy, mascota de Loop")
    }

    private var antennas: some View {
        HStack(spacing: 56) {
            antenna(side: -1)
            antenna(side: 1)
        }
        .offset(y: 6)
    }

    private func antenna(side: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(LoopPalette.periwinkle.opacity(0.85))
                .frame(width: 5, height: 22)
            Circle()
                .fill(LoopPalette.coral.opacity(mood == .idle ? 0.9 : 1))
                .frame(width: 10, height: 10)
                .offset(y: -20)
        }
        .offset(x: side * 26)
    }

    private var head: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LoopPalette.amethyst)
                .frame(width: 88, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(LoopPalette.periwinkle.opacity(0.35), lineWidth: 1)
                )

            HStack(spacing: 18) {
                eye
                eye
            }
            .offset(y: -4)

            // Boca tipo panel
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(LoopPalette.cerulean)
                .frame(width: 36, height: 8)
                .offset(y: 18)
        }
    }

    private var eye: some View {
        ZStack {
            Circle()
                .fill(LoopPalette.baseBackground.opacity(0.9))
                .frame(width: 18, height: 18)
            Circle()
                .fill(LoopPalette.periwinkle)
                .frame(width: 8, height: 8)
        }
    }

    private var torso: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [LoopPalette.cerulean, LoopPalette.amethyst.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 62)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LoopPalette.periwinkle.opacity(0.3), lineWidth: 1)
                )

            // Panel pecho
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(LoopPalette.baseBackground.opacity(0.35))
                .frame(width: 52, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(LoopPalette.mint.opacity(0.5), lineWidth: 1)
                )
        }
        .padding(.top, 6)
    }
}
