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

## Status: targets M150, pending a build

The embedder targets the **M150 `//content` API**, verified signature-by-signature
against a `150.0.7850.0` checkout. It has not been compiled yet — a build pass on
the pinned revision is still expected — but the public API surface was checked
against the real headers.

**Adjusted for M150** (vs. the initial draft): `ContentBrowserClient::
WillCreateURLLoaderFactory` returns `void`; `BrowserContext::GetPath()` is
`const`; `ScopedSendingEvent` lives in `base::mac` (not `base::apple`); login
detection uses `WebFormControlElement::FormControlType() ==
blink::mojom::FormControlType::kInputPassword` (the old
`IsPasswordFieldForAutofill` is gone); `StringDataSource` takes
`base::span<const char>`. `ContentMainDelegate`/`ContentMainRunner`,
`CreateThrottlesForNavigation(NavigationThrottleRegistry&)`, the 16
`BrowserContext` pure virtuals, `DocumentService`, `DownloadImage`,
`PNGCodec::EncodeBGRASkBitmap`, the mojo data-pipe APIs, and the GN
templates/labels all matched M150 as written.

**Still needs a build/runtime pass:**

- **Main-loop integration** (`app/crwebview_engine.mm`): the highest-risk seam.
  We `Initialize` the `ContentMainRunner` but never `Run()`, relying on
  Chromium's Cocoa pump to schedule onto the host `NSApplication` run loop. Prove
  this in a standalone harness before trusting it.
- **Offline capture body splice** (`browser/crwebview_offline_url_loader_factory.cc`,
  `BodyTee`): signatures are M150-correct, but the live tee's data-pipe pumping is
  unproven. Replay streams via `DataPipeProducer` and the manifest format is
  settled. Both capture writes and replay file opens currently block on the
  calling sequence — move to a blocking task runner.
- **ObjC ↔ `base::Bind`**: the favicon/login callbacks and `CRSiteData` bind a
  `__weak CRWebView*` / ObjC block through `base::Bind` (relying on ARC to
  manage the captured object). Confirm this behaves at runtime; swap to an
  explicit trampoline if not.
- **Packaging** (`BUILD.gn`): target labels are valid for M150, but the exact
  `repack` `.pak` set and runtime-payload layout are iterative — expect to adjust
  during the first framework build.

## Privacy invariants (must hold; verify explicitly)

- third-party cookies blocked, no opt-out (`browser/crwebview_privacy.cc`);
- ephemeral context leaves nothing on disk (`CRWebViewBrowserContext`, OTR);
- offline replay never serves JavaScript; capture never stores it
  (`request.destination == kScript` skipped);
- only http/https/arcadia-cache/about navigate
  (`browser/crwebview_navigation_throttle.cc`).
