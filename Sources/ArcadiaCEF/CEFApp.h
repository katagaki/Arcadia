#pragma once
#include "include/cef_app.h"

// Factory for the browser-process CefApp. Implemented in CEFApp.mm.
CefRefPtr<CefApp> ArcadiaCreateBrowserProcessApp();
