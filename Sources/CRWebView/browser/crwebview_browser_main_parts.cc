#include "arcadia/crwebview/browser/crwebview_browser_main_parts.h"

#include "content/public/common/result_codes.h"

namespace crwebview {

CRWebViewBrowserMainParts::CRWebViewBrowserMainParts() = default;
CRWebViewBrowserMainParts::~CRWebViewBrowserMainParts() = default;

int CRWebViewBrowserMainParts::PreMainMessageLoopRun() {
  // No global profile to set up; per-session contexts are created lazily by
  // CRWebView. Returning the sentinel keeps //content's normal run loop going.
  return content::RESULT_CODE_NORMAL_EXIT;
}

void CRWebViewBrowserMainParts::PostMainMessageLoopRun() {}

}  // namespace crwebview
