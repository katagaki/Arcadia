#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Process-wide entry point for the Chromium engine. Replaces CEFEngine.
///
/// Note vs. CEF: there is no -doMessageLoopWork. The old build pumped CEF from a
/// 60 Hz timer (external_message_pump); CRWebView lets Chromium's Cocoa message
/// pump schedule work on the main run loop instead, so the timer is gone.
@interface CRWebEngine : NSObject

@property (class, readonly) CRWebEngine *shared;

/// Loads the embedded framework. Call before any other engine use.
+ (BOOL)loadLibrary;

/// Initializes the browser process (content::ContentMain + BrowserMainRunner)
/// and integrates with the host NSApplication's run loop. Safe to call once.
- (BOOL)initializeWithError:(NSError **)error;

/// Tears the engine down. Call on termination after all web views are closed.
- (void)shutdown;

/// Always YES; third-party cookies are blocked with no way to disable.
@property (nonatomic, readonly) BOOL blocksThirdPartyCookies;

@end

NS_ASSUME_NONNULL_END
