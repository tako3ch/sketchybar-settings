import SwiftUI

/// SketchyBar 中央アイランドの近似プレビュー（適用前確認用）。
/// レイアウト数値は `ResolvedBarLayout` のみを使う。
struct BarPreviewView: View {
    let input: RenderInput

    private var layout: ResolvedBarLayout {
        ResolvedBarLayout.make(from: input)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プレビュー")
                .font(.headline)

            Text("これは適用前のプレビューです。実際の SketchyBar とは微妙に異なる場合があります。")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.06))
                    .frame(height: 120)

                VStack(spacing: 16) {
                    previewBar
                    previewIsland(for: .center)
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var previewBar: some View {
        let barColor = SketchyBarColorHex.color(
            from: layout.barBackgroundHex,
            fallbackHex: SketchyBarColorHex.defaultBarBackground
        )

        return RoundedRectangle(cornerRadius: CGFloat(layout.barCornerRadius))
            .fill(barColor)
            .frame(height: CGFloat(layout.barHeight))
            .shadow(color: layout.barShadow ? .black.opacity(0.25) : .clear, radius: 4, y: 2)
            .overlay {
                Text("バー全体")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
    }

    private func previewIsland(for placement: WidgetPlacement) -> some View {
        let widgets = layout.widgets(in: placement)
        let hasIndividualBackground = widgets.contains {
            $0.backgroundEnabled && $0.hasConfigurableBackground
        }

        return HStack(spacing: CGFloat(layout.itemSpacing)) {
            if hasIndividualBackground {
                ForEach(widgets, id: \.id) { widget in
                    previewWidget(widget)
                }
            } else if !widgets.isEmpty {
                HStack(spacing: CGFloat(layout.itemSpacing)) {
                    ForEach(widgets, id: \.id) { widget in
                        previewWidgetContent(widget, showBackground: false)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: CGFloat(min(layout.barCornerRadius, 10)))
                        .fill(SketchyBarColorHex.color(from: WidgetConfig.panelBackgroundHex, fallbackHex: WidgetConfig.panelBackgroundHex))
                        .overlay(
                            RoundedRectangle(cornerRadius: CGFloat(min(layout.barCornerRadius, 10)))
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
    }

    @ViewBuilder
    private func previewWidget(_ widget: ResolvedWidgetLayout) -> some View {
        if widget.isSpotifyGroup {
            previewSpotifyGroup(widget)
        } else {
            previewWidgetContent(widget, showBackground: widget.backgroundEnabled)
        }
    }

    private func previewSpotifyGroup(_ widget: ResolvedWidgetLayout) -> some View {
        let spotify = widget.spotify
        let coverSize = CGFloat(spotify?.coverSize ?? layout.coverSize)
        let coverCorner = CGFloat(spotify?.coverCornerRadius ?? 4)
        let gap = CGFloat(layout.iconLabelGap)

        return HStack(spacing: gap) {
            if widget.showIcon {
                RoundedRectangle(cornerRadius: coverCorner)
                    .fill(Color.gray.opacity(0.35))
                    .frame(width: coverSize, height: coverSize)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }

            HStack(spacing: gap) {
                Text("♫")
                    .font(previewFont)
                    .foregroundStyle(previewColor(widget: widget))
                Text("Now Playing — Song Title")
                    .font(previewFont)
                    .foregroundStyle(previewColor(widget: widget))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, CGFloat(layout.widgetPadding))
        .frame(height: CGFloat(layout.cardHeight))
        .background(widgetBackgroundShape(widget, enabled: widget.backgroundEnabled))
    }

    private func previewWidgetContent(
        _ widget: ResolvedWidgetLayout,
        showBackground: Bool
    ) -> some View {
        HStack(spacing: CGFloat(layout.iconLabelGap)) {
            if widget.hasIcon || (widget.isImageItem && widget.showIcon), let icon = previewIcon(for: widget) {
                Text(icon)
                    .font(previewFont)
                    .foregroundStyle(previewColor(widget: widget))
            }
            Text(previewLabel(for: widget))
                .font(previewFont)
                .foregroundStyle(previewColor(widget: widget))
                .lineLimit(1)
        }
        .padding(.horizontal, CGFloat(layout.widgetPadding))
        .frame(height: CGFloat(layout.cardHeight))
        .background(widgetBackgroundShape(widget, enabled: showBackground))
    }

    @ViewBuilder
    private func widgetBackgroundShape(_ widget: ResolvedWidgetLayout, enabled: Bool) -> some View {
        if enabled, widget.hasConfigurableBackground {
            RoundedRectangle(cornerRadius: CGFloat(layout.cardCornerRadius))
                .fill(SketchyBarColorHex.color(from: widget.backgroundHex, fallbackHex: WidgetConfig.panelBackgroundHex))
        }
    }

    private var previewFont: Font {
        .custom(layout.fontFamily, size: CGFloat(layout.fontSize))
    }

    private func previewColor(widget: ResolvedWidgetLayout) -> Color {
        let hex = widget.colorHex ?? SketchyBarColorHex.defaultWidgetColor
        return SketchyBarColorHex.color(from: hex, fallbackHex: SketchyBarColorHex.defaultWidgetColor)
    }

    private func previewLabel(for widget: ResolvedWidgetLayout) -> String {
        switch widget.id {
        case "date": "8月20日(水)"
        case "clock": "16:30"
        case "ai_usage": "AI 42%"
        case "umi_status": "umi 稼働中"
        case "audio_output": "MacBook Pro"
        case "volume": "72%"
        case "battery": "85%"
        case "umi_icon": ""
        default: widget.name
        }
    }

    private func previewIcon(for widget: ResolvedWidgetLayout) -> String? {
        switch widget.id {
        case "date", "clock", "ai_usage", "umi_status", "battery": return nil
        case "audio_output": return "◉"
        case "volume": return "♪"
        case "umi_icon": return "●"
        default: return nil
        }
    }
}
