import AdminAppCore
import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct AdminApp: App {
    init() {
        #if os(macOS)
        // Lanzada con `swift run` no hay bundle: pedimos ser una app normal para que salga la ventana.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        #endif
    }

    var body: some Scene {
        WindowGroup("Administración") {
            AdminRootView()
        }
    }
}
