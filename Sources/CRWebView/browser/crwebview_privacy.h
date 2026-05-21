#ifndef ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_PRIVACY_H_
#define ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_PRIVACY_H_

#include "services/network/public/mojom/network_context.mojom.h"

namespace crwebview {

// Blocks third-party cookies for a context, with no way to turn it off. Applied
// to every NetworkContext at creation (CRWebViewContentBrowserClient::
// ConfigureNetworkContextParams). The //content replacement for CEF's always-on
// profile.cookie_controls_mode = kBlockThirdParty preference.
void ApplyThirdPartyCookieBlock(
    network::mojom::NetworkContextParams* network_context_params);

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_PRIVACY_H_
