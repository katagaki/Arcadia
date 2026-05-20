#import "CEFRequestContextFactory.h"
#import "CEFPrivacy.h"

namespace arcadia {

namespace {

// Re-applies privacy prefs once a freshly created context is initialized.
class PrivacyContextHandler : public CefRequestContextHandler {
public:
    void OnRequestContextInitialized(CefRefPtr<CefRequestContext> context) override {
        ArcadiaApplyPrivacyPreferences(context);
    }
private:
    IMPLEMENT_REFCOUNTING(PrivacyContextHandler);
};

}  // namespace

CefRefPtr<CefRequestContext> CreateEphemeralContext() {
    CefRequestContextSettings settings;
    // No cache_path => in-memory only.
    return CefRequestContext::CreateContext(settings, new PrivacyContextHandler());
}

CefRefPtr<CefRequestContext> CreatePersistentContext(const std::string& cachePath) {
    CefRequestContextSettings settings;
    CefString(&settings.cache_path).FromString(cachePath);
    return CefRequestContext::CreateContext(settings, new PrivacyContextHandler());
}

}  // namespace arcadia
