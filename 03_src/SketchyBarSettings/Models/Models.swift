import Foundation

// MARK: - 配置

enum WidgetPlacement: String, CaseIterable, Codable, Identifiable {
    case left, center, right
    var id: String { rawValue }
    var title: String {
        switch self {
        case .left: "左"
        case .center: "中央"
        case .right: "右"
        }
    }
}

// MARK: - バー設定

struct BarSettings: Codable, Equatable {
    var height: Int = 40
    var yOffset: Int = 4
    var cornerRadius: Int = 14
    var backgroundHex: String = "0x00000000"
    var shadow: Bool = false
    var paddingLeft: Int = 3
    var paddingRight: Int = 3
    var itemSpacing: Int = 6
    /// 全ウィジェット共通のカード内部 padding（icon/label.padding）。
    var widgetPadding: Int = 4
    /// Spotify カバー (`spotify_cover`) の一辺サイズ (pt)。
    var spotifyCoverSize: Int = 28
    /// 全ウィジェット共通フォント。
    var fontFamily: String = FontFamilies.defaultFamily
    var fontSize: Int = 13
    /// 適用済み Earth スタイルプリセット ID（永続化用）。
    var selectedStylePresetID: String?

    enum CodingKeys: String, CodingKey {
        case height, yOffset, cornerRadius, backgroundHex, shadow
        case paddingLeft, paddingRight, itemSpacing, widgetPadding, spotifyCoverSize
        case fontFamily, fontSize, selectedStylePresetID
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        height = try c.decodeIfPresent(Int.self, forKey: .height) ?? 40
        yOffset = try c.decodeIfPresent(Int.self, forKey: .yOffset) ?? 4
        cornerRadius = try c.decodeIfPresent(Int.self, forKey: .cornerRadius) ?? 14
        backgroundHex = try c.decodeIfPresent(String.self, forKey: .backgroundHex) ?? "0x00000000"
        shadow = try c.decodeIfPresent(Bool.self, forKey: .shadow) ?? false
        paddingLeft = try c.decodeIfPresent(Int.self, forKey: .paddingLeft) ?? 3
        paddingRight = try c.decodeIfPresent(Int.self, forKey: .paddingRight) ?? 3
        itemSpacing = try c.decodeIfPresent(Int.self, forKey: .itemSpacing) ?? 6
        widgetPadding = try c.decodeIfPresent(Int.self, forKey: .widgetPadding) ?? 4
        spotifyCoverSize = try c.decodeIfPresent(Int.self, forKey: .spotifyCoverSize) ?? 28
        fontFamily = try c.decodeIfPresent(String.self, forKey: .fontFamily) ?? FontFamilies.defaultFamily
        fontSize = try c.decodeIfPresent(Int.self, forKey: .fontSize) ?? 13
        selectedStylePresetID = try c.decodeIfPresent(String.self, forKey: .selectedStylePresetID)
    }
}

// MARK: - 項目（ウィジェット）設定

struct WidgetConfig: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var enabled: Bool = true
    var placement: WidgetPlacement = .center
    var order: Int = 0
    var colorHex: String?
    /// 互換のため読み込み可能。UI の主設定は BarSettings の全体フォント。
    var fontFamily: String?
    var fontSize: Int?
    var showIcon: Bool = true
    var backgroundEnabled: Bool = false
    var backgroundHex: String?
    var paddingLeft: Int = 4
    var paddingRight: Int = 4

    static let panelBackgroundHex = "0xD02A2A37"
    static let spotifyID = "spotify"

    enum CodingKeys: String, CodingKey {
        case id, name, enabled, placement, order
        case colorHex, fontFamily, fontSize, showIcon
        case backgroundEnabled, backgroundHex
        case paddingLeft, paddingRight
    }

    init(
        id: String,
        name: String,
        enabled: Bool = true,
        placement: WidgetPlacement = .center,
        order: Int = 0,
        colorHex: String? = nil,
        fontFamily: String? = nil,
        fontSize: Int? = nil,
        showIcon: Bool = true,
        backgroundEnabled: Bool = false,
        backgroundHex: String? = nil,
        paddingLeft: Int = 4,
        paddingRight: Int = 4
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.placement = placement
        self.order = order
        self.colorHex = colorHex
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.showIcon = showIcon
        self.backgroundEnabled = backgroundEnabled
        self.backgroundHex = backgroundHex
        self.paddingLeft = paddingLeft
        self.paddingRight = paddingRight
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        placement = try c.decodeIfPresent(WidgetPlacement.self, forKey: .placement) ?? .center
        order = try c.decodeIfPresent(Int.self, forKey: .order) ?? 0
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex)
        fontFamily = try c.decodeIfPresent(String.self, forKey: .fontFamily)
        fontSize = try c.decodeIfPresent(Int.self, forKey: .fontSize)
        showIcon = try c.decodeIfPresent(Bool.self, forKey: .showIcon) ?? true
        backgroundEnabled = try c.decodeIfPresent(Bool.self, forKey: .backgroundEnabled) ?? false
        backgroundHex = try c.decodeIfPresent(String.self, forKey: .backgroundHex)
        paddingLeft = try c.decodeIfPresent(Int.self, forKey: .paddingLeft) ?? 4
        paddingRight = try c.decodeIfPresent(Int.self, forKey: .paddingRight) ?? 4
    }

    var isSpotifyGroup: Bool { id == Self.spotifyID }

    static let defaults: [WidgetConfig] = [
        WidgetConfig(
            id: "date", name: "日付", placement: .center, order: 0,
            colorHex: EarthColorCatalog.sand,
            backgroundEnabled: false, backgroundHex: panelBackgroundHex
        ),
        WidgetConfig(
            id: "clock", name: "時刻", placement: .center, order: 1,
            colorHex: EarthColorCatalog.terracotta,
            backgroundEnabled: false, backgroundHex: panelBackgroundHex
        ),
        WidgetConfig(
            id: "ai_usage", name: "AI 使用量", placement: .center, order: 2,
            colorHex: EarthColorCatalog.olive,
            backgroundEnabled: false, backgroundHex: panelBackgroundHex
        ),
        WidgetConfig(id: "umi_icon", name: "umi アイコン", placement: .center, order: 3),
        WidgetConfig(
            id: "umi_status", name: "umi 状態", placement: .center, order: 4,
            backgroundEnabled: false, backgroundHex: panelBackgroundHex
        ),
        WidgetConfig(
            id: "audio_output", name: "オーディオ出力", placement: .center, order: 5,
            colorHex: EarthColorCatalog.clay,
            backgroundEnabled: false, backgroundHex: panelBackgroundHex
        ),
        WidgetConfig(
            id: "volume", name: "音量", placement: .center, order: 6,
            colorHex: EarthColorCatalog.moss,
            backgroundEnabled: false, backgroundHex: panelBackgroundHex
        ),
        WidgetConfig(
            id: "battery", name: "バッテリー", placement: .center, order: 7,
            backgroundEnabled: false, backgroundHex: panelBackgroundHex
        ),
        WidgetConfig(
            id: spotifyID, name: "Spotify", placement: .center, order: 8,
            colorHex: EarthColorCatalog.sand,
            backgroundEnabled: true, backgroundHex: panelBackgroundHex
        ),
    ]
}

struct SettingsDocument: Codable, Equatable {
    var bar: BarSettings
    var widgets: [WidgetConfig]

    init(bar: BarSettings, widgets: [WidgetConfig]) {
        self.bar = bar
        self.widgets = widgets
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bar = try c.decodeIfPresent(BarSettings.self, forKey: .bar) ?? BarSettings()
        widgets = try c.decodeIfPresent([WidgetConfig].self, forKey: .widgets) ?? WidgetConfig.defaults
    }
}

enum SettingsLoadError: Equatable {
    case noData
    case decodeFailed(String)

    var message: String {
        switch self {
        case .noData:
            "保存済み設定がありません。デフォルト値を使用しています。"
        case .decodeFailed(let detail):
            "設定の読み込みに失敗しました: \(detail)"
        }
    }
}

/// TemplateRenderer 向けの純粋な入力。
struct RenderInput: Equatable {
    var bar: BarSettings
    var widgets: [WidgetConfig]

    init(bar: BarSettings, widgets: [WidgetConfig]) {
        self.bar = bar
        self.widgets = widgets
    }

    init(document: SettingsDocument) {
        bar = document.bar
        widgets = document.widgets
    }

    func enabledWidgets(in placement: WidgetPlacement) -> [WidgetConfig] {
        widgets
            .filter { $0.enabled && $0.placement == placement }
            .sorted { $0.order < $1.order }
    }
}

/// UI 一覧表示用。Spotify は 1 グループとして扱う。
enum WidgetDisplayCatalog {
    static func sortedWidgets(from widgets: [WidgetConfig]) -> [WidgetConfig] {
        widgets.sorted {
            if $0.placement == $1.placement {
                return $0.order < $1.order
            }
            return $0.placement.rawValue < $1.placement.rawValue
        }
    }
}
