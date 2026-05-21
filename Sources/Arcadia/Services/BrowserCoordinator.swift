import Foundation
import SwiftData
import ArcadiaCEF

/// Top-level browsing state: the active session, opening bookmarks, creating
/// bookmarks with offline capture, and persisting login for a site.
@MainActor
final class BrowserCoordinator: ObservableObject {
    @Published private(set) var activeSession: BrowserSession

    private var persistedDomains: Set<String> = []
    private var captureSessions: Set<BrowserSession> = []

    init() {
        activeSession = BrowserCoordinator.makeExplorerSession()
    }

    // MARK: Sessions

    static func makeExplorerSession() -> BrowserSession {
        let config = CEFBrowserConfiguration()
        config.storageMode = .ephemeral
        config.offlineMode = .none
        return BrowserSession(kind: .explorer, configuration: config)
    }

    func showExplorer() {
        if activeSession.kind != .explorer {
            activeSession.close()
            activeSession = BrowserCoordinator.makeExplorerSession()
        }
        activeSession.clearToStartPage()
    }

    func openBookmark(_ bookmark: Bookmark) {
        activeSession.close()

        let config = CEFBrowserConfiguration()
        let domain = bookmark.url?.host ?? ""
        if bookmark.persistLogin {
            config.storageMode = .persistent
            config.persistentCachePath = AppPaths.contextDirectory(forDomain: domain).path
        } else {
            config.storageMode = .ephemeral
        }
        if let snapshotID = bookmark.offlineSnapshotID {
            config.offlineMode = .replay
            config.snapshotDirectory = AppPaths.snapshotDirectory(snapshotID).path
        } else {
            config.offlineMode = .none
        }

        let session = BrowserSession(kind: .bookmark(bookmark.id), configuration: config)
        activeSession = session
        if let url = bookmark.url { session.load(url.absoluteString) }
    }

    // MARK: Bookmarking and offline capture

    func addBookmark(to workspace: Workspace, context: ModelContext) {
        let session = activeSession
        guard !session.currentURL.isEmpty, session.currentURL != "about:blank" else { return }

        let nextIndex = (workspace.bookmarks.map(\.sortIndex).max() ?? -1) + 1
        let bookmark = Bookmark(title: session.title.isEmpty ? session.currentURL : session.title,
                                urlString: session.currentURL,
                                sortIndex: nextIndex)
        bookmark.workspace = workspace
        context.insert(bookmark)
        try? context.save()

        captureSnapshot(for: bookmark, sourceURL: session.currentURL, context: context)
    }

    private func captureSnapshot(for bookmark: Bookmark, sourceURL: String, context: ModelContext) {
        let snapshotID = UUID()
        let config = CEFBrowserConfiguration()
        config.storageMode = .ephemeral
        config.offlineMode = .capture
        config.snapshotDirectory = AppPaths.snapshotDirectory(snapshotID).path

        let capture = BrowserSession(kind: .bookmark(bookmark.id), configuration: config)
        captureSessions.insert(capture)

        var observer: NSObjectProtocol?
        observer = NotificationCenter.default.addObserver(
            forName: .arcadiaCaptureFinished, object: nil, queue: .main) { [weak self] _ in
            bookmark.offlineSnapshotID = snapshotID
            try? context.save()
            capture.close()
            self?.captureSessions.remove(capture)
            if let observer { NotificationCenter.default.removeObserver(observer) }
        }
        capture.load(sourceURL)
    }

    // MARK: Login persistence

    func persistLogin(context: ModelContext) {
        guard let host = URL(string: activeSession.currentURL)?.host else { return }
        guard !persistedDomains.contains(host) else { return }
        persistedDomains.insert(host)

        let path = AppPaths.contextDirectory(forDomain: host).path
        context.insert(PersistedLoginSite(domain: host, requestContextPath: path))
        try? context.save()

        activeSession.loginPromptVisible = false
    }

    func dismissLoginPrompt() {
        activeSession.loginPromptVisible = false
    }
}
