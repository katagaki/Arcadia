#ifndef ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_BROWSER_CONTEXT_H_
#define ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_BROWSER_CONTEXT_H_

#include <memory>
#include <string>

#include "base/files/file_path.h"
#include "base/files/scoped_temp_dir.h"
#include "content/public/browser/browser_context.h"

namespace crwebview {

// One browsing context. Two flavors, matching CEF's ephemeral vs persistent
// CefRequestContext (CEFRequestContextFactory):
//   * ephemeral  -> off-the-record; storage is in-memory and discarded on
//                   destruction (privacy invariant: leaves nothing on disk).
//   * persistent -> on-disk profile dir, only for login-opted-in domains.
//
// Trimmed after content_shell's ShellBrowserContext; the per-milestone set of
// pure-virtual Get*Delegate methods tracks //content and may need adjustment on
// uplift (see Sources/CRWebView/README.md).
class CRWebViewBrowserContext : public content::BrowserContext {
 public:
  // `path` is the on-disk profile dir for persistent contexts; ignored (a temp
  // dir is used) when `off_the_record` is true.
  CRWebViewBrowserContext(bool off_the_record, const base::FilePath& path);
  CRWebViewBrowserContext(const CRWebViewBrowserContext&) = delete;
  CRWebViewBrowserContext& operator=(const CRWebViewBrowserContext&) = delete;
  ~CRWebViewBrowserContext() override;

  // content::BrowserContext:
  base::FilePath GetPath() override;
  bool IsOffTheRecord() override;
  std::unique_ptr<content::ZoomLevelDelegate> CreateZoomLevelDelegate(
      const base::FilePath& partition_path) override;
  content::DownloadManagerDelegate* GetDownloadManagerDelegate() override;
  content::BrowserPluginGuestManager* GetGuestManager() override;
  storage::SpecialStoragePolicy* GetSpecialStoragePolicy() override;
  content::PlatformNotificationService* GetPlatformNotificationService()
      override;
  content::PushMessagingService* GetPushMessagingService() override;
  content::StorageNotificationService* GetStorageNotificationService() override;
  content::SSLHostStateDelegate* GetSSLHostStateDelegate() override;
  content::PermissionControllerDelegate* GetPermissionControllerDelegate()
      override;
  content::ClientHintsControllerDelegate* GetClientHintsControllerDelegate()
      override;
  content::BackgroundFetchDelegate* GetBackgroundFetchDelegate() override;
  content::BackgroundSyncController* GetBackgroundSyncController() override;
  content::BrowsingDataRemoverDelegate* GetBrowsingDataRemoverDelegate()
      override;
  content::ReduceAcceptLanguageControllerDelegate*
  GetReduceAcceptLanguageControllerDelegate() override;

 private:
  const bool off_the_record_;
  base::ScopedTempDir temp_dir_;  // backing dir for ephemeral contexts
  base::FilePath path_;
};

// Factory mirroring CEFRequestContextFactory. Returned contexts are owned by the
// caller (CRWebView) and must outlive their WebContents.
std::unique_ptr<CRWebViewBrowserContext> CreateEphemeralContext();
std::unique_ptr<CRWebViewBrowserContext> CreatePersistentContext(
    const base::FilePath& profile_dir);

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_BROWSER_CRWEBVIEW_BROWSER_CONTEXT_H_
