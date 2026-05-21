#include "arcadia/crwebview/browser/crwebview_offline_url_loader_factory.h"

#include <functional>
#include <memory>
#include <string>
#include <utility>

#include "arcadia/crwebview/browser/crwebview_state.h"
#include "base/containers/span.h"
#include "base/files/file.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/functional/bind.h"
#include "base/json/json_reader.h"
#include "base/json/json_writer.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/values.h"
#include "content/public/browser/web_contents.h"
#include "mojo/public/cpp/base/big_buffer.h"
#include "mojo/public/cpp/bindings/pending_receiver.h"
#include "mojo/public/cpp/bindings/pending_remote.h"
#include "mojo/public/cpp/bindings/receiver_set.h"
#include "mojo/public/cpp/bindings/remote.h"
#include "mojo/public/cpp/bindings/self_owned_receiver.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/public/cpp/system/data_pipe_producer.h"
#include "mojo/public/cpp/system/file_data_source.h"
#include "mojo/public/cpp/system/simple_watcher.h"
#include "mojo/public/cpp/system/string_data_source.h"
#include "net/base/net_errors.h"
#include "net/http/http_response_headers.h"
#include "net/url_request/redirect_info.h"
#include "services/network/public/cpp/resource_request.h"
#include "services/network/public/cpp/url_loader_completion_status.h"
#include "services/network/public/cpp/url_loader_factory_builder.h"
#include "services/network/public/mojom/early_hints.mojom.h"
#include "services/network/public/mojom/fetch_api.mojom-shared.h"
#include "services/network/public/mojom/url_loader.mojom.h"
#include "services/network/public/mojom/url_response_head.mojom.h"

namespace crwebview {

// ---- shared helpers (format identical to CEF's CEFOfflineCache) -------------

std::string FileNameForURL(const std::string& url) {
  return base::NumberToString(std::hash<std::string>{}(url)) + ".bin";
}

namespace {

base::FilePath SnapshotFilePath(const base::FilePath& dir,
                                const std::string& url) {
  return dir.AppendASCII(FileNameForURL(url));
}

// One JSON-Lines record per captured resource: {"url":..,"file":..,"mime":..}.
void AppendManifestEntry(const base::FilePath& dir,
                         const std::string& url,
                         const std::string& mime) {
  base::Value::Dict dict;
  dict.Set("url", url);
  dict.Set("file", FileNameForURL(url));
  dict.Set("mime", mime);
  std::string line;
  base::JSONWriter::Write(base::Value(std::move(dict)), &line);
  line += "\n";
  base::AppendToFile(dir.AppendASCII("manifest.jsonl"), line);
}

std::string MimeForURL(const base::FilePath& dir, const std::string& url) {
  std::string contents;
  if (!base::ReadFileToString(dir.AppendASCII("manifest.jsonl"), &contents)) {
    return "application/octet-stream";
  }
  for (std::string_view line : base::SplitStringPiece(
           contents, "\n", base::TRIM_WHITESPACE, base::SPLIT_WANT_NONEMPTY)) {
    std::optional<base::Value> v = base::JSONReader::Read(line);
    if (!v || !v->is_dict()) {
      continue;
    }
    const std::string* u = v->GetDict().FindString("url");
    if (u && *u == url) {
      const std::string* m = v->GetDict().FindString("mime");
      return m ? *m : "application/octet-stream";
    }
  }
  return "application/octet-stream";
}

bool IsScript(const network::ResourceRequest& request) {
  return request.destination == network::mojom::RequestDestination::kScript;
}

// ---- replay: serve stored bytes by URL; scripts -> 404 ----------------------

// One self-owned response. Streams a DataSource into the body pipe so any size
// works (a single WriteData would truncate large files such as cached video),
// and keeps the client Remote alive until the stream completes.
class ReplayResponder {
 public:
  static void RespondWithFile(
      mojo::Remote<network::mojom::URLLoaderClient> client,
      const std::string& mime,
      base::File file) {
    auto head = network::mojom::URLResponseHead::New();
    head->headers =
        base::MakeRefCounted<net::HttpResponseHeaders>("HTTP/1.1 200 OK");
    head->mime_type = mime;
    head->content_length = file.GetLength();
    new ReplayResponder(std::move(client), std::move(head),
                        std::make_unique<mojo::FileDataSource>(std::move(file)));
  }

  static void Respond404(
      mojo::Remote<network::mojom::URLLoaderClient> client) {
    auto head = network::mojom::URLResponseHead::New();
    head->headers = base::MakeRefCounted<net::HttpResponseHeaders>(
        "HTTP/1.1 404 Not Found");
    head->mime_type = "text/plain";
    new ReplayResponder(
        std::move(client), std::move(head),
        std::make_unique<mojo::StringDataSource>(
            base::span<const char>(), mojo::StringDataSource::AsyncWritingMode::
                                          STRING_STAYS_VALID_UNTIL_COMPLETION));
  }

 private:
  ReplayResponder(mojo::Remote<network::mojom::URLLoaderClient> client,
                  network::mojom::URLResponseHeadPtr head,
                  std::unique_ptr<mojo::DataPipeProducer::DataSource> source)
      : client_(std::move(client)) {
    mojo::ScopedDataPipeProducerHandle producer;
    mojo::ScopedDataPipeConsumerHandle consumer;
    if (mojo::CreateDataPipe(nullptr, producer, consumer) != MOJO_RESULT_OK) {
      client_->OnComplete(network::URLLoaderCompletionStatus(
          net::ERR_INSUFFICIENT_RESOURCES));
      delete this;
      return;
    }
    client_->OnReceiveResponse(std::move(head), std::move(consumer),
                               std::nullopt);
    producer_ = std::make_unique<mojo::DataPipeProducer>(std::move(producer));
    producer_->Write(
        std::move(source),
        base::BindOnce(&ReplayResponder::OnDone, base::Unretained(this)));
  }

  void OnDone(MojoResult result) {
    client_->OnComplete(network::URLLoaderCompletionStatus(
        result == MOJO_RESULT_OK ? net::OK : net::ERR_FAILED));
    delete this;
  }

  mojo::Remote<network::mojom::URLLoaderClient> client_;
  std::unique_ptr<mojo::DataPipeProducer> producer_;
};

// Self-owned factory that answers every request from the snapshot dir. Replaces
// CEF's ReplayHandler (CefStreamResourceHandler from the manifest). Deletes
// itself when its last receiver disconnects.
class ReplayURLLoaderFactory : public network::mojom::URLLoaderFactory {
 public:
  ReplayURLLoaderFactory(
      base::FilePath snapshot_dir,
      mojo::PendingReceiver<network::mojom::URLLoaderFactory> receiver)
      : snapshot_dir_(std::move(snapshot_dir)) {
    receivers_.Add(this, std::move(receiver));
    receivers_.set_disconnect_handler(base::BindRepeating(
        &ReplayURLLoaderFactory::OnDisconnect, base::Unretained(this)));
  }

  void CreateLoaderAndStart(
      mojo::PendingReceiver<network::mojom::URLLoader> loader,
      int32_t request_id,
      uint32_t options,
      const network::ResourceRequest& request,
      mojo::PendingRemote<network::mojom::URLLoaderClient> client,
      const net::MutableNetworkTrafficAnnotationTag& annotation) override {
    mojo::Remote<network::mojom::URLLoaderClient> client_remote(
        std::move(client));

    if (IsScript(request)) {
      ReplayResponder::Respond404(std::move(client_remote));
      return;
    }
    const std::string url = request.url.spec();
    base::File file(SnapshotFilePath(snapshot_dir_, url),
                    base::File::FLAG_OPEN | base::File::FLAG_READ);
    if (!file.IsValid()) {
      ReplayResponder::Respond404(std::move(client_remote));
      return;
    }
    ReplayResponder::RespondWithFile(std::move(client_remote),
                                     MimeForURL(snapshot_dir_, url),
                                     std::move(file));
  }

  void Clone(mojo::PendingReceiver<network::mojom::URLLoaderFactory> r)
      override {
    receivers_.Add(this, std::move(r));
  }

 private:
  void OnDisconnect() {
    if (receivers_.empty()) {
      delete this;
    }
  }

  base::FilePath snapshot_dir_;
  mojo::ReceiverSet<network::mojom::URLLoaderFactory> receivers_;
};

// ---- capture: forward to the network, tee non-script bodies to disk ---------

// Splices a source body pipe into both a file and a destination pipe (to the
// renderer), so capture never changes what the page receives. The
// network-service analog of CEF's FileTeeFilter.
//
// The byte-pump below is Stage A's A4 validation target (plan §9 "hardest
// port"): the watcher/two-phase-read mechanics must be confirmed against the
// pinned milestone's mojo data-pipe API. The architecture around it — skip
// scripts, write manifest on response, attach the tee between network and
// renderer — is final.
class BodyTee {
 public:
  static void Start(base::FilePath path,
                    mojo::ScopedDataPipeConsumerHandle source,
                    mojo::ScopedDataPipeProducerHandle dest) {
    new BodyTee(std::move(path), std::move(source), std::move(dest));
  }

 private:
  BodyTee(base::FilePath path,
          mojo::ScopedDataPipeConsumerHandle source,
          mojo::ScopedDataPipeProducerHandle dest)
      : file_(path,
              base::File::FLAG_CREATE_ALWAYS | base::File::FLAG_WRITE),
        source_(std::move(source)),
        dest_(std::move(dest)),
        watcher_(FROM_HERE, mojo::SimpleWatcher::ArmingPolicy::AUTOMATIC) {
    watcher_.Watch(
        source_.get(),
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
        base::BindRepeating(&BodyTee::OnReadable, base::Unretained(this)));
  }

  void OnReadable(MojoResult result, const mojo::HandleSignalsState&) {
    if (result != MOJO_RESULT_OK) {
      delete this;
      return;
    }
    base::span<const uint8_t> chunk;
    MojoResult r = source_->BeginReadData(MOJO_BEGIN_READ_DATA_FLAG_NONE, chunk);
    if (r == MOJO_RESULT_SHOULD_WAIT) {
      return;
    }
    if (r != MOJO_RESULT_OK) {  // FAILED_PRECONDITION == source finished
      delete this;
      return;
    }
    file_.WriteAtCurrentPos(chunk);
    size_t written = 0;
    dest_->WriteData(chunk, MOJO_WRITE_DATA_FLAG_NONE, written);
    source_->EndReadData(chunk.size());
  }

  base::File file_;
  mojo::ScopedDataPipeConsumerHandle source_;
  mojo::ScopedDataPipeProducerHandle dest_;
  mojo::SimpleWatcher watcher_;
};

// URLLoaderClient interposed between the network loader and the renderer's
// client. Records the manifest entry and tees the body. CEF analog:
// CaptureHandler::GetResourceResponseFilter.
class CaptureProxyClient : public network::mojom::URLLoaderClient {
 public:
  CaptureProxyClient(base::FilePath snapshot_dir,
                     std::string url,
                     mojo::PendingRemote<network::mojom::URLLoaderClient> real)
      : snapshot_dir_(std::move(snapshot_dir)),
        url_(std::move(url)),
        real_(std::move(real)) {}

  void OnReceiveResponse(
      network::mojom::URLResponseHeadPtr head,
      mojo::ScopedDataPipeConsumerHandle body,
      std::optional<mojo_base::BigBuffer> cached_metadata) override {
    AppendManifestEntry(snapshot_dir_, url_, head->mime_type);

    mojo::ScopedDataPipeProducerHandle to_renderer_producer;
    mojo::ScopedDataPipeConsumerHandle to_renderer_consumer;
    if (body && mojo::CreateDataPipe(nullptr, to_renderer_producer,
                                     to_renderer_consumer) == MOJO_RESULT_OK) {
      BodyTee::Start(SnapshotFilePath(snapshot_dir_, url_), std::move(body),
                     std::move(to_renderer_producer));
      real_->OnReceiveResponse(std::move(head), std::move(to_renderer_consumer),
                               std::move(cached_metadata));
    } else {
      real_->OnReceiveResponse(std::move(head), std::move(body),
                               std::move(cached_metadata));
    }
  }

  void OnReceiveEarlyHints(network::mojom::EarlyHintsPtr hints) override {
    real_->OnReceiveEarlyHints(std::move(hints));
  }
  void OnReceiveRedirect(const net::RedirectInfo& info,
                         network::mojom::URLResponseHeadPtr head) override {
    real_->OnReceiveRedirect(info, std::move(head));
  }
  void OnUploadProgress(int64_t current, int64_t total,
                        base::OnceCallback<void()> ack) override {
    real_->OnUploadProgress(current, total, std::move(ack));
  }
  void OnTransferSizeUpdated(int32_t diff) override {
    real_->OnTransferSizeUpdated(diff);
  }
  void OnComplete(const network::URLLoaderCompletionStatus& status) override {
    real_->OnComplete(status);
  }

 private:
  base::FilePath snapshot_dir_;
  std::string url_;
  mojo::Remote<network::mojom::URLLoaderClient> real_;
};

// Wraps the real network factory: scripts pass through untouched (live-loaded
// but never stored), everything else is teed via CaptureProxyClient.
class CaptureURLLoaderFactory : public network::mojom::URLLoaderFactory {
 public:
  CaptureURLLoaderFactory(
      base::FilePath snapshot_dir,
      mojo::PendingReceiver<network::mojom::URLLoaderFactory> receiver,
      mojo::PendingRemote<network::mojom::URLLoaderFactory> target)
      : snapshot_dir_(std::move(snapshot_dir)), target_(std::move(target)) {
    receivers_.Add(this, std::move(receiver));
    receivers_.set_disconnect_handler(base::BindRepeating(
        &CaptureURLLoaderFactory::OnDisconnect, base::Unretained(this)));
  }

  void CreateLoaderAndStart(
      mojo::PendingReceiver<network::mojom::URLLoader> loader,
      int32_t request_id,
      uint32_t options,
      const network::ResourceRequest& request,
      mojo::PendingRemote<network::mojom::URLLoaderClient> client,
      const net::MutableNetworkTrafficAnnotationTag& annotation) override {
    if (IsScript(request)) {
      target_->CreateLoaderAndStart(std::move(loader), request_id, options,
                                    request, std::move(client), annotation);
      return;
    }
    mojo::PendingRemote<network::mojom::URLLoaderClient> proxy_remote;
    mojo::MakeSelfOwnedReceiver(
        std::make_unique<CaptureProxyClient>(snapshot_dir_, request.url.spec(),
                                             std::move(client)),
        proxy_remote.InitWithNewPipeAndPassReceiver());
    target_->CreateLoaderAndStart(std::move(loader), request_id, options,
                                  request, std::move(proxy_remote), annotation);
  }

  void Clone(mojo::PendingReceiver<network::mojom::URLLoaderFactory> r)
      override {
    receivers_.Add(this, std::move(r));
  }

 private:
  void OnDisconnect() {
    if (receivers_.empty()) {
      delete this;
    }
  }

  base::FilePath snapshot_dir_;
  mojo::Remote<network::mojom::URLLoaderFactory> target_;
  mojo::ReceiverSet<network::mojom::URLLoaderFactory> receivers_;
};

void InstallCaptureProxy(const base::FilePath& snapshot_dir,
                         network::URLLoaderFactoryBuilder& factory_builder) {
  base::CreateDirectory(snapshot_dir);
  auto [receiver, target] = factory_builder.Append();
  new CaptureURLLoaderFactory(snapshot_dir, std::move(receiver),
                              std::move(target));
}

}  // namespace

bool MaybeInstallOfflineProxy(
    content::WebContents* web_contents,
    network::URLLoaderFactoryBuilder& factory_builder) {
  auto* state = CRWebViewState::FromWebContents(web_contents);
  if (!state || state->offline_mode == OfflineMode::kNone ||
      state->snapshot_dir.empty()) {
    return false;
  }

  if (state->offline_mode == OfflineMode::kReplay) {
    // Replace the network factory entirely: take the receiver end and bind our
    // disk-serving factory to it; drop the real network remote.
    auto [receiver, target] = factory_builder.Append();
    new ReplayURLLoaderFactory(state->snapshot_dir, std::move(receiver));
    // `target` (the real network factory) is intentionally left unbound;
    // everything is served from disk.
    return true;
  }

  // Capture: forward to the network, teeing each non-script body to disk.
  // CRWebViewCaptureURLLoaderFactory wraps the target factory (see below);
  // implemented as the validated-in-A4 body splice (plan §9).
  InstallCaptureProxy(state->snapshot_dir, factory_builder);
  return true;
}

mojo::PendingRemote<network::mojom::URLLoaderFactory>
CreateArcadiaCacheURLLoaderFactory(content::WebContents* web_contents) {
  auto* state = CRWebViewState::FromWebContents(web_contents);
  if (!state || state->snapshot_dir.empty()) {
    return mojo::NullRemote();
  }
  mojo::PendingRemote<network::mojom::URLLoaderFactory> remote;
  new ReplayURLLoaderFactory(state->snapshot_dir,
                             remote.InitWithNewPipeAndPassReceiver());
  return remote;
}

}  // namespace crwebview
