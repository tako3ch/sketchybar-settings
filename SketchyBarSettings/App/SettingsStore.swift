import Foundation
import Observation

@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    var bar = BarSettings()
    var widgets: [WidgetConfig] = WidgetConfig.defaults
    var selectedWidgetID: String?
    var lastLoadError: SettingsLoadError?

    let configPath: String
    let pluginsDir: String

    private let defaults: UserDefaults
    private let defaultsKey: String
    private var hasLoadedSuccessfully = false

    init(
        defaults: UserDefaults = .standard,
        defaultsKey: String = "sketchybar.settings.v1",
        configPath: String? = nil,
        pluginsDir: String? = nil
    ) {
        self.defaults = defaults
        self.defaultsKey = defaultsKey
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.configPath = configPath ?? home.appendingPathComponent(".config/sketchybar/sketchybarrc").path
        self.pluginsDir = pluginsDir ?? home.appendingPathComponent(".config/sketchybar/plugins").path
        load()
    }

    var document: SettingsDocument {
        SettingsDocument(bar: bar, widgets: widgets)
    }

    var renderInput: RenderInput {
        RenderInput(bar: bar, widgets: widgets)
    }

    var selectedWidget: WidgetConfig? {
        guard let selectedWidgetID else { return nil }
        return widget(id: selectedWidgetID)
    }

    var displayWidgets: [WidgetConfig] {
        WidgetDisplayCatalog.sortedWidgets(from: widgets)
    }

    func widget(id: String) -> WidgetConfig? {
        widgets.first { $0.id == id }
    }

    func widgets(in placement: WidgetPlacement) -> [WidgetConfig] {
        widgets
            .filter { $0.enabled && $0.placement == placement }
            .sorted { $0.order < $1.order }
    }

    func toggle(_ id: String) {
        guard let index = widgets.firstIndex(where: { $0.id == id }) else { return }
        widgets[index].enabled.toggle()
        save()
    }

    func setPlacement(_ id: String, _ placement: WidgetPlacement) {
        guard let index = widgets.firstIndex(where: { $0.id == id }) else { return }
        let oldPlacement = widgets[index].placement
        guard oldPlacement != placement else { return }

        widgets[index].placement = placement
        renumber(oldPlacement)

        var ordered = widgets
            .filter { $0.placement == placement }
            .sorted { $0.order < $1.order }
        guard let currentIndex = ordered.firstIndex(where: { $0.id == id }) else { return }
        let item = ordered.remove(at: currentIndex)
        ordered.append(item)
        applyOrders(ordered)
        save()
    }

    /// 同一配置内の並び順を変更する唯一のメソッド。
    func reorderWidget(id: String, toIndex: Int, in placement: WidgetPlacement) {
        var ordered = widgets
            .filter { $0.placement == placement }
            .sorted { $0.order < $1.order }
        guard let fromIndex = ordered.firstIndex(where: { $0.id == id }) else { return }

        let item = ordered.remove(at: fromIndex)
        let clampedIndex = min(max(toIndex, 0), ordered.count)
        ordered.insert(item, at: clampedIndex)
        applyOrders(ordered)
        save()
    }

    func moveWidgetBefore(_ draggedID: String, targetID: String) {
        guard draggedID != targetID,
              let dragged = widget(id: draggedID),
              let target = widget(id: targetID),
              dragged.placement == target.placement else { return }

        let placement = dragged.placement
        var ordered = widgets
            .filter { $0.placement == placement }
            .sorted { $0.order < $1.order }
        guard let fromIndex = ordered.firstIndex(where: { $0.id == draggedID }),
              let targetIndex = ordered.firstIndex(where: { $0.id == targetID }) else { return }

        let item = ordered.remove(at: fromIndex)
        var insertIndex = targetIndex
        if fromIndex < targetIndex {
            insertIndex -= 1
        }
        ordered.insert(item, at: insertIndex)
        applyOrders(ordered)
        save()
    }

    func move(_ id: String, up: Bool) {
        guard let widget = widget(id: id) else { return }
        let ordered = widgets(in: widget.placement)
        guard let current = ordered.firstIndex(where: { $0.id == id }) else { return }

        let target = current + (up ? -1 : 1)
        guard ordered.indices.contains(target) else { return }
        reorderWidget(id: id, toIndex: target, in: widget.placement)
    }

    func select(_ id: String?) {
        selectedWidgetID = id
    }

    func updateSelectedWidget(_ update: (inout WidgetConfig) -> Void) {
        guard let id = selectedWidgetID,
              let index = widgets.firstIndex(where: { $0.id == id }) else { return }
        update(&widgets[index])
        save()
    }

    func updateBar(_ update: (inout BarSettings) -> Void) {
        update(&bar)
        save()
    }

    func updateBarBackgroundHex(_ hex: String) {
        bar.backgroundHex = SketchyBarColorHex.sanitized(
            hex,
            fallback: SketchyBarColorHex.defaultBarBackground
        )
        save()
    }

    func updateSelectedWidgetBackground(enabled: Bool) {
        updateSelectedWidget { $0.backgroundEnabled = enabled }
    }

    func updateSelectedWidgetBackgroundHex(_ hex: String) {
        let sanitized = SketchyBarColorHex.sanitized(
            hex,
            fallback: WidgetConfig.panelBackgroundHex
        )
        updateSelectedWidget { $0.backgroundHex = sanitized }
    }

    func applyStylePreset(_ preset: EarthStylePreset, applyCardBackgrounds: Bool) {
        bar.selectedStylePresetID = preset.id

        for index in widgets.indices {
            let id = widgets[index].id
            if EarthColorCatalog.mutedWidgetIDs.contains(id) {
                widgets[index].colorHex = SketchyBarColorHex.sanitized(
                    preset.mutedTextHex,
                    fallback: SketchyBarColorHex.defaultWidgetColor
                )
            } else {
                widgets[index].colorHex = SketchyBarColorHex.sanitized(
                    preset.textHex,
                    fallback: SketchyBarColorHex.defaultWidgetColor
                )
            }
            widgets[index].backgroundHex = SketchyBarColorHex.sanitized(
                preset.cardBackgroundHex,
                fallback: WidgetConfig.panelBackgroundHex
            )
            if applyCardBackgrounds, id != "umi_icon" {
                widgets[index].backgroundEnabled = true
            }
        }
        save()
    }

    func resetToDefaults() {
        bar = BarSettings()
        widgets = WidgetConfig.defaults
        selectedWidgetID = nil
        lastLoadError = nil
        save()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(document) else { return }
        defaults.set(data, forKey: defaultsKey)
    }

    private func load() {
        guard let data = defaults.data(forKey: defaultsKey) else {
            lastLoadError = .noData
            return
        }

        do {
            let doc = try JSONDecoder().decode(SettingsDocument.self, from: data)
            bar = doc.bar
            widgets = doc.widgets
            hasLoadedSuccessfully = true
            lastLoadError = nil
            migrateWidgetBackgroundIfNeeded(from: data)
            mergeMissingDefaults()
            applyRecommendedWidgetBackgroundHex()
            applyRecommendedWidgetColorHex()
        } catch {
            lastLoadError = .decodeFailed(error.localizedDescription)
            if !hasLoadedSuccessfully {
                // 初回起動で壊れたデータのみデフォルト維持（プロパティ初期値）
            }
        }
    }

    private func migrateWidgetBackgroundIfNeeded(from data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let widgetsJSON = json["widgets"] as? [[String: Any]] else { return }

        let hasBackgroundFields = widgetsJSON.contains { $0.keys.contains("backgroundEnabled") }
        guard !hasBackgroundFields else { return }

        if let index = widgets.firstIndex(where: { $0.id == WidgetConfig.spotifyID }) {
            widgets[index].backgroundEnabled = true
            widgets[index].backgroundHex = WidgetConfig.panelBackgroundHex
        }
        applyRecommendedWidgetBackgroundHex()
        applyRecommendedWidgetColorHex()
        save()
    }

    private func applyRecommendedWidgetColorHex() {
        for def in WidgetConfig.defaults {
            guard let hex = def.colorHex,
                  let index = widgets.firstIndex(where: { $0.id == def.id }) else { continue }
            if widgets[index].colorHex == nil {
                widgets[index].colorHex = hex
            }
        }
    }

    private func applyRecommendedWidgetBackgroundHex() {
        for def in WidgetConfig.defaults {
            guard let hex = def.backgroundHex,
                  let index = widgets.firstIndex(where: { $0.id == def.id }) else { continue }
            if widgets[index].backgroundHex == nil {
                widgets[index].backgroundHex = hex
            }
        }
    }

    private func mergeMissingDefaults() {
        let known = Set(widgets.map(\.id))
        for def in WidgetConfig.defaults where !known.contains(def.id) {
            widgets.append(def)
        }
    }

    private func renumber(_ placement: WidgetPlacement) {
        let ordered = widgets
            .filter { $0.placement == placement }
            .sorted { $0.order < $1.order }
        applyOrders(ordered)
    }

    private func applyOrders(_ ordered: [WidgetConfig]) {
        for (order, widget) in ordered.enumerated() {
            guard let index = widgets.firstIndex(where: { $0.id == widget.id }) else { continue }
            widgets[index].order = order
        }
    }
}
