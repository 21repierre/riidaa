//
//  DictionaryImporter.swift
//  riidaa
//

import Foundation
import os
import ZIPFoundation

enum DictionaryImportError: LocalizedError {
    case permissionDenied
    case missingIndex
    case malformedIndex
    case missingProperties
    case alreadyInstalled(String)
    case emptyArchive
    case decoding(String)
    case saving(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied"
        case .missingIndex:
            return "Could not find dictionary index.json"
        case .malformedIndex:
            return "Invalid file format"
        case .missingProperties:
            return "Missing mandatory properties"
        case .alreadyInstalled(let message):
            return message
        case .emptyArchive:
            return "This dictionary contains no term or metadata banks."
        case .decoding(let what):
            return "Error decoding \(what)"
        case .saving(let what):
            return "Error saving \(what)"
        }
    }
}

struct DictionaryIndex {

    let revision: String
    let title: String
    let sequenced: Bool
    let format: Int
    let author: String?
    let isUpdatable: Bool
    let indexUrl: String?
    let downloadUrl: String?
    let url: String?
    let description: String?
    let attribution: String?
    let sourceLanguage: String?
    let targetLanguage: String?
    let frequencyMode: String?

    init(json: Any) throws {
        guard let json = json as? [String: Any] else {
            throw DictionaryImportError.malformedIndex
        }
        guard let revision = json["revision"] as? String, let title = json["title"] as? String else {
            throw DictionaryImportError.missingProperties
        }
        self.revision = revision
        self.title = title
        self.sequenced = json["sequenced"] as? Bool ?? false
        self.format = json["format"] as? Int ?? 3
        self.author = json["author"] as? String
        self.isUpdatable = json["isUpdatable"] as? Bool ?? false
        self.indexUrl = json["indexUrl"] as? String
        self.downloadUrl = json["downloadUrl"] as? String
        self.url = json["url"] as? String
        self.description = json["description"] as? String
        self.attribution = json["attribution"] as? String
        self.sourceLanguage = json["sourceLanguage"] as? String
        self.targetLanguage = json["targetLanguage"] as? String
        self.frequencyMode = json["frequencyMode"] as? String
    }

    /// Matched on `indexUrl` where a dictionary publishes one, on the title otherwise.
    func installedCopy(among dictionaries: [DictionaryDB], ignoring replacing: Int64?) -> DictionaryDB? {
        dictionaries.first { existing in
            if existing.id == replacing { return false }
            if let indexUrl = indexUrl, let other = existing.indexUrl, !indexUrl.isEmpty {
                return other == indexUrl
            }
            return existing.title == title
        }
    }

}

enum DictionaryBank {

    static func terms(from json: Any, dictionaryId: Int64) throws -> [TermInsertion] {
        guard let rows = json as? [[Any]] else {
            throw DictionaryImportError.decoding("terms")
        }
        return rows.compactMap { row in
            guard row.count >= 8,
                  let term = row[0] as? String,
                  let reading = row[1] as? String,
                  let wordTypes = row[3] as? String,
                  let score = row[4] as? Int64,
                  let definitions = row[5] as? [Any],
                  let sequence = row[6] as? Int64,
                  let termTags = row[7] as? String,
                  let definitionsEncoded = try? JSONSerialization.data(withJSONObject: definitions)
            else {
                return nil
            }
            return TermInsertion(
                term: term, reading: reading, definitionTags: row[2] as? String ?? "",
                wordTypes: wordTypes, score: score, definitions: definitionsEncoded,
                sequence: sequence, termTags: termTags, dictionaryId: dictionaryId
            )
        }
    }

    static func meta(from json: Any, dictionaryId: Int64) throws -> [TermMetaInsertion] {
        guard let rows = json as? [[Any]] else {
            throw DictionaryImportError.decoding("term metadata")
        }
        return rows.compactMap { row in
            guard row.count >= 3,
                  let term = row[0] as? String,
                  let mode = row[1] as? String,
                  let parsed = TermMetaParser.parse(mode: mode, data: row[2]),
                  let dataEncoded = try? JSONSerialization.data(withJSONObject: row[2], options: [.fragmentsAllowed])
            else {
                return nil
            }
            return TermMetaInsertion(
                term: term, reading: parsed.reading, mode: mode,
                data: dataEncoded, dictionaryId: dictionaryId
            )
        }
    }

}

/// Progress is reported through `AppManager` so it outlives the screen that started it.
final class DictionaryImporter {

    private let appManager: AppManager

    init(appManager: AppManager) {
        self.appManager = appManager
    }

    /// Serial: two imports at once would fight over the same tables for no gain.
    private static let queue = DispatchQueue(label: "dev.repierre.riidaa.import", qos: .userInitiated)

    func importArchives(at paths: [URL]) {
        for path in paths {
            importArchive(at: path)
        }
    }

    func importArchive(at path: URL, securityScoped: Bool = true, replacing: Int64? = nil) {
        DictionaryImporter.queue.async { [appManager] in
            let installedSnapshot = DispatchQueue.main.sync { appManager.dictionaries }
            let fileManager = FileManager.default
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("dictionaries")
            let dicDirectory = documents.appendingPathComponent(UUID().uuidString)

            var done = 0
            var total = 0
            var reportingId: Int64? = replacing
            var stranded: String? = nil
            func report(_ message: String) {
                appManager.setProgress(
                    DictionaryProgress(message: message, value: done, total: total),
                    for: reportingId
                )
            }
            defer {
                try? fileManager.removeItem(at: dicDirectory)
                if !securityScoped {
                    try? fileManager.removeItem(at: path)
                }
            }

            do {
                let scoped = securityScoped && path.startAccessingSecurityScopedResource()
                if securityScoped && !scoped {
                    throw DictionaryImportError.permissionDenied
                }
                defer {
                    if scoped {
                        path.stopAccessingSecurityScopedResource()
                    }
                }

                report("Unpacking…")
                try fileManager.createDirectory(at: dicDirectory, withIntermediateDirectories: true)
                try fileManager.unzipItem(at: path, to: dicDirectory)

                total = try fileManager.contentsOfDirectory(at: dicDirectory, includingPropertiesForKeys: nil).count
                report("Processing dictionary…")

                guard let indexData = try? Data(contentsOf: dicDirectory.appendingPathComponent("index.json")) else {
                    throw DictionaryImportError.missingIndex
                }
                let index = try DictionaryIndex(json: try JSONSerialization.jsonObject(with: indexData))

                if let existing = index.installedCopy(among: installedSnapshot, ignoring: replacing) {
                    let action = replacing == nil
                        ? "Use Update on it instead, or delete it first."
                        : "Delete one of them first."
                    throw DictionaryImportError.alreadyInstalled(
                        existing.revision == index.revision
                            ? "\(existing.title) is already installed."
                            : "\(existing.title) is already installed (revision \(existing.revision)). \(action)"
                    )
                }

                var installed: DictionaryDB? = nil
                defer {
                    if let installed = installed {
                        do {
                            try SQLiteManager.shared.deleteDictionary(dictionaryId: installed.id)
                            DispatchQueue.main.async {
                                appManager.dictionaries.removeAll { $0.id == installed.id }
                            }
                            appManager.purgeOrphanedEntries()
                        } catch {
                            Logger.dictionary.error("Failed to roll back a partial import: \(error.localizedDescription, privacy: .public)")
                            stranded = index.title
                        }
                    }
                }

                guard let dictionary = SQLiteManager.shared.insertDictionary(
                    revision: index.revision, title: index.title, sequenced: index.sequenced,
                    format: index.format, author: index.author, isUpdatable: index.isUpdatable,
                    indexUrl: index.indexUrl, downloadUrl: index.downloadUrl, url: index.url,
                    description: index.description, attribution: index.attribution,
                    sourceLanguage: index.sourceLanguage, targetLanguage: index.targetLanguage,
                    frequencyMode: index.frequencyMode
                ) else {
                    throw DictionaryImportError.saving("dictionary")
                }
                installed = dictionary
                if replacing == nil {
                    reportingId = dictionary.id
                    DispatchQueue.main.async { appManager.dictionaries.append(dictionary) }
                }
                done += 1
                report("Importing…")

                var importedTerms = 0
                var importedMeta = 0

                var i = 1
                while let bank = try? Data(contentsOf: dicDirectory.appending(component: "term_bank_\(i).json")) {
                    try autoreleasepool {
                        let rows = try DictionaryBank.terms(
                            from: try JSONSerialization.jsonObject(with: bank), dictionaryId: dictionary.id
                        )
                        guard SQLiteManager.shared.insertTerms(termsInsert: rows) != nil else {
                            throw DictionaryImportError.saving("terms")
                        }
                        importedTerms += rows.count
                        i += 1
                        done += 1
                        report("Processing dictionary…")
                    }
                }

                // Pitch and frequency dictionaries ship no term_bank files at all.
                var m = 1
                while let bank = try? Data(contentsOf: dicDirectory.appending(component: "term_meta_bank_\(m).json")) {
                    try autoreleasepool {
                        let rows = try DictionaryBank.meta(
                            from: try JSONSerialization.jsonObject(with: bank), dictionaryId: dictionary.id
                        )
                        guard SQLiteManager.shared.insertTermMeta(metaInsert: rows) != nil else {
                            throw DictionaryImportError.saving("term metadata")
                        }
                        importedMeta += rows.count
                        m += 1
                        done += 1
                        report("Processing dictionary…")
                    }
                }

                if i == 1 && m == 1 {
                    throw DictionaryImportError.emptyArchive
                }

                // Removed only once the replacement is safely in, so a failed update can't
                // leave the user with nothing.
                if let replacing = replacing {
                    try SQLiteManager.shared.deleteDictionary(dictionaryId: replacing)
                }

                DispatchQueue.main.async {
                    if let replacing = replacing {
                        appManager.dictionaries.removeAll { $0.id == replacing }
                        appManager.dictionaries.append(dictionary)
                    }
                    appManager.setProgress(nil, for: dictionary.id)
                    appManager.setProgress(nil, for: replacing)
                }
                installed = nil
                Logger.dictionary.info("Imported \(index.title): \(importedTerms) entries, \(importedMeta) pitch/frequency entries")
                appManager.purgeOrphanedEntries()
            } catch {
                appManager.setProgress(nil, for: reportingId)
                if let stranded = stranded {
                    appManager.report(error: "\(error.localizedDescription)\n\n\(stranded) was only partly imported and could not be removed automatically. Delete it under Dictionaries.")
                } else {
                    appManager.report(error: error.localizedDescription)
                }
            }
        }
    }

}
