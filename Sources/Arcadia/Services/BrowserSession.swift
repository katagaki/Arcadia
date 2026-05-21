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

    /// A user nav still waiting for its title. Redirects update this URL in
    /// place; the crumb is only appended once a title arrives (or load ends).
    private var pendingCrumbURL: String?

    /// True while goBack / goForward / jumpToCrumb is driving the web view,
    /// so the next URL change is history travel, not a new crumb.
    private var isInternalNavigation: Bool = false

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
        pendingCrumbURL = urlString
        controller.load(urlString)
    }

    func goBack() {
        guard chain.canGoBack else { return }
        chain.jump(to: chain.currentIndex - 1)
        if let node = chain.current {
            isInternalNavigation = true
            controller.load(node.url)
        }
    }

    func goForward() {
        guard chain.canGoForward else { return }
        chain.jump(to: chain.currentIndex + 1)
        if let node = chain.current {
            isInternalNavigation = true
            controller.load(node.url)
        }
    }

    func jumpToCrumb(_ index: Int) {
        chain.jump(to: index)
        if let node = chain.current {
            isInternalNavigation = true
            controller.load(node.url)
        }
    }

    func clearToStartPage() {
        chain.clear()
        isAtStartPage = true
        loginPromptVisible = false
        pendingCrumbURL = nil
        controller.load("about:blank")
    }

    func close() {
        controller.close()
    }

    // MARK: CRWebViewDelegate

    func webView(_ webView: CRWebView, didChangeURL url: String, userInitiated: Bool) {
        currentURL = url
        guard url != "about:blank" else { return }
        isAtStartPage = false

        if isInternalNavigation {
            isInternalNavigation = false
            return
        }
        if pendingCrumbURL != nil || userInitiated {
            pendingCrumbURL = url
        } else {
            chain.updateCurrentURL(url)
        }
    }

    func webView(_ webView: CRWebView, didChange title: String) {
        self.title = title
        commitPendingCrumb(withTitle: title)
        if !currentURL.isEmpty { chain.updateTitle(title, for: currentURL) }
    }

    func webView(_ webView: CRWebView, didChangeLoading isLoading: Bool) {
        self.isLoading = isLoading
        if !isLoading { commitPendingCrumb(withTitle: title) }
    }

    private func commitPendingCrumb(withTitle title: String) {
        guard let url = pendingCrumbURL else { return }
        let resolved = title.isEmpty ? (URL(string: url)?.host ?? "Untitled") : title
        chain.recordNavigation(to: url, title: resolved)
        pendingCrumbURL = nil
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
