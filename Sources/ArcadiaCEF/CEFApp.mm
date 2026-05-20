#import "CEFApp.h"
#import "CEFSchemeConstants.h"
#import "CEFPrivacy.h"

#include "include/cef_browser_process_handler.h"
#include "include/cef_scheme.h"

namespace {

// Browser-process application handler.
class ArcadiaBrowserApp : public CefApp, public CefBrowserProcessHandler {
public:
    ArcadiaBrowserApp() = default;

    CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override {
        return this;
    }

    // Register the offline-replay scheme as standard + secure in every process.
    void OnRegisterCustomSchemes(CefRawPtr<CefSchemeRegistrar> registrar) override {
        registrar->AddCustomScheme(
            ARCADIA_CACHE_SCHEME,
            CEF_SCHEME_OPTION_STANDARD | CEF_SCHEME_OPTION_SECURE |
            CEF_SCHEME_OPTION_CORS_ENABLED);
    }

    // Apply always-on privacy to the GLOBAL context once it is ready. Every
    // per-site context created later also re-applies this (see CEFPrivacy).
    void OnContextInitialized() override {
        ArcadiaApplyPrivacyPreferences(CefRequestContext::GetGlobalContext());
    }

private:
    IMPLEMENT_REFCOUNTING(ArcadiaBrowserApp);
    DISALLOW_COPY_AND_ASSIGN(ArcadiaBrowserApp);
};

}  // namespace

CefRefPtr<CefApp> ArcadiaCreateBrowserProcessApp() {
    return new ArcadiaBrowserApp();
}
