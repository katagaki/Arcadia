#ifndef ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_LOGIN_FORM_DETECTOR_IMPL_H_
#define ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_LOGIN_FORM_DETECTOR_IMPL_H_

#include "arcadia/crwebview/common/crwebview.mojom.h"
#include "content/public/browser/document_service.h"
#include "mojo/public/cpp/bindings/pending_receiver.h"

namespace content {
class RenderFrameHost;
}

namespace crwebview {

// Browser-side receiver of the renderer's LoginFormDetected signal. Routes it
// to the owning session's CRWebViewState::on_login_detected (which CRWebView
// wired to its delegate). Lifetime tied to the document via DocumentService.
class CRWebViewLoginFormDetectorImpl
    : public content::DocumentService<mojom::LoginFormDetector> {
 public:
  static void Create(
      content::RenderFrameHost* render_frame_host,
      mojo::PendingReceiver<mojom::LoginFormDetector> receiver);

  // mojom::LoginFormDetector:
  void LoginFormDetected() override;

 private:
  CRWebViewLoginFormDetectorImpl(
      content::RenderFrameHost& render_frame_host,
      mojo::PendingReceiver<mojom::LoginFormDetector> receiver);
  ~CRWebViewLoginFormDetectorImpl() override;
};

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_LOGIN_FORM_DETECTOR_IMPL_H_
