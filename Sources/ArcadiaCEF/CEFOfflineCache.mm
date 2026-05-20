#import "CEFOfflineCache.h"
#import <Foundation/Foundation.h>

#include "include/cef_resource_handler.h"
#include "include/cef_response_filter.h"
#include "include/wrapper/cef_stream_resource_handler.h"
#include <fstream>
#include <functional>

namespace arcadia {

std::string FileNameForURL(const std::string& url) {
    // Deterministic, filesystem-safe name. (std::hash is fine for collision-rare
    // local caching; switch to SHA-256 if you need stronger guarantees.)
    return std::to_string(std::hash<std::string>{}(url)) + ".bin";
}

namespace {

NSString* NS(const std::string& s) { return [NSString stringWithUTF8String:s.c_str()]; }

std::string SnapshotFilePath(const std::string& dir, const std::string& url) {
    return dir + "/" + FileNameForURL(url);
}

// ---- Capture ---------------------------------------------------------------

// Response filter that appends streamed bytes to a file.
class FileTeeFilter : public CefResponseFilter {
public:
    explicit FileTeeFilter(const std::string& path) : path_(path) {}

    bool InitFilter() override {
        out_.open(path_, std::ios::binary | std::ios::trunc);
        return out_.is_open();
    }

    FilterStatus Filter(void* data_in, size_t data_in_size, size_t& data_in_read,
                        void* data_out, size_t data_out_size, size_t& data_out_written) override {
        // Pass data through unchanged, copying a tee to disk.
        if (data_in && data_in_size > 0) {
            out_.write(static_cast<const char*>(data_in), data_in_size);
        }
        data_in_read = data_in_size;
        size_t n = std::min(data_in_size, data_out_size);
        if (n > 0 && data_in && data_out) { memcpy(data_out, data_in, n); }
        data_out_written = n;
        return (n < data_in_size) ? RESPONSE_FILTER_NEED_MORE_DATA : RESPONSE_FILTER_DONE;
    }

private:
    std::string path_;
    std::ofstream out_;
    IMPLEMENT_REFCOUNTING(FileTeeFilter);
};

class CaptureHandler : public CefResourceRequestHandler {
public:
    explicit CaptureHandler(const std::string& dir) : dir_(dir) {}

    CefRefPtr<CefResponseFilter> GetResourceResponseFilter(
        CefRefPtr<CefBrowser>, CefRefPtr<CefFrame>, CefRefPtr<CefRequest> request,
        CefRefPtr<CefResponse> response) override {
        // Skip JavaScript entirely — it is never stored.
        if (request->GetResourceType() == RT_SCRIPT) { return nullptr; }

        const std::string url = request->GetURL().ToString();
        AppendManifest(url, response->GetMimeType().ToString());
        return new FileTeeFilter(SnapshotFilePath(dir_, url));
    }

private:
    void AppendManifest(const std::string& url, const std::string& mime) {
        // One JSON-line per resource: {"url":..., "file":..., "mime":...}
        NSString* line = [NSString stringWithFormat:
            @"{\"url\":%@,\"file\":%@,\"mime\":%@}\n",
            JSONString(url), JSONString(FileNameForURL(url)), JSONString(mime)];
        NSString* manifest = [NS(dir_) stringByAppendingPathComponent:@"manifest.jsonl"];
        NSFileHandle* fh = [NSFileHandle fileHandleForWritingAtPath:manifest];
        if (!fh) {
            [[NSFileManager defaultManager] createFileAtPath:manifest contents:nil attributes:nil];
            fh = [NSFileHandle fileHandleForWritingAtPath:manifest];
        }
        [fh seekToEndOfFile];
        [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
    }

    static NSString* JSONString(const std::string& s) {
        NSData* d = [NSJSONSerialization dataWithJSONObject:@[NS(s)] options:0 error:nil];
        NSString* arr = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
        // arr is `["..."]`; strip the brackets to get the quoted string.
        return [arr substringWithRange:NSMakeRange(1, arr.length - 2)];
    }

    std::string dir_;
    IMPLEMENT_REFCOUNTING(CaptureHandler);
};

// ---- Replay ----------------------------------------------------------------

class ReplayHandler : public CefResourceRequestHandler {
public:
    explicit ReplayHandler(const std::string& dir) : dir_(dir) {}

    CefRefPtr<CefResourceHandler> GetResourceHandler(
        CefRefPtr<CefBrowser>, CefRefPtr<CefFrame>, CefRefPtr<CefRequest> request) override {
        // Never serve (or run) scripts offline.
        if (request->GetResourceType() == RT_SCRIPT) {
            return EmptyHandler();
        }
        const std::string url = request->GetURL().ToString();
        NSString* path = NS(SnapshotFilePath(dir_, url));
        NSData* data = [NSData dataWithContentsOfFile:path];
        if (!data) { return EmptyHandler(); }

        const std::string mime = MimeForURL(url);
        CefRefPtr<CefStreamReader> stream =
            CefStreamReader::CreateForData(const_cast<void*>(data.bytes), data.length);
        return new CefStreamResourceHandler(mime, stream);
    }

private:
    CefRefPtr<CefResourceHandler> EmptyHandler() {
        CefRefPtr<CefStreamReader> empty = CefStreamReader::CreateForData((void*)"", 0);
        return new CefStreamResourceHandler(404, "Not Found", "text/plain",
                                            CefResponse::HeaderMap(), empty);
    }

    std::string MimeForURL(const std::string& url) {
        // Read MIME from the manifest; fall back to octet-stream.
        // (Linear scan is fine for the modest number of resources per page.)
        NSString* manifest = [NS(dir_) stringByAppendingPathComponent:@"manifest.jsonl"];
        NSString* contents = [NSString stringWithContentsOfFile:manifest
                                                       encoding:NSUTF8StringEncoding error:nil];
        if (!contents) { return "application/octet-stream"; }
        for (NSString* line in [contents componentsSeparatedByString:@"\n"]) {
            if (line.length == 0) { continue; }
            NSData* d = [line dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary* obj = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
            if ([obj[@"url"] isEqualToString:NS(url)]) {
                return std::string([obj[@"mime"] UTF8String] ?: "application/octet-stream");
            }
        }
        return "application/octet-stream";
    }

    std::string dir_;
    IMPLEMENT_REFCOUNTING(ReplayHandler);
};

}  // namespace

CefRefPtr<CefResourceRequestHandler> MakeCaptureResourceHandler(const std::string& dir) {
    [[NSFileManager defaultManager] createDirectoryAtPath:NS(dir)
                              withIntermediateDirectories:YES attributes:nil error:nil];
    return new CaptureHandler(dir);
}

CefRefPtr<CefResourceRequestHandler> MakeReplayResourceHandler(const std::string& dir) {
    return new ReplayHandler(dir);
}

}  // namespace arcadia
