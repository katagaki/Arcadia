#import <Cocoa/Cocoa.h>
#import "CEFTypes.h"

NS_ASSUME_NONNULL_BEGIN

@class CEFBrowserController;

/// Callbacks from a browser, always delivered on the main thread.
@protocol CEFBrowserDelegate <NSObject>
@optional
- (void)browser:(CEFBrowserController *)browser didChangeURL:(NSString *)url;
- (void)browser:(CEFBrowserController *)browser didChangeTitle:(NSString *)title;
- (void)browser:(CEFBrowserController *)browser didChangeLoading:(BOOL)isLoading;
- (void)browser:(CEFBrowserController *)browser didChangeCanGoBack:(BOOL)canGoBack
       canGoForward:(BOOL)canGoForward;
- (void)browser:(CEFBrowserController *)browser didReceiveFavicon:(nullable NSData *)pngData;

/// Return NO to block a navigation. Used to forbid every non-http(s) scheme
/// (chrome://, devtools://, file://, ...) so Chromium-internal pages are
/// unreachable. The arcadia-cache:// scheme is allowed for offline replay.
- (BOOL)browser:(CEFBrowserController *)browser shouldAllowNavigationTo:(NSString *)url;

/// Fired (best-effort) when a password field is detected on the current page,
/// so the UI can offer "Stay signed in to this site?".
- (void)browserDidDetectLoginForm:(CEFBrowserController *)browser;

/// Fired when an offline capture (CEFOfflineModeCapture) has finished writing a
/// snapshot to disk.
- (void)browser:(CEFBrowserController *)browser didFinishCaptureToSnapshot:(NSString *)snapshotID;
@end


/// Configuration used to create a browser.
@interface CEFBrowserConfiguration : NSObject
@property (nonatomic) CEFStorageMode storageMode;
/// For persistent storage, the on-disk cache directory path; ignored otherwise.
@property (nonatomic, copy, nullable) NSString *persistentCachePath;
@property (nonatomic) CEFOfflineMode offlineMode;
/// For capture/replay, the snapshot directory; nil otherwise.
@property (nonatomic, copy, nullable) NSString *snapshotDirectory;
@end


/// Wraps a single CefBrowser bound to an NSView. One per BrowserSession.
@interface CEFBrowserController : NSObject

- (instancetype)initWithConfiguration:(CEFBrowserConfiguration *)configuration;

/// The native view hosting the rendered page; embed this in SwiftUI.
@property (nonatomic, readonly) NSView *view;
@property (nonatomic, weak, nullable) id<CEFBrowserDelegate> delegate;

@property (nonatomic, readonly, copy) NSString *currentURL;
@property (nonatomic, readonly, copy) NSString *currentTitle;
@property (nonatomic, readonly) BOOL isLoading;
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;

- (void)loadURL:(NSString *)url;
- (void)goBack;
- (void)goForward;
- (void)reload;
- (void)stopLoading;

/// Captures the current page to `snapshotDirectory` (HTML/CSS/images/media,
/// excluding JavaScript), then notifies the delegate.
- (void)captureSnapshotWithID:(NSString *)snapshotID;

/// Closes the browser and releases its request context. For ephemeral contexts
/// this is what deletes the site's cookies/cache.
- (void)close;

@end

NS_ASSUME_NONNULL_END
