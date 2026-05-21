#pragma once
#include "include/cef_request_context.h"

/// Blocks third-party cookies on a context, with no way to turn it off.
/// Applied to the global context and to every per-site context.
void ArcadiaApplyPrivacyPreferences(CefRefPtr<CefRequestContext> context);
