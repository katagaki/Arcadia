import SwiftUI
import SwiftData
import CRWebView

@main
struct ArcadiaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    let modelContainer: ModelContainer

    init() {
        // Make the Chromium-required NSApplication subclass the live instance.
        ArcadiaApplication.ensureLoaded()
        do {
            modelContainer = try ModelContainer(
                for: Workspace.self, Bookmark.self, PersistedLoginSite.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .modelContainer(modelContainer)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
        }
        .modelContainer(modelContainer)
    }
}
