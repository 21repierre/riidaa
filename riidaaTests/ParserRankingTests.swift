//
//  ParserRankingTests.swift
//  riidaaTests
//

import Foundation
import Testing
@testable import riidaa

/// Homographs are the case that matters: はし is both 橋 and 箸, and which one a reader wants
/// depends on how common it is, not on the per-dictionary score Yomitan ships.
@MainActor
@Suite(.serialized)
struct ParserRankingTests {

    init() async {
        _ = AppManager.shared
        var waited = 0
        while AppManager.shared.isLoading && waited < 500 {
            try? await Task.sleep(nanoseconds: 10_000_000)
            waited += 1
        }
        AppManager.shared.waitForPendingPurge()
    }

    private func makeDictionary() -> DictionaryDB? {
        let dictionary = SQLiteManager.shared.insertDictionary(
            revision: "test", title: "Ranking", sequenced: false, format: 3, author: nil,
            isUpdatable: false, indexUrl: nil, downloadUrl: nil, url: nil, description: nil,
            attribution: nil, sourceLanguage: nil, targetLanguage: nil, frequencyMode: nil
        )
        if let dictionary = dictionary { AppManager.shared.dictionaries.append(dictionary) }
        return dictionary
    }

    private func forget(_ dictionary: DictionaryDB) {
        try? SQLiteManager.shared.deleteDictionary(dictionaryId: dictionary.id)
        AppManager.shared.dictionaries.removeAll { $0.id == dictionary.id }
        SQLiteManager.shared.purgeOrphanedEntries()
    }

    private func insertTerms(_ dictionary: DictionaryDB) {
        let rows = [("橋", Int64(100)), ("箸", Int64(100))].map { term, score in
            TermInsertion(term: term, reading: "はし", definitionTags: "", wordTypes: "",
                          score: score, definitions: Data(#"["a gloss"]"#.utf8), sequence: 0,
                          termTags: "", dictionaryId: dictionary.id)
        }
        _ = SQLiteManager.shared.insertTerms(termsInsert: rows)
    }

    private func rank(_ commonest: String, _ dictionary: DictionaryDB) -> [String] {
        _ = SQLiteManager.shared.insertTermMeta(metaInsert: [
            TermMetaInsertion(term: commonest, reading: "はし", mode: "freq",
                              data: Data(#"{"value":50,"displayValue":"50"}"#.utf8),
                              dictionaryId: dictionary.id),
            TermMetaInsertion(term: commonest == "橋" ? "箸" : "橋", reading: "はし", mode: "freq",
                              data: Data(#"{"value":9000,"displayValue":"9000"}"#.utf8),
                              dictionaryId: dictionary.id),
        ])
        let parsed = Parser.parse(text: "はし")
        return parsed.first?.results.map { $0.term.term } ?? []
    }

    @Test func putsTheCommonerHomographFirst() throws {
        guard let dictionary = makeDictionary() else { Issue.record("no dictionary"); return }
        defer { forget(dictionary) }
        insertTerms(dictionary)

        let bridgeFirst = rank("橋", dictionary)
        #expect(bridgeFirst.prefix(2) == ["橋", "箸"], "got \(bridgeFirst)")
    }

    /// The same two entries, with the frequencies the other way round, must flip the order —
    /// otherwise the first case could be passing on insertion order alone.
    @Test func followsTheFrequencyRatherThanTheInsertionOrder() throws {
        guard let dictionary = makeDictionary() else { Issue.record("no dictionary"); return }
        defer { forget(dictionary) }
        insertTerms(dictionary)

        let chopsticksFirst = rank("箸", dictionary)
        #expect(chopsticksFirst.prefix(2) == ["箸", "橋"], "got \(chopsticksFirst)")
    }


    @Test func remembersThatAWordWasExported() throws {
        guard let dictionary = makeDictionary() else { Issue.record("no dictionary"); return }
        defer { forget(dictionary) }
        insertTerms(dictionary)

        #expect(SQLiteManager.shared.findTerms(texts: ["はし"])
            .filter { $0.dictionary.id == dictionary.id }
            .allSatisfy { !$0.exportedToAnki })

        SQLiteManager.shared.markExported(term: "箸", reading: "はし")

        let found = SQLiteManager.shared.findTerms(texts: ["はし"])
            .filter { $0.dictionary.id == dictionary.id }
        #expect(found.first { $0.term == "箸" }?.exportedToAnki == true)
        // The other homograph is a different word and must not be marked with it.
        #expect(found.first { $0.term == "橋" }?.exportedToAnki == false)
    }

}
