import Foundation

struct NavNode: Identifiable, Equatable {
    let id = UUID()
    var url: String
    var title: String
}

/// The linear navigation hierarchy shown as the bottom breadcrumb. Following a
/// link appends a node; jumping to a crumb truncates everything after it.
@Observable
final class NavigationChain {
    private(set) var nodes: [NavNode] = []
    private(set) var currentIndex: Int = -1

    var current: NavNode? {
        guard nodes.indices.contains(currentIndex) else { return nil }
        return nodes[currentIndex]
    }

    var isEmpty: Bool { nodes.isEmpty }
    var canGoBack: Bool { currentIndex > 0 }
    var canGoForward: Bool { currentIndex >= 0 && currentIndex < nodes.count - 1 }

    func recordNavigation(to url: String, title: String) {
        if let cur = current, cur.url == url {
            nodes[currentIndex].title = title
            return
        }
        if currentIndex < nodes.count - 1, nodes[currentIndex + 1].url == url {
            currentIndex += 1
            nodes[currentIndex].title = title
            return
        }
        if currentIndex < nodes.count - 1 {
            nodes.removeSubrange((currentIndex + 1)...)
        }
        nodes.append(NavNode(url: url, title: title))
        currentIndex = nodes.count - 1
    }

    func updateTitle(_ title: String, for url: String) {
        for i in nodes.indices where nodes[i].url == url {
            nodes[i].title = title
        }
    }

    func jump(to index: Int) {
        guard nodes.indices.contains(index) else { return }
        currentIndex = index
    }

    func clear() {
        nodes.removeAll()
        currentIndex = -1
    }
}
