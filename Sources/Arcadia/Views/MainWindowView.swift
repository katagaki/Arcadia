import SwiftUI

/// The main browser window: sidebar (workspaces + bookmarks) and the detail pane
/// (web content + bottom breadcrumb). No top toolbar beyond the sidebar controls.
struct MainWindowView: View {
    @StateObject private var coordinator = BrowserCoordinator()

    var body: some View {
        NavigationSplitView {
            WorkspaceSidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 360)
        } detail: {
            BrowserView(session: coordinator.activeSession)
        }
        .environmentObject(coordinator)
    }
}
