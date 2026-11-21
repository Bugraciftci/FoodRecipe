import SwiftUI

enum CulinaryTheme {
    static let background = Color(red: 0.06, green: 0.07, blue: 0.09)
    static let cardBackground = Color(red: 0.11, green: 0.12, blue: 0.15)
    static let elevatedSurface = Color(red: 0.15, green: 0.17, blue: 0.21)
    static let saffronAccent = Color(red: 0.96, green: 0.52, blue: 0.18)
    static let herbEmerald = Color(red: 0.16, green: 0.78, blue: 0.54)
    static let proteinRose = Color(red: 0.95, green: 0.36, blue: 0.48)
    static let carbAmber = Color(red: 0.98, green: 0.74, blue: 0.24)
    static let fatCyan = Color(red: 0.24, green: 0.72, blue: 0.96)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.68)

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.96, green: 0.52, blue: 0.18),
            Color(red: 0.88, green: 0.31, blue: 0.22)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
