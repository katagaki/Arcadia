import SwiftUI

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
