import SwiftUI
import AppKit

/// SwiftUI の ColorPicker ではなく、AppKit の NSColorWell を使うカラーピッカー。
struct AppKitColorWell: NSViewRepresentable {
    @Binding var hex: String
    let fallbackHex: String
    var onCommit: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(hex: $hex, fallbackHex: fallbackHex, onCommit: onCommit)
    }

    func makeNSView(context: Context) -> NSColorWell {
        let well = NSColorWell()
        well.target = context.coordinator
        well.action = #selector(Coordinator.colorChanged(_:))
        return well
    }

    func updateNSView(_ well: NSColorWell, context: Context) {
        guard !context.coordinator.isUpdatingFromWell else { return }
        let color = SketchyBarColorHex.color(from: hex, fallbackHex: fallbackHex)
        well.color = NSColor(color)
    }

    final class Coordinator: NSObject {
        @Binding var hex: String
        let fallbackHex: String
        var onCommit: (() -> Void)?
        var isUpdatingFromWell = false

        init(hex: Binding<String>, fallbackHex: String, onCommit: (() -> Void)?) {
            _hex = hex
            self.fallbackHex = fallbackHex
            self.onCommit = onCommit
        }

        @objc func colorChanged(_ sender: NSColorWell) {
            isUpdatingFromWell = true
            defer { isUpdatingFromWell = false }

            let formatted = SketchyBarColorHex.hex(from: Color(nsColor: sender.color))
            hex = formatted
            onCommit?()
        }
    }
}

struct EarthColorPaletteRow: View {
    @Binding var hex: String
    let fallbackHex: String
    var onCommit: (() -> Void)?

    private let swatchSize: CGFloat = 22

    var body: some View {
        HStack(spacing: 6) {
            ForEach(EarthColorCatalog.presets) { preset in
                Button {
                    applyPreset(preset.hex)
                } label: {
                    ZStack {
                        Circle()
                            .fill(preset.displayColor)
                            .frame(width: swatchSize, height: swatchSize)

                        if preset.id == "transparent" || preset.id == "white" {
                            Circle()
                                .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1)
                                .frame(width: swatchSize, height: swatchSize)
                        }

                        if isSelected(preset.hex) {
                            Circle()
                                .strokeBorder(Color.accentColor, lineWidth: 2)
                                .frame(width: swatchSize + 4, height: swatchSize + 4)
                        }
                    }
                    .frame(width: swatchSize + 4, height: swatchSize + 4)
                    .help(preset.name)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func isSelected(_ presetHex: String) -> Bool {
        let current = SketchyBarColorHex.sanitized(hex, fallback: fallbackHex)
        let target = SketchyBarColorHex.sanitized(presetHex, fallback: fallbackHex)
        return current == target
    }

    private func applyPreset(_ presetHex: String) {
        hex = SketchyBarColorHex.sanitized(presetHex, fallback: fallbackHex)
        onCommit?()
    }
}

struct HexColorField: View {
    @Binding var hex: String
    let fallbackHex: String
    var onCommit: (() -> Void)?

    @State private var hexText: String = ""
    @State private var isInvalid = false
    @FocusState private var hexFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                AppKitColorWell(hex: $hex, fallbackHex: fallbackHex, onCommit: onCommit)
                    .frame(width: 44, height: 28)

                TextField(fallbackHex, text: $hexText)
                    .textFieldStyle(.roundedBorder)
                    .focused($hexFieldFocused)
                    .onSubmit(commitHexText)
            }

            if isInvalid {
                Text("無効な Hex です。\(fallbackHex) 形式（0xRRGGBB / 0xAARRGGBB）で入力してください。")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            EarthColorPaletteRow(hex: $hex, fallbackHex: fallbackHex, onCommit: onCommit)
        }
        .onAppear { syncFromBinding(forceHexText: true) }
        .onChange(of: hex) { _, _ in
            if !hexFieldFocused {
                syncFromBinding(forceHexText: true)
            }
        }
        .onChange(of: hexFieldFocused) { _, focused in
            if !focused {
                commitHexText()
            }
        }
    }

    private func syncFromBinding(forceHexText: Bool) {
        if forceHexText {
            hexText = hex.isEmpty ? fallbackHex : hex
        }
        isInvalid = false
    }

    private func commitHexText() {
        let trimmed = hexText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            hex = fallbackHex
            isInvalid = false
            syncFromBinding(forceHexText: true)
            onCommit?()
            return
        }

        guard SketchyBarColorHex.isValid(trimmed) else {
            isInvalid = true
            return
        }

        isInvalid = false
        hex = SketchyBarColorHex.sanitized(trimmed, fallback: fallbackHex)
        hexText = hex
        onCommit?()
    }
}

struct IntSliderField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var onChange: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value) pt")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .onChange(of: value) { _, _ in onChange?() }
        }
    }
}
