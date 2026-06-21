import XCTest
import SwiftData
@testable import Mosaic

/// Unit tests for Mosaic's pure logic: the word-of-the-day mapping, the find-it challenge
/// tokenizer/matcher, the streak pipeline, and the Pro favorite gate.
@MainActor
final class MosaicLogicTests: XCTestCase {

    private func memoryModel() -> ModelContainer {
        try! ModelContainer(for: WordVisit.self,
                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private var calUTC: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    // MARK: - Word deck

    func testDeckLoadsAtLeast120Words() {
        XCTAssertGreaterThanOrEqual(WordDeck.all.count, 120, "curated deck must have >= 120 entries")
        // All entries are well-formed.
        for w in WordDeck.all {
            XCTAssertFalse(w.word.isEmpty)
            XCTAssertFalse(w.definition.isEmpty)
            XCTAssertFalse(w.etymology.isEmpty)
            XCTAssertFalse(w.passage.isEmpty)
        }
    }

    func testWordOfDayIsDeterministicForSameDate() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = WordDeck.word(for: date, calendar: calUTC)
        let b = WordDeck.word(for: date, calendar: calUTC)
        XCTAssertEqual(a, b, "same date must always map to the same word")
    }

    func testConsecutiveDaysAdvanceThroughDeck() {
        let cal = calUTC
        let day0 = Date(timeIntervalSince1970: 1_700_000_000)
        let day1 = cal.date(byAdding: .day, value: 1, to: day0)!
        let w0 = WordDeck.word(for: day0, calendar: cal)
        let w1 = WordDeck.word(for: day1, calendar: cal)
        // With a 124-word deck, adjacent days never collide.
        XCTAssertNotEqual(w0, w1, "consecutive days should yield different words")
    }

    func testEveryPassageContainsItsWord() {
        // The find-it challenge is unwinnable if a passage lacks its word.
        for w in WordDeck.all {
            let c = FindChallenge(passage: w.passage, target: w.word)
            XCTAssertTrue(c.isSolvable, "passage for '\(w.word)' must contain the word")
        }
    }

    // MARK: - FindChallenge

    func testTokenizerPreservesPassageExactly() {
        let passage = "The quick brown fox, it jumps!"
        let toks = FindChallenge.tokenize(passage)
        XCTAssertEqual(toks.map(\.text).joined(), passage, "tokens must reconstruct the original")
    }

    func testChallengeMatchesWordDespitePunctuation() {
        let c = FindChallenge(passage: "At dusk the lantern, the only lantern, glowed.", target: "lantern")
        XCTAssertTrue(c.isSolvable)
        // The correct index is a real word token whose core equals the target.
        let correct = c.tokens.first { $0.index == c.targetIndex }
        XCTAssertEqual(FindChallenge.core(correct?.text ?? ""), "lantern")
        XCTAssertTrue(c.isCorrect(index: c.targetIndex))
        // A different word token is wrong.
        if let other = c.tokens.first(where: { $0.isWord && $0.index != c.targetIndex }) {
            XCTAssertFalse(c.isCorrect(index: other.index))
        }
    }

    func testCoreStripsPunctuationAndLowercases() {
        XCTAssertEqual(FindChallenge.core("Petrichor."), "petrichor")
        XCTAssertEqual(FindChallenge.core("\u{201C}halcyon\u{201D}"), "halcyon")
        XCTAssertEqual(FindChallenge.core("END!"), "end")
    }

    // MARK: - Streak pipeline

    func testMarkSeenBuildsStreakAndIsIdempotentPerWord() {
        let model = AppModel(container: memoryModel())
        XCTAssertEqual(model.totalSeen, 0)
        XCTAssertFalse(model.didSeeToday)

        let today = WordDeck.today()
        model.markSeen(today)
        XCTAssertEqual(model.totalSeen, 1)
        XCTAssertTrue(model.didSeeToday)
        XCTAssertEqual(model.currentStreak, 1)

        // Re-seeing the same word does not create a duplicate visit.
        model.markSeen(today)
        XCTAssertEqual(model.totalSeen, 1, "marking the same word twice must be idempotent")
        XCTAssertEqual(model.currentStreak, 1)
    }

    func testCurrentStreakCountsConsecutiveDays() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let days: Set<Date> = [
            today,
            cal.date(byAdding: .day, value: -1, to: today)!,
            cal.date(byAdding: .day, value: -2, to: today)!
        ]
        XCTAssertEqual(AppModel.currentStreak(days: days, cal: cal), 3)
        XCTAssertEqual(AppModel.longestStreak(days: days, cal: cal), 3)
    }

    func testStreakBreaksWithGap() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        // Today + a 3-day-ago cluster: current streak counts only today.
        let days: Set<Date> = [
            today,
            cal.date(byAdding: .day, value: -3, to: today)!,
            cal.date(byAdding: .day, value: -4, to: today)!
        ]
        XCTAssertEqual(AppModel.currentStreak(days: days, cal: cal), 1)
        XCTAssertEqual(AppModel.longestStreak(days: days, cal: cal), 2)
    }

    // MARK: - Pro gating (defense-in-depth)

    func testFavoriteIsNoOpWithoutPro() {
        let model = AppModel(container: memoryModel())
        // No store attached -> not Pro -> favorite must not persist.
        let entry = WordDeck.today()
        model.toggleFavorite(entry)
        XCTAssertFalse(model.isFavorite(entry), "free users must not be able to favorite")
        XCTAssertTrue(model.favorites.isEmpty)
    }

    func testFreeArchiveIsLimitedAndProIsFull() {
        let model = AppModel(container: memoryModel())
        XCTAssertEqual(model.archiveWords(isPro: false).count, AppModel.freeArchiveDays)
        XCTAssertGreaterThan(model.archiveWords(isPro: true).count, AppModel.freeArchiveDays)
    }
}
