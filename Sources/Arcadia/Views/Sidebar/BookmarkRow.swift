import SwiftUI

struct BookmarkRow: View {
    let bookmark: Bookmark

    var body: some View {
        Label {
            Text(bookmark.title).lineLimit(1)
        } icon: {
            FaviconView(data: bookmark.faviconData)
        }
    }
}
