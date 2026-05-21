#ifndef ARCADIA_CRWEBVIEW_COMMON_CRWEBVIEW_OFFLINE_MODE_H_
#define ARCADIA_CRWEBVIEW_COMMON_CRWEBVIEW_OFFLINE_MODE_H_

namespace crwebview {

// Plain-C++ mirror of the ObjC CROfflineMode, usable from non-ObjC translation
// units (the browser client and the offline URLLoaderFactory). Mapped to/from
// CROfflineMode in crwebview.mm.
enum class OfflineMode {
  kNone = 0,
  kCapture = 1,
  kReplay = 2,
};

}  // namespace crwebview

#endif  // ARCADIA_CRWEBVIEW_COMMON_CRWEBVIEW_OFFLINE_MODE_H_
