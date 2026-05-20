import AppKit
import ArcadiaCEF

/// Owns the CEF process lifecycle and pumps its message loop on the main thread.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var pumpTimer: Timer?

    func applicationWillFinishLaunching(_ notification: Notification) {
        guard CEFEngine.loadLibrary() else {
            fatalError("Failed to load CEF. Run Scripts/fetch_cef.sh and check embedding.")
        }
        do {
            try CEFEngine.shared.initialize()
        } catch {
            fatalError("CEF initialization failed: \(error)")
        }

        // external_message_pump = true, so CEF work is driven from AppKit's loop.
        pumpTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            CEFEngine.shared.doMessageLoopWork()
        }
        if let pumpTimer {
            RunLoop.main.add(pumpTimer, forMode: .common)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        pumpTimer?.invalidate()
        pumpTimer = nil
        CEFEngine.shared.shutdown()
    }
}
