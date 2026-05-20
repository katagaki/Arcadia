#pragma once
#include "include/cef_request_context.h"
#include <string>

// Creates request contexts with Arcadia's privacy settings already applied.
namespace arcadia {

// In-memory context: cookies/cache vanish when the context is released. This is
// the default for all browsing ("deleted when closed completely").
CefRefPtr<CefRequestContext> CreateEphemeralContext();

// On-disk context for sites where the user opted to persist login. `cachePath`
// is an absolute directory path.
CefRefPtr<CefRequestContext> CreatePersistentContext(const std::string& cachePath);

}  // namespace arcadia
