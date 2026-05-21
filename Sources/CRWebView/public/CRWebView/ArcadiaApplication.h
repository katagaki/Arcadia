#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// NSApplication subclass required by Chromium on macOS. Set as the principal
/// class via `NSPrincipalClass` in Info.plist.
///
/// Conforms to Chromium's CrAppProtocol/CrAppControlProtocol (the
/// isHandlingSendEvent pair) instead of CEF's CefAppProtocol; the two methods
/// are the same shape, with base::mac::ScopedSendingEvent in place of
/// CefScopedSendingEvent.
@interface ArcadiaApplication : NSApplication
+ (void)ensureLoaded;
@end

NS_ASSUME_NONNULL_END
