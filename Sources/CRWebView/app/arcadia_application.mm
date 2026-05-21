#import <CRWebView/ArcadiaApplication.h>

#import "base/apple/scoped_sending_event.h"
#import "base/message_loop/message_pump_apple.h"

// CrAppProtocol / CrAppControlProtocol are the Chromium equivalents of CEF's
// CefAppProtocol: the same isHandlingSendEvent pair, with
// base::apple::ScopedSendingEvent in place of CefScopedSendingEvent. (Header
// names track the base/mac -> base/apple migration; adjust on uplift.)
@interface ArcadiaApplication () <CrAppProtocol, CrAppControlProtocol>
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

- (void)sendEvent:(NSEvent*)event {
  base::apple::ScopedSendingEvent sendingEventScoper;
  [super sendEvent:event];
}

@end
