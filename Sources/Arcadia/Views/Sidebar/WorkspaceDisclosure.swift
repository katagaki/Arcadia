import SwiftUI
import SwiftData

/// One collapsible workspace and its bookmarks. `isExpanded` persists.
struct WorkspaceDisclosure: View {
    @EnvironmentObject var coordinator: BrowserCoordinator
    @Environment(\.modelContext) private var modelContext
    @Bindable var workspace: Workspace

    var body: some View {
        DisclosureGroup(isExpanded: $workspace.isExpanded) {
            ForEach(workspace.sortedBookmarks) { bookmark in
                BookmarkRow(bookmark: bookmark)
                    .contentShape(Rectangle())
                    .onTapGesture { coordinator.openBookmark(bookmark) }
                    .contextMenu {
                        Button("Delete", role: .destructive) { delete(bookmark) }
                    }
            }
        } label: {
            Text(workspace.name)
                .font(.headline)
                .contextMenu {
                    Button("Delete Workspace", role: .destructive) { deleteWorkspace() }
                }
        }
    }

    private func delete(_ bookmark: Bookmark) {
        if let id = bookmark.offlineSnapshotID { AppPaths.deleteSnapshot(id) }
        modelContext.delete(bookmark)
        try? modelContext.save()
    }

    private func deleteWorkspace() {
        for bookmark in workspace.bookmarks {
            if let id = bookmark.offlineSnapshotID { AppPaths.deleteSnapshot(id) }
        }
        modelContext.delete(workspace)
        try? modelContext.save()
    }
}
