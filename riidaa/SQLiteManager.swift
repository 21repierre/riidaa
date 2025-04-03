//
//  SQLiteManager.swift
//  riidaa
//
//  Created by Pierre on 2025/04/03.
//

import Foundation
import SQLite
typealias Expression = SQLite.Expression

class SQLiteManager {
    static let shared = SQLiteManager()
    private var db: Connection?

    // Table Definitions
    let dictionaries = Table("dictionaries")
    let terms = Table("terms")

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

    private init() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/dictionaries.sqlite3")

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
                t.foreignKey(dictionaryId, references: dictionaries, id, delete: .cascade)
                t.primaryKey(term, reading, definitions, dictionaryId)
            })
            try db?.run(terms.createIndex(term, ifNotExists: true))
            try db?.run(terms.createIndex(reading, ifNotExists: true))
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    func getDatabase() -> Connection? {
        return db
    }
    
    func deleteDictionary(dictionaryId: Int64) throws {
        let terms = terms.filter(self.dictionaryId == dictionaryId)
        try db!.run(terms.delete())
        let dics = dictionaries.filter(id == dictionaryId)
        try db!.run(dics.delete())
    }
    
    func insertDictionary(revision: String, title: String, sequenced: Bool, format: Int, author: String?, isUpdatable: Bool, indexUrl: String?, downloadUrl: String?, url: String?, description: String?, attribution: String?, sourceLanguage: String?, targetLanguage: String?, frequencyMode: String?) -> DictionaryDB? {
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
            print("error: \(error)")
        }
        
        return nil
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
        let insertQuery = terms.insertMany(or: .ignore, setters)
        do {
            return try db?.run(insertQuery)
        } catch {
            print("error: \(error)")
        }
        return nil
    }
    
    func findTerms(texts: [String]) -> [TermDB] {
        var result: [TermDB] = []
        
        let query = self.terms.filter(
            texts.contains(self.term) ||
            texts.contains(self.reading)
        )
        do {
            for row in try db!.prepare(query) {
                let definitionTags = row[self.definitionTags].components(separatedBy: " ")
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
                        dictionary: AppManager.shared.dictionaries.first(where: { dic in
                            dic.id == row[self.dictionaryId]
                        })!
                    )
                )
            }
        } catch {
            print("error: \(error)")
        }
        
        return result
    }
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
