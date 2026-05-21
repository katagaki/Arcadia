#ifndef ARCADIA_CRWEBVIEW_RENDERER_CRWEBVIEW_LOGIN_FORM_OBSERVER_H_
#define ARCADIA_CRWEBVIEW_RENDERER_CRWEBVIEW_LOGIN_FORM_OBSERVER_H_

#include "arcadia/crwebview/common/crwebview.mojom.h"
#include "content/public/renderer/render_frame_observer.h"
#include "mojo/public/cpp/bindings/remote.h"

namespace crwebview {

// Watches a frame's document for password fields and, on first sight, signals
// the browser (LoginFormDetected). Best-effort, matching the CEF design's
// "best-effort signal that the page has a password field". One per RenderFrame;
// self-deletes with the frame.
class CRWebViewLoginFormObserver : public content::RenderFrameObserver {
 public:
  explicit CRWebViewLoginFormObserver(content::RenderFrame* render_frame);
  CRWebViewLoginFormObserver(const CRWebViewLoginFormObserver&) = delete;
  CRWebViewLoginFormObserver& operator=(const CRWebViewLoginFormObserver&) =
      delete;
  ~CRWebViewLoginFormObserver() override;

  // content::RenderFrameObserver:
  void DidFinishLoad() override;
  void OnDestruct() override;

 private:
  bool DocumentHasPasswordField() const;

  bool reported_ = false;
  mojo::Remote<mojom::LoginFormDetector> detector_;
};

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_RENDERER_CRWEBVIEW_LOGIN_FORM_OBSERVER_H_
