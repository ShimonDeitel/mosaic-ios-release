import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @AppStorage("mosaic.theme") private var themeRaw = AppTheme.system.rawValue

    @State private var showPaywall = false
    @State private var restoreMessage: String?

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Mosaic \(v)"
    }

    var body: some View {
        NavigationStack {
            Form {
                statsSection
                proSection
                appearanceSection
                aboutSection
            }
            .navigationTitle("Settings")
            .tint(Color.mosaicAccent)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var statsSection: some View {
        Section {
            HStack(spacing: 12) {
                MetricTile(value: "\(appModel.currentStreak)", label: "Day streak", systemImage: "flame.fill")
                MetricTile(value: "\(appModel.longestStreak)", label: "Best streak", systemImage: "trophy.fill")
            }
            HStack(spacing: 12) {
                MetricTile(value: "\(appModel.totalSeen)", label: "Words seen", systemImage: "eye.fill")
                MetricTile(value: "\(appModel.solvedCount)", label: "Found", systemImage: "checkmark.seal.fill")
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
    }

    @ViewBuilder
    private var proSection: some View {
        Section {
            if store.isPro {
                HStack {
                    Label("Mosaic Pro", systemImage: "sparkles")
                    Spacer()
                    Text("Unlocked").foregroundStyle(.secondary)
                }
            } else {
                Button {
                    Haptics.tap(); showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Mosaic Pro", systemImage: "sparkles")
                        Spacer()
                        Text(store.displayPrice).foregroundStyle(.secondary)
                    }
                }
                Button("Restore Purchase") {
                    Task {
                        await store.restore()
                        restoreMessage = store.isPro ? "Restored." : "No previous purchase found."
                    }
                }
                if let restoreMessage {
                    Text(restoreMessage).font(.footnote).foregroundStyle(.secondary)
                }
            }
        } footer: {
            if !store.isPro {
                Text("One-time purchase. The full archive, favorites, unlimited challenges & sharing.")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $themeRaw) {
                ForEach(AppTheme.allCases) { Text($0.label).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var aboutSection: some View {
        Section {
            Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/mosaic-site/privacy.html")!)
        } footer: {
            Text(version).frame(maxWidth: .infinity, alignment: .center).padding(.top, 4)
        }
    }
}
