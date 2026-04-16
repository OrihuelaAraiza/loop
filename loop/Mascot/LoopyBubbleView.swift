//
//  LoopyBubbleView.swift
//  loop
//
//  Burbuja de diálogo con cola hacia la mascota (lado izquierdo).
//

import SwiftUI

struct LoopyBubbleView: View {
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            tail
            bubbleText
        }
    }

    private var tail: some View {
        BubbleTailShape()
            .fill(Color.loopSurf2.opacity(0.9))
            .frame(width: 12, height: 22)
            .overlay(
                BubbleTailShape()
                    .stroke(Color.borderMid, lineWidth: 1)
            )
    }

    private var bubbleText: some View {
        Text(text)
            .font(LoopFont.semiBold(16))
            .foregroundStyle(Color.textPrimary)
            .multilineTextAlignment(.leading)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .fill(Color.loopSurf2.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                            .stroke(Color.borderMid, lineWidth: 1)
                    )
            )
    }
}

/// Cola triangular redondeada apuntando hacia la izquierda (hacia Loopy).
private struct BubbleTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w, y: h * 0.35))
        path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.5), control: CGPoint(x: w * 0.35, y: h * 0.28))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.65), control: CGPoint(x: w * 0.35, y: h * 0.72))
        path.closeSubpath()
        return path
    }
}
