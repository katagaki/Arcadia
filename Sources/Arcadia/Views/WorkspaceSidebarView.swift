import SwiftUI
import SwiftData

/// The sidebar: workspaces (collapsible) holding bookmarks. There are no tabs —
/// only the explorer (selected via the "Explorer" row) and bookmarks.
struct WorkspaceSidebarView: View {
    @EnvironmentObject var coordinator: BrowserCoordinator
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workspace.sortIndex) private var workspaces: [Workspace]

    var body: some View {
        List {
            Section {
                Label("Explorer", systemImage: "safari")
                    .contentShape(Rectangle())
                    .onTapGesture { coordinator.showExplorer() }
            }

            ForEach(workspaces) { workspace in
                WorkspaceDisclosure(workspace: workspace)
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItemGroup {
                Button("New Workspace", systemImage: "folder.badge.plus") {
                    addWorkspace()
                }
                Menu("Bookmark Page", systemImage: "bookmark") {
                    if workspaces.isEmpty {
                        Text("Create a workspace first")
                    }
                    ForEach(workspaces) { ws in
                        Button(ws.name) {
                            coordinator.addBookmark(to: ws, context: modelContext)
                        }
                    }
                }
                .disabled(workspaces.isEmpty)
            }
        }
    }

    private func addWorkspace() {
        let nextIndex = (workspaces.map(\.sortIndex).max() ?? -1) + 1
        let ws = Workspace(name: "Workspace \(nextIndex + 1)", sortIndex: nextIndex)
        modelContext.insert(ws)
        try? modelContext.save()
    }
}

/// One collapsible workspace and its bookmarks. `isExpanded` persists.
private struct WorkspaceDisclosure: View {
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
                        Button("Delete", role: .destructive) {
                            if let id = bookmark.offlineSnapshotID { AppPaths.deleteSnapshot(id) }
                            modelContext.delete(bookmark)
                            try? modelContext.save()
                        }
                    }
            }
        } label: {
            Text(workspace.name)
                .font(.headline)
                .contextMenu {
                    Button("Delete Workspace", role: .destructive) {
                        for b in workspace.bookmarks {
                            if let id = b.offlineSnapshotID { AppPaths.deleteSnapshot(id) }
                        }
                        modelContext.delete(workspace)
                        try? modelContext.save()
                    }
                }
        }
    }
}

private struct BookmarkRow: View {
    let bookmark: Bookmark

    var body: some View {
        Label {
            Text(bookmark.title).lineLimit(1)
        } icon: {
            if let data = bookmark.faviconData, let image = NSImage(data: data) {
                Image(nsImage: image).resizable().frame(width: 16, height: 16)
            } else {
                Image(systemName: "globe")
            }
        }
    }
}
