import SwiftUI

struct EarthColorPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let hex: String

    var displayColor: Color {
        SketchyBarColorHex.color(from: hex, fallbackHex: hex)
    }
}

/// ウィジェットの文字色 + 背景色セット。バー全体の背景は含まない。
struct EarthStylePreset: Identifiable, Equatable {
    let id: String
    let name: String
    let cardBackgroundHex: String
    let textHex: String
    let mutedTextHex: String
    let accentHex: String

    var cardColor: Color {
        SketchyBarColorHex.color(from: cardBackgroundHex, fallbackHex: cardBackgroundHex)
    }

    var textColor: Color {
        SketchyBarColorHex.color(from: textHex, fallbackHex: textHex)
    }
}

enum EarthColorCatalog {
    static let white = "0xFFFFFFFF"
    static let black = "0xFF000000"
    static let sand = "0xFFD8C3A5"
    static let terracotta = "0xFFC97C5D"
    static let olive = "0xFF87986A"
    static let moss = "0xFF606C38"
    static let clay = "0xFF9C6644"

    static let presets: [EarthColorPreset] = [
        EarthColorPreset(id: "white", name: "白", hex: white),
        EarthColorPreset(id: "black", name: "黒", hex: black),
        EarthColorPreset(id: "sand", name: "砂", hex: sand),
        EarthColorPreset(id: "terracotta", name: "テラコッタ", hex: terracotta),
        EarthColorPreset(id: "olive", name: "オリーブ", hex: olive),
        EarthColorPreset(id: "moss", name: "モス", hex: moss),
        EarthColorPreset(id: "clay", name: "クレイ", hex: clay),
        EarthColorPreset(id: "charcoal_brown", name: "チャコールブラウン", hex: "0xFF3C2F2F"),
        EarthColorPreset(id: "deep_forest", name: "深い森", hex: "0xFF283618"),
        EarthColorPreset(id: "transparent", name: "透明", hex: "0x00000000"),
    ]

    static let stylePresets: [EarthStylePreset] = [
        EarthStylePreset(
            id: "dune",
            name: "砂丘",
            cardBackgroundHex: "0xD03C3028",
            textHex: white,
            mutedTextHex: "0xFFE8DCC8",
            accentHex: "0xFFE8DCC8"
        ),
        EarthStylePreset(
            id: "terracotta",
            name: "テラコッタ",
            cardBackgroundHex: "0xD03C2F2F",
            textHex: white,
            mutedTextHex: "0xFFF1DFCB",
            accentHex: "0xFFF1DFCB"
        ),
        EarthStylePreset(
            id: "forest",
            name: "森林",
            cardBackgroundHex: "0xD01F2A20",
            textHex: white,
            mutedTextHex: "0xFFD7E2D0",
            accentHex: "0xFFD7E2D0"
        ),
        EarthStylePreset(
            id: "coastal_stone",
            name: "海岸の石",
            cardBackgroundHex: "0xD02F3838",
            textHex: white,
            mutedTextHex: "0xFFE1E7E5",
            accentHex: "0xFFE1E7E5"
        ),
        EarthStylePreset(
            id: "ink_and_sand",
            name: "墨と砂",
            cardBackgroundHex: "0xD0E1D2B8",
            textHex: "0xFF302A24",
            mutedTextHex: "0xFF655A4D",
            accentHex: "0xFF655A4D"
        ),
    ]

    /// プリセット適用時に muted 色を使うウィジェット。
    static let mutedWidgetIDs: Set<String> = ["date", "ai_usage", "audio_output"]
}
