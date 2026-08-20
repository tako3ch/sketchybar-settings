import SwiftUI

@main
struct SketchyBarSettingsApp: App {
    private var store = SettingsStore.shared

    var body: some Scene {
        WindowGroup(id: "settings") {
            SettingsWindowView()
                .environment(store)
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
