#import "ArcadiaCEF/CEFEngine.h"
#import "CEFApp.h"
#import "CEFSchemeConstants.h"

#include "include/cef_app.h"
#include "include/cef_scheme.h"
#include "include/wrapper/cef_library_loader.h"

extern CefRefPtr<CefApp> ArcadiaCreateBrowserProcessApp();

@implementation CEFEngine {
    BOOL _initialized;
}

+ (CEFEngine *)shared {
    static CEFEngine *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [[CEFEngine alloc] init]; });
    return instance;
}

- (BOOL)blocksThirdPartyCookies { return YES; }

+ (BOOL)loadLibrary {
    // Path is relative to the app bundle's Frameworks directory.
    return cef_load_library(
        "../Frameworks/Chromium Embedded Framework.framework/Chromium Embedded Framework");
}

- (BOOL)initializeWithError:(NSError **)error {
    if (_initialized) { return YES; }

    CefMainArgs main_args(*_NSGetArgc(), *_NSGetArgv());

    CefSettings settings;
    settings.no_sandbox = true;
    settings.external_message_pump = true;
    settings.command_line_args_disabled = true;
    CefString(&settings.user_agent_product).FromASCII("Arcadia");

    CefRefPtr<CefApp> app = ArcadiaCreateBrowserProcessApp();

    if (!CefInitialize(main_args, settings, app, nullptr)) {
        if (error) {
            *error = [NSError errorWithDomain:@"app.arcadia.cef" code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"CefInitialize failed"}];
        }
        return NO;
    }
    _initialized = YES;
    return YES;
}

- (void)doMessageLoopWork {
    if (_initialized) { CefDoMessageLoopWork(); }
}

- (void)shutdown {
    if (_initialized) {
        CefShutdown();
        _initialized = NO;
    }
}

@end
