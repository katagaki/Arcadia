// Entry point for Chromium's sub-processes (renderer, GPU, utility, …). All
// helper bundles share this binary; //content selects behavior from the
// --type= command line, exactly as CEF's helpers did — but via
// content::ContentMain instead of CefExecuteProcess.

#include "arcadia/crwebview/app/crwebview_main_delegate.h"
#include "content/public/app/content_main.h"

int main(int argc, const char** argv) {
  crwebview::CRWebViewMainDelegate delegate;
  content::ContentMainParams params(&delegate);
  params.argc = argc;
  params.argv = argv;
  return content::ContentMain(std::move(params));
}
