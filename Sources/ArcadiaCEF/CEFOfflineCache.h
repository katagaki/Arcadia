#pragma once
#include "include/cef_resource_request_handler.h"
#include <string>

namespace arcadia {

// Capture: tees every loaded resource to `snapshotDir`, EXCEPT JavaScript
// (RT_SCRIPT), and records a manifest mapping original URL -> local file + MIME.
CefRefPtr<CefResourceRequestHandler> MakeCaptureResourceHandler(const std::string& snapshotDir);

// Replay: serves resources from `snapshotDir` by original URL and returns an
// empty 404 for any script request, so cached pages render without JS running.
CefRefPtr<CefResourceRequestHandler> MakeReplayResourceHandler(const std::string& snapshotDir);

// Stable on-disk filename for a resource URL within a snapshot.
std::string FileNameForURL(const std::string& url);

}  // namespace arcadia
