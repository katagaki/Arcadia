import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            SiteDataSettingsView()
                .tabItem { Label("Site Data", systemImage: "externaldrive.badge.xmark") }
        }
        .frame(width: 480, height: 320)
    }
}
