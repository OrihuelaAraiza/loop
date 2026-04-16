//
//  OnboardingWelcomeContent.swift
//  loop
//
//  Paso 1: bienvenida, valor en tres cards con íconos Tabler.
//

import SwiftUI

struct OnboardingWelcomeContent: View {
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoopSpacing.section) {
                HStack(alignment: .top, spacing: 16) {
                    LoopyRobotView(mood: .idle)
                    LoopyBubbleView(
                        text: "Hola, soy Loopy. Aprender a programar puede ser divertido si lo hacemos en pasos claros y con un plan hecho para ti."
                    )
                }

                VStack(spacing: LoopSpacing.cardGap) {
                    valueCard(
                        icon: .tiStar,
                        title: "Rutas claras",
                        subtitle: "Conceptos en orden, como un mapa en el que siempre ves el siguiente paso."
                    )
                    valueCard(
                        icon: .tiFlame,
                        title: "Práctica guiada",
                        subtitle: "Ejercicios breves con feedback al instante para no quedarte atascado."
                    )
                    valueCard(
                        icon: .tiCircleCheck,
                        title: "Ritmo sostenible",
                        subtitle: "Un plan que respeta tu tiempo y no te culpa por equivocarte."
                    )
                }

                LoopPrimaryButton(title: "Continuar", action: onContinue)
            }
            .padding(.horizontal, LoopSpacing.screenHorizontal)
            .padding(.bottom, 28)
        }
    }

    private func valueCard(icon: TablerGlyph, title: String, subtitle: String) -> some View {
        LoopCard {
            HStack(alignment: .top, spacing: 14) {
                TablerIconView(glyph: icon, size: 26, color: LoopPalette.coral)
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(LoopFont.nunito(.bold, size: 17, relativeTo: .body))
                        .foregroundStyle(LoopPalette.periwinkle)
                    Text(subtitle)
                        .font(LoopFont.nunito(.regular, size: 14, relativeTo: .body))
                        .foregroundStyle(LoopPalette.periwinkle.opacity(0.88))
                }
            }
        }
    }
}
