import SwiftUI

/// The hidden-word challenge: the passage is rendered as tappable word tokens. Tap the word that
/// matches today's definition. Correct taps win; wrong taps nudge with a gentle shake.
struct FindChallengeView: View {
    let entry: WordEntry
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private var challenge: FindChallenge { FindChallenge(passage: entry.passage, target: entry.word) }

    @State private var solved = false
    @State private var wrongIndex: Int? = nil
    @State private var attempts = 0
    @State private var revealed = false

    var body: some View {
        NavigationStack {
            ZStack {
                MosaicBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Find the word that means:")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(entry.definition)
                                .font(.title3.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .mosaicCard()

                        passageView

                        if solved {
                            resultCard
                        } else {
                            HStack {
                                Text("Tap the hidden word in the passage above.")
                                    .font(.footnote).foregroundStyle(.secondary)
                                Spacer()
                                Button("Reveal") { reveal() }
                                    .font(.footnote.weight(.semibold))
                                    .tint(Color.mosaicAccent)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Find it")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { finish() } }
            }
        }
    }

    private var passageView: some View {
        FlowText(tokens: challenge.tokens) { token in
            tokenView(token)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mosaicCard()
    }

    @ViewBuilder
    private func tokenView(_ token: PassageToken) -> some View {
        if token.isWord {
            let isTarget = token.index == challenge.targetIndex
            let highlight = (solved || revealed) && isTarget
            let isWrong = wrongIndex == token.index
            Text(token.text)
                .font(.system(size: 19, weight: highlight ? .bold : .regular, design: .serif))
                .foregroundStyle(highlight ? Color.white : .primary)
                .padding(.horizontal, highlight ? 4 : 0)
                .background(
                    highlight ? Color.mosaicAccent : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                )
                .offset(x: isWrong ? -4 : 0)
                .onTapGesture { tap(token) }
        } else {
            Text(token.text)
                .font(.system(size: 19, design: .serif))
                .foregroundStyle(.primary)
        }
    }

    private var resultCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.mosaicAccent)
            Text("Found it")
                .font(.title3.weight(.bold))
            Text("\(entry.word) \u{2014} solved in \(attempts) tap\(attempts == 1 ? "" : "s").")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Done") { finish() }
                .prominentButton()
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .mosaicCard()
    }

    private func tap(_ token: PassageToken) {
        guard !solved else { return }
        attempts += 1
        if challenge.isCorrect(index: token.index) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { solved = true }
            Haptics.success()
            appModel.markSolved(entry)
        } else {
            Haptics.warning()
            withAnimation(.default) { wrongIndex = token.index }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { wrongIndex = nil }
        }
    }

    private func reveal() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { revealed = true }
        Haptics.soft()
    }

    private func finish() {
        // Count a free user's daily challenge as used once they've engaged with it.
        appModel.recordChallengePlayed()
        dismiss()
    }
}

/// A minimal wrapping layout that flows token views left-to-right, wrapping to new lines —
/// used to render the passage as inline tappable words. iOS 16+ `Layout`.
struct FlowText<Content: View>: View {
    let tokens: [PassageToken]
    let content: (PassageToken) -> Content

    var body: some View {
        FlowLayout(spacing: 0, lineSpacing: 8) {
            ForEach(tokens) { token in
                content(token)
            }
        }
    }
}

/// A simple flow layout: places subviews in rows, wrapping when the row is full.
struct FlowLayout: Layout {
    var spacing: CGFloat = 0
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + lineSpacing
                totalWidth = max(totalWidth, rowWidth)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
