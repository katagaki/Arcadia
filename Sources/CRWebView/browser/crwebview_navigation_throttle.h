#ifndef ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_NAVIGATION_THROTTLE_H_
#define ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_NAVIGATION_THROTTLE_H_

#include "content/public/browser/navigation_throttle.h"

namespace crwebview {

// Cancels navigations to non-web schemes, allowing only http/https,
// arcadia-cache, and about:. This is the //content replacement for CEF's
// OnBeforeBrowse returning true to block (it kept out chrome://, devtools://,
// file://, and other Chromium-internal schemes).
class CRWebViewSchemeNavigationThrottle : public content::NavigationThrottle {
 public:
  static void MaybeCreateAndAdd(
      content::NavigationThrottleRegistry& registry);

  explicit CRWebViewSchemeNavigationThrottle(
      content::NavigationThrottleRegistry& registry);
  ~CRWebViewSchemeNavigationThrottle() override;

  // content::NavigationThrottle:
  ThrottleCheckResult WillStartRequest() override;
  ThrottleCheckResult WillRedirectRequest() override;
  const char* GetNameForLogging() override;

 private:
  ThrottleCheckResult CheckScheme();
};

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_NAVIGATION_THROTTLE_H_
