# Migration Plan: CEF → Chromium (`CRWebView` framework)

Status: **plan / not started**. Target: replace the Chromium Embedded Framework
(CEF) with an in-house Chromium engine built from source.

## 1. Goal & approach

Arcadia renders pages with Chromium today, but via CEF: a prebuilt binary
distribution plus a C++ embedding API, wrapped by the `ArcadiaCEF` Obj-C++
framework behind a pure-Objective-C surface. This plan moves Arcadia off CEF and
onto Chromium directly, in **two stages**:

- **Stage A — build `CRWebView.framework` from Chromium source.** Inside a
  Chromium checkout, author a minimal [`//content`](https://www.chromium.org/developers/content-module/)
  embedder that exposes an Objective-C, `WKWebView`-shaped class named
  `CRWebView`, and package it (plus the helper apps and Chromium runtime
  payload) as a macOS `.framework`.
- **Stage B — consume `CRWebView.framework` in Arcadia.** Replace the CEF
  framework and the CEF internals of `ArcadiaCEF` with `CRWebView`, keeping the
  SwiftUI/SwiftData app unchanged behind the existing Objective-C seam.

This mirrors the current shape (a framework with an ObjC-friendly surface, plus
sub-process helper bundles) but lets us own the engine and tailor the API to
exactly what Arcadia needs.

## 2. What does **not** change

The migration is deliberately confined to the engine layer. Untouched:

- The SwiftUI app and all views (sidebar, breadcrumb, explorer, settings).
- SwiftData models: `Workspace`, `Bookmark`, `PersistedLoginSite`.
- `NavigationChain` (breadcrumb hierarchy), `SearchURLBuilder`, `AppPaths`.
- The product behavior and **privacy guarantees**: third-party cookies always
  blocked, ephemeral-by-default contexts, opt-in persistent login, offline
  caching that **never stores or serves JavaScript**.
- The *shape* of the ObjC bridge: an `NSView`-backed controller, a delegate of
  main-thread callbacks, a configuration object, a site-data utility, and the
  `NSApplication` subclass. We re-point these from CEF onto `CRWebView`
  (see §10 for the rename map).

## 3. Key technical decision: which Chromium layer `CRWebView` sits on

`CRWebView` will wrap Chromium's **`//content` public API** — `content::WebContents`,
`content::BrowserContext`, `content::NavigationController`,
`content::WebContentsObserver` — the same layer Chrome and `content_shell` use on
macOS. `WebContents::GetNativeView()` returns an `NSView` we host inside
`CRWebView`'s container view, exactly as the current code hosts CEF's child view.

**Naming note (important).** There is no off-the-shelf macOS "Blink web view"
Objective-C class in the Chromium tree to adopt:

- `//ios/web_view`'s `CWVWebView` (the "ChromeWebView" framework) is **iOS-only**
  and is backed by **WebKit**, not Blink — iOS forbids non-WebKit engines. It is
  therefore *not* a macOS Chromium engine and must not be mistaken for one.
- `content_shell` is a sample embedder, not a reusable framework.

So `CRWebView` is **our own class** (the `CR` prefix mirrors Chromium's existing
`CRW*` Cocoa naming convention), and `content_shell`'s mac sources are the
reference implementation we adapt. This is the central long-term cost of the
migration: the `//content` API is **not a stable ABI** (insulating callers from
that churn is the very reason CEF exists), so every Chromium uplift can require
embedder fixes. We accept that in exchange for owning the engine.

## 4. Target architecture

```
┌──────────────────────────────────────────────┐
│ Arcadia.app  (SwiftUI + SwiftData, unchanged)  │
│   ArcadiaApp / AppDelegate / Views / Models     │
│   BrowserCoordinator · BrowserSession           │
│        │  (Objective-C seam, unchanged shape)   │
│        ▼                                         │
│   CRWebView.framework  ◀── built in Stage A      │
│     CRWebView (NSView)  · CRWebViewConfiguration │
│     CRWebViewDelegate   · CRSiteData             │
│     content::WebContents / BrowserContext        │
│     ContentMainDelegate / ContentBrowserClient   │
└──────────────────────────────────────────────┘
   + 5 helper .app bundles (renderer/GPU/plugin/…)
   + Chromium runtime payload (icudtl.dat, *.pak,
     v8 snapshot, ANGLE dylibs)
```

Targets after migration:

| Target | Before | After |
|---|---|---|
| `Arcadia` (app) | SwiftUI app, depends on `ArcadiaCEF` | unchanged app; depends on `CRWebView.framework` |
| Engine framework | `ArcadiaCEF` (wraps CEF) | `CRWebView.framework` (built from Chromium source in Stage A); the thin `ArcadiaCEF` shim is removed or folded in |
| `ArcadiaHelper` ×5 | `main()` → `CefExecuteProcess` | `main()` → `content::ContentMain` with our delegate |

## 5. CEF → `//content` capability mapping

This table is the heart of the port. API names are illustrative and pinned to
the chosen Chromium milestone (they drift between versions).

| Capability | Today (CEF) | `CRWebView` on `//content` | Risk |
|---|---|---|---|
| Process bootstrap | `CefInitialize`/`CefShutdown`, `CefMainArgs`/`CefSettings` | `ContentMainRunner` + `BrowserMainRunner` driven by a `ContentMainDelegate`; embedder hooks `ContentClient` / `ContentBrowserClient` / `ContentRendererClient` | Med |
| Sub-processes | 5 helper bundles call `CefExecuteProcess` | same 5 bundles; `main()` calls `content::ContentMain` with our delegate | Low–Med |
| Main message loop | `external_message_pump` + 60 Hz `CefDoMessageLoopWork` timer in `AppDelegate` | Chromium's Cocoa pump (`base::MessagePumpNSApplication` / CFRunLoop) schedules work on the main run loop; **the timer is removed** | **High** |
| `NSApplication` subclass | `ArcadiaApplication <CefAppProtocol>` (`isHandlingSendEvent`, `CefScopedSendingEvent`) | conform to Chromium's `CrAppProtocol`/`CrAppControlProtocol` (same two methods + `base::mac::ScopedSendingEvent`) | Low |
| Browser + native view | `CefBrowserHost::CreateBrowser` + `window_info.SetAsChild(NSView)` | `WebContents::Create(BrowserContext)`; add `web_contents->GetNativeView()` (an `NSView`) as a subview of `CRWebView` | Low–Med |
| Storage modes | `CefRequestContext`: ephemeral (no `cache_path`) vs persistent (`cache_path`) | `BrowserContext`: off-the-record/in-memory vs on-disk profile dir; per-context `StoragePartition` | Med |
| Block 3rd-party cookies | `profile.cookie_controls_mode` preference = 1 | `network::mojom::CookieManager::BlockThirdPartyCookies(true)` on the context's `NetworkContext` (cleaner than a pref) | Low–Med |
| Custom `arcadia-cache` scheme | `OnRegisterCustomSchemes` (standard+secure+CORS) | `ContentClient::AddAdditionalSchemes` (standard+secure) + a non-network `URLLoaderFactory` via `ContentBrowserClient::RegisterNonNetwork{Navigation,Subresource}URLLoaderFactories` | Med |
| Scheme allow-list (block non-web) | `OnBeforeBrowse` returns `true` to cancel | a `NavigationThrottle` (registered via `ContentBrowserClient::CreateThrottlesForNavigation`) cancels disallowed schemes | Low–Med |
| Offline **capture** (tee, skip JS) | `GetResourceRequestHandler` + `CefResponseFilter` writing to disk; `RT_SCRIPT` skipped | a **proxying `network::mojom::URLLoaderFactory`** that tees the response data pipe to disk; skip when `request.destination == kScript` | **High** |
| Offline **replay** (serve disk, 404 scripts) | `CefResourceHandler` / `CefStreamResourceHandler` from manifest | a custom `URLLoaderFactory` serving stored bytes by URL; scripts → empty/404 | **High** |
| Title / URL / loading / nav state | `CefDisplayHandler` + `CefLoadHandler` | `WebContentsObserver` (`TitleWasSet`, `PrimaryMainFrameUrlChanged`/`DidFinishNavigation`, `DidStartLoading`/`DidStopLoading`) + `NavigationController::CanGoBack/Forward` | Low |
| Favicon | `OnFaviconURLChange` + `DownloadImage` | `WebContentsObserver::DidUpdateFaviconURL` + `WebContents::DownloadImage` | Low |
| Clear site data | `CefCookieManager::DeleteCookies` | `network::mojom::CookieManager::DeleteCookies` + remove the profile dir | Low–Med |
| Login-form detection (unwired hook) | planned render-process DOM visitor | a `RenderFrameObserver` in the renderer scanning Blink forms for password fields, Mojo message to the browser (or a small injected JS probe) | Med |
| Framework load | `cef_load_library(...)` + `CefScopedLibraryLoader` in helpers | link/embed `CRWebView.framework` via `@rpath`; helpers load the same framework | Low–Med (packaging) |

## 6. Roadmap

### Stage A — build `CRWebView.framework`

- **A0 · Toolchain & checkout.** Install `depot_tools`; `fetch chromium`; pin a
  milestone that builds against the macOS 26 SDK and supports deployment
  target 26; set GN args (`is_debug=false`, `is_component_build=false`,
  `target_cpu`, `enable_nacl=false`, `symbol_level`, `dcheck_always_on=false`).
  *Exit:* `content_shell` builds and runs locally.
- **A1 · Embedder skeleton.** Add an in-tree module (e.g. `//arcadia/crwebview`)
  with `ContentClient`, `ContentMainDelegate`, `ContentBrowserClient`,
  `ContentRendererClient`, a `BrowserContext`, and `BrowserMainParts`.
  *Exit:* a standalone test app loads `example.com` in an `NSView` (our own mini
  `content_shell`).
- **A2 · `CRWebView` public surface.** Define the ObjC `CRWebView` (NSView-backed)
  + `CRWebViewDelegate` + `CRWebViewConfiguration` mirroring today's CEF surface
  (§10). Wire `WebContentsObserver` callbacks to the delegate.
  *Exit:* load / back / forward / reload / stop and title/url/loading/favicon
  callbacks all work in the test app.
- **A3 · Privacy & contexts.** Off-the-record vs on-disk `BrowserContext`;
  `BlockThirdPartyCookies(true)`; cookie-deletion utility; `arcadia-cache`
  scheme; scheme allow-list `NavigationThrottle`.
  *Exit:* 3p cookies blocked (verified), ephemeral wipe verified, non-web schemes
  blocked.
- **A4 · Offline + login detection.** Capture/replay (skip-JS) via the proxying
  `URLLoaderFactory`; login-form detection via `RenderFrameObserver`.
  *Exit:* capture writes manifest + resources with no JS; replay serves them and
  404s scripts; password-field pages fire the login signal.
- **A5 · Package as a framework.** A GN `mac_framework_bundle` producing
  `CRWebView.framework` + the 5 helper apps + runtime payload (`icudtl.dat`,
  `*.pak`, v8 snapshot, ANGLE dylibs).
  *Exit:* a self-contained `CRWebView.framework` consumable outside the Chromium
  tree.

### Stage B — consume it in Arcadia

- **B0 · Bridge swap.** Replace `ArcadiaCEF`'s CEF internals with thin Obj-C++
  over `CRWebView` (or drop `ArcadiaCEF` and import `CRWebView` directly). Apply
  the rename (§10). *Exit:* the bridge compiles against `CRWebView.framework`.
- **B1 · App lifecycle.** Rewrite `AppDelegate` (remove the 60 Hz pump; initialize
  content/browser-main; integrate Chromium's Cocoa pump) and switch
  `ArcadiaApplication` to `CrAppProtocol`. *Exit:* app launches; explorer renders
  a live page.
- **B2 · Feature-parity pass.** Walk every `BrowserSession` / `BrowserCoordinator`
  path: bookmark open, ephemeral vs persistent, capture-on-bookmark, replay,
  login persist, site-data clear. *Exit:* all flows behave as before.
- **B3 · Build / sign / package.** `project.yml` embeds `CRWebView.framework` +
  helpers; per-helper entitlements; remove `Scripts/fetch_cef.sh`, add
  fetch+build scripts; notarize. *Exit:* a signed `Arcadia.app` runs on a clean
  macOS 26 machine.
- **B4 · Cleanup & docs.** Delete CEF-specific files; update README and the
  architecture table. *Exit:* no CEF references remain.

## 7. Build, packaging & runtime payload

- **Build system.** Stage A is GN/ninja inside a Chromium checkout, not Xcode.
  Expect a ~100 GB+ checkout and a multi-hour first build; needs macOS hardware.
- **Runtime payload to assemble** (CEF's `Release/` folder handed us this for
  free; now we produce it): the framework binary, `icudtl.dat`,
  `chrome_100_percent.pak` / `resources.pak` / locale `.pak`s,
  `v8_context_snapshot.bin` (or `snapshot_blob.bin`), ANGLE `libEGL.dylib` /
  `libGLESv2.dylib`, optional SwiftShader, and the helper apps — laid out inside
  the framework's `Versions/A/{Resources,Libraries,Helpers}`.
- **Scripts.** Replace `Scripts/fetch_cef.sh` with `Scripts/fetch_chromium.sh`
  (`depot_tools` + `gclient sync` to the pinned revision) and
  `Scripts/build_crwebview.sh` (`gn gen` + `ninja` + assemble framework).
- **Versioning.** Pin a Chromium revision; "update" = re-sync + rebuild + re-run
  the validation harness (§11).

## 8. Code signing, entitlements, helpers, sandbox

- **Sandbox stays off** (Developer ID, not Mac App Store) — unchanged from today.
- **Helpers.** Chromium uses distinct entitlements per helper type on macOS. The
  renderer helper needs JIT / `allow-unsigned-executable-memory`; GPU and the
  others differ. Today all 5 helpers share one Info.plist; the migration must
  split entitlements per helper (mirror Chrome's helper layout).
- **Sign order** is unchanged in spirit: framework + helpers first (each signed),
  then the app, hardened runtime on. The app entitlements
  (`allow-jit`, `allow-unsigned-executable-memory`, `disable-library-validation`)
  carry over.

## 9. Risks & mitigations

| Risk | Mitigation |
|---|---|
| **`//content` API churn** (no stable ABI) | Pin a Chromium revision; keep the embedder small; gate uplifts behind the validation harness; budget recurring maintenance |
| **Main-loop integration** with SwiftUI/`NSApplicationMain` | Prototype in Stage A's standalone harness before touching Arcadia; follow `content_shell`'s mac pump integration exactly |
| **Offline capture/replay** (Mojo / Network Service) is the hardest port | Build it last in Stage A (A4); model on the extensions WebRequest proxy and `URLLoaderInterceptor`; keep the disk format/manifest identical so Swift is unaffected |
| **Build cost / CI** (~100 GB, hours, mac-only) | Self-hosted mac runner; cache the checkout; build the framework as a versioned artifact consumed by the Arcadia build |
| **macOS 26 SDK vs Chromium milestone** compatibility | Resolve in A0 before committing to a revision |
| **Big-bang cutover** | Optionally keep CEF behind the bridge during transition and switch at B1 (parallel bridges), or accept a hard cutover on a branch |

## 10. Objective-C surface & rename map

The Swift app only ever touches the ObjC seam, so the migration preserves the
*shape* of that seam and re-points it at `CRWebView`. Suggested renames
(`CEF*` → `CR*`); keeping the old names as aliases is possible if minimizing
Swift churn is preferred, but the rename is recommended to retire "CEF":

| Today | After | Role |
|---|---|---|
| `CEFEngine` | `CRWebEngine` (or fold into framework init) | process lifecycle |
| `CEFBrowserController` | `CRWebView` | `NSView`-backed controller/view |
| `CEFBrowserConfiguration` | `CRWebViewConfiguration` | storage/offline/snapshot config |
| `CEFBrowserDelegate` | `CRWebViewDelegate` | main-thread callbacks |
| `CEFStorageMode` / `CEFOfflineMode` | `CRStorageMode` / `CROfflineMode` | enums |
| `CEFSiteData` | `CRSiteData` | clear cookies/cache |
| `ArcadiaApplication` | `ArcadiaApplication` | stays; protocol changes to `CrAppProtocol` |
| `CEFApp`, `CEFClientHandler`, `CEFClientSink`, `CEFPrivacy`, `CEFRequestContextFactory`, `CEFOfflineCache`, `CEFSchemeConstants` | (moved into `CRWebView.framework` as `//content`-based equivalents) | engine internals — no longer in Arcadia |

**Swift files touched** (6, all in the engine seam):

- `Arcadia/ArcadiaApp.swift` — `ArcadiaApplication.ensureLoaded()`, import.
- `Arcadia/AppDelegate.swift` — engine load/init/**pump removed**/shutdown.
- `Arcadia/Services/BrowserCoordinator.swift` — `…Configuration` construction.
- `Arcadia/Services/BrowserSession.swift` — controller + delegate conformance.
- `Arcadia/Views/Browser/CEFWebView.swift` — rename to `WebView.swift`; wraps `CRWebView`.
- `Arcadia/Views/Settings/SiteDataSettingsView.swift` — `CRSiteData.clearData`.

Everything else in `Sources/Arcadia` is untouched.

## 11. Validation & acceptance

- **Standalone harness first.** Prove the engine in Stage A's mini-`content_shell`
  before integrating, so engine bugs are isolated from app bugs.
- **Privacy invariants** (must hold, verified explicitly):
  - third-party cookies blocked with no opt-out;
  - ephemeral context leaves nothing on disk after close;
  - offline replay **never** serves JavaScript; capture **never** stores it;
  - persistent storage exists only for domains the user opted into;
  - "Clear" removes a site's cookies *and* its on-disk context dir.
- **Smoke flows:** explorer search → follow links → breadcrumb jump; bookmark +
  offline capture; open bookmark offline (replay); login persist → reopen still
  signed in; settings "Clear".
- **Maintenance drill:** bump the pinned Chromium revision, rebuild, re-run the
  harness — to measure the recurring uplift cost.

## 12. Open questions

- Exact Chromium milestone that builds cleanly against the macOS 26 SDK.
- Universal (arm64 + x86_64) binary, or arm64-only?
- Where the embedder source lives: an in-tree `//arcadia` overlay vs a separate
  repo pulled in via `gclient`/DEPS.
- CI ownership of the Chromium build (self-hosted mac runner; cadence).
- Transition strategy: parallel CEF + `CRWebView` bridges, or a hard cutover on
  this branch.
