import Foundation

/// One curated word in the Mosaic deck. Pure value type, decoded from the bundled `words.json`.
/// `passage` is a short original sentence that *contains* the word — used by the hidden-word
/// "find it" challenge. Every definition/etymology here is factual and authored for this app.
struct WordEntry: Codable, Identifiable, Equatable, Hashable {
    let word: String
    let definition: String
    let etymology: String
    let example: String
    let passage: String

    /// Stable id is the word itself (lowercased) — words are unique in the deck.
    var id: String { word.lowercased() }
}

/// Loads and serves the curated word deck. The "word of the day" is a deterministic function of
/// the calendar day, so it is identical on every device with no network or server involved.
enum WordDeck {
    /// All curated words, loaded once from the app bundle. Falls back to a tiny built-in set if the
    /// resource is somehow missing so the app never shows an empty screen.
    static let all: [WordEntry] = load()

    private static func load() -> [WordEntry] {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([WordEntry].self, from: data),
              !decoded.isEmpty
        else { return fallback }
        return decoded
    }

    private static let fallback: [WordEntry] = [
        WordEntry(word: "lumen", definition: "A unit of luminous flux; a measure of visible light.",
                  etymology: "From Latin 'lumen', light.",
                  example: "The lamp gave off a soft lumen of light.",
                  passage: "A single lumen of candlelight was enough to read the old letter by.")
    ]

    // MARK: - Word of the day (deterministic, offline)

    /// A stable integer "day index" for a given date, counting whole days from a fixed epoch.
    /// Using the user's current calendar keeps the rollover at local midnight.
    static func dayIndex(for date: Date, calendar: Calendar = .current) -> Int {
        let epoch = Date(timeIntervalSince1970: 0)            // 1970-01-01
        let startDay = calendar.startOfDay(for: date)
        let startEpoch = calendar.startOfDay(for: epoch)
        let days = calendar.dateComponents([.day], from: startEpoch, to: startDay).day ?? 0
        return days
    }

    /// The word for a given day. Deterministic across all devices for the same deck + date.
    static func word(for date: Date, calendar: Calendar = .current, deck: [WordEntry] = all) -> WordEntry {
        guard !deck.isEmpty else { return fallback[0] }
        let idx = ((dayIndex(for: date, calendar: calendar) % deck.count) + deck.count) % deck.count
        return deck[idx]
    }

    static func today(calendar: Calendar = .current) -> WordEntry {
        word(for: .now, calendar: calendar)
    }

    /// The most recent `count` days of words, today first. Used by the Archive screen.
    static func recent(count: Int, from date: Date = .now, calendar: Calendar = .current,
                       deck: [WordEntry] = all) -> [WordEntry] {
        guard !deck.isEmpty else { return [] }
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: date)
                .map { word(for: $0, calendar: calendar, deck: deck) }
        }
    }

    static func entry(id: String, deck: [WordEntry] = all) -> WordEntry? {
        deck.first { $0.id == id }
    }
}
