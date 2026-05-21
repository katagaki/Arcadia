#ifndef ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_BROWSER_MAIN_PARTS_H_
#define ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_BROWSER_MAIN_PARTS_H_

#include "content/public/browser/browser_main_parts.h"

namespace crwebview {

// Process-global browser startup/teardown. Arcadia creates BrowserContexts
// per-session (ephemeral vs on-disk), so this stays minimal — the analog of
// CEF's CefInitialize browser-process side, with no global profile to own.
class CRWebViewBrowserMainParts : public content::BrowserMainParts {
 public:
  CRWebViewBrowserMainParts();
  CRWebViewBrowserMainParts(const CRWebViewBrowserMainParts&) = delete;
  CRWebViewBrowserMainParts& operator=(const CRWebViewBrowserMainParts&) =
      delete;
  ~CRWebViewBrowserMainParts() override;

  // content::BrowserMainParts:
  int PreMainMessageLoopRun() override;
  void PostMainMessageLoopRun() override;
};

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_BROWSER_MAIN_PARTS_H_
