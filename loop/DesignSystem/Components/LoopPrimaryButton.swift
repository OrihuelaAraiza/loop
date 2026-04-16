//
//  LoopPrimaryButton.swift
//  loop
//
//  Botón CTA primario (Coral + sombra definida en el brief).
//

import SwiftUI

struct LoopPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LoopFont.nunito(.heavy, size: 18, relativeTo: .body))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: LoopSpacing.buttonCornerRadius, style: .continuous)
                        .fill(LoopPalette.coral)
                        .shadow(color: LoopPalette.coral.opacity(0.3), radius: 16, y: 8)
                )
        }
        .buttonStyle(.plain)
    }
}
