import SwiftUI
import SwiftData
import ArcadiaCEF

@main
struct ArcadiaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    let modelContainer: ModelContainer

    init() {
        // Ensure the CEF-required NSApplication subclass is the live instance.
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
            // No browser toolbar; the only chrome beyond the sidebar/breadcrumb.
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
        }
        .modelContainer(modelContainer)
    }
}
