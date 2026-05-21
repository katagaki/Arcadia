#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// NSApplication subclass required by CEF on macOS. Set as the principal class
/// via `NSPrincipalClass` in Info.plist.
@interface ArcadiaApplication : NSApplication
+ (void)ensureLoaded;
@end

NS_ASSUME_NONNULL_END
