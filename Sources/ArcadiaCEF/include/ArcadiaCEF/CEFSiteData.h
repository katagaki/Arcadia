#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CEFSiteData : NSObject

/// Deletes cookies and cache for the persistent context at `cachePath`.
/// Completion runs on the main thread.
+ (void)clearDataAtCachePath:(NSString *)cachePath
                  completion:(void (^_Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
