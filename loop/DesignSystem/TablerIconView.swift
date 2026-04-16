//
//  TablerIconView.swift
//  loop
//
//  Íconos Tabler vía fuente embebida (tabler-icons.ttf, misma familia que el webfont CDN).
//

import SwiftUI

/// Códigos tomados de `tabler-icons.min.css` (@tabler/icons-webfont 3.31.0).
enum TablerGlyph: CaseIterable {
    case tiHome
    case tiMap2
    case tiTrophy
    case tiUserCircle
    case tiPencil
    case tiArrowsMove
    case tiBug
    case tiQuestionMark
    case tiHammer
    case tiFlame
    case tiStar
    case tiHeart
    case tiCircleCheck
    case tiLock
    case tiX
    case tiShare
    case tiAdjustmentsHorizontal

    var codePoint: UInt32 {
        switch self {
        case .tiHome: return 0xEAC1
        case .tiMap2: return 0xEAE7
        case .tiTrophy: return 0xEB45
        case .tiUserCircle: return 0xEF68
        case .tiPencil: return 0xEB04
        case .tiArrowsMove: return 0xF22F
        case .tiBug: return 0xEA48
        case .tiQuestionMark: return 0xEC9D
        case .tiHammer: return 0xEF91
        case .tiFlame: return 0xEC2C
        case .tiStar: return 0xEB2E
        case .tiHeart: return 0xEABE
        case .tiCircleCheck: return 0xEA67
        case .tiLock: return 0xEAE2
        case .tiX: return 0xEB55
        case .tiShare: return 0xEB21
        case .tiAdjustmentsHorizontal: return 0xEC38
        }
    }

    var character: Character {
        Character(UnicodeScalar(codePoint)!)
    }
}

private let tablerFontName = "tabler-icons"

/// Muestra un glifo Tabler a tamaño y color dados.
struct TablerIconView: View {
    let glyph: TablerGlyph
    var size: CGFloat = 22
    var color: Color = LoopPalette.periwinkle

    var body: some View {
        Text(String(glyph.character))
            .font(.custom(tablerFontName, size: size))
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }
}
