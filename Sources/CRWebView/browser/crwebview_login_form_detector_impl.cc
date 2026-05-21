#include "arcadia/crwebview/browser/crwebview_login_form_detector_impl.h"

#include <utility>

#include "arcadia/crwebview/browser/crwebview_state.h"
#include "content/public/browser/render_frame_host.h"
#include "content/public/browser/web_contents.h"

namespace crwebview {

// static
void CRWebViewLoginFormDetectorImpl::Create(
    content::RenderFrameHost* render_frame_host,
    mojo::PendingReceiver<mojom::LoginFormDetector> receiver) {
  // Only the primary main frame's password fields matter for the login prompt.
  if (!render_frame_host || render_frame_host->GetParentOrOuterDocument()) {
    return;
  }
  // DocumentService self-owns; tied to the document's lifetime.
  new CRWebViewLoginFormDetectorImpl(*render_frame_host, std::move(receiver));
}

CRWebViewLoginFormDetectorImpl::CRWebViewLoginFormDetectorImpl(
    content::RenderFrameHost& render_frame_host,
    mojo::PendingReceiver<mojom::LoginFormDetector> receiver)
    : content::DocumentService<mojom::LoginFormDetector>(render_frame_host,
                                                         std::move(receiver)) {}

CRWebViewLoginFormDetectorImpl::~CRWebViewLoginFormDetectorImpl() = default;

void CRWebViewLoginFormDetectorImpl::LoginFormDetected() {
  content::WebContents* web_contents =
      content::WebContents::FromRenderFrameHost(&render_frame_host());
  if (!web_contents) {
    return;
  }
  auto* state = CRWebViewState::FromWebContents(web_contents);
  if (state && state->on_login_detected) {
    state->on_login_detected.Run();
  }
}

}  // namespace crwebview
