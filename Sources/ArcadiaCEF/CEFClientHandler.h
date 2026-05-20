#pragma once
#import "CEFClientSink.h"
#import "ArcadiaCEF/CEFTypes.h"

#include "include/cef_client.h"
#include <string>

// CefClient that aggregates the handlers Arcadia needs and forwards results to
// an ObjC sink (CEFBrowserController). Also enforces the scheme allow-list and
// drives offline capture/replay.
class ArcadiaClientHandler : public CefClient,
                             public CefLifeSpanHandler,
                             public CefLoadHandler,
                             public CefDisplayHandler,
                             public CefRequestHandler {
public:
    ArcadiaClientHandler(id<CEFClientSink> sink,
                         CEFOfflineMode offlineMode,
                         const std::string& snapshotDirectory);

    CefRefPtr<CefBrowser> browser() const { return browser_; }

    // CefClient
    CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override { return this; }
    CefRefPtr<CefLoadHandler> GetLoadHandler() override { return this; }
    CefRefPtr<CefDisplayHandler> GetDisplayHandler() override { return this; }
    CefRefPtr<CefRequestHandler> GetRequestHandler() override { return this; }

    // CefLifeSpanHandler
    void OnAfterCreated(CefRefPtr<CefBrowser> browser) override;
    void OnBeforeClose(CefRefPtr<CefBrowser> browser) override;

    // CefLoadHandler
    void OnLoadingStateChange(CefRefPtr<CefBrowser> browser, bool isLoading,
                              bool canGoBack, bool canGoForward) override;

    // CefDisplayHandler
    void OnTitleChange(CefRefPtr<CefBrowser> browser, const CefString& title) override;
    void OnAddressChange(CefRefPtr<CefBrowser> browser, CefRefPtr<CefFrame> frame,
                         const CefString& url) override;
    void OnFaviconURLChange(CefRefPtr<CefBrowser> browser,
                            const std::vector<CefString>& icon_urls) override;

    // CefRequestHandler
    bool OnBeforeBrowse(CefRefPtr<CefBrowser> browser, CefRefPtr<CefFrame> frame,
                        CefRefPtr<CefRequest> request, bool user_gesture,
                        bool is_redirect) override;
    CefRefPtr<CefResourceRequestHandler> GetResourceRequestHandler(
        CefRefPtr<CefBrowser> browser, CefRefPtr<CefFrame> frame,
        CefRefPtr<CefRequest> request, bool is_navigation, bool is_download,
        const CefString& request_initiator, bool& disable_default_handling) override;

private:
    __weak id<CEFClientSink> sink_;
    CefRefPtr<CefBrowser> browser_;
    CEFOfflineMode offlineMode_;
    std::string snapshotDirectory_;

    IMPLEMENT_REFCOUNTING(ArcadiaClientHandler);
    DISALLOW_COPY_AND_ASSIGN(ArcadiaClientHandler);
};
