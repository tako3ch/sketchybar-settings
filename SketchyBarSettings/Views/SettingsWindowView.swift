import SwiftUI

struct SettingsWindowView: View {
    @Environment(SettingsStore.self) private var store
    @State private var statusMessage: String?
    @State private var isError = false
    @State private var isApplying = false
    @State private var showResetConfirmation = false

    private let applier: SketchyBarApplier

    init(applier: SketchyBarApplier = SketchyBarApplier()) {
        self.applier = applier
    }

    var body: some View {
        @Bindable var store = store

        HSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("SketchyBar Settings")
                        .font(.title2.bold())

                    if let error = store.lastLoadError, case .decodeFailed = error {
                        Text(error.message)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                    }

                    GlobalStyleSection()
                    WidgetListSection()
                    WidgetStyleSection()

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(isError ? .red : .green)
                    }
                }
                .padding(16)
            }
            .frame(minWidth: 420, idealWidth: 480, maxWidth: 520)

            BarPreviewView(input: store.renderInput)
                .frame(minWidth: 360, idealWidth: 480)
        }
        .frame(minWidth: 900, idealWidth: 1000, minHeight: 620, idealHeight: 700)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("デフォルトへリセット") {
                    showResetConfirmation = true
                }

                Spacer()

                Button(isApplying ? "適用中…" : "適用") {
                    applySettings()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isApplying)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .confirmationDialog(
            "設定をデフォルトに戻しますか？",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("リセット", role: .destructive) {
                store.resetToDefaults()
                statusMessage = "デフォルト設定に戻しました（未適用）"
                isError = false
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("UserDefaults の保存済み設定が上書きされます。適用するまで SketchyBar には反映されません。")
        }
    }

    private func applySettings() {
        isApplying = true
        defer { isApplying = false }

        do {
            try applier.apply(store: store)
            statusMessage = "設定を適用し、SketchyBar を再起動しました"
            isError = false
        } catch {
            statusMessage = error.localizedDescription
            isError = true
        }
    }
}

struct GlobalStyleSection: View {
    @Environment(SettingsStore.self) private var store
    @State private var applyCardBackgroundsOnPreset = true
    @State private var pendingPreset: EarthStylePreset?

    private let fontChoices = FontFamilies.available

    var body: some View {
        @Bindable var store = store

        GroupBox("全体スタイル") {
            VStack(alignment: .leading, spacing: 10) {
                EarthStylePresetRow(
                    selectedID: store.bar.selectedStylePresetID,
                    applyCardBackgrounds: $applyCardBackgroundsOnPreset,
                    onSelect: { preset in
                        pendingPreset = preset
                    }
                )

                if let preset = pendingPreset {
                    Text("「\(preset.name)」を適用すると、ウィジェットの文字色と背景色が上書きされます。バー全体の背景色は変わりません。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("適用") {
                            store.applyStylePreset(preset, applyCardBackgrounds: applyCardBackgroundsOnPreset)
                            pendingPreset = nil
                        }
                        .buttonStyle(.borderedProminent)

                        Button("キャンセル") {
                            pendingPreset = nil
                        }
                    }
                }

                Picker("フォント", selection: $store.bar.fontFamily) {
                    ForEach(fontChoices, id: \.self) { family in
                        Text(family).tag(family)
                    }
                }
                .onChange(of: store.bar.fontFamily) { _, _ in store.save() }

                IntSliderField(
                    title: "フォントサイズ",
                    value: $store.bar.fontSize,
                    range: 8...24,
                    onChange: store.save
                )

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        IntSliderField(title: "高さ", value: $store.bar.height, range: 24...80, onChange: store.save)
                        IntSliderField(title: "y_offset", value: $store.bar.yOffset, range: 0...40, onChange: store.save)
                    }
                    GridRow {
                        IntSliderField(title: "角丸", value: $store.bar.cornerRadius, range: 0...30, onChange: store.save)
                        IntSliderField(title: "項目間隔", value: $store.bar.itemSpacing, range: 0...24, onChange: store.save)
                    }
                    GridRow {
                        IntSliderField(title: "左パディング", value: $store.bar.paddingLeft, range: 0...24, onChange: store.save)
                        IntSliderField(title: "右パディング", value: $store.bar.paddingRight, range: 0...24, onChange: store.save)
                    }
                }

                IntSliderField(
                    title: "ウィジェット内部padding",
                    value: $store.bar.widgetPadding,
                    range: 0...24,
                    onChange: store.save
                )

                IntSliderField(
                    title: "Spotify カバーサイズ",
                    value: $store.bar.spotifyCoverSize,
                    range: 16...64,
                    onChange: store.save
                )

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("バー背景色")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HexColorField(
                            hex: $store.bar.backgroundHex,
                            fallbackHex: SketchyBarColorHex.defaultBarBackground,
                            onCommit: store.save
                        )
                    }
                    Toggle("シャドウ", isOn: $store.bar.shadow)
                        .padding(.top, 18)
                        .onChange(of: store.bar.shadow) { _, _ in store.save() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct EarthStylePresetRow: View {
    let selectedID: String?
    @Binding var applyCardBackgrounds: Bool
    var onSelect: (EarthStylePreset) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ウィジェットカラープリセット")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EarthColorCatalog.stylePresets) { preset in
                        Button {
                            onSelect(preset)
                        } label: {
                            VStack(spacing: 4) {
                                HStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(preset.cardColor)
                                        .frame(width: 36, height: 14)
                                    Circle()
                                        .fill(preset.textColor)
                                        .frame(width: 14, height: 14)
                                }
                                Text(preset.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedID == preset.id ? Color.accentColor.opacity(0.15) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        selectedID == preset.id ? Color.accentColor : Color.secondary.opacity(0.3),
                                        lineWidth: selectedID == preset.id ? 2 : 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Toggle("プリセット適用時にカード背景も有効化", isOn: $applyCardBackgrounds)
                .font(.caption)
        }
    }
}

struct WidgetListSection: View {
    @Environment(SettingsStore.self) private var store
    @State private var draggedWidgetID: String?
    @State private var dropTargetID: String?

    var body: some View {
        GroupBox("ウィジェット一覧") {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(store.displayWidgets) { widget in
                        WidgetRow(
                            widget: widget,
                            isDropTarget: dropTargetID == widget.id,
                            onDropTargetChange: { isTargeted in
                                dropTargetID = isTargeted ? widget.id : (dropTargetID == widget.id ? nil : dropTargetID)
                            },
                            onDrop: { draggedID in
                                store.moveWidgetBefore(draggedID, targetID: widget.id)
                                draggedWidgetID = nil
                                dropTargetID = nil
                            }
                        )
                        .draggable(widget.id) {
                            draggedWidgetID = widget.id
                            return Text(widget.name)
                                .padding(6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 220)
        }
    }
}

private struct WidgetRow: View {
    @Environment(SettingsStore.self) private var store
    let widget: WidgetConfig
    let isDropTarget: Bool
    let onDropTargetChange: (Bool) -> Void
    let onDrop: (String) -> Void

    var body: some View {
        @Bindable var store = store

        let isSelected = store.selectedWidgetID == widget.id

        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Toggle("", isOn: Binding(
                get: { store.widget(id: widget.id)?.enabled ?? false },
                set: { _ in store.toggle(widget.id) }
            ))
            .labelsHidden()

            Text(widget.name)
                .frame(width: 100, alignment: .leading)

            Picker("", selection: Binding(
                get: { store.widget(id: widget.id)?.placement ?? widget.placement },
                set: { store.setPlacement(widget.id, $0) }
            )) {
                ForEach(WidgetPlacement.allCases) { placement in
                    Text(placement.title).tag(placement)
                }
            }
            .labelsHidden()
            .frame(width: 72)

            HStack(spacing: 2) {
                Button {
                    store.move(widget.id, up: true)
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)

                Button {
                    store.move(widget.id, up: false)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(rowBackground(isSelected: isSelected))
        .overlay(alignment: .top) {
            if isDropTarget {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
            }
        }
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            store.select(widget.id)
        }
        .dropDestination(for: String.self) { items, _ in
            guard let draggedID = items.first,
                  draggedID != widget.id,
                  store.widget(id: draggedID)?.placement == widget.placement else {
                return false
            }
            onDrop(draggedID)
            return true
        } isTargeted: { isTargeted in
            onDropTargetChange(isTargeted)
        }
    }

    private func rowBackground(isSelected: Bool) -> Color {
        if isDropTarget {
            return Color.accentColor.opacity(0.25)
        }
        if isSelected {
            return Color.accentColor.opacity(0.15)
        }
        return Color.clear
    }
}

struct WidgetStyleSection: View {
    @Environment(SettingsStore.self) private var store

    var body: some View {
        GroupBox(widgetStyleTitle) {
            if let widget = store.selectedWidget {
                WidgetStyleForm(widget: widget)
            } else {
                Text("ウィジェットを選択してください")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var widgetStyleTitle: String {
        if let widget = store.selectedWidget {
            if widget.isSpotifyGroup {
                return "スタイル（Spotify）"
            }
            return "スタイル（\(widget.name)）"
        }
        return "スタイル（選択中のウィジェット）"
    }
}

private struct WidgetStyleForm: View {
    @Environment(SettingsStore.self) private var store
    let widget: WidgetConfig

    @State private var colorHex: String = SketchyBarColorHex.defaultWidgetColor
    @State private var showIcon = true
    @State private var backgroundEnabled = false
    @State private var backgroundHex: String = WidgetConfig.panelBackgroundHex

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("文字色 / アイコン色")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HexColorField(
                    hex: $colorHex,
                    fallbackHex: SketchyBarColorHex.defaultWidgetColor,
                    onCommit: persistColor
                )
            }

            Toggle("背景表示", isOn: $backgroundEnabled)
                .onChange(of: backgroundEnabled) { _, newValue in
                    store.updateSelectedWidgetBackground(enabled: newValue)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("ウィジェット背景色")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HexColorField(
                    hex: $backgroundHex,
                    fallbackHex: WidgetConfig.panelBackgroundHex,
                    onCommit: persistBackgroundColor
                )
            }

            if !widget.isSpotifyGroup {
                Toggle("アイコン表示", isOn: $showIcon)
                    .onChange(of: showIcon) { _, newValue in
                        store.updateSelectedWidget { $0.showIcon = newValue }
                    }
            } else {
                Toggle("カバー表示", isOn: $showIcon)
                    .onChange(of: showIcon) { _, newValue in
                        store.updateSelectedWidget { $0.showIcon = newValue }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { syncFromWidget() }
        .onChange(of: widget.id) { _, _ in syncFromWidget() }
    }

    private func syncFromWidget() {
        colorHex = widget.colorHex ?? SketchyBarColorHex.defaultWidgetColor
        showIcon = widget.showIcon
        backgroundEnabled = widget.backgroundEnabled
        backgroundHex = widget.backgroundHex ?? WidgetConfig.panelBackgroundHex
    }

    private func persistColor() {
        let trimmed = colorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        store.updateSelectedWidget { widget in
            if trimmed.isEmpty || !SketchyBarColorHex.isValid(trimmed) {
                widget.colorHex = nil
            } else {
                widget.colorHex = SketchyBarColorHex.sanitized(trimmed, fallback: SketchyBarColorHex.defaultWidgetColor)
            }
        }
    }

    private func persistBackgroundColor() {
        store.updateSelectedWidgetBackgroundHex(backgroundHex)
    }
}

// 後方互換: 旧ポップオーバー参照用エイリアス
typealias SettingsPanelView = SettingsWindowView
