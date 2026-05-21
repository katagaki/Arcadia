#import "CEFPrivacy.h"
#include "include/cef_values.h"

void ArcadiaApplyPrivacyPreferences(CefRefPtr<CefRequestContext> context) {
    if (!context) { return; }
    if (!context->CanSetPreference("profile.cookie_controls_mode")) { return; }

    // 1 == CookieControlsMode::kBlockThirdParty.
    CefRefPtr<CefValue> blockThirdParty = CefValue::Create();
    blockThirdParty->SetInt(1);

    CefString error;
    context->SetPreference("profile.cookie_controls_mode", blockThirdParty, error);
}
