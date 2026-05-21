#ifndef ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_STATE_H_
#define ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_STATE_H_

#include "arcadia/crwebview/common/crwebview_offline_mode.h"
#include "base/files/file_path.h"
#include "base/functional/callback.h"
#include "content/public/browser/web_contents_user_data.h"

namespace content {
class WebContents;
}

namespace crwebview {

// Per-WebContents Arcadia state, attached by CRWebView at creation. Lets the
// browser-process embedder (offline URLLoaderFactory, login Mojo receiver) find
// the owning session's offline config and notify it, without C++ holding ObjC
// pointers. This is the //content stand-in for the per-CefClient state that
// ArcadiaClientHandler carried in the CEF build.
class CRWebViewState : public content::WebContentsUserData<CRWebViewState> {
 public:
  ~CRWebViewState() override;

  OfflineMode offline_mode = OfflineMode::kNone;
  base::FilePath snapshot_dir;

  // Invoked (on the UI thread) when the renderer reports a password field.
  // CRWebView sets this to forward to its delegate.
  base::RepeatingClosure on_login_detected;

 private:
  explicit CRWebViewState(content::WebContents* contents);
  friend class content::WebContentsUserData<CRWebViewState>;
};

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_STATE_H_
