#ifndef ARCADIA_CRWEBVIEW_APP_CRWEBVIEW_MAIN_DELEGATE_H_
#define ARCADIA_CRWEBVIEW_APP_CRWEBVIEW_MAIN_DELEGATE_H_

#include <memory>
#include <optional>
#include <string>
#include <variant>

#include "content/public/app/content_main_delegate.h"
#include "content/public/common/main_function_params.h"

namespace crwebview {

class CRWebViewContentClient;

// Drives process bootstrap for every process type (browser + helpers). This is
// the //content replacement for CEF's CefInitialize/CefExecuteProcess split:
// the same delegate is handed to content::ContentMain from both the framework
// (browser process) and the helper executable (sub-processes).
class CRWebViewMainDelegate : public content::ContentMainDelegate {
 public:
  CRWebViewMainDelegate();
  CRWebViewMainDelegate(const CRWebViewMainDelegate&) = delete;
  CRWebViewMainDelegate& operator=(const CRWebViewMainDelegate&) = delete;
  ~CRWebViewMainDelegate() override;

  // content::ContentMainDelegate:
  std::optional<int> BasicStartupComplete() override;
  void PreSandboxStartup() override;
  std::variant<int, content::MainFunctionParams> RunProcess(
      const std::string& process_type,
      content::MainFunctionParams main_function_params) override;
  content::ContentClient* CreateContentClient() override;
  content::ContentBrowserClient* CreateContentBrowserClient() override;
  content::ContentRendererClient* CreateContentRendererClient() override;

 private:
  void InitializeResourceBundle();

  std::unique_ptr<CRWebViewContentClient> content_client_;
  std::unique_ptr<content::ContentBrowserClient> browser_client_;
  std::unique_ptr<content::ContentRendererClient> renderer_client_;
};

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_APP_CRWEBVIEW_MAIN_DELEGATE_H_
