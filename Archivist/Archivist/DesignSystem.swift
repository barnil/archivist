import SwiftUI

// MARK: - Palette
// Beige/olive/cream palette from the design brief. Kept deliberately small.
enum RetroPalette {
    static let background = Color(hex: "D8D2B8")
    static let panel      = Color(hex: "ECE7CF")
    static let textDark   = Color(hex: "25251F")
    static let accent     = Color(hex: "4E6651")   // primary green
    static let warning    = Color(hex: "A65D45")   // rust/orange
    static let highlight  = Color(hex: "E8C96A")   // mustard yellow

    // Derived bevel shades used by RetroButton/RetroPanel for the
    // light-top-left / dark-bottom-right "physical" 3D border effect.
    static let bevelLight = Color(hex: "FFFDEF")
    static let bevelDark  = Color(hex: "8A836A")
}

extension Color {
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography
// "Pixel" font is used for headings/buttons/labels only, per the brief —
// body copy stays on a normal monospaced system font for legibility.
//
// To get a true bitmap look, download a font such as "Departure Mono",
// "Silkscreen" or "Pixel Operator" (all free), drag the .ttf into the
// Xcode project (check "copy items if needed"), and add an
// "Fonts provided by application" (UIAppFonts-equivalent key is
// "ATSApplicationFontsPath" on macOS — simplest is to just add the file
// to the target; Xcode registers it automatically for app-only use).
// Then swap the string below to match the font's PostScript name.
enum RetroFont {
    static let pixelFamily = "Departure Mono" // fallback below if not installed

    static func pixel(_ size: CGFloat) -> Font {
        if NSFontManager.shared.availableFontFamilies.contains(pixelFamily) {
            return .custom(pixelFamily, size: size)
        }
        return .system(size: size, weight: .bold, design: .monospaced)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Metrics
enum RetroMetrics {
    static let borderWidth: CGFloat = 2
    static let cornerRadius: CGFloat = 0 // hard corners, no rounding
    static let panelPadding: CGFloat = 14
    static let pressedOffset: CGFloat = 2
}//
//  DesignSystem.swift
//  Archivist
//
//  Created by Barnil Mahanta on 21/09/26.
//

