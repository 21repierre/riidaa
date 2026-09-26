//
//  TermMetaStorageTests.swift
//  riidaaTests
//

import Foundation
import Testing
@testable import riidaa

/// Exercises the real SQLite layer on the test host. Serialised because every case drives the
/// shared connection and the shared dictionary list.
@MainActor
@Suite(.serialized)
struct TermMetaStorageTests {

    init() async {
        _ = AppManager.shared
        var waited = 0
        while AppManager.shared.isLoading && waited < 500 {
            try? await Task.sleep(nanoseconds: 10_000_000)
            waited += 1
        }
        AppManager.shared.waitForPendingPurge()
    }

    private func makeDictionary(_ title: String) -> DictionaryDB? {
        let dictionary = SQLiteManager.shared.insertDictionary(
            revision: "test", title: title, sequenced: false, format: 3,
            author: nil, isUpdatable: false, indexUrl: nil, downloadUrl: nil, url: nil,
            description: nil, attribution: nil, sourceLanguage: nil, targetLanguage: nil,
            frequencyMode: nil
        )
        if let dictionary = dictionary {
            AppManager.shared.dictionaries.append(dictionary)
        }
        return dictionary
    }

    private func forget(_ dictionary: DictionaryDB) {
        try? SQLiteManager.shared.deleteDictionary(dictionaryId: dictionary.id)
        AppManager.shared.dictionaries.removeAll { $0.id == dictionary.id }
        SQLiteManager.shared.purgeOrphanedEntries()
    }

    private func blob(_ raw: String) -> Data { raw.data(using: .utf8)! }

    private func remaining(_ dictionary: DictionaryDB) -> Int {
        let db = SQLiteManager.shared.getDatabase()!
        let raw = try? db.scalar("SELECT count(*) FROM term_meta WHERE dictionaryId = ?", dictionary.id)
        return (raw as? Int64).map(Int.init) ?? -1
    }

    @Test func storesAndReadsBackBothMetadataKinds() throws {
        guard let dictionary = makeDictionary("RoundTrip") else { Issue.record("no dictionary"); return }
        defer { forget(dictionary) }

        #expect(SQLiteManager.shared.insertTermMeta(metaInsert: [
            TermMetaInsertion(term: "夫妻", reading: "ふさい", mode: "freq",
                              data: blob(#"{"reading":"ふさい","frequency":{"value":6923,"displayValue":"6923"}}"#),
                              dictionaryId: dictionary.id),
            TermMetaInsertion(term: "夫妻", reading: "ふさい", mode: "pitch",
                              data: blob(#"{"reading":"ふさい","pitches":[{"position":1}]}"#),
                              dictionaryId: dictionary.id),
            TermMetaInsertion(term: "夫妻", reading: "ふうさい", mode: "freq",
                              data: blob(#"{"reading":"ふうさい","frequency":1}"#),
                              dictionaryId: dictionary.id),
        ]) != nil)

        let found = SQLiteManager.shared.findTermMeta(texts: ["夫妻"]).filter { $0.dictionary.id == dictionary.id }
        #expect(found.count == 3)

        // The entry for the other reading is filtered out.
        let summary = TermMetaSummary(meta: found, reading: "ふさい")
        #expect(summary.frequencyLabels == ["RoundTrip: 6923"])
        #expect(summary.pitchPositions == ["[1]"])
    }

    /// Wadoku ships 10,000 entries per bank, which is 50,000 bind parameters against SQLite's
    /// 32,766 limit — the import failed outright until the inserts were chunked.
    @Test func insertsABankLargerThanTheBindParameterLimit() throws {
        guard let dictionary = makeDictionary("BigBank") else { Issue.record("no dictionary"); return }
        defer { forget(dictionary) }

        let rows = (0..<10_000).map { index in
            TermMetaInsertion(term: "語\(index)", reading: "", mode: "freq",
                              data: blob(#"{"value":1,"displayValue":"1"}"#),
                              dictionaryId: dictionary.id)
        }
        #expect(SQLiteManager.shared.insertTermMeta(metaInsert: rows) != nil)

        for index in [0, 5_000, 9_999] {
            let found = SQLiteManager.shared.findTermMeta(texts: ["語\(index)"])
                .filter { $0.dictionary.id == dictionary.id }
            #expect(found.count == 1, "語\(index) missing after a large insert")
        }
    }

    /// Deleting removes the dictionary at once and clears its entries afterwards, resuming from
    /// whatever is still orphaned — so being interrupted strands nothing.
    @Test func purgesDeletedEntriesAndResumesIfInterrupted() throws {
        guard let dictionary = makeDictionary("PurgeMe") else { Issue.record("no dictionary"); return }
        SQLiteManager.shared.purgeOrphanedEntries()

        let rows = (0..<400).map { index in
            TermMetaInsertion(term: "purge\(index)", reading: "", mode: "freq",
                              data: blob(#"{"value":1,"displayValue":"1"}"#),
                              dictionaryId: dictionary.id)
        }
        #expect(SQLiteManager.shared.insertTermMeta(metaInsert: rows) != nil)

        try SQLiteManager.shared.deleteDictionary(dictionaryId: dictionary.id)
        AppManager.shared.dictionaries.removeAll { $0.id == dictionary.id }

        // Invisible immediately, even though the rows are still on disk.
        #expect(SQLiteManager.shared.findTermMeta(texts: ["purge0"]).isEmpty)
        #expect(remaining(dictionary) == 400)

        var batchesAllowed = 2
        SQLiteManager.shared.purgeOrphanedEntries(batchSize: 50) {
            defer { batchesAllowed -= 1 }
            return batchesAllowed > 0
        }
        let afterInterruption = remaining(dictionary)
        #expect(afterInterruption < 400 && afterInterruption > 0)

        SQLiteManager.shared.purgeOrphanedEntries(batchSize: 50)
        #expect(remaining(dictionary) == 0)
    }

}
