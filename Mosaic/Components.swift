import SwiftUI

/// The word "tile" used on Home and in detail — the headline word over its definition,
/// laid on a flat card. The mark in the corner is the app's small mosaic glyph.
struct WordCard: View {
    let entry: WordEntry
    var showEtymology = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.word)
                    .font(.system(size: 38, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                Spacer()
                MosaicGlyph(size: 26)
            }

            Text(entry.definition)
                .font(.title3)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if showEtymology {
                Divider().background(Color.mosaicHair)
                Label {
                    Text(entry.etymology)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "book.closed")
                        .font(.subheadline)
                        .foregroundStyle(Color.mosaicAccent)
                }
            }

            Text("\u{201C}\(entry.example)\u{201D}")
                .font(.callout.italic())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mosaicCard()
    }
}

/// A compact tile drawn from four small squares — the "mosaic" mark. Pure vector, no asset.
struct MosaicGlyph: View {
    var size: CGFloat = 24
    var tint: Color = .mosaicAccent

    var body: some View {
        let gap = size * 0.12
        let cell = (size - gap) / 2
        VStack(spacing: gap) {
            HStack(spacing: gap) {
                cellView(opacity: 1.0, cell: cell)
                cellView(opacity: 0.45, cell: cell)
            }
            HStack(spacing: gap) {
                cellView(opacity: 0.45, cell: cell)
                cellView(opacity: 1.0, cell: cell)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func cellView(opacity: Double, cell: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cell * 0.22, style: .continuous)
            .fill(tint.opacity(opacity))
            .frame(width: cell, height: cell)
    }
}

/// A small labelled metric tile (streak, total seen, etc.).
struct MetricTile: View {
    let value: String
    let label: String
    var systemImage: String? = nil

    var body: some View {
        VStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.mosaicAccent)
            }
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.mosaicAccent)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.mosaicCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// A streak "flame" pill.
struct StreakPill: View {
    let streak: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill").font(.subheadline.weight(.semibold))
            Text("\(streak) day\(streak == 1 ? "" : "s")").font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(streak > 0 ? Color.mosaicAccent : .secondary)
        .mosaicPill()
    }
}

/// A small "Pro" lock badge.
struct ProBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
            Text("Pro").font(.caption2.weight(.bold))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.mosaicAccent.opacity(0.15), in: Capsule())
        .foregroundStyle(Color.mosaicAccent)
    }
}

/// Wraps UIActivityViewController so we can share a word.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

/// Plain-text share copy for a word — original, factual, no emoji.
func shareText(for entry: WordEntry) -> String {
    """
    \(entry.word)
    \(entry.definition)

    Origin: \(entry.etymology)

    Found with Mosaic — one word a day.
    """
}
