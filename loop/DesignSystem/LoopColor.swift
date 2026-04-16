import SwiftUI

extension Color {
    // Backgrounds (3 niveles de profundidad)
    static let loopBG = Color(hex: "0D1020")
    static let loopSurf1 = Color(hex: "131628")
    static let loopSurf2 = Color(hex: "1A1E35")
    static let loopSurf3 = Color(hex: "222640")

    // Paleta de acento
    static let coral = Color(hex: "EE6352")
    static let periwinkle = Color(hex: "ADBDFF")
    static let cerulean = Color(hex: "1C6E8C")
    static let amethyst = Color(hex: "9649CB")
    static let loopGold = Color(hex: "F4B942")
    static let mint = Color(hex: "4ECBA5")

    // Texto
    static let textPrimary = Color(hex: "EEF0FF")
    static let textSecond = Color(hex: "ADBDFF").opacity(0.65)
    static let textMuted = Color(hex: "ADBDFF").opacity(0.35)

    // Bordes
    static let borderSoft = Color(hex: "ADBDFF").opacity(0.08)
    static let borderMid = Color(hex: "ADBDFF").opacity(0.16)

    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
