import Foundation

/// A single token (word or punctuation run) from a passage, with its index.
struct PassageToken: Identifiable, Equatable {
    let index: Int
    let text: String          // the exact substring, including any trailing punctuation
    let isWord: Bool          // false for whitespace/punctuation-only runs
    var id: Int { index }
}

/// Pure logic for the hidden-word "find it" challenge: tokenize a passage, identify which token
/// is the target word, and check a tapped token. No UI, no I/O — fully unit-testable.
struct FindChallenge: Equatable {
    let passage: String
    let target: String        // the word to find
    let tokens: [PassageToken]
    let targetIndex: Int      // index of the first token whose core matches the target; -1 if none

    init(passage: String, target: String) {
        self.passage = passage
        self.target = target
        let toks = FindChallenge.tokenize(passage)
        self.tokens = toks
        let normTarget = FindChallenge.core(target)
        self.targetIndex = toks.first(where: { $0.isWord && FindChallenge.core($0.text) == normTarget })?.index ?? -1
    }

    /// True when the given token index is the hidden word.
    func isCorrect(index: Int) -> Bool { index == targetIndex && targetIndex >= 0 }

    /// Whether the passage actually contains the target (it always should for curated content).
    var isSolvable: Bool { targetIndex >= 0 }

    // MARK: - Tokenization

    /// Lowercased core of a token: strips leading/trailing non-letters so "petrichor." matches "petrichor".
    static func core(_ s: String) -> String {
        let lowered = s.lowercased()
        let trimmed = lowered.drop(while: { !$0.isLetter })
        var end = trimmed.endIndex
        while end > trimmed.startIndex {
            let prev = trimmed.index(before: end)
            if trimmed[prev].isLetter { break }
            end = prev
        }
        return String(trimmed[trimmed.startIndex..<end])
    }

    /// Split a passage into alternating word / non-word runs, preserving every character so the
    /// UI can re-render the passage exactly. A "word" run is a maximal run of letters/apostrophes.
    static func tokenize(_ passage: String) -> [PassageToken] {
        var result: [PassageToken] = []
        var current = ""
        var currentIsWord: Bool? = nil
        var idx = 0

        func flush() {
            guard let isWord = currentIsWord, !current.isEmpty else { return }
            result.append(PassageToken(index: idx, text: current, isWord: isWord))
            idx += 1
            current = ""
        }

        for ch in passage {
            let isWordChar = ch.isLetter || ch == "'" || ch == "\u{2019}"
            if currentIsWord == nil {
                currentIsWord = isWordChar
                current.append(ch)
            } else if currentIsWord == isWordChar {
                current.append(ch)
            } else {
                flush()
                currentIsWord = isWordChar
                current.append(ch)
            }
        }
        flush()
        return result
    }
}
