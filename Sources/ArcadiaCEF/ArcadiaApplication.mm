#import "ArcadiaCEF/ArcadiaApplication.h"
#include "include/cef_application_mac.h"

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

- (void)terminate:(id)sender {
    [super terminate:sender];
}

@end
