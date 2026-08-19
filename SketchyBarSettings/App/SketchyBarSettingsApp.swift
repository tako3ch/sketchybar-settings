import SwiftUI
import AppKit

@main
struct SketchyBarSettingsApp: App {
    @Environment(\.openWindow) private var openWindow
    private var store = SettingsStore.shared

    var body: some Scene {
        MenuBarExtra("SketchyBar Settings", systemImage: "slider.horizontal.3") {
            Button("設定を開く") {
                openSettingsWindow()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("終了") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }

        WindowGroup(id: "settings") {
            SettingsWindowView()
                .environment(store)
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }

    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "settings")
    }
}
