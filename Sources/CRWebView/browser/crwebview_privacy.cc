#include "arcadia/crwebview/browser/crwebview_privacy.h"

#include "services/network/public/mojom/cookie_manager.mojom.h"

namespace crwebview {

void ApplyThirdPartyCookieBlock(
    network::mojom::NetworkContextParams* network_context_params) {
  if (!network_context_params) {
    return;
  }
  if (!network_context_params->cookie_manager_params) {
    network_context_params->cookie_manager_params =
        network::mojom::CookieManagerParams::New();
  }
  network_context_params->cookie_manager_params->block_third_party_cookies =
      true;
}

}  // namespace crwebview
