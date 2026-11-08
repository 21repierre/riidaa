//
//  ParserInflectionTests.swift
//  riidaaTests
//

import Foundation
import Testing
@testable import riidaa

/// How lines split, and which dictionary form each piece lands on.
@MainActor
@Suite(.serialized)
struct ParserInflectionTests {

    init() async {
        _ = AppManager.shared
        var waited = 0
        while AppManager.shared.isLoading && waited < 500 {
            try? await Task.sleep(nanoseconds: 10_000_000)
            waited += 1
        }
        AppManager.shared.waitForPendingPurge()
    }

    private func withDictionary(_ terms: [(term: String, reading: String, rules: String)], _ body: () -> Void) {
        guard let dictionary = SQLiteManager.shared.insertDictionary(
            revision: "test", title: "Inflection", sequenced: false, format: 3, author: nil,
            isUpdatable: false, indexUrl: nil, downloadUrl: nil, url: nil, description: nil,
            attribution: nil, sourceLanguage: nil, targetLanguage: nil, frequencyMode: nil
        ) else {
            Issue.record("no dictionary")
            return
        }
        AppManager.shared.dictionaries.append(dictionary)
        defer {
            try? SQLiteManager.shared.deleteDictionary(dictionaryId: dictionary.id)
            AppManager.shared.dictionaries.removeAll { $0.id == dictionary.id }
            SQLiteManager.shared.purgeOrphanedEntries()
        }
        _ = SQLiteManager.shared.insertTerms(termsInsert: terms.map {
            TermInsertion(term: $0.term, reading: $0.reading, definitionTags: "", wordTypes: $0.rules,
                          score: 0, definitions: Data(#"["a gloss"]"#.utf8), sequence: 0,
                          termTags: "", dictionaryId: dictionary.id)
        })
        body()
    }

    private func split(_ text: String) -> [String] {
        Parser.parse(text: text).map { part in
            guard let term = part.results.first?.term.term else { return part.original }
            return "\(part.original)→\(term)"
        }
    }

    /// Nouns carry no conjugation rules, and used to match any verb ending: にいた was read as
    /// 肉 (にく) with a ーた chain.
    @Test func doesNotConjugateNouns() {
        withDictionary([("肉", "にく", ""), ("いる", "いる", "v1")]) {
            #expect(split("にいた") == ["に", "いた→いる"])
        }
    }

    /// Monolingual dictionaries often ship no conjugation rules at all, and their verbs still
    /// have to be found from an inflected form.
    @Test func conjugatesEntriesFromDictionariesWithoutRules() {
        withDictionary([("食べる", "たべる", "")]) {
            #expect(split("食べた") == ["食べた→食べる"])
        }
    }

    /// ている contracts to てる, which then takes ない, ます and た like any ichidan verb.
    @Test func followsTeiruContractions() {
        withDictionary([("見る", "みる", "v1"), ("待つ", "まつ", "v5")]) {
            #expect(split("見てない") == ["見てない→見る"])
            #expect(split("待ってます") == ["待ってます→待つ"])
            #expect(split("見てた") == ["見てた→見る"])
        }
    }

    /// Manga stretches volitionals with ー and shouts imperatives in katakana.
    @Test func deinflectsStretchedAndKatakanaForms() {
        withDictionary([("行く", "いく", "v5"), ("止める", "やめる", "v1"), ("食べる", "たべる", "v1")]) {
            #expect(split("行こー") == ["行こー→行く"])
            #expect(split("食べよー") == ["食べよー→食べる"])
            #expect(split("ヤメロ") == ["ヤメロ→止める"])
        }
    }

    /// Emphatic ー after hiragana is dropped, but a katakana long vowel is part of the word.
    @Test func dropsStretchingOnlyAfterHiragana() {
        withDictionary([("すごい", "すごい", "adj-i"), ("ビル", "びる", "")]) {
            #expect(split("すごーい") == ["すごーい→すごい"])
            #expect(!split("ビール").contains("ビール→ビル"))
        }
    }

    @Test func findsSuruNounsAndNegativeForms() {
        withDictionary([("勉強", "べんきょう", "vs"), ("行く", "いく", "v5")]) {
            #expect(split("勉強した") == ["勉強した→勉強"])
            #expect(split("行かないで") == ["行かないで→行く"])
            #expect(split("行かなくちゃ") == ["行かなくちゃ→行く"])
        }
    }

    @Test func readsThroughStretchedSpellings() {
        withDictionary([("すごい", "すごい", "adj-i")]) {
            #expect(split("すごーい") == ["すごーい→すごい"])
            #expect(split("すご〜い") == ["すご〜い→すごい"])
            #expect(split("すごぉい") == ["すごぉい→すごい"])
        }
    }
}
