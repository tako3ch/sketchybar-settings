import AppKit

enum FontFamilies {
    static let defaultFamily = "SF Pro Text"

    static var available: [String] {
        let families = NSFontManager.shared.availableFontFamilies.sorted()
        if families.contains(defaultFamily) {
            return families
        }
        return [defaultFamily] + families
    }
}
