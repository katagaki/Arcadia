#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// NSApplication subclass required by CEF on macOS. CEF needs the app to conform
/// to CefAppProtocol and to track whether it is inside -sendEvent:. Set as the
/// app's principal class via `NSPrincipalClass` in Info.plist.
@interface ArcadiaApplication : NSApplication
+ (void)ensureLoaded;  // forces +sharedApplication to instantiate this subclass
@end

NS_ASSUME_NONNULL_END
