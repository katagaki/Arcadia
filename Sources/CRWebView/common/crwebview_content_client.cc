#include "arcadia/crwebview/common/crwebview_content_client.h"

#include "arcadia/crwebview/common/crwebview_scheme_constants.h"
#include "base/strings/utf_string_conversions.h"
#include "ui/base/resource/resource_bundle.h"
#include "url/url_util.h"

namespace crwebview {

CRWebViewContentClient::CRWebViewContentClient() = default;
CRWebViewContentClient::~CRWebViewContentClient() = default;

void CRWebViewContentClient::AddAdditionalSchemes(Schemes* schemes) {
  // Mirrors CEF's OnRegisterCustomSchemes: standard + secure + CORS-enabled.
  // Secure so it isn't treated as mixed content during offline replay; CORS so
  // replayed subresources load cross-origin.
  schemes->standard_schemes.push_back(kArcadiaCacheScheme);
  schemes->secure_schemes.push_back(kArcadiaCacheScheme);
  schemes->cors_enabled_schemes.push_back(kArcadiaCacheScheme);
}

std::u16string CRWebViewContentClient::GetLocalizedString(int message_id) {
  return ui::ResourceBundle::GetSharedInstance().GetLocalizedString(message_id);
}

std::string_view CRWebViewContentClient::GetDataResource(
    int resource_id,
    ui::ResourceScaleFactor scale_factor) {
  return ui::ResourceBundle::GetSharedInstance().GetRawDataResourceForScale(
      resource_id, scale_factor);
}

base::RefCountedMemory* CRWebViewContentClient::GetDataResourceBytes(
    int resource_id) {
  return ui::ResourceBundle::GetSharedInstance().LoadDataResourceBytes(
      resource_id);
}

gfx::Image& CRWebViewContentClient::GetNativeImageNamed(int resource_id) {
  return ui::ResourceBundle::GetSharedInstance().GetNativeImageNamed(
      resource_id);
}

}  // namespace crwebview
