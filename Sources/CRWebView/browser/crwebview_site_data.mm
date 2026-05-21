#import <CRWebView/CRSiteData.h>

#import "arcadia/crwebview/browser/crwebview_browser_context.h"

#include <memory>
#include <utility>

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/functional/bind.h"
#include "base/task/thread_pool.h"
#include "content/public/browser/storage_partition.h"
#include "services/network/public/mojom/cookie_manager.mojom.h"

@implementation CRSiteData

+ (void)clearDataAtProfilePath:(NSString*)profilePath
                    completion:(void (^)(void))completion {
  if (profilePath.length == 0) {
    if (completion) {
      completion();
    }
    return;
  }

  base::FilePath dir(profilePath.UTF8String);
  std::unique_ptr<crwebview::CRWebViewBrowserContext> context =
      crwebview::CreatePersistentContext(dir);
  network::mojom::CookieManager* cookie_manager =
      context->GetDefaultStoragePartition()
          ->GetCookieManagerForBrowserProcess();

  // Empty filter == delete every cookie in this context (CEF: DeleteCookies
  // with empty url/name). Then close the context and remove the profile dir.
  network::mojom::CookieDeletionFilterPtr filter =
      network::mojom::CookieDeletionFilter::New();
  cookie_manager->DeleteCookies(
      std::move(filter),
      base::BindOnce(
          [](std::unique_ptr<crwebview::CRWebViewBrowserContext> ctx,
             base::FilePath dir, void (^cb)(void), uint32_t) {
            ctx.reset();
            base::ThreadPool::PostTaskAndReply(
                FROM_HERE, {base::MayBlock()},
                base::BindOnce(
                    [](base::FilePath d) { base::DeletePathRecursively(d); },
                    dir),
                base::BindOnce(
                    [](void (^c)(void)) {
                      if (c) {
                        c();
                      }
                    },
                    cb));
          },
          std::move(context), dir, [completion copy]));
}

@end
