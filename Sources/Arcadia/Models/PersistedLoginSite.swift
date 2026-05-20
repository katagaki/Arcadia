import Foundation
import SwiftData

/// A domain whose login the user chose to persist. Cookies/cache for these sites
/// are stored in a persistent CEF request context (on disk) instead of the
/// default ephemeral one. The Settings "Site Data" tab lists these and lets the
/// user clear each one.
@Model
final class PersistedLoginSite {
    @Attribute(.unique) var domain: String

    /// Path (relative to Application Support/Arcadia/Contexts/) of the persistent
    /// request-context cache directory backing this domain.
    var requestContextPath: String

    var dateAdded: Date

    init(domain: String, requestContextPath: String) {
        self.domain = domain
        self.requestContextPath = requestContextPath
        self.dateAdded = .now
    }
}
