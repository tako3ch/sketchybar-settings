import SwiftUI
import AppKit

/// SketchyBar の `0xAARRGGBB` 形式と SwiftUI Color の相互変換。
enum SketchyBarColorHex {
    static let defaultBarBackground = "0x00000000"
    static let defaultWidgetColor = "0xFFDCD7BA"

    static func isValid(_ value: String) -> Bool {
        parse(value) != nil
    }

    /// 不正な値は `fallback` を返す。
    static func sanitized(_ value: String, fallback: String) -> String {
        guard let components = parse(value) else { return fallback }
        return format(components)
    }

    static func parse(_ hex: String) -> (a: UInt8, r: UInt8, g: UInt8, b: UInt8)? {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = /^0x([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/
        guard let match = trimmed.wholeMatch(of: pattern) else { return nil }

        let digits = String(match.output.1)
        if digits.count == 6 {
            guard let rgb = UInt32(digits, radix: 16) else { return nil }
            return (
                a: 255,
                r: UInt8((rgb >> 16) & 0xFF),
                g: UInt8((rgb >> 8) & 0xFF),
                b: UInt8(rgb & 0xFF)
            )
        }

        guard let argb = UInt32(digits, radix: 16) else { return nil }
        return (
            a: UInt8((argb >> 24) & 0xFF),
            r: UInt8((argb >> 16) & 0xFF),
            g: UInt8((argb >> 8) & 0xFF),
            b: UInt8(argb & 0xFF)
        )
    }

    static func format(_ components: (a: UInt8, r: UInt8, g: UInt8, b: UInt8)) -> String {
        String(format: "0x%02X%02X%02X%02X", components.a, components.r, components.g, components.b)
    }

    static func color(from hex: String, fallbackHex: String = defaultBarBackground) -> Color {
        let sanitized = sanitized(hex, fallback: fallbackHex)
        guard let components = parse(sanitized) else { return .clear }
        return Color(
            .sRGB,
            red: Double(components.r) / 255,
            green: Double(components.g) / 255,
            blue: Double(components.b) / 255,
            opacity: Double(components.a) / 255
        )
    }

    static func hex(from color: Color) -> String {
        guard let components = rgbaComponents(from: color) else {
            return defaultBarBackground
        }
        return format((
            a: UInt8(clamping: Int((components.opacity * 255).rounded())),
            r: UInt8(clamping: Int((components.red * 255).rounded())),
            g: UInt8(clamping: Int((components.green * 255).rounded())),
            b: UInt8(clamping: Int((components.blue * 255).rounded()))
        ))
    }

    private static func rgbaComponents(from color: Color) -> (red: Double, green: Double, blue: Double, opacity: Double)? {
        #if canImport(AppKit)
        let nsColor = NSColor(color)
        guard let converted = nsColor.usingColorSpace(.sRGB) else { return nil }
        return (
            red: Double(converted.redComponent),
            green: Double(converted.greenComponent),
            blue: Double(converted.blueComponent),
            opacity: Double(converted.alphaComponent)
        )
        #else
        return nil
        #endif
    }
}
