#pragma once
#include "include/cef_resource_request_handler.h"
#include <string>

namespace arcadia {

/// Tees every loaded resource to `snapshotDir` except JavaScript, recording a
/// manifest of original URL to local file and MIME type.
CefRefPtr<CefResourceRequestHandler> MakeCaptureResourceHandler(const std::string& snapshotDir);

/// Serves resources from `snapshotDir` by original URL; returns 404 for scripts.
CefRefPtr<CefResourceRequestHandler> MakeReplayResourceHandler(const std::string& snapshotDir);

std::string FileNameForURL(const std::string& url);

}  // namespace arcadia
