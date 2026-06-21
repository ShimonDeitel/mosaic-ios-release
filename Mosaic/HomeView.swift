import SwiftUI

/// Home — today's word with its definition and etymology, the streak, and the hidden-word
/// "find it" challenge. Visiting Home marks today's word seen (drives the streak).
struct HomeView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showPaywall = false
    @State private var showChallenge = false
    @State private var showShare = false

    private let today = WordDeck.today()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header

                    WordCard(entry: today)

                    challengeCard

                    if store.isPro {
                        Button {
                            Haptics.tap(); showShare = true
                        } label: {
                            Label("Share this word", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .softButton()
                    } else {
                        unlockCard
                    }
                }
                .padding()
            }
            .background(MosaicBackground())
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { appModel.markSeen(today) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showShare) { ShareSheet(items: [shareText(for: today)]) }
            .sheet(isPresented: $showChallenge) {
                FindChallengeView(entry: today)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Word of the day")
                    .font(.title3.weight(.bold))
            }
            Spacer()
            StreakPill(streak: appModel.currentStreak)
        }
    }

    private var challengeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Find it", systemImage: "magnifyingglass")
                    .font(.headline)
                Spacer()
                if !store.isPro { ProBadge().opacity(appModel.canPlayChallengeToday() ? 0 : 1) }
            }
            Text("Today's word is hidden in a short passage. Can you spot it?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Haptics.tap()
                if appModel.canPlayChallengeToday() {
                    showChallenge = true
                } else {
                    showPaywall = true
                }
            } label: {
                Text(appModel.canPlayChallengeToday() ? "Start the challenge" : "Daily challenge used \u{2014} go Pro")
                    .frame(maxWidth: .infinity)
            }
            .prominentButton()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mosaicCard()
    }

    private var unlockCard: some View {
        Button {
            Haptics.tap(); showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.mosaicAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Mosaic Pro").font(.headline)
                    Text("Full archive, favorites, unlimited challenges & sharing.")
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Text(store.displayPrice).font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .mosaicCard()
        }
        .buttonStyle(.plain)
    }
}
