#include "arcadia/crwebview/renderer/crwebview_login_form_observer.h"

#include "content/public/renderer/render_frame.h"
#include "third_party/blink/public/mojom/forms/form_control_type.mojom-shared.h"
#include "third_party/blink/public/platform/browser_interface_broker_proxy.h"
#include "third_party/blink/public/web/web_document.h"
#include "third_party/blink/public/web/web_form_control_element.h"
#include "third_party/blink/public/web/web_form_element.h"
#include "third_party/blink/public/web/web_local_frame.h"

namespace crwebview {

CRWebViewLoginFormObserver::CRWebViewLoginFormObserver(
    content::RenderFrame* render_frame)
    : content::RenderFrameObserver(render_frame) {}

CRWebViewLoginFormObserver::~CRWebViewLoginFormObserver() = default;

void CRWebViewLoginFormObserver::DidFinishLoad() {
  if (reported_ || !DocumentHasPasswordField()) {
    return;
  }
  reported_ = true;
  if (!detector_.is_bound()) {
    render_frame()->GetBrowserInterfaceBroker().GetInterface(
        detector_.BindNewPipeAndPassReceiver());
  }
  detector_->LoginFormDetected();
}

void CRWebViewLoginFormObserver::OnDestruct() {
  delete this;
}

bool CRWebViewLoginFormObserver::DocumentHasPasswordField() const {
  blink::WebLocalFrame* frame = render_frame()->GetWebFrame();
  if (!frame) {
    return false;
  }
  blink::WebDocument document = frame->GetDocument();
  if (document.IsNull()) {
    return false;
  }
  for (const blink::WebFormElement& form : document.Forms()) {
    for (const blink::WebFormControlElement& control :
         form.GetFormControlElements()) {
      if (control.FormControlType() ==
          blink::mojom::FormControlType::kInputPassword) {
        return true;
      }
    }
  }
  return false;
}

}  // namespace crwebview
