//
//  Furigana.swift
//  riidaa
//

import Foundation

/// Builds Anki's furigana notation from a term and its reading.
public struct Furigana {

    public static func annotate(term: String, reading: String) -> String? {
        guard !term.isEmpty else { return nil }
        guard !reading.isEmpty, reading != term else { return term }

        let termChars = Array(term)
        let readingChars = Array(reading)
        guard termChars.contains(where: { !isKana($0) }) else {
            return "\(term)[\(reading)]"
        }
        return distributed(term: termChars, reading: readingChars)
            ?? trimmed(term: termChars, reading: readingChars)
    }

    public static func annotate(surface: String, term: String, reading: String) -> String? {
        if surface == term {
            return annotate(term: term, reading: reading)
        }
        let surfaceChars = Array(surface)
        let termChars = Array(term)
        var shared = 0
        while shared < surfaceChars.count, shared < termChars.count, surfaceChars[shared] == termChars[shared] {
            shared += 1
        }
        let termEnding = String(termChars[shared...])
        // 来る's stem reads き or こ once conjugated, never the く of its dictionary form, and
        // compounds like 帰って来る inherit that.
        let endsInKuru = term.hasSuffix("来る") || term.hasSuffix("來る")
        guard shared > 0, !endsInKuru, termEnding.allSatisfy(isKana), reading.hasSuffix(termEnding) else {
            return nil
        }
        let stem = String(surfaceChars[..<shared])
        guard let annotatedStem = annotate(term: stem, reading: String(reading.dropLast(termEnding.count))) else {
            return nil
        }
        return annotatedStem + String(surfaceChars[shared...])
    }

    /// Gives each kanji run the slice of the reading ending where the next kana run starts
    private static func distributed(term: [Character], reading: [Character]) -> String? {
        let runs = runs(of: term)
        var result = ""
        var position = 0

        for (index, run) in runs.enumerated() {
            if run.isKana {
                let end = position + run.characters.count
                guard end <= reading.count, Array(reading[position..<end]) == run.characters else {
                    return nil
                }
                result += String(run.characters)
                position = end
                continue
            }

            let end: Int
            if index + 1 < runs.count {
                guard let anchor = firstIndex(
                    of: runs[index + 1].characters,
                    in: reading,
                    from: position + run.characters.count
                ) else {
                    return nil
                }
                end = anchor
            } else {
                end = reading.count
            }
            guard end > position else { return nil }

            if !result.isEmpty {
                result += " "
            }
            result += "\(String(run.characters))[\(String(reading[position..<end]))]"
            position = end
        }

        guard position == reading.count else { return nil }
        return result
    }

    /// Brackets everything between the kana the term and reading already share.
    private static func trimmed(term: [Character], reading: [Character]) -> String {
        var prefix = 0
        while prefix < term.count, prefix < reading.count, term[prefix] == reading[prefix] {
            prefix += 1
        }

        var suffix = 0
        while suffix < term.count - prefix, suffix < reading.count - prefix,
              term[term.count - 1 - suffix] == reading[reading.count - 1 - suffix] {
            suffix += 1
        }

        let base = String(term[prefix..<(term.count - suffix)])
        let baseReading = String(reading[prefix..<(reading.count - suffix)])
        guard !base.isEmpty, !baseReading.isEmpty else { return String(term) }

        let head = String(term[0..<prefix])
        let tail = String(term[(term.count - suffix)...])
        return "\(head)\(head.isEmpty ? "" : " ")\(base)[\(baseReading)]\(tail)"
    }

    private struct Run {
        let characters: [Character]
        let isKana: Bool
    }

    private static func runs(of term: [Character]) -> [Run] {
        var runs: [Run] = []
        for character in term {
            let kana = isKana(character)
            if let last = runs.last, last.isKana == kana {
                runs[runs.count - 1] = Run(characters: last.characters + [character], isKana: kana)
            } else {
                runs.append(Run(characters: [character], isKana: kana))
            }
        }
        return runs
    }

    private static func isKana(_ character: Character) -> Bool {
        String(character).isKana
    }

    private static func firstIndex(of needle: [Character], in haystack: [Character], from: Int) -> Int? {
        guard !needle.isEmpty, from >= 0 else { return nil }
        var start = from
        while start + needle.count <= haystack.count {
            if Array(haystack[start..<(start + needle.count)]) == needle {
                return start
            }
            start += 1
        }
        return nil
    }

}
