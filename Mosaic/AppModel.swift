import Foundation
import SwiftData
import SwiftUI

/// App state: owns the SwiftData store, derives the streak from visited words, tracks favorites,
/// and enforces the free/Pro feature split. Stats are always derived from visits — never stored truth.
///
/// Free: today's word + streak, and one find-it challenge per day.
/// Pro: the full archive, unlimited find-it challenges, favorites, and sharing.
@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var currentStreak = 0
    @Published private(set) var longestStreak = 0
    @Published private(set) var totalSeen = 0
    @Published private(set) var solvedCount = 0
    @Published private(set) var didSeeToday = false
    @Published private(set) var favorites: [WordVisit] = []

    /// Free users get one find-it attempt per calendar day. This tracks the last day a challenge
    /// was played, stored locally (not security-sensitive — Pro gating for content is separate).
    private let kLastChallengeDay = "mosaic.challenge.lastDay"

    /// The free archive shows only the most recent few days.
    static let freeArchiveDays = 3

    init(container: ModelContainer) {
        self.container = container
        #if DEBUG
        seedIfRequested()
        #endif
        refresh()
    }

    // MARK: Container (local-only on-device persistence)

    static func makeContainer() -> ModelContainer {
        let schema = Schema([WordVisit.self])
        let local = ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: local) { return c }
        // Last resort so the app never crashes on launch.
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: mem)
    }

    // MARK: Visits

    private func fetchAll() -> [WordVisit] {
        (try? container.mainContext.fetch(FetchDescriptor<WordVisit>())) ?? []
    }

    func visit(for entry: WordEntry) -> WordVisit? {
        fetchAll().first { $0.wordID == entry.id }
    }

    /// Records that the user has seen a word today. Idempotent per word — re-seeing keeps the
    /// original date so the streak reflects first-seen days. Returns the (existing or new) visit.
    @discardableResult
    func markSeen(_ entry: WordEntry) -> WordVisit {
        let ctx = container.mainContext
        if let existing = visit(for: entry) {
            refresh()
            return existing
        }
        let v = WordVisit(wordID: entry.id, word: entry.word, date: .now)
        ctx.insert(v)
        try? ctx.save()
        refresh()
        return v
    }

    func isFavorite(_ entry: WordEntry) -> Bool { visit(for: entry)?.isFavorite ?? false }

    /// Toggle favorite. Favoriting is a Pro feature; for free users this is a no-op (the UI also gates).
    func toggleFavorite(_ entry: WordEntry) {
        guard store?.isPro == true else { return }
        let ctx = container.mainContext
        let v = visit(for: entry) ?? {
            let nv = WordVisit(wordID: entry.id, word: entry.word, date: .now)
            ctx.insert(nv); return nv
        }()
        v.isFavorite.toggle()
        try? ctx.save()
        refresh()
    }

    func markSolved(_ entry: WordEntry) {
        let ctx = container.mainContext
        let v = visit(for: entry) ?? {
            let nv = WordVisit(wordID: entry.id, word: entry.word, date: .now)
            ctx.insert(nv); return nv
        }()
        if !v.solvedChallenge {
            v.solvedChallenge = true
            try? ctx.save()
            refresh()
        }
    }

    // MARK: Challenge daily limit (free tier)

    /// True if a free user may still play a find-it challenge today. Pro users are unlimited.
    func canPlayChallengeToday() -> Bool {
        if store?.isPro == true { return true }
        let today = Calendar.current.startOfDay(for: .now)
        guard let last = UserDefaults.standard.object(forKey: kLastChallengeDay) as? Date else { return true }
        return Calendar.current.startOfDay(for: last) != today
    }

    /// Call after a free user completes a challenge so the next one is gated until tomorrow.
    func recordChallengePlayed() {
        guard store?.isPro != true else { return }
        UserDefaults.standard.set(Date(), forKey: kLastChallengeDay)
    }

    // MARK: Archive (Pro-gated depth)

    /// Words available in the archive. Free users see only the most recent few days.
    func archiveWords(isPro: Bool) -> [WordEntry] {
        let days = isPro ? min(WordDeck.all.count, 365) : Self.freeArchiveDays
        return WordDeck.recent(count: days)
    }

    // MARK: Stats

    func refresh() {
        let all = fetchAll()
        totalSeen = all.count
        solvedCount = all.filter { $0.solvedChallenge }.count
        favorites = all.filter { $0.isFavorite }.sorted { $0.date > $1.date }

        let cal = Calendar.current
        let days = Set(all.map { cal.startOfDay(for: $0.date) })
        didSeeToday = days.contains(cal.startOfDay(for: .now))
        currentStreak = Self.currentStreak(days: days, cal: cal)
        longestStreak = Self.longestStreak(days: days, cal: cal)
    }

    nonisolated static func currentStreak(days: Set<Date>, cal: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        var day = cal.startOfDay(for: .now)
        // If today isn't logged yet, the streak still stands as of yesterday.
        if !days.contains(day) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day), days.contains(yesterday)
            else { return 0 }
            day = yesterday
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    nonisolated static func longestStreak(days: Set<Date>, cal: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        var best = 1, run = 1
        for i in 1..<sorted.count {
            if let prev = cal.date(byAdding: .day, value: 1, to: sorted[i - 1]), prev == sorted[i] {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    // MARK: Account deletion

    /// Erase all on-device data (used by Delete Account).
    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: WordVisit.self)
        try? ctx.save()
        UserDefaults.standard.removeObject(forKey: kLastChallengeDay)
        refresh()
    }

    // MARK: DEBUG seeding (compiled out of Release)

    #if DEBUG
    private func seedIfRequested() {
        let env = ProcessInfo.processInfo.environment
        guard let n = env["MOSAIC_SEED"].flatMap(Int.init), n > 0 else { return }
        let ctx = container.mainContext
        if fetchAll().isEmpty {
            let cal = Calendar.current
            for offset in 0..<n {
                if let day = cal.date(byAdding: .day, value: -offset, to: .now) {
                    let w = WordDeck.word(for: day)
                    ctx.insert(WordVisit(wordID: w.id, word: w.word, date: day,
                                         isFavorite: offset % 4 == 0, solvedChallenge: offset % 3 == 0))
                }
            }
            try? ctx.save()
        }
    }
    #endif
}
