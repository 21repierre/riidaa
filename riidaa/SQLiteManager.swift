//
//  SQLiteManager.swift
//  riidaa
//
//  Created by Pierre on 2025/04/03.
//

import Foundation
import os
import SQLite
typealias Expression = SQLite.Expression

class SQLiteManager {
    static let shared = SQLiteManager()
    private var db: Connection?
    /// Its own connection so a running import cannot block lookups; WAL lets it keep reading
    /// the last committed snapshot while the writer holds a transaction.
    private var reader: Connection?

    // Table Definitions
    let dictionaries = Table("dictionaries")
    let terms = Table("terms")
    let termMeta = Table("term_meta")

    // Dictionary
    let id = Expression<Int64>("id")
    let revision = SQLite.Expression<String>("revision")
    let title = SQLite.Expression<String>("title")
    let sequenced = SQLite.Expression<Bool>("sequenced")
    let format = SQLite.Expression<Int>("format")
    let author = SQLite.Expression<String?>("author")
    let isUpdatable = SQLite.Expression<Bool>("isUpdatable")
    let indexUrl = SQLite.Expression<String?>("indexUrl")
    let downloadUrl = SQLite.Expression<String?>("downloadUrl")
    let url = SQLite.Expression<String?>("url")
    let description = SQLite.Expression<String?>("description")
    let attribution = SQLite.Expression<String?>("attribution")
    let sourceLanguage = SQLite.Expression<String?>("sourceLanguage")
    let targetLanguage = SQLite.Expression<String?>("targetLanguage")
    let frequencyMode = SQLite.Expression<String?>("frequencyMode")

    // Term
    let term = SQLite.Expression<String>("term")
    let reading = SQLite.Expression<String>("reading")
    let definitionTags = SQLite.Expression<String>("definitionTags")
    let wordTypes = SQLite.Expression<String>("wordTypes")
    let score = SQLite.Expression<Int64>("score")
    let definitions = SQLite.Expression<Data>("definitions")
    let sequenceNumber = SQLite.Expression<Int64>("sequenceNumber")
    let termTags = SQLite.Expression<String>("termTags")
    let dictionaryId = SQLite.Expression<Int64>("dictionaryId")
    let exportedToAnki = SQLite.Expression<Bool>("exportedToAnki")

    // Term metadata
    let metaMode = SQLite.Expression<String>("mode")
    let metaReading = SQLite.Expression<String>("metaReading")
    let metaData = SQLite.Expression<Data>("data")

    private let access = DispatchQueue(label: "dev.repierre.riidaa.sqlite")
    private let readAccess = DispatchQueue(label: "dev.repierre.riidaa.sqlite.read", attributes: .concurrent)

    enum DatabaseError: LocalizedError {
        case unavailable

        var errorDescription: String? { "The dictionary database could not be opened." }
    }

    private func perform<T>(_ work: () throws -> T) rethrows -> T {
        try access.sync(execute: work)
    }

    private func performRead<T>(_ work: () throws -> T) rethrows -> T {
        try readAccess.sync(execute: work)
    }

    /// Mirrored here so lookups don't read published UI state off their own thread. Its own
    /// lock rather than `access`, which an import can hold for the length of a bank.
    private let installedLock = NSLock()
    private var installed: [Int64: DictionaryDB] = [:]

    func setInstalledDictionaries(_ dictionaries: [DictionaryDB]) {
        installedLock.lock()
        installed = Dictionary(dictionaries.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        installedLock.unlock()
    }

    private func installedDictionaries() -> [Int64: DictionaryDB] {
        installedLock.lock()
        defer { installedLock.unlock() }
        return installed
    }

    private init() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let databaseFile = "\(path)/dictionaries.sqlite3"
        do {
            db = try Connection(databaseFile)
            try db?.run("PRAGMA journal_mode=WAL")
            db?.busyTimeout = 5

            try db?.run(dictionaries.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(revision)
                t.column(title)
                t.column(sequenced)
                t.column(format)
                t.column(author)
                t.column(isUpdatable)
                t.column(indexUrl)
                t.column(downloadUrl)
                t.column(url)
                t.column(description)
                t.column(attribution)
                t.column(sourceLanguage)
                t.column(targetLanguage)
                t.column(frequencyMode)
            })

            try db?.run(terms.create(ifNotExists: true) { t in
                t.column(term)
                t.column(reading)
                t.column(definitionTags)
                t.column(wordTypes)
                t.column(score)
                t.column(definitions)
                t.column(sequenceNumber)
                t.column(termTags)
                t.column(dictionaryId)
                t.column(exportedToAnki, defaultValue: false)
                t.foreignKey(dictionaryId, references: dictionaries, id, delete: .cascade)
                t.primaryKey(term, reading, definitions, dictionaryId)
            })
            try db?.run(terms.createIndex(term, ifNotExists: true))
            try db?.run(terms.createIndex(reading, ifNotExists: true))
            try db?.run(terms.createIndex(dictionaryId, ifNotExists: true))

            try db?.run(termMeta.create(ifNotExists: true) { t in
                t.column(term)
                t.column(metaReading)
                t.column(metaMode)
                t.column(metaData)
                t.column(dictionaryId)
                t.foreignKey(dictionaryId, references: dictionaries, id, delete: .cascade)
            })
            try db?.run(termMeta.createIndex(term, ifNotExists: true))
            try db?.run(termMeta.createIndex(dictionaryId, ifNotExists: true))
        } catch {
            Logger.database.error("Database setup failed: \(error.localizedDescription, privacy: .public)")
        }

        do {
            try db?.run(terms.addColumn(exportedToAnki, defaultValue: false))
        } catch {
            // Column already present.
        }

        do {
            try db?.run("PRAGMA wal_checkpoint(TRUNCATE)")
        } catch {
            Logger.database.error("Checkpoint failed: \(error.localizedDescription, privacy: .public)")
        }

        do {
            // Opened after the writer, which creates the database and its WAL.
            reader = try Connection(databaseFile, readonly: true)
            reader?.busyTimeout = 5
        } catch {
            Logger.database.error("Read connection unavailable: \(error.localizedDescription, privacy: .public)")
        }
    }

    func getDatabase() -> Connection? {
        return db
    }

    func allDictionaries() -> [DictionaryDB] {
        perform {
            guard let db = db else { return [] }
            var loaded: [DictionaryDB] = []
            do {
                for row in try db.prepare(dictionaries) {
                    loaded.append(DictionaryDB(
                        id: row[id],
                        revision: row[revision],
                        title: row[title],
                        sequenced: row[sequenced],
                        format: row[format],
                        author: row[author],
                        isUpdatable: row[isUpdatable],
                        indexUrl: row[indexUrl],
                        downloadUrl: row[downloadUrl],
                        url: row[url],
                        description: row[description],
                        attribution: row[attribution],
                        sourceLanguage: row[sourceLanguage],
                        targetLanguage: row[targetLanguage],
                        frequencyMode: row[frequencyMode]
                    ))
                }
            } catch {
                Logger.database.error("Failed to load dictionaries: \(error.localizedDescription, privacy: .public)")
            }
            return loaded
        }
    }
    
    /// Removes the dictionary itself and nothing else.
    func deleteDictionary(dictionaryId: Int64) throws {
        try perform {
            guard let db = db else { throw DatabaseError.unavailable }
            try db.run(dictionaries.filter(id == dictionaryId).delete())
        }
    }

    /// Clears rows belonging to dictionaries that no longer exist, a batch at a time.
    func purgeOrphanedEntries(
        batchSize: Int = 750,
        shouldContinue: () -> Bool = { true },
        progress: ((_ cleared: Int, _ total: Int) -> Void)? = nil
    ) {
        let orphanCondition = "dictionaryId NOT IN (SELECT id FROM dictionaries)"
        let tables = ["terms", "term_meta"]

        let total: Int = perform {
            guard let db = db else { return 0 }
            return tables.reduce(0) { running, table in
                do {
                    guard let value = try db.scalar("SELECT count(*) FROM \(table) WHERE \(orphanCondition)") as? Int64 else {
                        return running
                    }
                    return running + Int(value)
                } catch {
                    Logger.database.error("Failed to count orphaned entries in \(table, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    return running
                }
            }
        }
        guard total > 0 else { return }

        var cleared = 0
        var finished = false
        progress?(cleared, total)

        for table in tables {
            let statement = "DELETE FROM \(table) WHERE rowid IN (SELECT rowid FROM \(table) WHERE \(orphanCondition) LIMIT ?)"
            while shouldContinue() {
                let removed: Int = perform {
                    guard let db = db else { return 0 }
                    do {
                        try db.run(statement, batchSize)
                        return db.changes
                    } catch {
                        Logger.database.error("Purge failed: \(error.localizedDescription, privacy: .public)")
                        return 0
                    }
                }
                if removed == 0 { break }
                cleared += removed
                progress?(cleared, total)
                finished = cleared >= total
                // Let anything waiting on the database in ahead of the next batch.
                Thread.sleep(forTimeInterval: 0.02)
            }
        }

        if finished {
            progress?(total, total)
        }
    }
    
    func insertDictionary(revision: String, title: String, sequenced: Bool, format: Int, author: String?, isUpdatable: Bool, indexUrl: String?, downloadUrl: String?, url: String?, description: String?, attribution: String?, sourceLanguage: String?, targetLanguage: String?, frequencyMode: String?) -> DictionaryDB? {
        perform {
            insertDictionaryLocked(revision: revision, title: title, sequenced: sequenced, format: format, author: author, isUpdatable: isUpdatable, indexUrl: indexUrl, downloadUrl: downloadUrl, url: url, description: description, attribution: attribution, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, frequencyMode: frequencyMode)
        }
    }

    private func insertDictionaryLocked(revision: String, title: String, sequenced: Bool, format: Int, author: String?, isUpdatable: Bool, indexUrl: String?, downloadUrl: String?, url: String?, description: String?, attribution: String?, sourceLanguage: String?, targetLanguage: String?, frequencyMode: String?) -> DictionaryDB? {
        let insertQuery = dictionaries.insert(
            self.title <- title,
            self.revision <- revision,
            self.sequenced <- sequenced,
            self.format <- format,
            self.author <- author,
            self.isUpdatable <- isUpdatable,
            self.indexUrl <- indexUrl,
            self.downloadUrl <- downloadUrl,
            self.url <- url,
            self.description <- description,
            self.attribution <- attribution,
            self.sourceLanguage <- sourceLanguage,
            self.targetLanguage <- targetLanguage,
            self.frequencyMode <- frequencyMode
        )
        do {
            let dicId = try db?.run(insertQuery)
            if let dicId = dicId {
                return DictionaryDB(id: dicId, revision: revision, title: title, sequenced: sequenced, format: format, author: author, isUpdatable: isUpdatable, indexUrl: indexUrl, downloadUrl: downloadUrl, url: url, description: description, attribution: attribution, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, frequencyMode: frequencyMode)
            }
        } catch {
            Logger.database.error("Failed to insert dictionary: \(error.localizedDescription, privacy: .public)")
        }
        
        return nil
    }
    
    /// SQLite rejects a statement carrying more than SQLITE_MAX_VARIABLE_NUMBER bind
    /// parameters — 32766 since 3.32. `insertMany` puts every row into a single statement, so a
    /// large bank has to be split
    private static let maxBindVariables = 32766

    private func insert(into table: Table, setters: [[Setter]], columnsPerRow: Int) -> Int64? {
        guard !setters.isEmpty else { return 0 }

        let chunkSize = max(1, SQLiteManager.maxBindVariables / max(1, columnsPerRow))
        return perform {
            guard let db = db else { return nil }
            var inserted: Int64 = 0
            do {
                try db.transaction {
                    for start in stride(from: 0, to: setters.count, by: chunkSize) {
                        let chunk = Array(setters[start..<min(start + chunkSize, setters.count)])
                        inserted = try db.run(table.insertMany(or: .ignore, chunk))
                    }
                }
                return inserted
            } catch {
                Logger.database.error("Failed to insert rows: \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
    }

    func insertTerms(termsInsert: [TermInsertion]) -> Int64? {
        var setters: [[Setter]] = []
        for term in termsInsert {
            setters.append([
                self.term <- term.term,
                self.reading <- term.reading,
                self.definitionTags <- term.definitionTags,
                self.wordTypes <- term.wordTypes,
                self.score <- term.score,
                self.definitions <- term.definitions,
                self.sequenceNumber <- term.sequence,
                self.termTags <- term.termTags,
                self.dictionaryId <- term.dictionaryId
            ])
        }
        return insert(into: terms, setters: setters, columnsPerRow: 9)
    }
    
    func insertTermMeta(metaInsert: [TermMetaInsertion]) -> Int64? {
        var setters: [[Setter]] = []
        for meta in metaInsert {
            setters.append([
                self.term <- meta.term,
                self.metaReading <- meta.reading,
                self.metaMode <- meta.mode,
                self.metaData <- meta.data,
                self.dictionaryId <- meta.dictionaryId
            ])
        }
        return insert(into: termMeta, setters: setters, columnsPerRow: 5)
    }

    func findTermMeta(texts: [String]) -> [TermMetaDB] {
        guard let reader = reader else {
            return perform { findTermMetaLocked(texts: texts, on: db) }
        }
        return performRead { findTermMetaLocked(texts: texts, on: reader) }
    }

    private func findTermMetaLocked(texts: [String], on connection: Connection?) -> [TermMetaDB] {
        var result: [TermMetaDB] = []
        guard let db = connection else { return result }

        let query = termMeta.filter(texts.contains(self.term))
        let dictionaries = installedDictionaries()
        do {
            for row in try db.prepare(query) {
                guard let dictionary = dictionaries[row[self.dictionaryId]] else {
                    continue
                }
                guard let raw = try? JSONSerialization.jsonObject(with: row[metaData]),
                      let parsed = TermMetaParser.parse(mode: row[metaMode], data: raw) else {
                    continue
                }
                result.append(
                    TermMetaDB(
                        term: row[self.term],
                        reading: parsed.reading,
                        dictionary: dictionary,
                        content: parsed.content
                    )
                )
            }
        } catch {
            Logger.database.error("Term metadata lookup failed: \(error.localizedDescription, privacy: .public)")
        }
        return result
    }

    func markExported(term exported: String, reading exportedReading: String) {
        perform {
            guard let db = db else { return }
            do {
                try db.run(
                    terms.filter(self.term == exported && self.reading == exportedReading)
                        .update(exportedToAnki <- true)
                )
            } catch {
                Logger.database.error("Failed to record an Anki export: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func findTerms(texts: [String]) -> [TermDB] {
        guard let reader = reader else {
            return perform { findTermsLocked(texts: texts, on: db) }
        }
        return performRead { findTermsLocked(texts: texts, on: reader) }
    }

    private func findTermsLocked(texts: [String], on connection: Connection?) -> [TermDB] {
        var result: [TermDB] = []
        
        guard let db = connection else { return result }

        let query = self.terms.filter(
            texts.contains(self.term) ||
            texts.contains(self.reading)
        )
        let dictionaries = installedDictionaries()
        do {
            for row in try db.prepare(query) {
                guard let dictionary = dictionaries[row[self.dictionaryId]] else {
                    continue
                }
                let definitionTags = row[self.definitionTags].components(separatedBy: " ").map{
                    $0.replacingOccurrences(of: "\u{a0}", with: " ")
                }
                let termTags = row[self.termTags].components(separatedBy: " ")
                let wordTypesArray = row[self.wordTypes].components(separatedBy: " ").compactMap({ s in
                    WordType(rawValue: s)
                })
                result.append(
                    TermDB(
                        term: row[self.term],
                        reading: row[self.reading],
                        definitionTags: definitionTags,
                        wordTypes: wordTypesArray,
                        score: row[self.score],
                        definitions: row[definitions],
                        sequenceNumber: row[sequenceNumber],
                        termTags: termTags,
                        dictionary: dictionary,
                        exportedToAnki: row[self.exportedToAnki]
                    )
                )
            }
        } catch {
            Logger.database.error("Term lookup failed: \(error.localizedDescription, privacy: .public)")
        }
        
        return result
    }
}

public struct TermMetaInsertion {
    let term: String
    let reading: String
    let mode: String
    let data: Data
    let dictionaryId: Int64
}

public struct TermInsertion {
    let term : String
    let reading : String
    let definitionTags: String
    let wordTypes :String
    let score : Int64
    let definitions: Data
    let sequence : Int64
    let termTags : String
    let dictionaryId: Int64
}
