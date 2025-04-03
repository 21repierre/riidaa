//
//  Dictionary+CoreDataClass.swift
//  redaa
//
//  Created by Pierre on 2025/03/08.
//
//

import Foundation
import CoreData
import ZIPFoundation

public enum UpdateState: Codable {
    case unkown, upToDate, updateAvailable
}

public class Dictionary: NSManagedObject {
    @Published public private(set) var hasUpdate: UpdateState = .unkown

    
    @MainActor
    public func update(targetDir: URL, progress: Progress? = nil) async throws {
        guard hasUpdate == .updateAvailable,
              let downloadUrl = self.downloadUrl,
              let url = URL(string: downloadUrl) else {
            return
        }
        
        do {
            // TODO: rewrite
//            let (content, _) = try await URLSession.shared.data(from: url)
//            let archive = try Archive(data: content, accessMode: .read)
//            
//            var totalUnitCount = Int64(0)
//            if let progress = progress {
//                totalUnitCount = archive.reduce(0, { $0 + archive.totalUnitCountForReading($1) })
//                progress.totalUnitCount = totalUnitCount
//            }
//            
//            let fileManager = FileManager.default
//            let targetContent = try fileManager.contentsOfDirectory(at: targetDir, includingPropertiesForKeys: [])
//            for item in targetContent {
//                try fileManager.removeItem(at: item.standardized)
//            }
//            
//            for item in archive {
//                let extractPath = targetDir.appendingPathComponent(item.path)
//                guard extractPath.isContained(in: targetDir) else {
//                    throw "path traversal error"
//                }
//                let crc32: CRC32
//                if let progress = progress {
//                    let entryProgress = Progress(totalUnitCount: archive.totalUnitCountForReading(item))
//                    progress.addChild(entryProgress, withPendingUnitCount: entryProgress.totalUnitCount)
//                    crc32 = try archive.extract(item, to: extractPath, skipCRC32: false, progress: entryProgress)
//                } else {
//                    crc32 = try archive.extract(item, to: extractPath, skipCRC32: false)
//                }
//                guard crc32 == item.checksum else {
//                    throw "invalid checksum for file \(item.path)"
//                }
//            }
//            
//            await MainActor.run {
//                self.hasUpdate = .upToDate
//            }
        } catch {
            print("failed to update dictionary:", error)
            throw error
        }
    }
    
    @MainActor
    public func fetchUpdate() async {
        guard let indexUrl = self.indexUrl,
              let url = URL(string: indexUrl) else {
            return
        }
        
        do {
            //TODO: rewrite
//            let (data, _) = try await URLSession.shared.data(from: url)
//            let json = try JSONDecoder().decode(DictionaryJson.self, from: data)
//            
//            let currentRevSplit = self.dictionary.revision.split(separator: ".")
//            let newRevSplit = json.revision.split(separator: ".")
//            
//            if currentRevSplit.count != newRevSplit.count { return }
//            
//            for i in 0..<currentRevSplit.count {
//                guard let currentI = Int(currentRevSplit[i]),
//                      let newI = Int(newRevSplit[i]) else { return }
//                
//                if newI > currentI {
//                    await MainActor.run {
//                        self.hasUpdate = .updateAvailable
//                    }
//                    return
//                }
//            }
//            
//            await MainActor.run {
//                self.hasUpdate = .upToDate
//            }
        } catch {
            print("failed to fetch update:", error)
        }
    }
    
}
