import SwiftUI

extension Color {
    static let camBackground = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let camSurface = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let camBorder = Color(red: 0.22, green: 0.22, blue: 0.22)
    static let camAccent = Color(red: 0.95, green: 0.85, blue: 0.72)   // warm sand
    static let camAccentSoft = Color(red: 0.95, green: 0.85, blue: 0.72).opacity(0.15)
    static let camPro = Color(red: 0.9, green: 0.75, blue: 0.45)       // gold for pro badge

    static func fromHex(_ hex: String) -> Color {
        var h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if h.count == 6 { h = "FF" + h }
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        return Color(
            red: Double((val & 0xFF0000) >> 16) / 255,
            green: Double((val & 0x00FF00) >> 8) / 255,
            blue: Double(val & 0x0000FF) / 255,
            opacity: Double((val & 0xFF000000) >> 24) / 255
        )
    }
}

extension UIColor {
    static let camBackground = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)
}
