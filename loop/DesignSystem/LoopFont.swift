//
//  LoopFont.swift
//  loop
//
//  Tipografía Nunito (400 / 600 / 700 / 800 / 900).
//

import SwiftUI

enum LoopFont {
    /// Nombres PostScript de los TTF embebidos (Google Fonts static).
    private static let regular = "Nunito-Regular"
    private static let semiBold = "Nunito-SemiBold"
    private static let bold = "Nunito-Bold"
    private static let extraBold = "Nunito-ExtraBold"
    private static let black = "Nunito-Black"

    /// Fuente Nunito por peso lógico de SwiftUI.
    static func nunito(_ weight: Font.Weight, size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        let psName: String
        switch weight {
        case .semibold: psName = semiBold
        case .bold: psName = bold
        case .heavy: psName = extraBold
        case .black: psName = black
        default: psName = regular
        }
        return Font.custom(psName, size: size, relativeTo: textStyle)
    }
}
