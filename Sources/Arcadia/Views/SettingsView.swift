import SwiftUI
import SwiftData
import ArcadiaCEF

/// Settings window (⌘,). A tab view; for now the only tab clears site data for
/// sites that persisted login.
struct SettingsView: View {
    var body: some View {
        TabView {
            SiteDataSettingsView()
                .tabItem { Label("Site Data", systemImage: "externaldrive.badge.xmark") }
        }
        .frame(width: 480, height: 320)
    }
}

private struct SiteDataSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersistedLoginSite.domain) private var sites: [PersistedLoginSite]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Sites with saved login")
                .font(.headline)
            Text("These sites are allowed to keep you signed in. Clearing a site removes its cookies and cached data.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if sites.isEmpty {
                Spacer()
                Text("No sites have saved login data.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                List {
                    ForEach(sites) { site in
                        HStack {
                            Text(site.domain)
                            Spacer()
                            Button("Clear") { clear(site) }
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func clear(_ site: PersistedLoginSite) {
        CEFSiteData.clearData(atCachePath: site.requestContextPath) {
            modelContext.delete(site)
            try? modelContext.save()
        }
    }
}
