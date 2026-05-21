#include "arcadia/crwebview/app/crwebview_main_delegate.h"

#include "arcadia/crwebview/browser/crwebview_content_browser_client.h"
#include "arcadia/crwebview/common/crwebview_content_client.h"
#include "arcadia/crwebview/renderer/crwebview_content_renderer_client.h"
#include "base/base_paths.h"
#include "base/files/file_path.h"
#include "base/path_service.h"
#include "content/public/common/content_switches.h"
#include "ui/base/resource/resource_bundle.h"
#include "ui/base/ui_base_paths.h"

namespace crwebview {

CRWebViewMainDelegate::CRWebViewMainDelegate() = default;
CRWebViewMainDelegate::~CRWebViewMainDelegate() = default;

std::optional<int> CRWebViewMainDelegate::BasicStartupComplete() {
  // Return nullopt to let //content continue normal startup.
  return std::nullopt;
}

void CRWebViewMainDelegate::PreSandboxStartup() {
  InitializeResourceBundle();
}

std::variant<int, content::MainFunctionParams> CRWebViewMainDelegate::RunProcess(
    const std::string& process_type,
    content::MainFunctionParams main_function_params) {
  // Browser process: hand control to the default BrowserMain (our
  // BrowserMainParts does the Arcadia-specific setup). Sub-processes use the
  // default runners too, so forward params unchanged.
  return std::move(main_function_params);
}

content::ContentClient* CRWebViewMainDelegate::CreateContentClient() {
  content_client_ = std::make_unique<CRWebViewContentClient>();
  return content_client_.get();
}

content::ContentBrowserClient*
CRWebViewMainDelegate::CreateContentBrowserClient() {
  browser_client_ = std::make_unique<CRWebViewContentBrowserClient>();
  return browser_client_.get();
}

content::ContentRendererClient*
CRWebViewMainDelegate::CreateContentRendererClient() {
  renderer_client_ = std::make_unique<CRWebViewContentRendererClient>();
  return renderer_client_.get();
}

void CRWebViewMainDelegate::InitializeResourceBundle() {
  // The .pak files ship in the framework's Resources directory; PathService
  // resolves DIR_ASSETS to that location for a bundled framework on macOS.
  base::FilePath pak_dir;
  base::PathService::Get(base::DIR_ASSETS, &pak_dir);
  ui::ResourceBundle::InitSharedInstanceWithPakPath(
      pak_dir.Append(FILE_PATH_LITERAL("resources.pak")));
}

}  // namespace crwebview
