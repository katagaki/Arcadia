import AppKit
import Combine
import ArcadiaCEF

enum SessionKind: Equatable {
    case explorer
    case bookmark(UUID)
}

/// Drives one CEF browser and maps its callbacks onto Arcadia's models: the
/// breadcrumb navigation chain, loading state, title/favicon, login detection.
final class BrowserSession: NSObject, ObservableObject, CEFBrowserDelegate {
    let kind: SessionKind
    let controller: CEFBrowserController
    let chain = NavigationChain()

    @Published var title: String = ""
    @Published var currentURL: String = ""
    @Published var isLoading: Bool = false
    @Published var favicon: NSImage?
    @Published var isAtStartPage: Bool = true
    @Published var loginPromptVisible: Bool = false

    init(kind: SessionKind, configuration: CEFBrowserConfiguration) {
        self.kind = kind
        self.controller = CEFBrowserController(configuration: configuration)
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

    // MARK: CEFBrowserDelegate

    func browser(_ browser: CEFBrowserController, didChangeURL url: String) {
        currentURL = url
        guard url != "about:blank" else { return }
        chain.recordNavigation(to: url, title: title)
        isAtStartPage = false
    }

    func browser(_ browser: CEFBrowserController, didChange title: String) {
        self.title = title
        if !currentURL.isEmpty { chain.updateTitle(title, for: currentURL) }
    }

    func browser(_ browser: CEFBrowserController, didChangeLoading isLoading: Bool) {
        self.isLoading = isLoading
    }

    func browser(_ browser: CEFBrowserController, didReceiveFavicon pngData: Data?) {
        favicon = pngData.flatMap(NSImage.init(data:))
    }

    func browser(_ browser: CEFBrowserController, shouldAllowNavigationTo url: String) -> Bool {
        true
    }

    func browserDidDetectLoginForm(_ browser: CEFBrowserController) {
        loginPromptVisible = true
    }

    func browser(_ browser: CEFBrowserController, didFinishCaptureToSnapshot snapshotID: String) {
        NotificationCenter.default.post(
            name: .arcadiaCaptureFinished, object: nil,
            userInfo: ["snapshotID": snapshotID])
    }
}

extension Notification.Name {
    static let arcadiaCaptureFinished = Notification.Name("arcadiaCaptureFinished")
}
