#import "CEFPrivacy.h"
#include "include/cef_values.h"

void ArcadiaApplyPrivacyPreferences(CefRefPtr<CefRequestContext> context) {
    if (!context) { return; }

    // Preferences can only be set once the context is fully initialized.
    if (!context->CanSetPreference("profile.cookie_controls_mode")) {
        return;
    }

    // Chromium's cookie-controls mode. Value 1 == "block third-party cookies"
    // (CookieControlsMode::kBlockThirdParty). There is intentionally no UI to
    // change this.
    CefRefPtr<CefValue> blockThirdParty = CefValue::Create();
    blockThirdParty->SetInt(1);

    CefString error;
    context->SetPreference("profile.cookie_controls_mode", blockThirdParty, error);
}
