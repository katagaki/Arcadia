#import <CRWebView/CRWebEngine.h>

#import "arcadia/crwebview/app/crwebview_main_delegate.h"

#include <crt_externs.h>

#include <memory>

#include "base/no_destructor.h"
#include "content/public/app/content_main.h"
#include "content/public/app/content_main_runner.h"

@implementation CRWebEngine {
  std::unique_ptr<content::ContentMainRunner> _contentMainRunner;
  BOOL _initialized;
}

+ (CRWebEngine*)shared {
  static CRWebEngine* instance;
  static dispatch_once_t once;
  dispatch_once(&once, ^{ instance = [[CRWebEngine alloc] init]; });
  return instance;
}

- (BOOL)blocksThirdPartyCookies { return YES; }

+ (BOOL)loadLibrary {
  // CRWebView.framework is linked/embedded via @rpath, so the dynamic loader
  // brings it in — there is no CEF-style cef_load_library dance. Kept for
  // API symmetry with the old CEFEngine seam.
  return YES;
}

- (BOOL)initializeWithError:(NSError**)error {
  if (_initialized) {
    return YES;
  }

  static base::NoDestructor<crwebview::CRWebViewMainDelegate> delegate;

  content::ContentMainParams params(delegate.get());
  params.argc = *_NSGetArgc();
  params.argv = const_cast<const char**>(*_NSGetArgv());

  _contentMainRunner = content::ContentMainRunner::Create();

  // HIGH-RISK SEAM (plan §5 "Main message loop", §9). On macOS the browser
  // process attaches to the host NSApplication run loop via
  // base::MessagePumpNSApplication, so Chromium schedules its work onto the
  // main run loop that SwiftUI/AppKit already owns. We Initialize the runner
  // but never call Run() — that is what removes CEF's 60 Hz
  // CefDoMessageLoopWork timer. Validate this exactly against content_shell's
  // mac pump integration in Stage A's standalone harness before trusting it.
  int exit_code = _contentMainRunner->Initialize(std::move(params));
  if (exit_code >= 0) {
    if (error) {
      *error = [NSError errorWithDomain:@"app.arcadia.crwebview"
                                   code:exit_code
                               userInfo:@{NSLocalizedDescriptionKey:
                                            @"ContentMainRunner init failed"}];
    }
    return NO;
  }

  _initialized = YES;
  return YES;
}

- (void)shutdown {
  if (_initialized) {
    _contentMainRunner->Shutdown();
    _contentMainRunner.reset();
    _initialized = NO;
  }
}

@end
