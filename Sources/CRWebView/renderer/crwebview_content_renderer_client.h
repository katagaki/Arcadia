#ifndef ARCADIA_CRWEBVIEW_RENDERER_CRWEBVIEW_CONTENT_RENDERER_CLIENT_H_
#define ARCADIA_CRWEBVIEW_RENDERER_CRWEBVIEW_CONTENT_RENDERER_CLIENT_H_

#include "content/public/renderer/content_renderer_client.h"

namespace crwebview {

// Renderer-process embedder. Its one Arcadia job is to attach a
// RenderFrameObserver that watches Blink for password fields and signals the
// browser (CEF's planned render-process DOM visitor). See
// CRWebViewLoginFormObserver.
class CRWebViewContentRendererClient : public content::ContentRendererClient {
 public:
  CRWebViewContentRendererClient();
  CRWebViewContentRendererClient(const CRWebViewContentRendererClient&) =
      delete;
  CRWebViewContentRendererClient& operator=(
      const CRWebViewContentRendererClient&) = delete;
  ~CRWebViewContentRendererClient() override;

  // content::ContentRendererClient:
  void RenderFrameCreated(content::RenderFrame* render_frame) override;
};

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_RENDERER_CRWEBVIEW_CONTENT_RENDERER_CLIENT_H_
