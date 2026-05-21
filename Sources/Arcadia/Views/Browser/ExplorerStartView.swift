import SwiftUI

/// The explorer start page: a single field for a URL or a Google search.
struct ExplorerStartView: View {
    @ObservedObject var session: BrowserSession
    @State private var input: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("Arcadia")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            TextField("Search Google or enter a URL", text: $input)
                .textFieldStyle(.plain)
                .font(.title3)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.quaternary, in: Capsule())
                .frame(maxWidth: 560)
                .focused($focused)
                .onSubmit { submit() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .onAppear { focused = true }
    }

    private func submit() {
        session.submitStartPageInput(input)
        input = ""
    }
}
