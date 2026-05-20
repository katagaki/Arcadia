import SwiftUI
import ArcadiaCEF

/// Hosts a CEF browser's native NSView inside SwiftUI. The view identity is tied
/// to the session so switching sessions swaps the underlying browser view.
struct CEFWebView: NSViewRepresentable {
    let session: BrowserSession

    func makeNSView(context: Context) -> NSView {
        session.controller.view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // The controller owns its view; nothing to push on update.
    }
}
