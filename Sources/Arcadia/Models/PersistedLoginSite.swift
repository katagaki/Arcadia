import Foundation
import SwiftData

/// A domain whose login the user chose to persist. Its cookies/cache live in an
/// on-disk request context; Settings can clear them.
@Model
final class PersistedLoginSite {
    @Attribute(.unique) var domain: String

    /// Path of the persistent request-context cache directory for this domain.
    var requestContextPath: String

    var dateAdded: Date

    init(domain: String, requestContextPath: String) {
        self.domain = domain
        self.requestContextPath = requestContextPath
        self.dateAdded = .now
    }
}
