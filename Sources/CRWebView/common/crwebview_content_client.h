#ifndef ARCADIA_CRWEBVIEW_COMMON_CRWEBVIEW_CONTENT_CLIENT_H_
#define ARCADIA_CRWEBVIEW_COMMON_CRWEBVIEW_CONTENT_CLIENT_H_

#include "content/public/common/content_client.h"

namespace crwebview {

// Process-wide content embedder hooks shared by every process type. The only
// Arcadia-specific behavior is registering the arcadia-cache scheme as a
// standard, secure, CORS-enabled scheme (the //content equivalent of CEF's
// CefApp::OnRegisterCustomSchemes).
class CRWebViewContentClient : public content::ContentClient {
 public:
  CRWebViewContentClient();
  CRWebViewContentClient(const CRWebViewContentClient&) = delete;
  CRWebViewContentClient& operator=(const CRWebViewContentClient&) = delete;
  ~CRWebViewContentClient() override;

  // content::ContentClient:
  void AddAdditionalSchemes(Schemes* schemes) override;
  std::u16string GetLocalizedString(int message_id) override;
  std::string_view GetDataResource(
      int resource_id,
      ui::ResourceScaleFactor scale_factor) override;
  base::RefCountedMemory* GetDataResourceBytes(int resource_id) override;
  gfx::Image& GetNativeImageNamed(int resource_id) override;
};

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_COMMON_CRWEBVIEW_CONTENT_CLIENT_H_
