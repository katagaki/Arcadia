import SwiftUI

/// Native bottom navigation. Replaces the top toolbar: it shows the navigation
/// hierarchy and lets the user jump back to any ancestor. There is no address
/// bar; a new destination means bookmarking or clearing back to the start page.
struct BreadcrumbBar: View {
    @ObservedObject var session: BrowserSession
    var onClearToStart: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: session.goBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!session.chain.canGoBack)

            Button(action: session.goForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!session.chain.canGoForward)

            Divider().frame(height: 14)

            crumbs

            Spacer(minLength: 8)

            if session.kind == .explorer {
                Button("Start Page", systemImage: "house") {
                    onClearToStart()
                }
                .labelStyle(.iconOnly)
                .help("Clear the hierarchy and return to the start page")
            }

            if session.isLoading {
                ProgressView().controlSize(.small)
            }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(.bar)
    }

    private var crumbs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(session.chain.nodes.enumerated()), id: \.element.id) { index, node in
                    if index > 0 {
                        Image(systemName: "chevron.compact.right")
                            .foregroundStyle(.tertiary)
                    }
                    Button {
                        session.jumpToCrumb(index)
                    } label: {
                        Text(crumbLabel(node))
                            .lineLimit(1)
                            .fontWeight(index == session.chain.currentIndex ? .semibold : .regular)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(index == session.chain.currentIndex ? .primary : .secondary)
                }
            }
        }
    }

    private func crumbLabel(_ node: NavNode) -> String {
        node.title.isEmpty ? "Untitled" : node.title
    }
}
