import Foundation
import SwiftData

/// A user-created group in the sidebar that holds bookmarks. Workspaces can be
/// freely expanded and collapsed; `isExpanded` persists that state.
@Model
final class Workspace {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortIndex: Int
    var isExpanded: Bool

    @Relationship(deleteRule: .cascade, inverse: \Bookmark.workspace)
    var bookmarks: [Bookmark]

    init(name: String, sortIndex: Int, isExpanded: Bool = true) {
        self.id = UUID()
        self.name = name
        self.sortIndex = sortIndex
        self.isExpanded = isExpanded
        self.bookmarks = []
    }

    var sortedBookmarks: [Bookmark] {
        bookmarks.sorted { $0.sortIndex < $1.sortIndex }
    }
}
