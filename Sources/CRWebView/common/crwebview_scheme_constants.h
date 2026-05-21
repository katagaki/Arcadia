#ifndef ARCADIA_CRWEBVIEW_COMMON_CRWEBVIEW_SCHEME_CONSTANTS_H_
#define ARCADIA_CRWEBVIEW_COMMON_CRWEBVIEW_SCHEME_CONSTANTS_H_

namespace crwebview {

// Scheme used to replay offline snapshots. Registered as standard + secure.
// Only http/https, this scheme, and about: are allowed to navigate (see
// CRWebViewSchemeNavigationThrottle).
inline constexpr char kArcadiaCacheScheme[] = "arcadia-cache";

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_COMMON_CRWEBVIEW_SCHEME_CONSTANTS_H_
