#import "CEFRequestContextFactory.h"
#import "CEFPrivacy.h"

namespace arcadia {

namespace {

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
    CefRequestContextSettings settings;  // no cache_path => in-memory
    return CefRequestContext::CreateContext(settings, new PrivacyContextHandler());
}

CefRefPtr<CefRequestContext> CreatePersistentContext(const std::string& cachePath) {
    CefRequestContextSettings settings;
    CefString(&settings.cache_path).FromString(cachePath);
    return CefRequestContext::CreateContext(settings, new PrivacyContextHandler());
}

}  // namespace arcadia
