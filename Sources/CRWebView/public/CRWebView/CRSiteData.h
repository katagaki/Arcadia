#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Clears a persisted site's data. Replaces CEFSiteData.
@interface CRSiteData : NSObject

/// Deletes cookies and removes the on-disk profile dir at `profilePath`.
/// Completion runs on the main thread.
+ (void)clearDataAtProfilePath:(NSString *)profilePath
                    completion:(void (^_Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
