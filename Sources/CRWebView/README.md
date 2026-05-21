# CRWebView engine source

The in-house Chromium engine for Arcadia: a minimal `//content` embedder that
exposes an Objective-C, `WKWebView`-shaped class (`CRWebView`) and packages as
`CRWebView.framework`. This replaces CEF (see
`docs/cef-to-crwebview-migration.md`).

This tree is **overlaid into a Chromium checkout** at `src/arcadia/crwebview/`
by `Scripts/build_crwebview.sh`; it is not built by Xcode and does not compile
outside a Chromium tree. Build it with:

```sh
Scripts/fetch_chromium.sh      # depot_tools + pinned Chromium checkout
Scripts/build_crwebview.sh     # gn gen + ninja + assemble the framework
```

## Layout

| Dir | Role | CEF analog |
|---|---|---|
| `app/` | `ContentMainDelegate`, engine bootstrap (`CRWebEngine`), `ArcadiaApplication` | `CEFEngine`, `ArcadiaApplication` |
| `browser/` | `ContentBrowserClient` hub, `BrowserContext`, privacy, scheme throttle, offline `URLLoaderFactory`, `CRWebView`/`CRSiteData`, login receiver | `CEFClientHandler`, `CEFRequestContextFactory`, `CEFPrivacy`, `CEFOfflineCache`, `CEFBrowserController`, `CEFSiteData` |
| `renderer/` | `ContentRendererClient`, login-form `RenderFrameObserver` | (planned DOM visitor) |
| `common/` | `ContentClient`, scheme constants, IPC mojom | `CEFApp`, `CEFSchemeConstants` |
| `public/CRWebView/` | the framework's public ObjC headers | `ArcadiaCEF/include` |

## Needs a finishing pass against the pinned milestone

The `//content` API is not a stable ABI. The following were authored against the
138-era API and must be confirmed when the pinned revision is finalized (plan
§3, §9):

- **Main-loop integration** (`app/crwebview_engine.mm`): the highest-risk seam.
  We `Initialize` the `ContentMainRunner` but never `Run()`, relying on
  Chromium's Cocoa pump to schedule onto the host `NSApplication` run loop. Prove
  this in a standalone harness before trusting it.
- **Offline capture body splice** (`browser/crwebview_offline_url_loader_factory.cc`,
  `BodyTee`): the mojo data-pipe two-phase read/write mechanics. Replay streams
  via `DataPipeProducer` and the manifest format is settled; the live capture
  tee is the A4 validation target. Note both capture writes and replay file
  opens currently block on the calling sequence — move to a blocking task
  runner during A4.
- **`BrowserContext` delegate set**: the exact list of pure-virtual
  `Get*Delegate` methods drifts; track `content_shell`'s `ShellBrowserContext`.
- **ObjC ↔ `base::Bind`**: the favicon/login callbacks and `CRSiteData` bind a
  `__weak CRWebView*` / ObjC block through `base::Bind` (relying on ARC to
  manage the captured object). Confirm this compiles/behaves on the milestone;
  swap to an explicit trampoline if not.
- **API name drift**: `NavigationThrottleRegistry`, `base/apple` vs `base/mac`,
  `WebInputElement::IsPasswordFieldForAutofill`, `PNGCodec::EncodeBGRASkBitmap`,
  `WebContentsUserData` registration, GN template/dep names in `BUILD.gn`.

## Privacy invariants (must hold; verify explicitly)

- third-party cookies blocked, no opt-out (`browser/crwebview_privacy.cc`);
- ephemeral context leaves nothing on disk (`CRWebViewBrowserContext`, OTR);
- offline replay never serves JavaScript; capture never stores it
  (`request.destination == kScript` skipped);
- only http/https/arcadia-cache/about navigate
  (`browser/crwebview_navigation_throttle.cc`).
