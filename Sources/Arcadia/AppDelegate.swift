import AppKit
import CRWebView

/// Owns the Chromium engine lifecycle. There is no message-pump timer: the
/// engine integrates with AppKit's run loop via Chromium's Cocoa message pump
/// and schedules its own work on the main thread.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        guard CRWebEngine.loadLibrary() else {
            fatalError("Failed to load CRWebView.framework. Build it with Scripts/build_crwebview.sh and check embedding.")
        }
        do {
            try CRWebEngine.shared.initialize()
        } catch {
            fatalError("CRWebView engine initialization failed: \(error)")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        CRWebEngine.shared.shutdown()
    }
}
