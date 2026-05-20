#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Process-wide entry point for the Chromium Embedded Framework.
@interface CEFEngine : NSObject

@property (class, readonly) CEFEngine *shared;

/// Loads the embedded framework dylib. Call before any other CEF use.
+ (BOOL)loadLibrary;

/// Initializes CEF for the browser process. Safe to call once.
- (BOOL)initializeWithError:(NSError **)error;

/// Performs a slice of CEF work. Pump from the main thread.
- (void)doMessageLoopWork;

/// Tears CEF down. Call on termination after all browsers are closed.
- (void)shutdown;

/// Always YES; third-party cookies are blocked with no way to disable.
@property (nonatomic, readonly) BOOL blocksThirdPartyCookies;

@end

NS_ASSUME_NONNULL_END
