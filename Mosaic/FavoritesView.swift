import SwiftUI

/// Favorites — the words the user has starred. Favoriting is a Pro feature, so free users see an
/// invitation to upgrade rather than an empty list.
struct FavoritesView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if !store.isPro {
                    proPrompt
                } else if appModel.favorites.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(MosaicBackground())
            .navigationTitle("Favorites")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(appModel.favorites) { visit in
                    if let entry = WordDeck.entry(id: visit.wordID) {
                        NavigationLink {
                            WordDetailView(entry: entry)
                        } label: {
                            ArchiveRow(entry: entry,
                                       dayLabel: visit.date.formatted(.dateTime.month().day()),
                                       isFavorite: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text("No favorites yet")
                .font(.headline)
            Text("Tap the star on any word to keep it here.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var proPrompt: some View {
        VStack(spacing: 14) {
            MosaicGlyph(size: 48)
            Text("Favorites are Pro")
                .font(.title3.weight(.bold))
            Text("Keep the words you love in one place, synced across your devices.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Unlock Mosaic Pro \u{00B7} \(store.displayPrice)") {
                Haptics.tap(); showPaywall = true
            }
            .prominentButton()
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
