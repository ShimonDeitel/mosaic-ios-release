import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @AppStorage("mosaic.theme") private var themeRaw = AppTheme.system.rawValue

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .system }

    var body: some View {
        MainTabView()
            .preferredColorScheme(theme.colorScheme)
            .onChange(of: store.isPro) { _, _ in appModel.refresh() }
    }
}

/// The four core screens: Home, Archive, Favorites, Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "sparkles") }
            ArchiveView()
                .tabItem { Label("Archive", systemImage: "square.grid.2x2") }
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "star") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Color.mosaicAccent)
    }
}
