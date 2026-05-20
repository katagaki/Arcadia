#import "ArcadiaCEF/CEFSiteData.h"
#import "CEFRequestContextFactory.h"

#include "include/cef_cookie.h"
#include "include/cef_request_context.h"

namespace {

class DeleteCookiesDone : public CefDeleteCookiesCallback {
public:
    explicit DeleteCookiesDone(void (^block)(void)) : block_(block) {}
    void OnComplete(int) override {
        void (^b)(void) = block_;
        dispatch_async(dispatch_get_main_queue(), ^{ if (b) { b(); } });
    }
private:
    void (^block_)(void);
    IMPLEMENT_REFCOUNTING(DeleteCookiesDone);
};

}  // namespace

@implementation CEFSiteData

+ (void)clearDataAtCachePath:(NSString *)cachePath
                  completion:(void (^)(void))completion {
    if (cachePath.length == 0) { if (completion) { completion(); } return; }

    CefRefPtr<CefRequestContext> ctx =
        arcadia::CreatePersistentContext(cachePath.UTF8String);
    CefRefPtr<CefCookieManager> cookies = ctx->GetCookieManager(nullptr);

    NSString *path = [cachePath copy];
    void (^afterCookies)(void) = ^{
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        if (completion) { completion(); }
    };

    if (cookies) {
        cookies->DeleteCookies(CefString(), CefString(), new DeleteCookiesDone(afterCookies));
    } else {
        afterCookies();
    }
}

@end
