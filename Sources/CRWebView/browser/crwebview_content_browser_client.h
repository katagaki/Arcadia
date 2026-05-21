#ifndef ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_CONTENT_BROWSER_CLIENT_H_
#define ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_CONTENT_BROWSER_CLIENT_H_

#include <memory>

#include "content/public/browser/content_browser_client.h"

namespace crwebview {

// The browser-process embedder hub. This is where Arcadia's privacy and offline
// behavior attaches to //content:
//   * scheme allow-list  -> a NavigationThrottle (CEF's OnBeforeBrowse)
//   * offline capture    -> proxying URLLoaderFactory (CEF's GetResourceRequestHandler)
//   * arcadia-cache       -> a non-network URLLoaderFactory
//   * 3p-cookie blocking  -> NetworkContext params (CEF's cookie_controls_mode pref)
class CRWebViewContentBrowserClient : public content::ContentBrowserClient {
 public:
  CRWebViewContentBrowserClient();
  CRWebViewContentBrowserClient(const CRWebViewContentBrowserClient&) = delete;
  CRWebViewContentBrowserClient& operator=(
      const CRWebViewContentBrowserClient&) = delete;
  ~CRWebViewContentBrowserClient() override;

  // content::ContentBrowserClient:
  std::unique_ptr<content::BrowserMainParts> CreateBrowserMainParts(
      bool is_integration_test) override;

  void ConfigureNetworkContextParams(
      content::BrowserContext* context,
      bool in_memory,
      const base::FilePath& relative_partition_path,
      network::mojom::NetworkContextParams* network_context_params,
      cert_verifier::mojom::CertVerifierCreationParams*
          cert_verifier_creation_params) override;

  void CreateThrottlesForNavigation(
      content::NavigationThrottleRegistry& registry) override;

  void WillCreateURLLoaderFactory(
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
      scoped_refptr<base::SequencedTaskRunner> navigation_response_task_runner)
      override;

  void RegisterNonNetworkSubresourceURLLoaderFactories(
      int render_process_id,
      int render_frame_id,
      const std::optional<url::Origin>& request_initiator_origin,
      NonNetworkURLLoaderFactoryMap* factories) override;

  void RegisterBrowserInterfaceBindersForFrame(
      content::RenderFrameHost* render_frame_host,
      mojo::BinderMapWithContext<content::RenderFrameHost*>* map) override;
};

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_CONTENT_BROWSER_CLIENT_H_
