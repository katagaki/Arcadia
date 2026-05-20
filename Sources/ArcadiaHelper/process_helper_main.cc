// Minimal entry point for CEF's sub-processes (renderer, GPU, plugin, alerts).
// All five helper bundles share this binary; CEF selects behaviour from the
// command line passed by the browser process.

#include "include/cef_app.h"
#include "include/wrapper/cef_library_loader.h"

int main(int argc, char* argv[]) {
    // Load the embedded framework relative to this helper executable.
    CefScopedLibraryLoader library_loader;
    if (!library_loader.LoadInHelper()) {
        return 1;
    }

    CefMainArgs main_args(argc, argv);

    // No CefApp needed for the generic helper; pass-through process execution.
    return CefExecuteProcess(main_args, nullptr, nullptr);
}
