# Arcadia

A minimalist, native macOS web browser. The chrome is entirely SwiftUI/AppKit;
Chromium (via the **Chromium Embedded Framework**, CEF) is used **only** to
render pages. There are no traditional tabs — just **workspaces** of
**bookmarks** in the sidebar, plus a single ephemeral **explorer** tab.

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
- A CEF binary distribution (downloaded by the script below; not committed).

## Build

```sh
# 1. Fetch the CEF binary distribution into third_party/cef/
#    (edit CEF_VERSION in the script to a current build from
#     https://cef-builds.spotifycdn.com/index.html)
Scripts/fetch_cef.sh

# 2. Generate the Xcode project from project.yml
xcodegen generate

# 3. Open and build/run
open Arcadia.xcodeproj
```

### CEF embedding (manual finishing step)

XcodeGen sets up the targets and search paths, but CEF's macOS bundle layout
needs a final pass in Xcode (this mirrors the `cefsimple`/`cefclient` samples):

1. **Embed the framework**: copy
   `third_party/cef/Release/Chromium Embedded Framework.framework` into
   `Arcadia.app/Contents/Frameworks/` (Copy Files build phase, "Frameworks",
   **without** code-signing-on-copy if already signed; otherwise sign).
2. **Helpers**: the five helper targets (`Arcadia Helper`, `… (GPU)`,
   `… (Renderer)`, `… (Plugin)`, `… (Alerts)`) are embedded into
   `Contents/Frameworks/`. Each must be signed.
3. **Sign order**: framework and helpers first, then the app, with the
   entitlements in `Sources/Arcadia/Resources/Arcadia.entitlements` and the
   hardened runtime enabled.

> **App Sandbox is off.** CEF's multi-process model is impractical to sandbox,
> so Arcadia ships unsandboxed (Developer ID). Mac App Store distribution is out
> of scope.

## Architecture

| Layer | Where | Notes |
|------|-------|------|
| SwiftUI app | `Sources/Arcadia` | windows, sidebar, breadcrumb, settings, SwiftData models |
| Engine bridge | `Sources/ArcadiaCEF` | Obj-C++ wrapper over CEF; exposes a pure-ObjC surface so Swift never sees CEF C++ types |
| Sub-process helper | `Sources/ArcadiaHelper` | minimal `CefExecuteProcess` entry point shared by all helper bundles |

Key files:

- `ArcadiaCEF/CEFEngine.mm` — `CefInitialize`/message-pump/`CefShutdown`.
- `ArcadiaCEF/CEFApp.mm` — registers the `arcadia-cache` scheme; applies global
  privacy on context init.
- `ArcadiaCEF/CEFPrivacy.mm` — always-on third-party cookie blocking.
- `ArcadiaCEF/CEFRequestContextFactory.mm` — ephemeral (default) vs persistent
  (login-persisted) contexts.
- `ArcadiaCEF/CEFClientHandler.mm` — load/title/favicon/URL callbacks, scheme
  allow-list (blocks `chrome://`, `devtools://`, `file://`, …), offline routing.
- `ArcadiaCEF/CEFOfflineCache.mm` — resource capture that **skips JavaScript**
  and offline replay that never serves scripts.
- `ArcadiaCEF/CEFBrowserController.mm` — one browser bound to an `NSView`.
- `Arcadia/Services/BrowserCoordinator.swift` — sessions, bookmarking, capture,
  login persistence.
- `Arcadia/Services/NavigationChain.swift` — the breadcrumb hierarchy.

## Status / not yet validated

This scaffold was authored on Linux and **has not been compiled against CEF or
run on macOS**. Expect a finishing pass on a Mac:

- Confirm the CEF C++ API calls match your fetched CEF version (the API evolves
  between Chromium versions — especially `DownloadImage`, `SetAsChild`,
  `SetPreference` keys, and `CefStreamResourceHandler`).
- Wire the best-effort **login-form detection** (a render-process DOM visitor
  for password fields) — currently a hook in `CEFClientHandler` that calls
  `sinkDidDetectLoginForm`.
- Finish the **persistent-context reload** path when a user opts into login
  persistence mid-session.
- Verify the manual CEF embedding/signing build phases above.
