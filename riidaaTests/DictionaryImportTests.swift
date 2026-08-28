//
//  DictionaryImportTests.swift
//  riidaaTests
//

import Foundation
import Testing
@testable import riidaa

struct DictionaryImportTests {

    /// Fixtures go through JSONSerialization because that is what the importer is handed —
    /// Swift's own literals bridge to different types than parsed JSON does.
    private func json(_ raw: String) throws -> Any {
        try JSONSerialization.jsonObject(with: Data(raw.utf8), options: [.fragmentsAllowed])
    }

    private func index(_ raw: String) throws -> DictionaryIndex {
        try DictionaryIndex(json: try json(raw))
    }

    @Test func readsIndexAndFillsInOptionalProperties() throws {
        let full = try index("""
        {"revision": "2025.01.10.0", "title": "Jitendex", "sequenced": true, "format": 3,
         "isUpdatable": true, "indexUrl": "https://jitendex.org/static/yomitan.json"}
        """)
        #expect(full.revision == "2025.01.10.0")
        #expect(full.title == "Jitendex")
        #expect(full.sequenced)
        #expect(full.isUpdatable)
        #expect(full.indexUrl == "https://jitendex.org/static/yomitan.json")

        let minimal = try index(#"{"revision": "1", "title": "Wadoku"}"#)
        #expect(minimal.format == 3)
        #expect(!minimal.sequenced)
        #expect(!minimal.isUpdatable)
        #expect(minimal.indexUrl == nil)
    }

    @Test func rejectsAnIndexItCannotUse() throws {
        #expect(throws: DictionaryImportError.self) { try index(#"{"title": "No revision"}"#) }
        #expect(throws: DictionaryImportError.self) { try index(#"{"revision": "1"}"#) }
        #expect(throws: DictionaryImportError.self) { try index(#"["not", "an", "object"]"#) }
    }

    /// Two copies of one dictionary put doubles in every lookup.
    @Test func spotsADictionaryThatIsAlreadyInstalled() throws {
        func installed(_ id: Int64, _ title: String, _ indexUrl: String?) -> DictionaryDB {
            DictionaryDB(id: id, revision: "1", title: title, sequenced: false, format: 3,
                         author: nil, isUpdatable: false, indexUrl: indexUrl, downloadUrl: nil,
                         url: nil, description: nil, attribution: nil, sourceLanguage: nil,
                         targetLanguage: nil, frequencyMode: nil)
        }
        let library = [installed(1, "Jitendex", "https://jitendex.org/x.json"), installed(2, "Wadoku", nil)]

        let sameUrl = try index(#"{"revision": "2", "title": "Renamed", "indexUrl": "https://jitendex.org/x.json"}"#)
        #expect(sameUrl.installedCopy(among: library, ignoring: nil)?.id == 1)
        #expect(sameUrl.installedCopy(among: library, ignoring: 1) == nil)

        let sameTitle = try index(#"{"revision": "2", "title": "Wadoku"}"#)
        #expect(sameTitle.installedCopy(among: library, ignoring: nil)?.id == 2)
        #expect(try index(#"{"revision": "1", "title": "New"}"#).installedCopy(among: library, ignoring: nil) == nil)
    }

    @Test func readsTermBankRows() throws {
        let rows = try DictionaryBank.terms(from: try json("""
        [["猫", "ねこ", "n", "n", 100, ["cat"], 1234, "news"],
         ["犬", "いぬ", null, "n", 50, ["dog"], 5678, ""]]
        """), dictionaryId: 7)

        #expect(rows.count == 2)
        #expect(rows.first?.term == "猫")
        #expect(rows.first?.reading == "ねこ")
        #expect(rows.first?.score == 100)
        #expect(rows.first?.sequence == 1234)
        #expect(rows.allSatisfy { $0.dictionaryId == 7 })
        #expect(rows.first.map { String(data: $0.definitions, encoding: .utf8) } == "[\"cat\"]")
        // definitionTags is the one column a dictionary is allowed to leave out.
        #expect(rows.last?.definitionTags == "")
    }

    /// A row shorter than eight columns used to be read by index and trap.
    @Test func skipsRowsItCannotRead() throws {
        let rows = try DictionaryBank.terms(from: try json("""
        [[],
         ["猫", "ねこ"],
         ["猫", "ねこ", "n", "n", "not a score", ["cat"], 1234, ""],
         ["猫", "ねこ", "n", "n", 100, ["cat"], 1234, ""]]
        """), dictionaryId: 1)

        #expect(rows.count == 1)
        #expect(throws: DictionaryImportError.self) {
            try DictionaryBank.terms(from: try json(#"["not a list of rows"]"#), dictionaryId: 1)
        }
    }

    @Test func readsTermMetaBankRows() throws {
        let rows = try DictionaryBank.meta(from: try json("""
        [["猫", "freq", 1234],
         ["猫", "pitch", {"reading": "ねこ", "pitches": [{"position": 1}]}],
         ["猫"],
         ["猫", "unknown-mode", 1]]
        """), dictionaryId: 3)

        #expect(rows.count == 2)
        #expect(rows.first?.mode == "freq")
        #expect(rows.last?.reading == "ねこ")
        #expect(rows.allSatisfy { $0.dictionaryId == 3 })
    }

}
