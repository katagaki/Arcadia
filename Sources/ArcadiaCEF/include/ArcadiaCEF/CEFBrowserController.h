#import <Cocoa/Cocoa.h>
#import "CEFTypes.h"

NS_ASSUME_NONNULL_BEGIN

@class CEFBrowserController;

/// Browser callbacks, always delivered on the main thread.
@protocol CEFBrowserDelegate <NSObject>
@optional
- (void)browser:(CEFBrowserController *)browser didChangeURL:(NSString *)url;
- (void)browser:(CEFBrowserController *)browser didChangeTitle:(NSString *)title;
- (void)browser:(CEFBrowserController *)browser didChangeLoading:(BOOL)isLoading;
- (void)browser:(CEFBrowserController *)browser didChangeCanGoBack:(BOOL)canGoBack
       canGoForward:(BOOL)canGoForward;
- (void)browser:(CEFBrowserController *)browser didReceiveFavicon:(nullable NSData *)pngData;

/// Return NO to block a navigation (used to forbid non-web schemes).
- (BOOL)browser:(CEFBrowserController *)browser shouldAllowNavigationTo:(NSString *)url;

/// Best-effort signal that the page has a password field.
- (void)browserDidDetectLoginForm:(CEFBrowserController *)browser;

- (void)browser:(CEFBrowserController *)browser didFinishCaptureToSnapshot:(NSString *)snapshotID;
@end


@interface CEFBrowserConfiguration : NSObject
@property (nonatomic) CEFStorageMode storageMode;
@property (nonatomic, copy, nullable) NSString *persistentCachePath;
@property (nonatomic) CEFOfflineMode offlineMode;
@property (nonatomic, copy, nullable) NSString *snapshotDirectory;
@end


/// Wraps a single CefBrowser bound to an NSView. One per BrowserSession.
@interface CEFBrowserController : NSObject

- (instancetype)initWithConfiguration:(CEFBrowserConfiguration *)configuration;

@property (nonatomic, readonly) NSView *view;
@property (nonatomic, weak, nullable) id<CEFBrowserDelegate> delegate;

@property (nonatomic, readonly, copy) NSString *currentURL;
@property (nonatomic, readonly, copy) NSString *currentTitle;
@property (nonatomic, readonly) BOOL isLoading;
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;

- (void)load:(NSString *)url;
- (void)goBack;
- (void)goForward;
- (void)reload;
- (void)stopLoading;

/// Captures the current page to `snapshotDirectory`, excluding JavaScript.
- (void)captureSnapshotWithID:(NSString *)snapshotID;

/// Closes the browser and releases its context (wipes ephemeral cookies).
- (void)close;

@end

NS_ASSUME_NONNULL_END
