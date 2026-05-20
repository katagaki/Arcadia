#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Operations on persisted site data, used by Settings → Site Data.
@interface CEFSiteData : NSObject

/// Deletes cookies and cache for the persistent context at `cachePath`.
/// Completion is called on the main thread once Chromium reports done.
+ (void)clearDataAtCachePath:(NSString *)cachePath
                  completion:(void (^_Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
