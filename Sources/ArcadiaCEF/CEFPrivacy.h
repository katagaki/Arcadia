#pragma once
#include "include/cef_request_context.h"

// Applies Arcadia's always-on privacy settings to a request context:
// third-party cookies are blocked and there is no way to turn this off.
// Called for the global context and for every per-site context.
void ArcadiaApplyPrivacyPreferences(CefRefPtr<CefRequestContext> context);
