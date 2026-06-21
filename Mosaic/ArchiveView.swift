import SwiftUI

/// Archive — the run of past words. Free users see only the most recent few days; Pro unlocks the
/// full history. A locked card at the bottom invites free users to upgrade.
struct ArchiveView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showPaywall = false

    private var words: [WordEntry] { appModel.archiveWords(isPro: store.isPro) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(words.enumerated()), id: \.element.id) { offset, entry in
                        NavigationLink {
                            WordDetailView(entry: entry)
                        } label: {
                            ArchiveRow(entry: entry, dayLabel: dayLabel(offset: offset),
                                       isFavorite: appModel.isFavorite(entry))
                        }
                        .buttonStyle(.plain)
                    }

                    if !store.isPro {
                        lockedCard
                    }
                }
                .padding()
            }
            .background(MosaicBackground())
            .navigationTitle("Archive")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func dayLabel(offset: Int) -> String {
        if offset == 0 { return "Today" }
        if offset == 1 { return "Yesterday" }
        if let day = Calendar.current.date(byAdding: .day, value: -offset, to: .now) {
            return day.formatted(.dateTime.month().day())
        }
        return ""
    }

    private var lockedCard: some View {
        Button {
            Haptics.tap(); showPaywall = true
        } label: {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill").foregroundStyle(Color.mosaicAccent)
                    Text("The full archive is Pro").font(.headline)
                }
                Text("Unlock every word Mosaic has ever featured, plus favorites and unlimited challenges.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("Unlock \u{00B7} \(store.displayPrice)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.mosaicAccent)
            }
            .frame(maxWidth: .infinity)
            .mosaicCard()
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
}

struct ArchiveRow: View {
    let entry: WordEntry
    let dayLabel: String
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 14) {
            MosaicGlyph(size: 28)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.word)
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.primary)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.mosaicAccent)
                    }
                }
                Text(entry.definition)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(dayLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.mosaicCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
