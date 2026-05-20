#import "ArcadiaCEF/ArcadiaApplication.h"
#include "include/cef_application_mac.h"

// Mirrors CEF's required NSApplication subclass (see cefclient). CefAppProtocol
// lets CEF know when the app is dispatching an event so it can pump correctly.
@interface ArcadiaApplication () <CefAppProtocol>
@end

@implementation ArcadiaApplication {
    BOOL _handlingSendEvent;
}

+ (void)ensureLoaded {
    [ArcadiaApplication sharedApplication];
}

- (BOOL)isHandlingSendEvent {
    return _handlingSendEvent;
}

- (void)setHandlingSendEvent:(BOOL)handlingSendEvent {
    _handlingSendEvent = handlingSendEvent;
}

- (void)sendEvent:(NSEvent *)event {
    CefScopedSendingEvent sendingEventScoper;
    [super sendEvent:event];
}

// CEF recommends terminating via this path so sub-processes shut down cleanly.
- (void)terminate:(id)sender {
    [super terminate:sender];
}

@end
