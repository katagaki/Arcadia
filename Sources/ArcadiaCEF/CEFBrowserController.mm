#import "ArcadiaCEF/CEFBrowserController.h"
#import "CEFClientHandler.h"
#import "CEFClientSink.h"
#import "CEFRequestContextFactory.h"

#include "include/cef_browser.h"
#include "include/cef_request_context.h"

@implementation CEFBrowserConfiguration
@end

@interface CEFBrowserController () <CEFClientSink>
@end

@implementation CEFBrowserController {
    NSView *_container;
    CefRefPtr<ArcadiaClientHandler> _client;
    CefRefPtr<CefRequestContext> _context;
    CEFBrowserConfiguration *_config;

    NSString *_currentURL;
    NSString *_currentTitle;
    BOOL _isLoading;
    BOOL _canGoBack;
    BOOL _canGoForward;
    NSString *_pendingCaptureID;
}

- (instancetype)initWithConfiguration:(CEFBrowserConfiguration *)configuration {
    if ((self = [super init])) {
        _config = configuration;
        _currentURL = @"";
        _currentTitle = @"";
        _container = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
        _container.wantsLayer = YES;
        [self createBrowser];
    }
    return self;
}

- (NSView *)view { return _container; }
- (NSString *)currentURL { return _currentURL; }
- (NSString *)currentTitle { return _currentTitle; }
- (BOOL)isLoading { return _isLoading; }
- (BOOL)canGoBack { return _canGoBack; }
- (BOOL)canGoForward { return _canGoForward; }

- (void)createBrowser {
    // Choose the request context: ephemeral by default; persistent only for
    // login-persisted sites.
    if (_config.storageMode == CEFStorageModePersistent && _config.persistentCachePath.length) {
        _context = arcadia::CreatePersistentContext(_config.persistentCachePath.UTF8String);
    } else {
        _context = arcadia::CreateEphemeralContext();
    }

    std::string snapshotDir = _config.snapshotDirectory.length
        ? std::string(_config.snapshotDirectory.UTF8String) : std::string();
    _client = new ArcadiaClientHandler(self, _config.offlineMode, snapshotDir);

    CefWindowInfo window_info;
    CefRect bounds(0, 0, (int)NSWidth(_container.bounds), (int)NSHeight(_container.bounds));
    window_info.SetAsChild((__bridge CefWindowHandle)_container, bounds);

    CefBrowserSettings browser_settings;

    // Start blank; the app drives the first real navigation.
    CefBrowserHost::CreateBrowser(window_info, _client.get(), CefString("about:blank"),
                                  browser_settings, nullptr, _context);
}

- (void)loadURL:(NSString *)url {
    if (!_client || !_client->browser()) { return; }
    _client->browser()->GetMainFrame()->LoadURL(CefString(url.UTF8String));
}

- (void)goBack { if (_client && _client->browser()) { _client->browser()->GoBack(); } }
- (void)goForward { if (_client && _client->browser()) { _client->browser()->GoForward(); } }
- (void)reload { if (_client && _client->browser()) { _client->browser()->Reload(); } }
- (void)stopLoading { if (_client && _client->browser()) { _client->browser()->StopLoad(); } }

- (void)captureSnapshotWithID:(NSString *)snapshotID {
    // Capture mode tees resources during load; force a reload to (re)populate
    // the snapshot, then notify on the next load-complete.
    _pendingCaptureID = snapshotID;
    [self reload];
}

- (void)close {
    if (_client && _client->browser()) {
        _client->browser()->GetHost()->CloseBrowser(/*force_close*/ true);
    }
    // Releasing the ephemeral context here is what wipes the site's cookies.
    _client = nullptr;
    _context = nullptr;
}

#pragma mark - CEFClientSink (main thread)

- (void)sinkAfterCreated {
    // Resize the child browser view to fill the container as it grows.
    for (NSView *sub in _container.subviews) {
        sub.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        sub.frame = _container.bounds;
    }
}

- (void)sinkURLChanged:(NSString *)url {
    _currentURL = url;
    if ([_delegate respondsToSelector:@selector(browser:didChangeURL:)]) {
        [_delegate browser:self didChangeURL:url];
    }
}

- (void)sinkTitleChanged:(NSString *)title {
    _currentTitle = title;
    if ([_delegate respondsToSelector:@selector(browser:didChangeTitle:)]) {
        [_delegate browser:self didChangeTitle:title];
    }
}

- (void)sinkLoadingChanged:(BOOL)isLoading canGoBack:(BOOL)back canGoForward:(BOOL)forward {
    _isLoading = isLoading;
    _canGoBack = back;
    _canGoForward = forward;
    if ([_delegate respondsToSelector:@selector(browser:didChangeLoading:)]) {
        [_delegate browser:self didChangeLoading:isLoading];
    }
    if ([_delegate respondsToSelector:@selector(browser:didChangeCanGoBack:canGoForward:)]) {
        [_delegate browser:self didChangeCanGoBack:back canGoForward:forward];
    }
    if (!isLoading && _pendingCaptureID) {
        NSString *sid = _pendingCaptureID;
        _pendingCaptureID = nil;
        [self sinkCaptureFinished:sid];
    }
}

- (void)sinkFaviconPNG:(NSData *)png {
    if ([_delegate respondsToSelector:@selector(browser:didReceiveFavicon:)]) {
        [_delegate browser:self didReceiveFavicon:png];
    }
}

- (void)sinkDidDetectLoginForm {
    if ([_delegate respondsToSelector:@selector(browserDidDetectLoginForm:)]) {
        [_delegate browserDidDetectLoginForm:self];
    }
}

- (void)sinkCaptureFinished:(NSString *)snapshotID {
    if ([_delegate respondsToSelector:@selector(browser:didFinishCaptureToSnapshot:)]) {
        [_delegate browser:self didFinishCaptureToSnapshot:snapshotID];
    }
}

- (BOOL)sinkShouldAllowNavigationTo:(NSString *)url {
    if ([_delegate respondsToSelector:@selector(browser:shouldAllowNavigationTo:)]) {
        return [_delegate browser:self shouldAllowNavigationTo:url];
    }
    return YES;
}

@end
