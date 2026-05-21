import AppKit
import Combine
import CRWebView

enum SessionKind: Equatable {
    case explorer
    case bookmark(UUID)
}

/// Drives one CRWebView and maps its callbacks onto Arcadia's models: the
/// breadcrumb navigation chain, loading state, title/favicon, login detection.
final class BrowserSession: NSObject, ObservableObject, CRWebViewDelegate {
    let kind: SessionKind
    let controller: CRWebView
    let chain = NavigationChain()

    @Published var title: String = ""
    @Published var currentURL: String = ""
    @Published var isLoading: Bool = false
    @Published var favicon: NSImage?
    @Published var isAtStartPage: Bool = true
    @Published var loginPromptVisible: Bool = false

    init(kind: SessionKind, configuration: CRWebViewConfiguration) {
        self.kind = kind
        self.controller = CRWebView(configuration: configuration)
        super.init()
        self.controller.delegate = self
    }

    // MARK: Navigation

    func submitStartPageInput(_ input: String) {
        guard let url = SearchURLBuilder.url(from: input) else { return }
        isAtStartPage = false
        load(url.absoluteString)
    }

    func load(_ urlString: String) {
        controller.load(urlString)
    }

    func goBack() {
        guard chain.canGoBack else { return }
        chain.jump(to: chain.currentIndex - 1)
        if let node = chain.current { controller.load(node.url) }
    }

    func goForward() {
        guard chain.canGoForward else { return }
        chain.jump(to: chain.currentIndex + 1)
        if let node = chain.current { controller.load(node.url) }
    }

    func jumpToCrumb(_ index: Int) {
        chain.jump(to: index)
        if let node = chain.current { controller.load(node.url) }
    }

    func clearToStartPage() {
        chain.clear()
        isAtStartPage = true
        loginPromptVisible = false
        controller.load("about:blank")
    }

    func close() {
        controller.close()
    }

    // MARK: CRWebViewDelegate

    func webView(_ webView: CRWebView, didChangeURL url: String) {
        currentURL = url
        guard url != "about:blank" else { return }
        chain.recordNavigation(to: url, title: title)
        isAtStartPage = false
    }

    func webView(_ webView: CRWebView, didChange title: String) {
        self.title = title
        if !currentURL.isEmpty { chain.updateTitle(title, for: currentURL) }
    }

    func webView(_ webView: CRWebView, didChangeLoading isLoading: Bool) {
        self.isLoading = isLoading
    }

    func webView(_ webView: CRWebView, didReceiveFavicon pngData: Data?) {
        favicon = pngData.flatMap(NSImage.init(data:))
    }

    func webView(_ webView: CRWebView, shouldAllowNavigationTo url: String) -> Bool {
        true
    }

    func webViewDidDetectLoginForm(_ webView: CRWebView) {
        loginPromptVisible = true
    }

    func webView(_ webView: CRWebView, didFinishCaptureToSnapshot snapshotID: String) {
        NotificationCenter.default.post(
            name: .arcadiaCaptureFinished, object: nil,
            userInfo: ["snapshotID": snapshotID])
    }
}

extension Notification.Name {
    static let arcadiaCaptureFinished = Notification.Name("arcadiaCaptureFinished")
}
