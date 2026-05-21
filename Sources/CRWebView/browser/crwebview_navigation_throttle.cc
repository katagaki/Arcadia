#include "arcadia/crwebview/browser/crwebview_navigation_throttle.h"

#include <memory>
#include <string_view>

#include "arcadia/crwebview/common/crwebview_scheme_constants.h"
#include "content/public/browser/navigation_handle.h"
#include "url/gurl.h"

namespace crwebview {

namespace {

bool IsAllowedScheme(std::string_view scheme) {
  return scheme == "http" || scheme == "https" ||
         scheme == kArcadiaCacheScheme || scheme == "about";
}

}  // namespace

// static
void CRWebViewSchemeNavigationThrottle::MaybeCreateAndAdd(
    content::NavigationThrottleRegistry& registry) {
  registry.AddThrottle(
      std::make_unique<CRWebViewSchemeNavigationThrottle>(registry));
}

CRWebViewSchemeNavigationThrottle::CRWebViewSchemeNavigationThrottle(
    content::NavigationThrottleRegistry& registry)
    : content::NavigationThrottle(registry) {}

CRWebViewSchemeNavigationThrottle::~CRWebViewSchemeNavigationThrottle() =
    default;

content::NavigationThrottle::ThrottleCheckResult
CRWebViewSchemeNavigationThrottle::WillStartRequest() {
  return CheckScheme();
}

content::NavigationThrottle::ThrottleCheckResult
CRWebViewSchemeNavigationThrottle::WillRedirectRequest() {
  return CheckScheme();
}

const char* CRWebViewSchemeNavigationThrottle::GetNameForLogging() {
  return "CRWebViewSchemeNavigationThrottle";
}

content::NavigationThrottle::ThrottleCheckResult
CRWebViewSchemeNavigationThrottle::CheckScheme() {
  const GURL& url = navigation_handle()->GetURL();
  if (IsAllowedScheme(url.scheme_piece())) {
    return PROCEED;
  }
  return CANCEL_AND_IGNORE;
}

}  // namespace crwebview
