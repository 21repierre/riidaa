//
//  JapaneseParser.swift
//  riidaa
//
//  Created by Pierre on 2025/03/27.
//

import CoreData

public struct TermDeinflection : Hashable {
    public static func == (lhs: TermDeinflection, rhs: TermDeinflection) -> Bool {
        return lhs.term == rhs.term && lhs.deinflections == rhs.deinflections
    }
    
    public let term: TermDB
    public let deinflections: [Deinflection]
    
}

public struct ParsingResult : Hashable {
    
    public var original: String
    public let results: [TermDeinflection]
    
}

public struct Parser {
    
    
    /// Longest candidate token considered at each position. Japanese words are well within
    /// this; capping bounds the per-line work (was unbounded → O(n²) DB queries on long lines).
    private static let maxTokenLength = 15

    private static func normalized(_ text: String) -> String {
        text.katakanaToHiragana().expandLongVowels()
    }

    private static func matches(
        cut: String, deinflections: [Deinflection],
        in results: [TermDB], frequencies: [String: Int64]
    ) -> [TermDeinflection] {
        var terms: [TermDeinflection] = []
        for deinflection in deinflections {
            let target = Parser.normalized(deinflection.text)
            for term in results where
                (Parser.normalized(term.term) == target ||
                 Parser.normalized(term.reading) == target) &&
                (deinflection.types.isEmpty ||
                 term.wordTypes.isEmpty ||
                 deinflection.types.inflectionMatch(wl: term.wordTypes)) {
                terms.append(TermDeinflection(term: term, deinflections: [deinflection]))
            }
        }
        guard !terms.isEmpty else { return [] }

        let grouped = Dictionary(grouping: terms, by: { $0.term })
        let merged: [TermDeinflection] = grouped.map { term, group in
            TermDeinflection(term: term, deinflections: group.flatMap { $0.deinflections })
        }
        return merged.sorted {
            if $0.term.reading == cut && $1.term.reading != cut {
                return true
            } else if $0.term.reading != cut && $1.term.reading == cut {
                return false
            }
            let left = Parser.frequency(of: $0.term, in: frequencies)
            let right = Parser.frequency(of: $1.term, in: frequencies)
            if left != right {
                // Lower is more common, and a word nobody ranked goes last.
                return (left ?? .max) < (right ?? .max)
            }
            return $0.term.score > $1.term.score
        }
    }

    /// One query per position. Yomitan's `score` ranks within a dictionary; it says nothing
    /// about how common a word actually is.
    private static func frequencies(for texts: [String]) -> [String: Int64] {
        var lowest: [String: Int64] = [:]
        for entry in SQLiteManager.shared.findTermMeta(texts: texts) {
            guard case .frequency(let frequency) = entry.content, let value = frequency.value else {
                continue
            }
            let key = frequencyKey(entry.term, entry.reading)
            if let seen = lowest[key], seen <= value { continue }
            lowest[key] = value
        }
        return lowest
    }

    private static func frequencyKey(_ term: String, _ reading: String) -> String {
        "\(term)\u{1}\(reading)"
    }

    /// Filed against a reading, or against none when the term has only one.
    private static func frequency(of term: TermDB, in frequencies: [String: Int64]) -> Int64? {
        frequencies[frequencyKey(term.term, term.reading)]
            ?? frequencies[frequencyKey(term.term, "")]
    }

    public static func parse(text: String) -> [ParsingResult] {
        guard !text.isEmpty else { return [] }
        let chars = Array(text)
        let n = chars.count
        var l = 0
        var parts: [ParsingResult] = []

        while l < n {
            let upper = min(n, l + maxTokenLength)

            // Build every candidate substring starting at `l` and collect all lookup texts,
            // so the whole position needs a single batched DB query instead of one per length.
            var candidates: [(cut: String, deinflections: [Deinflection])] = []
            var lookupTexts = Set<String>()
            for end in stride(from: upper, to: l, by: -1) {
                let cut = String(chars[l..<end])
                let deinflections = Inflection.deinflect(text: cut)
                candidates.append((cut: cut, deinflections: deinflections))
                for di in deinflections {
                    lookupTexts.insert(di.text)
                    lookupTexts.insert(di.text.katakanaToHiragana())
                    lookupTexts.insert(Parser.normalized(di.text))
                }
            }

            let results = SQLiteManager.shared.findTerms(texts: Array(lookupTexts))
            // Keyed off what was found, not what was searched for: frequency entries are filed
            // under the term itself (橋), never under the reading a deinflection arrived as.
            let frequencies = Parser.frequencies(
                for: Array(Set(results.flatMap { [$0.term, $0.reading] }))
            )

            var possibilities: [ParsingResult] = []
            for candidate in candidates {
                let matched = Parser.matches(
                    cut: candidate.cut, deinflections: candidate.deinflections,
                    in: results, frequencies: frequencies
                )
                if !matched.isEmpty {
                    possibilities.append(ParsingResult(original: candidate.cut, results: matched))
                }
            }

            if !possibilities.isEmpty {
                guard let bestPos = possibilities.max(by: {a, b in
                    let aScore = a.results.map { $0.term.score }.max() ?? 0
                    let bScore = b.results.map { $0.term.score }.max() ?? 0
                    return a.original.count == b.original.count ? aScore < bScore : a.original.count < b.original.count
                }) else { break }
                parts.append(bestPos)
                l += bestPos.original.count
            } else {
                let c = chars[l]
                if var lastPart = parts.last, lastPart.results.isEmpty {
                    lastPart.original += String(c)
                    parts[parts.count - 1] = lastPart
                } else {
                    parts.append(ParsingResult(original: String(c), results: []))
                }
                l += 1
            }
        }
        return parts
    }
    
}
