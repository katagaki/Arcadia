#include "arcadia/crwebview/browser/crwebview_content_browser_client.h"

#include <utility>

#include "arcadia/crwebview/browser/crwebview_browser_main_parts.h"
#include "arcadia/crwebview/browser/crwebview_login_form_detector_impl.h"
#include "arcadia/crwebview/browser/crwebview_navigation_throttle.h"
#include "arcadia/crwebview/browser/crwebview_offline_url_loader_factory.h"
#include "arcadia/crwebview/browser/crwebview_privacy.h"
#include "arcadia/crwebview/common/crwebview.mojom.h"
#include "arcadia/crwebview/common/crwebview_scheme_constants.h"
#include "base/functional/bind.h"
#include "content/public/browser/render_frame_host.h"
#include "content/public/browser/web_contents.h"
#include "mojo/public/cpp/bindings/binder_map.h"

namespace crwebview {

CRWebViewContentBrowserClient::CRWebViewContentBrowserClient() = default;
CRWebViewContentBrowserClient::~CRWebViewContentBrowserClient() = default;

std::unique_ptr<content::BrowserMainParts>
CRWebViewContentBrowserClient::CreateBrowserMainParts(bool is_integration_test) {
  return std::make_unique<CRWebViewBrowserMainParts>();
}

void CRWebViewContentBrowserClient::ConfigureNetworkContextParams(
    content::BrowserContext* context,
    bool in_memory,
    const base::FilePath& relative_partition_path,
    network::mojom::NetworkContextParams* network_context_params,
    cert_verifier::mojom::CertVerifierCreationParams*
        cert_verifier_creation_params) {
  // Always-on third-party cookie blocking, no opt-out (CEF set the
  // profile.cookie_controls_mode pref; on //content it is a NetworkContext
  // param applied to every context).
  ApplyThirdPartyCookieBlock(network_context_params);
}

void CRWebViewContentBrowserClient::CreateThrottlesForNavigation(
    content::NavigationThrottleRegistry& registry) {
  // Scheme allow-list: cancel navigations to non-web schemes (CEF's
  // OnBeforeBrowse returning true).
  CRWebViewSchemeNavigationThrottle::MaybeCreateAndAdd(registry);
}

void CRWebViewContentBrowserClient::WillCreateURLLoaderFactory(
    content::BrowserContext* browser_context,
    content::RenderFrameHost* frame,
    int render_process_id,
    URLLoaderFactoryType type,
    const url::Origin& request_initiator,
    const net::IsolationInfo& isolation_info,
    std::optional<int64_t> navigation_id,
    ukm::SourceIdObj ukm_source_id,
    network::URLLoaderFactoryBuilder& factory_builder,
    mojo::PendingRemote<network::mojom::TrustedURLLoaderHeaderClient>*
        header_client,
    bool* bypass_redirect_checks,
    bool* disable_secure_dns,
    network::mojom::URLLoaderFactoryOverridePtr* factory_override,
    scoped_refptr<base::SequencedTaskRunner> navigation_response_task_runner) {
  content::WebContents* web_contents =
      frame ? content::WebContents::FromRenderFrameHost(frame) : nullptr;
  if (!web_contents) {
    return;
  }
  // Installs a capture-tee or replay proxy in front of the real factory when
  // the owning session is in an offline mode; no-op otherwise. (M150's hook is
  // void; the proxy is installed via factory_builder, not a return value.)
  MaybeInstallOfflineProxy(web_contents, factory_builder);
}

void CRWebViewContentBrowserClient::RegisterNonNetworkSubresourceURLLoaderFactories(
    int render_process_id,
    int render_frame_id,
    const std::optional<url::Origin>& request_initiator_origin,
    NonNetworkURLLoaderFactoryMap* factories) {
  // Serve arcadia-cache:// from the active snapshot for the owning session.
  content::RenderFrameHost* frame =
      content::RenderFrameHost::FromID(render_process_id, render_frame_id);
  content::WebContents* web_contents =
      frame ? content::WebContents::FromRenderFrameHost(frame) : nullptr;
  if (!web_contents) {
    return;
  }
  if (auto factory = CreateArcadiaCacheURLLoaderFactory(web_contents)) {
    factories->emplace(kArcadiaCacheScheme, std::move(factory));
  }
}

void CRWebViewContentBrowserClient::RegisterBrowserInterfaceBindersForFrame(
    content::RenderFrameHost* render_frame_host,
    mojo::BinderMapWithContext<content::RenderFrameHost*>* map) {
  // Renderer's password-field signal -> browser receiver.
  map->Add<mojom::LoginFormDetector>(
      base::BindRepeating(&CRWebViewLoginFormDetectorImpl::Create));
}

}  // namespace crwebview
