//
//  LoopyMood.swift
//  loop
//
//  Estados de la mascota para animaciones futuras.
//

import Foundation

/// Estado visual de Loopy (idle / hablando / celebrando).
enum LoopyMood: String, CaseIterable {
    case idle
    case speaking
    case celebrating
}
