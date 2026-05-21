#ifndef ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_OFFLINE_URL_LOADER_FACTORY_H_
#define ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_OFFLINE_URL_LOADER_FACTORY_H_

#include <string>

#include "mojo/public/cpp/bindings/pending_remote.h"
#include "services/network/public/mojom/url_loader_factory.mojom.h"

namespace base {
class FilePath;
}

namespace content {
class WebContents;
}

namespace network {
class URLLoaderFactoryBuilder;
}

namespace crwebview {

// Snapshot file naming, kept byte-for-byte identical to the CEF build so the
// on-disk format (and the manifest the Swift side never reads but AppPaths
// lays out) is unchanged across the migration (plan §9).
std::string FileNameForURL(const std::string& url);

// If the session that owns `web_contents` is in an offline mode, installs a
// proxying URLLoaderFactory in front of the real network factory:
//   * capture -> tees each response body to the snapshot dir, skipping
//                request.destination == kScript, appending manifest.jsonl.
//   * replay  -> serves stored bytes by URL; scripts -> 404.
// Returns true if it modified the factory chain. The //content replacement for
// CEF's GetResourceRequestHandler + CefResponseFilter / CefResourceHandler.
bool MaybeInstallOfflineProxy(content::WebContents* web_contents,
                              network::URLLoaderFactoryBuilder& factory_builder);

// A non-network factory serving arcadia-cache:// from the active snapshot dir
// (registered via RegisterNonNetworkSubresourceURLLoaderFactories). Empty if
// the session has no snapshot.
mojo::PendingRemote<network::mojom::URLLoaderFactory>
CreateArcadiaCacheURLLoaderFactory(content::WebContents* web_contents);

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_OFFLINE_URL_LOADER_FACTORY_H_
