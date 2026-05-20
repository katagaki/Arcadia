#pragma once
#import <Foundation/Foundation.h>

@class CefBrowserHandle;

// Private bridge protocol implemented by CEFBrowserController. The C++ client
// handler forwards CEF callbacks here, always on the main thread.
@protocol CEFClientSink <NSObject>
- (void)sinkAfterCreated;
- (void)sinkURLChanged:(NSString *)url;
- (void)sinkTitleChanged:(NSString *)title;
- (void)sinkLoadingChanged:(BOOL)isLoading canGoBack:(BOOL)back canGoForward:(BOOL)forward;
- (void)sinkFaviconPNG:(NSData *)png;
- (void)sinkDidDetectLoginForm;
- (void)sinkCaptureFinished:(NSString *)snapshotID;
// Return YES to allow navigation to `url`, NO to block it.
- (BOOL)sinkShouldAllowNavigationTo:(NSString *)url;
@end
