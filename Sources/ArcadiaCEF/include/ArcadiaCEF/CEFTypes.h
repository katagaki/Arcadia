#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CEFStorageMode) {
    /// In-memory only; cookies and cache are discarded when the context is freed.
    CEFStorageModeEphemeral = 0,
    /// On-disk; used only for sites where the user opted to persist login.
    CEFStorageModePersistent = 1,
};

typedef NS_ENUM(NSInteger, CEFOfflineMode) {
    CEFOfflineModeNone = 0,
    /// Live browsing while capturing resources to a snapshot (skips JavaScript).
    CEFOfflineModeCapture = 1,
    /// Serve content from a stored snapshot.
    CEFOfflineModeReplay = 2,
};

NS_ASSUME_NONNULL_END
