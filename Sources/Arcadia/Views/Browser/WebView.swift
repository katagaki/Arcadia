import SwiftUI
import CRWebView

/// Hosts a CRWebView's native NSView inside SwiftUI.
struct WebView: NSViewRepresentable {
    let session: BrowserSession

    func makeNSView(context: Context) -> NSView {
        session.controller.view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
