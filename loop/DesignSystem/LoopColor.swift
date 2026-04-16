//
//  LoopColor.swift
//  loop
//
//  Tokens de color de Loop (hackathon Human-Centered AI).
//

import SwiftUI

/// Paleta fija de la marca. Las vistas deben usar `Color.loop*` o estos estáticos, sin literales sueltos.
enum LoopPalette {
    /// Prussian Blue — fondo de pantallas y headers
    static let prussian = Color(red: 25 / 255, green: 29 / 255, blue: 50 / 255)
    /// Coral — acción primaria
    static let coral = Color(red: 238 / 255, green: 99 / 255, blue: 82 / 255)
    /// Periwinkle — texto UI, chips, bordes
    static let periwinkle = Color(red: 173 / 255, green: 189 / 255, blue: 255 / 255)
    /// Cerulean — barras de progreso de ruta
    static let cerulean = Color(red: 28 / 255, green: 110 / 255, blue: 140 / 255)
    /// Amethyst — XP, logros, Loopy
    static let amethyst = Color(red: 150 / 255, green: 73 / 255, blue: 203 / 255)
    /// Gold — streaks, estrellas, días completados
    static let gold = Color(red: 244 / 255, green: 185 / 255, blue: 66 / 255)
    /// Mint — correcto, nodos completados
    static let mint = Color(red: 78 / 255, green: 203 / 255, blue: 165 / 255)
    /// Fondo base oscuro global
    static let baseBackground = Color(red: 15 / 255, green: 18 / 255, blue: 33 / 255)
    /// Cards: rgba(36,40,68,0.9)
    static let cardFill = Color(red: 36 / 255, green: 40 / 255, blue: 68 / 255).opacity(0.9)
}

extension Color {
    static let loopPrussian = LoopPalette.prussian
    static let loopCoral = LoopPalette.coral
    static let loopPeriwinkle = LoopPalette.periwinkle
    static let loopCerulean = LoopPalette.cerulean
    static let loopAmethyst = LoopPalette.amethyst
    static let loopGold = LoopPalette.gold
    static let loopMint = LoopPalette.mint
    static let loopBaseBackground = LoopPalette.baseBackground
    static let loopCardFill = LoopPalette.cardFill
}
