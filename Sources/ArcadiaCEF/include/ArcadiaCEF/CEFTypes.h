#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Which cookie/cache store a browser uses.
typedef NS_ENUM(NSInteger, CEFStorageMode) {
    /// In-memory only. Cookies and cache are discarded when the context is
    /// released ("closed completely"). This is the default for all browsing.
    CEFStorageModeEphemeral = 0,
    /// On-disk. Used only for sites where the user opted to persist login.
    CEFStorageModePersistent = 1,
};

/// How a browser should treat offline-cached content for a bookmark.
typedef NS_ENUM(NSInteger, CEFOfflineMode) {
    /// Normal live browsing (no capture, no replay).
    CEFOfflineModeNone = 0,
    /// Live browsing while capturing resources to a snapshot (skips JavaScript).
    CEFOfflineModeCapture = 1,
    /// Serve content from a stored snapshot via the arcadia-cache scheme.
    CEFOfflineModeReplay = 2,
};

NS_ASSUME_NONNULL_END
