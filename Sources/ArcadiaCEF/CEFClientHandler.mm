#import "CEFClientHandler.h"
#import "CEFSchemeConstants.h"
#import "CEFOfflineCache.h"

#include "include/cef_browser.h"
#include "include/cef_image.h"
#include "include/cef_parser.h"

namespace {

void OnMain(void (^block)(void)) {
    if ([NSThread isMainThread]) { block(); }
    else { dispatch_async(dispatch_get_main_queue(), block); }
}

NSString* ToNS(const CefString& s) {
    const std::string u = s.ToString();
    return [NSString stringWithUTF8String:u.c_str()] ?: @"";
}

bool IsAllowedScheme(const std::string& scheme) {
    return scheme == "http" || scheme == "https" ||
           scheme == ARCADIA_CACHE_SCHEME || scheme == "about";
}

class FaviconImageCallback : public CefDownloadImageCallback {
public:
    explicit FaviconImageCallback(__weak id<CEFClientSink> sink) : sink_(sink) {}
    void OnDownloadImageFinished(const CefString&, int, CefRefPtr<CefImage> image) override {
        if (!image) { return; }
        int w = 0, h = 0;
        CefRefPtr<CefBinaryValue> data = image->GetAsPNG(1.0f, true, w, h);
        if (!data) { return; }
        size_t size = data->GetSize();
        NSMutableData* bytes = [NSMutableData dataWithLength:size];
        data->GetData([bytes mutableBytes], size, 0);
        __weak id<CEFClientSink> sink = sink_;
        OnMain(^{ [sink sinkFaviconPNG:bytes]; });
    }
private:
    __weak id<CEFClientSink> sink_;
    IMPLEMENT_REFCOUNTING(FaviconImageCallback);
};

}  // namespace

ArcadiaClientHandler::ArcadiaClientHandler(id<CEFClientSink> sink,
                                           CEFOfflineMode offlineMode,
                                           const std::string& snapshotDirectory)
    : sink_(sink), offlineMode_(offlineMode), snapshotDirectory_(snapshotDirectory) {}

void ArcadiaClientHandler::OnAfterCreated(CefRefPtr<CefBrowser> browser) {
    browser_ = browser;
    __weak id<CEFClientSink> sink = sink_;
    OnMain(^{ [sink sinkAfterCreated]; });
}

void ArcadiaClientHandler::OnBeforeClose(CefRefPtr<CefBrowser> browser) {
    browser_ = nullptr;
}

void ArcadiaClientHandler::OnLoadingStateChange(CefRefPtr<CefBrowser> browser,
                                                bool isLoading, bool canGoBack,
                                                bool canGoForward) {
    __weak id<CEFClientSink> sink = sink_;
    OnMain(^{ [sink sinkLoadingChanged:isLoading canGoBack:canGoBack canGoForward:canGoForward]; });
}

void ArcadiaClientHandler::OnTitleChange(CefRefPtr<CefBrowser> browser,
                                         const CefString& title) {
    NSString* t = ToNS(title);
    __weak id<CEFClientSink> sink = sink_;
    OnMain(^{ [sink sinkTitleChanged:t]; });
}

void ArcadiaClientHandler::OnAddressChange(CefRefPtr<CefBrowser> browser,
                                           CefRefPtr<CefFrame> frame,
                                           const CefString& url) {
    if (!frame->IsMain()) { return; }
    NSString* u = ToNS(url);
    __weak id<CEFClientSink> sink = sink_;
    OnMain(^{ [sink sinkURLChanged:u]; });
}

void ArcadiaClientHandler::OnFaviconURLChange(CefRefPtr<CefBrowser> browser,
                                              const std::vector<CefString>& icon_urls) {
    if (icon_urls.empty()) { return; }
    browser->GetHost()->DownloadImage(icon_urls.front(), /*is_favicon*/ true,
                                      /*max_image_size*/ 64, /*bypass_cache*/ false,
                                      new FaviconImageCallback(sink_));
}

bool ArcadiaClientHandler::OnBeforeBrowse(CefRefPtr<CefBrowser> browser,
                                          CefRefPtr<CefFrame> frame,
                                          CefRefPtr<CefRequest> request,
                                          bool user_gesture, bool is_redirect) {
    CefURLParts parts;
    CefParseURL(request->GetURL(), parts);
    const std::string scheme = CefString(&parts.scheme).ToString();

    // Block every Chromium-internal / non-web scheme.
    if (!IsAllowedScheme(scheme)) { return true; }

    __block BOOL allowed = YES;
    NSString* url = ToNS(request->GetURL());
    __weak id<CEFClientSink> sink = sink_;
    if ([NSThread isMainThread]) {
        allowed = [sink sinkShouldAllowNavigationTo:url];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            allowed = [sink sinkShouldAllowNavigationTo:url];
        });
    }
    return allowed ? false : true;
}

CefRefPtr<CefResourceRequestHandler> ArcadiaClientHandler::GetResourceRequestHandler(
    CefRefPtr<CefBrowser> browser, CefRefPtr<CefFrame> frame,
    CefRefPtr<CefRequest> request, bool is_navigation, bool is_download,
    const CefString& request_initiator, bool& disable_default_handling) {
    switch (offlineMode_) {
        case CEFOfflineModeCapture:
            return arcadia::MakeCaptureResourceHandler(snapshotDirectory_);
        case CEFOfflineModeReplay:
            disable_default_handling = true;
            return arcadia::MakeReplayResourceHandler(snapshotDirectory_);
        case CEFOfflineModeNone:
        default:
            return nullptr;
    }
}
