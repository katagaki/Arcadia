import Foundation

/// On-disk locations under Application Support/Arcadia.
enum AppPaths {
    static var root: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Arcadia", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Offline snapshot directory for a bookmark.
    static func snapshotDirectory(_ id: UUID) -> URL {
        let dir = root.appendingPathComponent("Snapshots", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Persistent request-context cache directory for a login-persisted domain.
    static func contextDirectory(forDomain domain: String) -> URL {
        let safe = domain.replacingOccurrences(of: "/", with: "_")
        let dir = root.appendingPathComponent("Contexts", isDirectory: true)
            .appendingPathComponent(safe, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func deleteSnapshot(_ id: UUID) {
        try? FileManager.default.removeItem(at: snapshotDirectory(id))
    }
}
