#import <CRWebView/CRWebView.h>

#import "arcadia/crwebview/browser/crwebview_browser_context.h"
#import "arcadia/crwebview/browser/crwebview_state.h"
#import "arcadia/crwebview/common/crwebview_offline_mode.h"

#include <memory>
#include <vector>

#include "base/files/file_path.h"
#include "base/functional/bind.h"
#include "base/strings/sys_string_conversions.h"
#include "content/public/browser/navigation_controller.h"
#include "content/public/browser/navigation_handle.h"
#include "content/public/browser/web_contents.h"
#include "content/public/browser/web_contents_observer.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "ui/gfx/codec/png_codec.h"
#include "ui/gfx/geometry/size.h"
#include "url/gurl.h"

namespace {

crwebview::OfflineMode ToOfflineMode(CROfflineMode mode) {
  switch (mode) {
    case CROfflineModeCapture: return crwebview::OfflineMode::kCapture;
    case CROfflineModeReplay:  return crwebview::OfflineMode::kReplay;
    case CROfflineModeNone:
    default:                   return crwebview::OfflineMode::kNone;
  }
}

NSString* SysUTF16ToNS(const std::u16string& s) {
  return base::SysUTF16ToNSString(s);
}

NSString* SysUTF8ToNS(const std::string& s) {
  return base::SysUTF8ToNSString(s);
}

}  // namespace

// Internal callbacks invoked by the C++ observer / login closure, on the main
// thread. Not part of the public surface.
@interface CRWebView ()
- (void)crw_urlChanged:(NSString*)url;
- (void)crw_titleChanged:(NSString*)title;
- (void)crw_loadingChanged:(BOOL)isLoading;
- (void)crw_navStateChanged;
- (void)crw_faviconPNG:(NSData*)png;
- (void)crw_loginFormDetected;
@end

// Forwards content::WebContents events to the owning CRWebView. The //content
// analog of CEF's ArcadiaClientHandler sink. All WebContentsObserver callbacks
// already arrive on the UI (main) thread, so no marshaling is needed.
class CRWebViewObserver : public content::WebContentsObserver {
 public:
  CRWebViewObserver(content::WebContents* contents, __weak CRWebView* owner)
      : content::WebContentsObserver(contents), owner_(owner) {}

  void TitleWasSet(content::NavigationEntry* entry) override {
    [owner_ crw_titleChanged:SysUTF16ToNS(web_contents()->GetTitle())];
  }

  void DidStartLoading() override { [owner_ crw_loadingChanged:YES]; }
  void DidStopLoading() override { [owner_ crw_loadingChanged:NO]; }

  void DidFinishNavigation(content::NavigationHandle* handle) override {
    if (!handle->IsInPrimaryMainFrame() || !handle->HasCommitted()) {
      return;
    }
    [owner_ crw_urlChanged:SysUTF8ToNS(
                              web_contents()->GetLastCommittedURL().spec())];
    [owner_ crw_navStateChanged];
  }

  void DidUpdateFaviconURL(
      content::RenderFrameHost*,
      const std::vector<blink::mojom::FaviconURLPtr>& candidates) override {
    if (candidates.empty()) {
      return;
    }
    __weak CRWebView* owner = owner_;
    web_contents()->DownloadImage(
        candidates.front()->icon_url, /*is_favicon=*/true, gfx::Size(),
        /*max_bitmap_size=*/64, /*bypass_cache=*/false,
        base::BindOnce(
            [](__weak CRWebView* w, int, int, const GURL&,
               const std::vector<SkBitmap>& bitmaps,
               const std::vector<gfx::Size>&) {
              if (bitmaps.empty()) {
                return;
              }
              std::optional<std::vector<uint8_t>> png =
                  gfx::PNGCodec::EncodeBGRASkBitmap(bitmaps.front(),
                                                    /*discard_transparency=*/false);
              if (!png) {
                return;
              }
              [w crw_faviconPNG:[NSData dataWithBytes:png->data()
                                              length:png->size()]];
            },
            owner));
  }

 private:
  __weak CRWebView* owner_;
};

@implementation CRWebViewConfiguration
@end

@implementation CRWebView {
  NSView* _container;
  std::unique_ptr<crwebview::CRWebViewBrowserContext> _context;
  std::unique_ptr<content::WebContents> _webContents;
  std::unique_ptr<CRWebViewObserver> _observer;
  CRWebViewConfiguration* _config;

  NSString* _currentURL;
  NSString* _currentTitle;
  BOOL _isLoading;
  BOOL _canGoBack;
  BOOL _canGoForward;
  NSString* _pendingCaptureID;
}

- (instancetype)initWithConfiguration:(CRWebViewConfiguration*)configuration {
  if ((self = [super init])) {
    _config = configuration;
    _currentURL = @"";
    _currentTitle = @"";
    _container = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    _container.wantsLayer = YES;
    [self crw_createWebContents];
  }
  return self;
}

- (NSView*)view { return _container; }
- (NSString*)currentURL { return _currentURL; }
- (NSString*)currentTitle { return _currentTitle; }
- (BOOL)isLoading { return _isLoading; }
- (BOOL)canGoBack { return _canGoBack; }
- (BOOL)canGoForward { return _canGoForward; }

- (void)crw_createWebContents {
  if (_config.storageMode == CRStorageModePersistent &&
      _config.persistentProfilePath.length) {
    _context = crwebview::CreatePersistentContext(
        base::FilePath(_config.persistentProfilePath.UTF8String));
  } else {
    _context = crwebview::CreateEphemeralContext();
  }

  content::WebContents::CreateParams params(_context.get());
  _webContents = content::WebContents::Create(params);

  // Carry per-session offline config + login routing for the browser-process
  // embedder to find (CRWebViewContentBrowserClient).
  crwebview::CRWebViewState::CreateForWebContents(_webContents.get());
  auto* state = crwebview::CRWebViewState::FromWebContents(_webContents.get());
  state->offline_mode = ToOfflineMode(_config.offlineMode);
  if (_config.snapshotDirectory.length) {
    state->snapshot_dir =
        base::FilePath(_config.snapshotDirectory.UTF8String);
  }
  __weak CRWebView* weakSelf = self;
  state->on_login_detected = base::BindRepeating(
      [](__weak CRWebView* w) { [w crw_loginFormDetected]; }, weakSelf);

  _observer = std::make_unique<CRWebViewObserver>(_webContents.get(), self);

  NSView* native = _webContents->GetNativeView().GetNativeNSView();
  native.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  native.frame = _container.bounds;
  [_container addSubview:native];
}

- (void)load:(NSString*)url {
  if (!_webContents) {
    return;
  }
  content::NavigationController::LoadURLParams params(
      GURL(url.UTF8String));
  _webContents->GetController().LoadURLWithParams(params);
}

- (void)goBack {
  if (_webContents && _webContents->GetController().CanGoBack()) {
    _webContents->GetController().GoBack();
  }
}

- (void)goForward {
  if (_webContents && _webContents->GetController().CanGoForward()) {
    _webContents->GetController().GoForward();
  }
}

- (void)reload {
  if (_webContents) {
    _webContents->GetController().Reload(content::ReloadType::NORMAL, false);
  }
}

- (void)stopLoading {
  if (_webContents) {
    _webContents->Stop();
  }
}

- (void)captureSnapshotWithID:(NSString*)snapshotID {
  // Capture mode tees resources during load; reload to populate the snapshot.
  _pendingCaptureID = snapshotID;
  [self reload];
}

- (void)close {
  // Destroy WebContents (and its CRWebViewState) before the context it points
  // at; ephemeral contexts wipe their in-memory storage on destruction.
  _observer.reset();
  _webContents.reset();
  _context.reset();
}

#pragma mark - Observer callbacks (main thread)

- (void)crw_urlChanged:(NSString*)url {
  _currentURL = url;
  if ([_delegate respondsToSelector:@selector(webView:didChangeURL:)]) {
    [_delegate webView:self didChangeURL:url];
  }
}

- (void)crw_titleChanged:(NSString*)title {
  _currentTitle = title;
  if ([_delegate respondsToSelector:@selector(webView:didChangeTitle:)]) {
    [_delegate webView:self didChangeTitle:title];
  }
}

- (void)crw_loadingChanged:(BOOL)isLoading {
  _isLoading = isLoading;
  if ([_delegate respondsToSelector:@selector(webView:didChangeLoading:)]) {
    [_delegate webView:self didChangeLoading:isLoading];
  }
  if (!isLoading && _pendingCaptureID) {
    NSString* sid = _pendingCaptureID;
    _pendingCaptureID = nil;
    if ([_delegate respondsToSelector:@selector(webView:
                                          didFinishCaptureToSnapshot:)]) {
      [_delegate webView:self didFinishCaptureToSnapshot:sid];
    }
  }
}

- (void)crw_navStateChanged {
  if (!_webContents) {
    return;
  }
  _canGoBack = _webContents->GetController().CanGoBack();
  _canGoForward = _webContents->GetController().CanGoForward();
  if ([_delegate respondsToSelector:@selector(webView:
                                        didChangeCanGoBack:canGoForward:)]) {
    [_delegate webView:self
        didChangeCanGoBack:_canGoBack
              canGoForward:_canGoForward];
  }
}

- (void)crw_faviconPNG:(NSData*)png {
  if ([_delegate respondsToSelector:@selector(webView:didReceiveFavicon:)]) {
    [_delegate webView:self didReceiveFavicon:png];
  }
}

- (void)crw_loginFormDetected {
  if ([_delegate respondsToSelector:@selector(webViewDidDetectLoginForm:)]) {
    [_delegate webViewDidDetectLoginForm:self];
  }
}

@end
