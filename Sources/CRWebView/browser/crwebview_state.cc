#include "arcadia/crwebview/browser/crwebview_state.h"

#include "content/public/browser/web_contents.h"

namespace crwebview {

CRWebViewState::CRWebViewState(content::WebContents* contents)
    : content::WebContentsUserData<CRWebViewState>(*contents) {}

CRWebViewState::~CRWebViewState() = default;

}  // namespace crwebview
