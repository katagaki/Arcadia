import SwiftUI
import SwiftData

struct BrowserView: View {
    @ObservedObject var session: BrowserSession
    @EnvironmentObject var coordinator: BrowserCoordinator
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                CEFWebView(session: session)
                    .opacity(showStartPage ? 0 : 1)

                if showStartPage {
                    ExplorerStartView(session: session)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if session.loginPromptVisible {
                loginPrompt
            }

            BreadcrumbBar(session: session) {
                coordinator.showExplorer()
            }
        }
    }

    private var showStartPage: Bool {
        session.kind == .explorer && session.isAtStartPage
    }

    private var loginPrompt: some View {
        HStack {
            Image(systemName: "person.badge.key")
            Text("Stay signed in to this site?")
            Spacer()
            Button("Not Now") { coordinator.dismissLoginPrompt() }
            Button("Stay Signed In") {
                coordinator.persistLogin(context: modelContext)
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(.thinMaterial)
    }
}
