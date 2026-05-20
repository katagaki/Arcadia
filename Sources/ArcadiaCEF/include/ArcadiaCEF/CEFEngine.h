#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Process-wide entry point for the Chromium Embedded Framework.
///
/// Lifecycle (driven by the app delegate):
///   1. `+loadLibrary` early in `main` / before AppKit fully starts.
///   2. `-initializeWithError:` once, before any browser is created. This calls
///      CefInitialize with `external_message_pump = true` and registers the
///      arcadia-cache:// scheme handler.
///   3. `-doMessageLoopWork` pumped from a CADisplayLink/Timer (or in response to
///      CEF's schedule-work callback) to integrate with AppKit's run loop.
///   4. `-shutdown` on app termination (CefShutdown).
@interface CEFEngine : NSObject

@property (class, readonly) CEFEngine *shared;

/// Loads the embedded "Chromium Embedded Framework.framework" dynamic library.
/// Must be called before any other CEF use. Returns NO on failure.
+ (BOOL)loadLibrary;

/// Initializes CEF for the browser (main) process. Safe to call once.
- (BOOL)initializeWithError:(NSError **)error;

/// Performs a slice of CEF work. Pump this from the main thread.
- (void)doMessageLoopWork;

/// Tears CEF down. Call on app termination after all browsers are closed.
- (void)shutdown;

/// Always-on global privacy: blocks third-party cookies for every context.
/// There is intentionally no way to disable this. Applied during init and to
/// every request context created afterwards.
@property (nonatomic, readonly) BOOL blocksThirdPartyCookies; // always YES

@end

NS_ASSUME_NONNULL_END
