// Umbrella header for the CRWebView framework. Only pure Objective-C/Cocoa
// types are exposed; all Chromium //content C++ types stay inside the .mm files.
#import <Cocoa/Cocoa.h>
#import <CRWebView/CRTypes.h>
#import <CRWebView/CRWebEngine.h>
#import <CRWebView/CRSiteData.h>
#import <CRWebView/ArcadiaApplication.h>

NS_ASSUME_NONNULL_BEGIN

@class CRWebView;

/// Web view callbacks, always delivered on the main thread. Replaces
/// CEFBrowserDelegate (callbacks renamed browser: -> webView:).
@protocol CRWebViewDelegate <NSObject>
@optional
- (void)webView:(CRWebView *)webView
   didChangeURL:(NSString *)url
  userInitiated:(BOOL)userInitiated
    NS_SWIFT_NAME(webView(_:didChangeURL:userInitiated:));
- (void)webView:(CRWebView *)webView didChangeTitle:(NSString *)title;
- (void)webView:(CRWebView *)webView didChangeLoading:(BOOL)isLoading;
- (void)webView:(CRWebView *)webView didChangeCanGoBack:(BOOL)canGoBack
       canGoForward:(BOOL)canGoForward;
- (void)webView:(CRWebView *)webView didReceiveFavicon:(nullable NSData *)pngData;

/// Return NO to block a navigation (used to forbid non-web schemes).
- (BOOL)webView:(CRWebView *)webView shouldAllowNavigationTo:(NSString *)url;

/// Best-effort signal that the page has a password field.
- (void)webViewDidDetectLoginForm:(CRWebView *)webView;

- (void)webView:(CRWebView *)webView didFinishCaptureToSnapshot:(NSString *)snapshotID;
@end


/// Storage/offline/snapshot config. Replaces CEFBrowserConfiguration.
@interface CRWebViewConfiguration : NSObject
@property (nonatomic) CRStorageMode storageMode;
@property (nonatomic, copy, nullable) NSString *persistentProfilePath;
@property (nonatomic) CROfflineMode offlineMode;
@property (nonatomic, copy, nullable) NSString *snapshotDirectory;
@end


/// An NSView-backed Chromium web view bound to one content::WebContents. One per
/// BrowserSession. Replaces CEFBrowserController; -view hosts
/// WebContents::GetNativeView().
@interface CRWebView : NSObject

- (instancetype)initWithConfiguration:(CRWebViewConfiguration *)configuration;

@property (nonatomic, readonly) NSView *view;
@property (nonatomic, weak, nullable) id<CRWebViewDelegate> delegate;

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

/// Closes the web view and releases its context (wipes ephemeral cookies).
- (void)close;

@end

NS_ASSUME_NONNULL_END
