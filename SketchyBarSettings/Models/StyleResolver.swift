import Foundation

/// TemplateRenderer とプレビューで共有するスタイル解釈。
/// 数値と Hex のみを持ち、SwiftUI Color は保持しない。
enum StyleResolver {
    /// WidgetConfig.fontFamily は互換読み込み専用。生成・プレビューは BarSettings のみ使う。
    static func resolvedFontFamily(widget _: WidgetConfig, bar: BarSettings) -> String {
        bar.fontFamily
    }

    /// WidgetConfig.fontSize は互換読み込み専用。生成・プレビューは BarSettings のみ使う。
    static func resolvedFontSize(widget _: WidgetConfig, bar: BarSettings) -> Int {
        bar.fontSize
    }

    static func resolvedLabelColorHex(widget: WidgetConfig) -> String? {
        guard let hex = widget.colorHex, !hex.isEmpty else { return nil }
        return SketchyBarColorHex.sanitized(hex, fallback: SketchyBarColorHex.defaultWidgetColor)
    }

    static func layout(from input: RenderInput) -> ResolvedBarLayout {
        ResolvedBarLayout.make(from: input)
    }
}

struct ResolvedBarLayout: Equatable {
    var barHeight: Int
    var barYOffset: Int
    var barCornerRadius: Int
    var barBackgroundHex: String
    var barShadow: Bool
    var barPaddingLeft: Int
    var barPaddingRight: Int
    var widgetPadding: Int
    var itemSpacing: Int
    var iconLabelGap: Int
    var fontFamily: String
    var fontSize: Int
    var cardHeight: Int
    var cardCornerRadius: Int
    var coverSize: Int
    var left: [ResolvedWidgetLayout]
    var center: [ResolvedWidgetLayout]
    var right: [ResolvedWidgetLayout]

    var allWidgets: [ResolvedWidgetLayout] {
        left + center + right
    }

    func widgets(in placement: WidgetPlacement) -> [ResolvedWidgetLayout] {
        switch placement {
        case .left: left
        case .center: center
        case .right: right
        }
    }

    static func make(from input: RenderInput) -> ResolvedBarLayout {
        let bar = input.bar
        let metrics = WidgetBackgroundMetrics.make(barHeight: bar.height, barCornerRadius: bar.cornerRadius)
        let widgetPadding = ItemLayoutMetrics.widgetInnerPadding(bar.widgetPadding)
        let itemSpacing = max(bar.itemSpacing, 0)
        let iconLabelGap = ItemLayoutMetrics.iconLabelGap
        let cover = SpotifyCoverMetrics.make(requestedSize: bar.spotifyCoverSize, cardHeight: metrics.cardHeight)

        func resolve(_ widgets: [WidgetConfig]) -> [ResolvedWidgetLayout] {
            widgets.enumerated().map { index, widget in
                ResolvedWidgetLayout.make(
                    widget: widget,
                    bar: bar,
                    cardHeight: metrics.cardHeight,
                    cardCornerRadius: metrics.cardCornerRadius,
                    widgetPadding: widgetPadding,
                    itemSpacing: itemSpacing,
                    iconLabelGap: iconLabelGap,
                    cover: cover,
                    isFirst: index == 0,
                    isLast: index == widgets.count - 1
                )
            }
        }

        return ResolvedBarLayout(
            barHeight: bar.height,
            barYOffset: bar.yOffset,
            barCornerRadius: bar.cornerRadius,
            barBackgroundHex: SketchyBarColorHex.sanitized(
                bar.backgroundHex,
                fallback: SketchyBarColorHex.defaultBarBackground
            ),
            barShadow: bar.shadow,
            barPaddingLeft: bar.paddingLeft,
            barPaddingRight: bar.paddingRight,
            widgetPadding: widgetPadding,
            itemSpacing: itemSpacing,
            iconLabelGap: iconLabelGap,
            fontFamily: bar.fontFamily,
            fontSize: bar.fontSize,
            cardHeight: metrics.cardHeight,
            cardCornerRadius: metrics.cardCornerRadius,
            coverSize: cover.width,
            left: resolve(input.enabledWidgets(in: .left)),
            center: resolve(input.enabledWidgets(in: .center)),
            right: resolve(input.enabledWidgets(in: .right))
        )
    }
}

struct ResolvedWidgetLayout: Equatable {
    var id: String
    var name: String
    var placement: WidgetPlacement
    var showIcon: Bool
    var hasIcon: Bool
    var isImageItem: Bool
    var isSpotifyGroup: Bool
    var colorHex: String?
    var backgroundEnabled: Bool
    var backgroundHex: String
    var fontFamily: String
    var fontSize: Int
    var cardHeight: Int
    var cardCornerRadius: Int
    var iconPaddingLeft: Int
    var iconPaddingRight: Int
    var labelPaddingLeft: Int
    var labelPaddingRight: Int
    var outerPaddingLeft: Int
    var outerPaddingRight: Int
    var spotify: ResolvedSpotifyLayout?

    var hasConfigurableBackground: Bool {
        id != "umi_icon"
    }

    static func make(
        widget: WidgetConfig,
        bar: BarSettings,
        cardHeight: Int,
        cardCornerRadius: Int,
        widgetPadding: Int,
        itemSpacing: Int,
        iconLabelGap: Int,
        cover: SpotifyCoverMetrics.Result,
        isFirst: Bool,
        isLast: Bool
    ) -> ResolvedWidgetLayout {
        let entry = WidgetCatalog.entry(for: widget.id)
        let isImageItem = entry?.isImageItem ?? (widget.id == "umi_icon")
        let isSpotifyGroup = widget.isSpotifyGroup
        let hasIcon: Bool = {
            if isImageItem { return false }
            if isSpotifyGroup { return true }
            guard widget.showIcon else { return false }
            return !(entry?.icon ?? "").isEmpty
        }()
        let content = ItemLayoutMetrics.contentPadding(
            hasIcon: hasIcon && !isSpotifyGroup,
            widgetPadding: widgetPadding,
            iconLabelGap: iconLabelGap
        )
        let outer = ItemLayoutMetrics.outerPadding(
            itemSpacing: itemSpacing,
            isFirst: isFirst,
            isLast: isLast
        )
        let backgroundHex = SketchyBarColorHex.sanitized(
            widget.backgroundHex ?? WidgetConfig.panelBackgroundHex,
            fallback: WidgetConfig.panelBackgroundHex
        )
        let showCover = isSpotifyGroup && widget.showIcon
        let spotify: ResolvedSpotifyLayout? = isSpotifyGroup
            ? ResolvedSpotifyLayout.make(
                cover: cover,
                cardHeight: cardHeight,
                cardCornerRadius: cardCornerRadius,
                widgetPadding: widgetPadding,
                iconLabelGap: iconLabelGap,
                outer: outer,
                showCover: showCover
            )
            : nil

        return ResolvedWidgetLayout(
            id: widget.id,
            name: widget.name,
            placement: widget.placement,
            showIcon: widget.showIcon,
            hasIcon: hasIcon,
            isImageItem: isImageItem,
            isSpotifyGroup: isSpotifyGroup,
            colorHex: StyleResolver.resolvedLabelColorHex(widget: widget),
            backgroundEnabled: widget.backgroundEnabled && widget.id != "umi_icon",
            backgroundHex: backgroundHex,
            fontFamily: StyleResolver.resolvedFontFamily(widget: widget, bar: bar),
            fontSize: StyleResolver.resolvedFontSize(widget: widget, bar: bar),
            cardHeight: cardHeight,
            cardCornerRadius: cardCornerRadius,
            iconPaddingLeft: content.iconLeft,
            iconPaddingRight: content.iconRight,
            labelPaddingLeft: content.labelLeft,
            labelPaddingRight: content.labelRight,
            outerPaddingLeft: outer.left,
            outerPaddingRight: outer.right,
            spotify: spotify
        )
    }
}

struct ResolvedSpotifyLayout: Equatable {
    var coverSize: Int
    var coverCornerRadius: Int
    var imageScale: String
    var cardHeight: Int
    var cardCornerRadius: Int
    var showCover: Bool
    var coverBackgroundHex: String
    var coverPaddingLeft: Int
    var coverPaddingRight: Int
    var titlePaddingLeft: Int
    var titlePaddingRight: Int
    var titleIconPaddingLeft: Int
    var titleIconPaddingRight: Int
    var titleLabelPaddingLeft: Int
    var titleLabelPaddingRight: Int

    static func make(
        cover: SpotifyCoverMetrics.Result,
        cardHeight: Int,
        cardCornerRadius: Int,
        widgetPadding: Int,
        iconLabelGap: Int,
        outer: ItemLayoutMetrics.OuterPadding,
        showCover: Bool
    ) -> ResolvedSpotifyLayout {
        if showCover {
            return ResolvedSpotifyLayout(
                coverSize: cover.width,
                coverCornerRadius: cover.cornerRadius,
                imageScale: cover.imageScale,
                cardHeight: cardHeight,
                cardCornerRadius: cardCornerRadius,
                showCover: true,
                coverBackgroundHex: ItemLayoutMetrics.transparentHex,
                coverPaddingLeft: widgetPadding,
                coverPaddingRight: 0,
                titlePaddingLeft: 0,
                titlePaddingRight: outer.right,
                titleIconPaddingLeft: iconLabelGap,
                titleIconPaddingRight: iconLabelGap,
                titleLabelPaddingLeft: iconLabelGap,
                titleLabelPaddingRight: widgetPadding
            )
        }

        return ResolvedSpotifyLayout(
            coverSize: cover.width,
            coverCornerRadius: cover.cornerRadius,
            imageScale: cover.imageScale,
            cardHeight: cardHeight,
            cardCornerRadius: cardCornerRadius,
            showCover: false,
            coverBackgroundHex: ItemLayoutMetrics.transparentHex,
            coverPaddingLeft: 0,
            coverPaddingRight: 0,
            titlePaddingLeft: outer.left,
            titlePaddingRight: outer.right,
            titleIconPaddingLeft: widgetPadding,
            titleIconPaddingRight: iconLabelGap,
            titleLabelPaddingLeft: iconLabelGap,
            titleLabelPaddingRight: widgetPadding
        )
    }
}

/// カード間 gap・内部 padding・アイコン-文字 gap の計算。
enum ItemLayoutMetrics {
    static let iconLabelGap = 4
    static let transparentHex = "0x00000000"

    struct OuterPadding: Equatable {
        let left: Int
        let right: Int
    }

    struct ContentPadding: Equatable {
        let iconLeft: Int
        let iconRight: Int
        let labelLeft: Int
        let labelRight: Int
    }

    static func widgetInnerPadding(_ widgetPadding: Int) -> Int {
        max(widgetPadding, 0)
    }

    /// 隣接カード間の実 gap = itemSpacing。奇数値は丸めない。
    /// 先頭 left=0・末尾 right=0。間は後続ではなく先行 item の trailing に全量を載せる。
    static func outerPadding(
        itemSpacing: Int,
        isFirst: Bool,
        isLast: Bool
    ) -> OuterPadding {
        _ = isFirst
        return OuterPadding(
            left: 0,
            right: isLast ? 0 : max(itemSpacing, 0)
        )
    }

    static func gapBetweenCards(
        leftOuter: OuterPadding,
        rightOuter: OuterPadding
    ) -> Int {
        leftOuter.right + rightOuter.left
    }

    static func contentPadding(
        hasIcon: Bool,
        widgetPadding: Int,
        iconLabelGap: Int
    ) -> ContentPadding {
        let inner = widgetInnerPadding(widgetPadding)
        if hasIcon {
            return ContentPadding(
                iconLeft: inner,
                iconRight: iconLabelGap,
                labelLeft: iconLabelGap,
                labelRight: inner
            )
        }
        return ContentPadding(
            iconLeft: 0,
            iconRight: 0,
            labelLeft: inner,
            labelRight: inner
        )
    }
}

enum WidgetBackgroundMetrics {
    struct Result: Equatable {
        let cardHeight: Int
        let cardCornerRadius: Int
    }

    static func make(barHeight: Int, barCornerRadius: Int) -> Result {
        let cardHeight = min(max(barHeight - 8, 24), barHeight)
        let cardCornerRadius = min(max(barCornerRadius - 4, 4), 14)
        return Result(cardHeight: cardHeight, cardCornerRadius: cardCornerRadius)
    }
}

enum SpotifyCoverMetrics {
    /// Spotify アートワークの典型解像度。scale = coverSize / reference で枠内に収める。
    static let referenceArtworkSize = 640.0

    struct Result: Equatable {
        let width: Int
        let height: Int
        let cornerRadius: Int
        let imageScale: String
    }

    static func make(requestedSize: Int, cardHeight: Int) -> Result {
        let requested = min(max(requestedSize, 16), 64)
        let coverSize = min(requested, max(cardHeight - 4, 16))
        let corner = max(coverSize * 9 / 28, 4)
        let scale = Double(coverSize) / referenceArtworkSize
        let scaleString = String(format: "%.4f", scale)
        return Result(width: coverSize, height: coverSize, cornerRadius: corner, imageScale: scaleString)
    }
}
