import SwiftUI
import ArcadiaCEF

/// Hosts a CEF browser's native NSView inside SwiftUI.
struct CEFWebView: NSViewRepresentable {
    let session: BrowserSession

    func makeNSView(context: Context) -> NSView {
        session.controller.view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
