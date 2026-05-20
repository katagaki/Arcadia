#pragma once
#import <Foundation/Foundation.h>

/// Private bridge implemented by CEFBrowserController. The C++ client handler
/// forwards CEF callbacks here, always on the main thread.
@protocol CEFClientSink <NSObject>
- (void)sinkAfterCreated;
- (void)sinkURLChanged:(NSString *)url;
- (void)sinkTitleChanged:(NSString *)title;
- (void)sinkLoadingChanged:(BOOL)isLoading canGoBack:(BOOL)back canGoForward:(BOOL)forward;
- (void)sinkFaviconPNG:(NSData *)png;
- (void)sinkDidDetectLoginForm;
- (void)sinkCaptureFinished:(NSString *)snapshotID;
- (BOOL)sinkShouldAllowNavigationTo:(NSString *)url;
@end
