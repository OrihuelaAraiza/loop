import SwiftUI

extension Color {
    // Backgrounds (3 niveles de profundidad — base: Charcoal Blue #334E58)
    static let loopBG = Color(hex: "334E58")
    static let loopSurf1 = Color(hex: "3A555F")
    static let loopSurf2 = Color(hex: "415C66")
    static let loopSurf3 = Color(hex: "48636D")

    // Paleta de acento
    static let coral = Color(hex: "EE6352")      // Vibrant Coral — sin cambio
    static let periwinkle = Color(hex: "EAE1DF") // Alabaster Grey (era periwinkle)
    static let cerulean = Color(hex: "951E0E")   // Oxblood (era cerulean)
    static let amethyst = Color(hex: "A8C69F")   // Celadon (era amethyst)
    static let loopGold = Color(hex: "EE6352")   // Coral — tono más cálido disponible
    static let mint = Color(hex: "A8C69F")       // Celadon (único verde en la paleta)

    // Texto
    static let textPrimary = Color(hex: "EAE1DF")
    static let textSecond = Color(hex: "EAE1DF").opacity(0.65)
    static let textMuted = Color(hex: "EAE1DF").opacity(0.35)

    // Bordes
    static let borderSoft = Color(hex: "EAE1DF").opacity(0.08)
    static let borderMid = Color(hex: "EAE1DF").opacity(0.16)

    // Tracks (slider / progress inactivo)
    static let trackInactive = Color(hex: "29444E")

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
