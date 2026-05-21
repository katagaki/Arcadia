#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CRStorageMode) {
    /// In-memory only; cookies and cache are discarded when the context is freed.
    CRStorageModeEphemeral = 0,
    /// On-disk; used only for sites where the user opted to persist login.
    CRStorageModePersistent = 1,
};

typedef NS_ENUM(NSInteger, CROfflineMode) {
    CROfflineModeNone = 0,
    /// Live browsing while capturing resources to a snapshot (skips JavaScript).
    CROfflineModeCapture = 1,
    /// Serve content from a stored snapshot.
    CROfflineModeReplay = 2,
};

NS_ASSUME_NONNULL_END
