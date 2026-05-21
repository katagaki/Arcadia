#include "arcadia/crwebview/browser/crwebview_browser_context.h"

#include <utility>

#include "base/check.h"
#include "content/public/browser/browser_thread.h"

namespace crwebview {

CRWebViewBrowserContext::CRWebViewBrowserContext(bool off_the_record,
                                                 const base::FilePath& path)
    : off_the_record_(off_the_record) {
  if (off_the_record_) {
    CHECK(temp_dir_.CreateUniqueTempDir());
    path_ = temp_dir_.GetPath();
  } else {
    CHECK(!path.empty());
    path_ = path;
  }
}

CRWebViewBrowserContext::~CRWebViewBrowserContext() {
  NotifyWillBeDestroyed();
  ShutdownStoragePartitions();
}

base::FilePath CRWebViewBrowserContext::GetPath() const {
  return path_;
}

bool CRWebViewBrowserContext::IsOffTheRecord() {
  return off_the_record_;
}

std::unique_ptr<content::ZoomLevelDelegate>
CRWebViewBrowserContext::CreateZoomLevelDelegate(const base::FilePath&) {
  return nullptr;
}

content::DownloadManagerDelegate*
CRWebViewBrowserContext::GetDownloadManagerDelegate() {
  return nullptr;
}

content::BrowserPluginGuestManager* CRWebViewBrowserContext::GetGuestManager() {
  return nullptr;
}

storage::SpecialStoragePolicy*
CRWebViewBrowserContext::GetSpecialStoragePolicy() {
  return nullptr;
}

content::PlatformNotificationService*
CRWebViewBrowserContext::GetPlatformNotificationService() {
  return nullptr;
}

content::PushMessagingService*
CRWebViewBrowserContext::GetPushMessagingService() {
  return nullptr;
}

content::StorageNotificationService*
CRWebViewBrowserContext::GetStorageNotificationService() {
  return nullptr;
}

content::SSLHostStateDelegate*
CRWebViewBrowserContext::GetSSLHostStateDelegate() {
  return nullptr;
}

content::PermissionControllerDelegate*
CRWebViewBrowserContext::GetPermissionControllerDelegate() {
  return nullptr;
}

content::ClientHintsControllerDelegate*
CRWebViewBrowserContext::GetClientHintsControllerDelegate() {
  return nullptr;
}

content::BackgroundFetchDelegate*
CRWebViewBrowserContext::GetBackgroundFetchDelegate() {
  return nullptr;
}

content::BackgroundSyncController*
CRWebViewBrowserContext::GetBackgroundSyncController() {
  return nullptr;
}

content::BrowsingDataRemoverDelegate*
CRWebViewBrowserContext::GetBrowsingDataRemoverDelegate() {
  return nullptr;
}

content::ReduceAcceptLanguageControllerDelegate*
CRWebViewBrowserContext::GetReduceAcceptLanguageControllerDelegate() {
  return nullptr;
}

std::unique_ptr<CRWebViewBrowserContext> CreateEphemeralContext() {
  return std::make_unique<CRWebViewBrowserContext>(/*off_the_record=*/true,
                                                   base::FilePath());
}

std::unique_ptr<CRWebViewBrowserContext> CreatePersistentContext(
    const base::FilePath& profile_dir) {
  return std::make_unique<CRWebViewBrowserContext>(/*off_the_record=*/false,
                                                   profile_dir);
}

}  // namespace crwebview
