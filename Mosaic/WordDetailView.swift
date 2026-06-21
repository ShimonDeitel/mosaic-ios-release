import SwiftUI

/// Full detail for a single word, reachable from the Archive and Favorites. Favoriting and
/// sharing are Pro features; the find-it challenge is reachable here too (subject to the daily gate).
struct WordDetailView: View {
    let entry: WordEntry
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showPaywall = false
    @State private var showChallenge = false
    @State private var showShare = false
    @State private var isFavorite = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                WordCard(entry: entry)

                HStack(spacing: 12) {
                    Button {
                        Haptics.tap()
                        if store.isPro {
                            appModel.toggleFavorite(entry)
                            isFavorite = appModel.isFavorite(entry)
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Label(isFavorite ? "Favorited" : "Favorite",
                              systemImage: isFavorite ? "star.fill" : "star")
                            .frame(maxWidth: .infinity)
                    }
                    .softButton()

                    Button {
                        Haptics.tap()
                        if store.isPro { showShare = true } else { showPaywall = true }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .softButton()
                }

                Button {
                    Haptics.tap()
                    if appModel.canPlayChallengeToday() { showChallenge = true }
                    else { showPaywall = true }
                } label: {
                    Label(appModel.canPlayChallengeToday() ? "Find it in a passage" : "Daily challenge used \u{2014} go Pro",
                          systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .prominentButton()
            }
            .padding()
        }
        .background(MosaicBackground())
        .navigationTitle(entry.word)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isFavorite = appModel.isFavorite(entry) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showShare) { ShareSheet(items: [shareText(for: entry)]) }
        .sheet(isPresented: $showChallenge) { FindChallengeView(entry: entry) }
    }
}
