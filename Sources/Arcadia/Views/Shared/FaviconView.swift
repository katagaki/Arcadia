import SwiftUI

/// A site favicon, falling back to a globe glyph when none is available.
struct FaviconView: View {
    let data: Data?

    var body: some View {
        if let data, let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .frame(width: 16, height: 16)
        } else {
            Image(systemName: "globe")
        }
    }
}
