import Foundation

enum WidgetCatalog {
    struct Entry {
        let id: String
        let script: String
        let updateFreq: Int
        let icon: String
        var isImageItem = false
        var imagePath: String?
        var clickScript: String?
        var subscribe: [String] = []
        var extraSetLines: [String] = []
        var companions: [Companion] = []
    }

    struct Companion {
        let id: String
        let script: String
        let clickScript: String?
        let extraSetLines: [String]
    }

    static let spotifyGroupBracketID = "spotify_group"
    static let spotifyCoverID = "spotify_cover"

    static let entries: [Entry] = [
        Entry(id: "date", script: "date.sh", updateFreq: 60, icon: "",
              extraSetLines: ["icon.drawing=off", "label.color=\"$MUTED\""]),
        Entry(id: "clock", script: "clock.sh", updateFreq: 10, icon: "",
              extraSetLines: ["icon.drawing=off", "label.color=\"$TEXT\""]),
        Entry(id: "ai_usage", script: "ai-usage.py", updateFreq: 120, icon: "",
              extraSetLines: ["icon.drawing=off", "label.max_chars=48", "label.color=\"$MUTED\""]),
        Entry(id: "umi_icon", script: "", updateFreq: 0, icon: "",
              isImageItem: true,
              imagePath: "$CONFIG_DIR/assets/umi-status.png",
              clickScript: "open -a UmiWorkspace",
              extraSetLines: [
                  "icon.drawing=off",
                  "label.drawing=off",
                  "background.color=0x00000000",
              ]),
        Entry(id: "umi_status", script: "umi-status.sh", updateFreq: 30, icon: "",
              clickScript: "$PLUGIN_DIR/umi-menu.sh",
              extraSetLines: [
                  "icon.drawing=off",
                  "label.color=\"$TEXT\"",
                  "popup.align=right",
                  "popup.background.border_width=1",
                  "popup.background.border_color=\"$BG_SURFACE\"",
                  "popup.background.color=\"$PANEL_COLOR\"",
                  "popup.background.corner_radius=10",
                  "popup.background.shadow.drawing=on",
              ]),
        Entry(id: "audio_output", script: "audio-output.sh", updateFreq: 30, icon: "◉",
              extraSetLines: ["icon.color=\"$ACCENT\"", "label.max_chars=22", "label.color=\"$MUTED\""]),
        Entry(id: "volume", script: "volume.sh", updateFreq: 10, icon: "♪",
              subscribe: ["volume_change"],
              extraSetLines: ["icon.color=\"$ACCENT\""]),
        Entry(id: "battery", script: "battery.sh", updateFreq: 120, icon: "",
              subscribe: ["system_woke", "power_source_change"],
              extraSetLines: ["icon=\"\""]),
        Entry(id: "spotify", script: "spotify.sh", updateFreq: 2, icon: "♫",
              clickScript: "$PLUGIN_DIR/spotify-toggle.sh",
              subscribe: ["media_change"],
              extraSetLines: [
                  "drawing=off",
                  "icon.color=\"$FG_SECONDARY\"",
                  "label.color=\"$TEXT\"",
                  "label.max_chars=42",
              ],
              companions: [
                Companion(
                    id: "spotify_cover",
                    script: "spotify.sh",
                    clickScript: "$PLUGIN_DIR/spotify-toggle.sh",
                    extraSetLines: [
                        "drawing=off",
                        "width=28",
                        "background.drawing=off",
                        "background.image.drawing=off",
                        "background.image.scale=0.05",
                        "background.image.corner_radius=9",
                    ]
                ),
            ]),
    ]

    static func entry(for id: String) -> Entry? {
        entries.first { $0.id == id }
    }
}

enum SketchyBarFont {
    static func labelFont(family: String, size: Int) -> String {
        let escapedFamily = family
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\(escapedFamily):Medium:\(size).0"
    }
}

enum BarTheme {
    static let text = "0xFFDCD7BA"
    static let muted = "0xFFC8C093"
    static let panel = "0xD02A2A37"
    static let surface = "0xFF2A2A37"
}

enum TemplateRenderError: Error, Equatable {
    case templateNotFound(String)
    case templateReadFailed(String)
}

protocol TemplateLoading {
    func loadTemplate(named name: String) throws -> String
}

private final class BundleLocator {}

struct BundleTemplateLoader: TemplateLoading {
    let bundle: Bundle
    let templateName: String

    init(bundle: Bundle = Bundle(for: BundleLocator.self), templateName: String = "sketchybarrc") {
        self.bundle = bundle
        self.templateName = templateName
    }

    func loadTemplate(named name: String) throws -> String {
        let resourceName = name.hasSuffix(".template") ? String(name.dropLast(".template".count)) : name
        guard let url = bundle.url(forResource: resourceName, withExtension: "template") else {
            throw TemplateRenderError.templateNotFound(name)
        }
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw TemplateRenderError.templateReadFailed(error.localizedDescription)
        }
    }
}

struct StringTemplateLoader: TemplateLoading {
    let template: String

    func loadTemplate(named name: String) throws -> String {
        template
    }
}

enum TemplatePlaceholderValues {
    static func make(from input: RenderInput) -> [String: String] {
        let layout = ResolvedBarLayout.make(from: input)

        return [
            "BAR_HEIGHT": String(layout.barHeight),
            "BAR_Y_OFFSET": String(layout.barYOffset),
            "BAR_CORNER_RADIUS": String(layout.barCornerRadius),
            "BAR_BACKGROUND_HEX": layout.barBackgroundHex,
            "BAR_SHADOW": layout.barShadow ? "on" : "off",
            "BAR_PADDING_LEFT": String(layout.barPaddingLeft),
            "BAR_PADDING_RIGHT": String(layout.barPaddingRight),
            "BAR_ICON_PADDING": "0",
            "WIDGET_BLOCKS": WidgetSectionRenderer.render(layout),
            "BRACKET_BLOCKS": BracketSectionRenderer.render(layout),
        ]
    }

    static func apply(_ template: String, values: [String: String]) -> String {
        values
            .sorted { $0.key.count > $1.key.count }
            .reduce(template) { result, pair in
                result.replacingOccurrences(of: "{{\(pair.key)}}", with: pair.value)
            }
    }

    static func sanitizeHex(_ value: String, fallback: String) -> String {
        SketchyBarColorHex.sanitized(value, fallback: fallback)
    }
}

enum WidgetSectionRenderer {
    static func render(_ layout: ResolvedBarLayout) -> String {
        var blocks: [String] = []

        for placement in [WidgetPlacement.left, .center, .right] {
            for widget in layout.widgets(in: placement) {
                blocks.append(renderWidget(widget))
            }
        }

        return blocks.joined()
    }

    private static func renderWidget(
        _ widget: ResolvedWidgetLayout
    ) -> String {
        guard let entry = WidgetCatalog.entry(for: widget.id) else { return "" }

        if widget.isSpotifyGroup {
            return renderSpotifyGroup(widget: widget, entry: entry)
        }

        return renderPrimary(widget, entry: entry)
    }

    private static func renderSpotifyGroup(
        widget: ResolvedWidgetLayout,
        entry: WidgetCatalog.Entry
    ) -> String {
        guard let spotify = widget.spotify else { return "" }
        var blocks: [String] = []

        if spotify.showCover {
            for companion in entry.companions {
                blocks.append(renderSpotifyCoverCompanion(
                    companion,
                    widget: widget,
                    spotify: spotify
                ))
            }
        }

        blocks.append(renderSpotifyTitleItem(widget: widget, entry: entry, spotify: spotify))

        if spotify.showCover, widget.backgroundEnabled {
            blocks.append(renderSpotifySharedBackground(widget: widget, spotify: spotify))
        }

        return blocks.joined()
    }

    private static func renderSpotifyCoverCompanion(
        _ companion: WidgetCatalog.Companion,
        widget: ResolvedWidgetLayout,
        spotify: ResolvedSpotifyLayout
    ) -> String {
        var lines = filteredExtraSetLines(companion.extraSetLines, widget: widget)

        lines = lines.map { line in
            switch line {
            case "width=28": "width=\(spotify.coverSize)"
            case let value where value.hasPrefix("background.image.scale="):
                "background.image.scale=\(spotify.imageScale)"
            case let value where value.hasPrefix("background.image.corner_radius="):
                "background.image.corner_radius=\(spotify.coverCornerRadius)"
            default: line
            }
        }

        lines.append("width=\(spotify.coverSize)")
        lines.append("padding_left=\(spotify.coverPaddingLeft)")
        lines.append("padding_right=\(spotify.coverPaddingRight)")
        lines.append("background.drawing=on")
        lines.append("background.color=\"\(spotify.coverBackgroundHex)\"")
        lines.append("background.height=\(spotify.cardHeight)")
        lines.append("background.image.scale=\(spotify.imageScale)")
        lines.append("background.image.corner_radius=\(spotify.coverCornerRadius)")
        lines.append(contentsOf: fontSetLines(for: widget))

        lines.append("script=\"$PLUGIN_DIR/\(companion.script)\"")
        lines.append("update_freq=2")
        if let clickScript = companion.clickScript {
            lines.append("click_script=\"\(clickScript)\"")
        }

        lines = uniquedSetLines(lines)

        var out = "sketchybar --add item \(companion.id) \(widget.placement.rawValue) \\\n"
        out += "  --set \(companion.id) \\\n"
        out += lines.map { "    \($0) \\" }.joined(separator: "\n")
        out += "\n\n"
        return out
    }

    private static func renderSpotifyTitleItem(
        widget: ResolvedWidgetLayout,
        entry: WidgetCatalog.Entry,
        spotify: ResolvedSpotifyLayout
    ) -> String {
        var lines = filteredExtraSetLines(entry.extraSetLines, widget: widget)

        lines.append("icon=\"\(entry.icon)\"")
        lines.append("icon.drawing=off")

        if let hex = widget.colorHex {
            lines.append("label.color=\"\(hex)\"")
            lines.append("icon.color=\"\(hex)\"")
        }

        lines.append(contentsOf: fontSetLines(for: widget))
        lines.append("icon.padding_left=\(spotify.titleIconPaddingLeft)")
        lines.append("icon.padding_right=\(spotify.titleIconPaddingRight)")
        lines.append("label.padding_left=\(spotify.titleLabelPaddingLeft)")
        lines.append("label.padding_right=\(spotify.titleLabelPaddingRight)")
        lines.append("padding_left=\(spotify.titlePaddingLeft)")
        lines.append("padding_right=\(spotify.titlePaddingRight)")

        if spotify.showCover {
            lines.append("background.drawing=off")
        } else if let backgroundLines = widgetBackgroundLines(for: widget) {
            lines.append(contentsOf: backgroundLines)
        }

        if entry.updateFreq > 0 {
            lines.append("update_freq=\(entry.updateFreq)")
        }
        if !entry.script.isEmpty {
            lines.append("script=\"$PLUGIN_DIR/\(entry.script)\"")
        }
        if let clickScript = entry.clickScript {
            lines.append("click_script=\"\(clickScript)\"")
        }

        lines = uniquedSetLines(lines)

        var out = "sketchybar --add item \(widget.id) \(widget.placement.rawValue) \\\n"
        out += "  --set \(widget.id) \\\n"
        out += lines.map { "    \($0) \\" }.joined(separator: "\n")
        out += "\n"

        if !entry.subscribe.isEmpty {
            out += "  --subscribe \(widget.id) \(entry.subscribe.joined(separator: " "))\n"
        }
        out += "\n"
        return out
    }

    /// 共有カード背景。center_status のメンバーにはせず、leaf item だけを括る。
    private static func renderSpotifySharedBackground(
        widget: ResolvedWidgetLayout,
        spotify: ResolvedSpotifyLayout
    ) -> String {
        let lines: [String] = [
            "background.drawing=on",
            "background.color=\"\(widget.backgroundHex)\"",
            "background.corner_radius=\(spotify.cardCornerRadius)",
            "background.height=\(spotify.cardHeight)",
        ]

        var out = "sketchybar --add bracket \(WidgetCatalog.spotifyGroupBracketID) \(WidgetCatalog.spotifyCoverID) \(widget.id) \\\n"
        out += "  --set \(WidgetCatalog.spotifyGroupBracketID) \\\n"
        out += lines.map { "    \($0) \\" }.joined(separator: "\n")
        out += "\n\n"
        return out
    }

    private static func renderPrimary(
        _ widget: ResolvedWidgetLayout,
        entry: WidgetCatalog.Entry
    ) -> String {
        let placement = widget.placement.rawValue
        var lines: [String] = []

        lines.append(contentsOf: filteredExtraSetLines(entry.extraSetLines, widget: widget))

        if entry.isImageItem {
            lines.append("width=28")
            lines.append("background.height=28")
            lines.append("background.corner_radius=6")
            if let imagePath = entry.imagePath {
                lines.append("background.image=\"\(imagePath)\"")
            }
            lines.append("background.image.drawing=on")
            lines.append("background.image.scale=0.35")
            lines.append("background.image.corner_radius=6")
        } else if widget.showIcon, !entry.icon.isEmpty {
            lines.append("icon=\"\(entry.icon)\"")
        } else if !entry.icon.isEmpty {
            lines.append("icon=\"\(entry.icon)\"")
            lines.append("icon.drawing=off")
        } else {
            lines.append("icon.drawing=off")
        }

        if let backgroundLines = widgetBackgroundLines(for: widget) {
            lines.append(contentsOf: backgroundLines)
        }

        if let hex = widget.colorHex {
            lines.append("label.color=\"\(hex)\"")
            lines.append("icon.color=\"\(hex)\"")
        }

        lines.append(contentsOf: fontSetLines(for: widget))
        lines.append("icon.padding_left=\(widget.iconPaddingLeft)")
        lines.append("icon.padding_right=\(widget.iconPaddingRight)")
        lines.append("label.padding_left=\(widget.labelPaddingLeft)")
        lines.append("label.padding_right=\(widget.labelPaddingRight)")
        lines.append("padding_left=\(widget.outerPaddingLeft)")
        lines.append("padding_right=\(widget.outerPaddingRight)")

        if entry.updateFreq > 0 {
            lines.append("update_freq=\(entry.updateFreq)")
        }
        if !entry.script.isEmpty {
            lines.append("script=\"$PLUGIN_DIR/\(entry.script)\"")
        }
        if let clickScript = entry.clickScript {
            lines.append("click_script=\"\(clickScript)\"")
        }

        lines = uniquedSetLines(lines)

        var out = "sketchybar --add item \(widget.id) \(placement) \\\n"
        out += "  --set \(widget.id) \\\n"
        out += lines.map { "    \($0) \\" }.joined(separator: "\n")
        out += "\n"

        if !entry.subscribe.isEmpty {
            out += "  --subscribe \(widget.id) \(entry.subscribe.joined(separator: " "))\n"
        }
        out += "\n"
        return out
    }

    private static func filteredExtraSetLines(
        _ lines: [String],
        widget: ResolvedWidgetLayout
    ) -> [String] {
        var filtered = lines

        if widget.hasConfigurableBackground || widget.isSpotifyGroup {
            filtered = filtered.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("background.image.") { return true }
                if trimmed == "background.drawing=on" || trimmed == "background.drawing=off" { return false }
                if trimmed.hasPrefix("background.color") { return false }
                if trimmed.hasPrefix("background.corner_radius") { return false }
                if trimmed.hasPrefix("background.height") { return false }
                if trimmed.hasPrefix("background.padding_left") { return false }
                if trimmed.hasPrefix("background.padding_right") { return false }
                if trimmed.hasPrefix("padding_left=") { return false }
                if trimmed.hasPrefix("padding_right=") { return false }
                if trimmed.hasPrefix("width=") { return false }
                return true
            }
        }

        if widget.colorHex != nil {
            filtered = filtered.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("label.color") { return false }
                if trimmed.hasPrefix("icon.color") { return false }
                return true
            }
        }

        return filtered
    }

    private static func fontSetLines(for widget: ResolvedWidgetLayout) -> [String] {
        let font = SketchyBarFont.labelFont(family: widget.fontFamily, size: widget.fontSize)
        return [
            "label.font=\"\(font)\"",
            "icon.font=\"\(font)\"",
        ]
    }

    private static func widgetBackgroundLines(for widget: ResolvedWidgetLayout) -> [String]? {
        guard widget.hasConfigurableBackground else { return nil }

        if !widget.backgroundEnabled {
            return ["background.drawing=off"]
        }

        return [
            "background.drawing=on",
            "background.color=\"\(widget.backgroundHex)\"",
            "background.corner_radius=\(widget.cardCornerRadius)",
            "background.height=\(widget.cardHeight)",
        ]
    }

    private static func uniquedSetLines(_ lines: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for line in lines {
            let key: String
            if let eq = line.firstIndex(of: "=") {
                key = String(line[..<eq])
            } else {
                key = line
            }
            if seen.contains(key) { continue }
            seen.insert(key)
            result.append(line)
        }
        return result
    }
}

enum BracketSectionRenderer {
    static func render(_ layout: ResolvedBarLayout) -> String {
        let centerWidgets = layout.center
        let rightWidgets = layout.right

        let centerIDs = centerWidgets.flatMap { bracketMembers(for: $0) }
        let rightIDs = rightWidgets.flatMap { bracketMembers(for: $0) }

        var out = ""
        if !centerIDs.isEmpty {
            out += renderBracket(
                name: "center_status",
                members: centerIDs,
                widgets: centerWidgets,
                cornerRadius: min(layout.barCornerRadius, 10),
                height: layout.barHeight - 8
            )
            out += "sketchybar --reorder \(centerIDs.joined(separator: " "))\n\n"
        }

        if !rightIDs.isEmpty {
            out += renderBracket(
                name: "status",
                members: rightIDs,
                widgets: rightWidgets,
                cornerRadius: min(layout.barCornerRadius, 10),
                height: layout.barHeight - 8
            )
        }

        return out
    }

    private static func bracketMembers(for widget: ResolvedWidgetLayout) -> [String] {
        if widget.isSpotifyGroup, widget.spotify?.showCover == true {
            return [WidgetCatalog.spotifyCoverID, widget.id]
        }
        return [widget.id]
    }

    /// 個別ウィジェット背景が1つでも有効な bracket では共通背景を off にし、
    /// 各ウィジェットのカード背景が見えるようにする。全て off のときだけ従来のアイランド背景を使う。
    private static func renderBracket(
        name: String,
        members: [String],
        widgets: [ResolvedWidgetLayout],
        cornerRadius: Int,
        height: Int
    ) -> String {
        let hasIndividualBackground = widgets.contains {
            $0.backgroundEnabled && $0.hasConfigurableBackground
        }

        var out = "sketchybar --add bracket \(name) \(members.joined(separator: " ")) \\\n"
        out += "  --set \(name) \\\n"

        if hasIndividualBackground {
            out += "    background.drawing=off\n\n"
            return out
        }

        out += "    background.drawing=on \\\n"
        out += "    background.color=\"$PANEL_COLOR\" \\\n"
        out += "    background.corner_radius=\(cornerRadius) \\\n"
        out += "    background.height=\(height) \\\n"
        out += "    background.border_width=1 \\\n"
        out += "    background.border_color=0x40727169\n\n"
        return out
    }
}

enum TemplateRenderer {
    static let templateFileName = "sketchybarrc.template"

    static func render(
        _ input: RenderInput,
        loader: TemplateLoading = BundleTemplateLoader()
    ) throws -> String {
        let template = try loader.loadTemplate(named: templateFileName)
        let values = TemplatePlaceholderValues.make(from: input)
        return TemplatePlaceholderValues.apply(template, values: values)
    }
}
