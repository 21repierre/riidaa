//
//  Dictionary+CoreDataClass.swift
//  riidaa
//
//  Created by Pierre on 2025/03/08.
//
//

import Foundation
import os

public enum UpdateState: Codable {
    case unknown
    case upToDate
    case updateAvailable
    case checkFailed
    case notUpdatable
}

class DictionaryDB: Hashable, ObservableObject, Identifiable {
    static func == (lhs: DictionaryDB, rhs: DictionaryDB) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    init(id: Int64, revision: String, title: String, sequenced: Bool, format: Int, author: String?, isUpdatable: Bool, indexUrl: String?, downloadUrl: String?, url: String?, description: String?, attribution: String?, sourceLanguage: String?, targetLanguage: String?, frequencyMode: String?) {
        self.id = id
        self.revision = revision
        self.title = title
        self.sequenced = sequenced
        self.format = format
        self.author = author
        self.isUpdatable = isUpdatable
        self.indexUrl = indexUrl
        self.downloadUrl = downloadUrl
        self.url = url
        self.description = description
        self.attribution = attribution
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.frequencyMode = frequencyMode
    }
    
    init(id: Int64, revision: String, title: String, format: Int) {
        self.id = id
        self.revision = revision
        self.title = title
        self.format = format
    }
    
    let id: Int64
    var revision: String
    var title: String
    var sequenced: Bool = false
    var format: Int
    var author: String? = nil
    var isUpdatable: Bool = false
    var indexUrl: String? = nil
    var downloadUrl: String? = nil
    var url: String? = nil
    var description: String? = nil
    var attribution: String? = nil
    var sourceLanguage: String? = nil
    var targetLanguage: String? = nil
    var frequencyMode: String? = nil
    
    @Published var hasUpdate: UpdateState = .unknown
}

extension DictionaryDB {
    
    @MainActor
    func fetchUpdate() async {
        guard isUpdatable, let indexUrl = self.indexUrl, let url = URL(string: indexUrl) else {
            hasUpdate = .notUpdatable
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            let json = try JSONDecoder().decode(DictionaryJson.self, from: data)
            hasUpdate = DictionaryDB.isNewer(json.revision, than: revision) ? .updateAvailable : .upToDate
        } catch {
            Logger.dictionary.error("Failed to fetch update: \(error.localizedDescription, privacy: .public)")
            hasUpdate = .checkFailed
        }
    }

    static func isNewer(_ candidate: String, than current: String) -> Bool {
        candidate.compare(current, options: .numeric) == .orderedDescending
    }
    
}

struct DictionaryJson: Codable {
    let revision: String
}
