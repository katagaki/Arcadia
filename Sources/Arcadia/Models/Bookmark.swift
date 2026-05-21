import Foundation
import SwiftData

/// A saved page inside a workspace, cached offline (HTML/images/video, no JS).
@Model
final class Bookmark {
    @Attribute(.unique) var id: UUID
    var title: String
    var urlString: String
    var faviconData: Data?
    var sortIndex: Int

    /// Snapshot directory name under Snapshots/. Nil until caching completes.
    var offlineSnapshotID: UUID?

    /// Whether this site may persist login (cookies stored on disk).
    var persistLogin: Bool

    var workspace: Workspace?

    init(title: String,
         urlString: String,
         sortIndex: Int,
         faviconData: Data? = nil,
         persistLogin: Bool = false) {
        self.id = UUID()
        self.title = title
        self.urlString = urlString
        self.sortIndex = sortIndex
        self.faviconData = faviconData
        self.persistLogin = persistLogin
    }

    var url: URL? { URL(string: urlString) }
}
