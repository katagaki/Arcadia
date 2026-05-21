#include "arcadia/crwebview/renderer/crwebview_content_renderer_client.h"

#include "arcadia/crwebview/renderer/crwebview_login_form_observer.h"

namespace crwebview {

CRWebViewContentRendererClient::CRWebViewContentRendererClient() = default;
CRWebViewContentRendererClient::~CRWebViewContentRendererClient() = default;

void CRWebViewContentRendererClient::RenderFrameCreated(
    content::RenderFrame* render_frame) {
  // Self-owned; deletes itself when the frame is destroyed (OnDestruct).
  new CRWebViewLoginFormObserver(render_frame);
}

}  // namespace crwebview
