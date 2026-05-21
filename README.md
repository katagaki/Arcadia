# Arcadia

A minimalist, native macOS web browser. The chrome is entirely SwiftUI/AppKit;
Chromium is used **only** to render pages, via an in-house engine
(**`CRWebView.framework`**) built from Chromium source. There are no traditional
tabs — just **workspaces** of **bookmarks** in the sidebar, plus a single
ephemeral **explorer** tab.

## Concepts

- **Explorer** — the one tab that doesn't live in a workspace. Its start page is
  a single field for a URL or a Google search. To visit something new you either
  bookmark the current page or clear the hierarchy back to the start page.
- **Workspaces & bookmarks** — the sidebar holds collapsible workspaces; each
  contains bookmarks (Arcadia's only persistent "tabs"). Bookmarking a page
  caches it offline (HTML/images/video, **not JavaScript**).
- **Breadcrumb** — there is no top toolbar. A native breadcrumb pinned to the
  bottom of the web view represents the navigation hierarchy; click any crumb to
  go back to it.
- **Privacy** — third-party cookies are always blocked (no opt-out). A site's
  cookies/cache are discarded the moment it is closed (it uses an in-memory
  context). Login pages can opt in to persist (stored on disk); the Settings
  window can clear that data.

## Requirements

- macOS **26 Tahoe** or later.
- Xcode with the macOS 26 SDK.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
- A Mac build machine with **~100 GB+ free disk** for the Chromium checkout used
  to build `CRWebView.framework` (not committed; see below).

## Build

Building has two phases: build the engine framework from Chromium source (slow,
done occasionally), then build the app (fast, in Xcode).

```sh
# 1. Fetch a pinned Chromium checkout (depot_tools + ~100 GB sync).
#    Pin CHROMIUM_VERSION in the script to a revision that builds against the
#    macOS 26 SDK.
Scripts/fetch_chromium.sh

# 2. Build CRWebView.framework (+ helper apps + runtime payload) into
#    third_party/crwebview/. First build is multi-hour.
Scripts/build_crwebview.sh

# 3. Generate the Xcode project from project.yml
xcodegen generate

# 4. Open and build/run
open Arcadia.xcodeproj
```

### Engine embedding

`CRWebView.framework` bundles its own sub-process helper apps
(`Versions/A/Helpers`) and Chromium runtime payload (`icudtl.dat`, `*.pak`, the
v8 snapshot, ANGLE dylibs), so the app embeds **one** framework into
`Contents/Frameworks/` (with code-signing on copy and `@rpath` set up by
`project.yml`). Per-helper entitlements (renderer JIT, GPU, default) are baked
into the helper bundles by the GN build — see `Sources/CRWebView/helper/`.

> **App Sandbox is off.** Chromium's multi-process model is impractical to
> sandbox, so Arcadia ships unsandboxed (Developer ID). Mac App Store
> distribution is out of scope.

## Architecture

| Layer | Where | Notes |
|------|-------|------|
| SwiftUI app | `Sources/Arcadia` | windows, sidebar, breadcrumb, settings, SwiftData models |
| Engine framework | `Sources/CRWebView` | a minimal Chromium `//content` embedder exposing the ObjC `CRWebView` surface; built from source into `CRWebView.framework` |
| Sub-process helper | `Sources/CRWebView/helper` | minimal `content::ContentMain` entry point shared by all helper bundles |

The Swift app only ever touches the Objective-C seam (`CRWebView`,
`CRWebViewConfiguration`, `CRWebViewDelegate`, `CRSiteData`, `CRWebEngine`); it
never sees Chromium C++ types. Engine internals and the per-milestone
finishing-pass notes live in [`Sources/CRWebView/README.md`](Sources/CRWebView/README.md).

Key files:

- `CRWebView/app/crwebview_engine.mm` — `content::ContentMain` bootstrap /
  shutdown (no message-pump timer; integrates with AppKit's run loop).
- `CRWebView/common/crwebview_content_client.cc` — registers the `arcadia-cache`
  scheme.
- `CRWebView/browser/crwebview_privacy.cc` — always-on third-party cookie
  blocking.
- `CRWebView/browser/crwebview_browser_context.cc` — ephemeral (default) vs
  persistent (login-persisted) contexts.
- `CRWebView/browser/crwebview_navigation_throttle.cc` — scheme allow-list
  (blocks `chrome://`, `devtools://`, `file://`, …).
- `CRWebView/browser/crwebview_offline_url_loader_factory.cc` — resource capture
  that **skips JavaScript** and offline replay that never serves scripts.
- `CRWebView/browser/crwebview.mm` — one `WebContents` bound to an `NSView`.
- `Arcadia/Services/BrowserCoordinator.swift` — sessions, bookmarking, capture,
  login persistence.
- `Arcadia/Services/NavigationChain.swift` — the breadcrumb hierarchy.

## Status / not yet validated

This migration off CEF (see `docs/cef-to-crwebview-migration.md`) **has not yet
been compiled or run**. The engine source in `Sources/CRWebView` targets the
**M150** `//content` API, verified signature-by-signature against a 150.0.7850.0
checkout; expect a finishing pass on a Mac with a Chromium build. The
highest-risk items are documented in
[`Sources/CRWebView/README.md`](Sources/CRWebView/README.md):

- Main-loop integration with AppKit's run loop (`crwebview_engine.mm`).
- The offline capture body splice (`crwebview_offline_url_loader_factory.cc`).
- `//content` API drift (the API is not a stable ABI; every Chromium uplift can
  require embedder fixes).
- Confirming the pinned Chromium revision builds against the macOS 26 SDK.
