import SwiftUI

@main
struct TransitoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 680, minHeight: 520)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 900, height: 620)

        Settings {
            PreferencesView()
                .frame(width: 520, height: 420)
        }
    }
}
