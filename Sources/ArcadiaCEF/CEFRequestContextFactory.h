#pragma once
#include "include/cef_request_context.h"
#include <string>

namespace arcadia {

/// In-memory context: cookies/cache vanish when the context is released.
CefRefPtr<CefRequestContext> CreateEphemeralContext();

/// On-disk context for login-persisted sites. `cachePath` is absolute.
CefRefPtr<CefRequestContext> CreatePersistentContext(const std::string& cachePath);

}  // namespace arcadia
