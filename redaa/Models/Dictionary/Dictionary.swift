//
//  Dictionary+CoreDataClass.swift
//  redaa
//
//  Created by Pierre on 2025/03/08.
//
//

import Foundation
import ZIPFoundation

public enum UpdateState: Codable {
    case unknown, upToDate, updateAvailable
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
    
    // Observable property
    var hasUpdate: UpdateState = .unknown
}

extension DictionaryDB {
    
    func fetchUpdate() async {
        guard let indexUrl = self.indexUrl, let url = URL(string: indexUrl) else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONDecoder().decode(DictionaryJson.self, from: data)
            
            let currentRevSplit = self.revision.split(separator: ".")
            let newRevSplit = json.revision.split(separator: ".")
            
            if currentRevSplit.count != newRevSplit.count { return }
            
            for i in 0..<currentRevSplit.count {
                guard let currentI = Int(currentRevSplit[i]),
                      let newI = Int(newRevSplit[i]) else { return }
                
                if newI > currentI {
                    self.hasUpdate = .updateAvailable
                    return
                }
            }
            
            self.hasUpdate = .upToDate
        } catch {
            print("Failed to fetch update:", error)
        }
    }
    
    func update(targetDir: URL, progress: Progress? = nil) async throws {
        guard hasUpdate == .updateAvailable,
              let downloadUrl = self.downloadUrl,
              let url = URL(string: downloadUrl) else {
            return
        }
        
        do {
            let (content, _) = try await URLSession.shared.data(from: url)
            let archive = try Archive(data: content, accessMode: .read)
            
            var totalUnitCount = Int64(0)
            if let progress = progress {
                totalUnitCount = archive.reduce(0, { $0 + archive.totalUnitCountForReading($1) })
                progress.totalUnitCount = totalUnitCount
            }
            
            let fileManager = FileManager.default
            let targetContent = try fileManager.contentsOfDirectory(at: targetDir, includingPropertiesForKeys: [])
            for item in targetContent {
                try fileManager.removeItem(at: item.standardized)
            }
            
            for item in archive {
                let extractPath = targetDir.appendingPathComponent(item.path)
                guard extractPath.isContained(in: targetDir) else {
                    throw NSError(domain: "DictionaryImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error extracting dictionary"])
                }
                
                let crc32: CRC32
                if let progress = progress {
                    let entryProgress = Progress(totalUnitCount: archive.totalUnitCountForReading(item))
                    progress.addChild(entryProgress, withPendingUnitCount: entryProgress.totalUnitCount)
                    crc32 = try archive.extract(item, to: extractPath, skipCRC32: false, progress: entryProgress)
                } else {
                    crc32 = try archive.extract(item, to: extractPath, skipCRC32: false)
                }
                
                guard crc32 == item.checksum else {
                    throw NSError(domain: "DictionaryImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid checksum for file \(item.path)"])
                }
            }
            
            // Mark dictionary as up-to-date
            self.hasUpdate = .upToDate
            
        } catch {
            print("Failed to update dictionary:", error)
            throw error
        }
    }
    
}

struct DictionaryJson: Codable {
    let revision: String
}


//public class Dictionary: NSManagedObject {
//    @Published public private(set) var hasUpdate: UpdateState = .unkown
//
//
//    @MainActor
//    public func update(targetDir: URL, progress: Progress? = nil) async throws {
//        guard hasUpdate == .updateAvailable,
//              let downloadUrl = self.downloadUrl,
//              let url = URL(string: downloadUrl) else {
//            return
//        }
//
//        do {
//            // TODO: rewrite
////            let (content, _) = try await URLSession.shared.data(from: url)
////            let archive = try Archive(data: content, accessMode: .read)
////
////            var totalUnitCount = Int64(0)
////            if let progress = progress {
////                totalUnitCount = archive.reduce(0, { $0 + archive.totalUnitCountForReading($1) })
////                progress.totalUnitCount = totalUnitCount
////            }
////
////            let fileManager = FileManager.default
////            let targetContent = try fileManager.contentsOfDirectory(at: targetDir, includingPropertiesForKeys: [])
////            for item in targetContent {
////                try fileManager.removeItem(at: item.standardized)
////            }
////
////            for item in archive {
////                let extractPath = targetDir.appendingPathComponent(item.path)
////                guard extractPath.isContained(in: targetDir) else {
////                    throw "path traversal error"
////                }
////                let crc32: CRC32
////                if let progress = progress {
////                    let entryProgress = Progress(totalUnitCount: archive.totalUnitCountForReading(item))
////                    progress.addChild(entryProgress, withPendingUnitCount: entryProgress.totalUnitCount)
////                    crc32 = try archive.extract(item, to: extractPath, skipCRC32: false, progress: entryProgress)
////                } else {
////                    crc32 = try archive.extract(item, to: extractPath, skipCRC32: false)
////                }
////                guard crc32 == item.checksum else {
////                    throw "invalid checksum for file \(item.path)"
////                }
////            }
////
////            await MainActor.run {
////                self.hasUpdate = .upToDate
////            }
//        } catch {
//            print("failed to update dictionary:", error)
//            throw error
//        }
//    }
//
//    @MainActor
//    public func fetchUpdate() async {
//        guard let indexUrl = self.indexUrl,
//              let url = URL(string: indexUrl) else {
//            return
//        }
//
//        do {
//            //TODO: rewrite
////            let (data, _) = try await URLSession.shared.data(from: url)
////            let json = try JSONDecoder().decode(DictionaryJson.self, from: data)
////
////            let currentRevSplit = self.dictionary.revision.split(separator: ".")
////            let newRevSplit = json.revision.split(separator: ".")
////
////            if currentRevSplit.count != newRevSplit.count { return }
////
////            for i in 0..<currentRevSplit.count {
////                guard let currentI = Int(currentRevSplit[i]),
////                      let newI = Int(newRevSplit[i]) else { return }
////
////                if newI > currentI {
////                    await MainActor.run {
////                        self.hasUpdate = .updateAvailable
////                    }
////                    return
////                }
////            }
////
////            await MainActor.run {
////                self.hasUpdate = .upToDate
////            }
//        } catch {
//            print("failed to fetch update:", error)
//        }
//    }
//
//}
