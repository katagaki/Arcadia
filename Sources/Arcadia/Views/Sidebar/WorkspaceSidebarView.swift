import SwiftUI
import SwiftData

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
        .toolbar { sidebarToolbar }
    }

    @ToolbarContentBuilder
    private var sidebarToolbar: some ToolbarContent {
        ToolbarItemGroup {
            Button("New Workspace", systemImage: "folder.badge.plus") {
                addWorkspace()
            }
            Menu("Bookmark Page", systemImage: "bookmark") {
                if workspaces.isEmpty {
                    Text("Create a workspace first")
                }
                ForEach(workspaces) { workspace in
                    Button(workspace.name) {
                        coordinator.addBookmark(to: workspace, context: modelContext)
                    }
                }
            }
            .disabled(workspaces.isEmpty)
        }
    }

    private func addWorkspace() {
        let nextIndex = (workspaces.map(\.sortIndex).max() ?? -1) + 1
        let workspace = Workspace(name: "Workspace \(nextIndex + 1)", sortIndex: nextIndex)
        modelContext.insert(workspace)
        try? modelContext.save()
    }
}
