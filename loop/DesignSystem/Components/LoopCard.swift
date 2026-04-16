//
//  LoopCard.swift
//  loop
//
//  Contenedor tipo card del design system.
//

import SwiftUI

struct LoopCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(LoopSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LoopSpacing.cardCornerRadius, style: .continuous)
                    .fill(LoopPalette.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: LoopSpacing.cardCornerRadius, style: .continuous)
                            .stroke(LoopPalette.periwinkle.opacity(0.25), lineWidth: 1)
                    )
            )
    }
}
