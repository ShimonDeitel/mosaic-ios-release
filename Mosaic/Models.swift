import Foundation
import SwiftData

/// A word the user has visited (revealed on Home or opened from the Archive). One row per word.
/// All properties have defaults and there are no unique constraints, so the schema is
/// CloudKit-mirroring compatible. `date` is the day the word was first seen (drives the streak);
/// `isFavorite` powers the Favorites screen; `solvedChallenge` records the find-it win.
@Model
final class WordVisit {
    var wordID: String = ""
    var word: String = ""
    var date: Date = Date.now
    var isFavorite: Bool = false
    var solvedChallenge: Bool = false

    init(wordID: String = "", word: String = "", date: Date = .now,
         isFavorite: Bool = false, solvedChallenge: Bool = false) {
        self.wordID = wordID
        self.word = word
        self.date = date
        self.isFavorite = isFavorite
        self.solvedChallenge = solvedChallenge
    }
}
