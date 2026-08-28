//
//  AppManager.swift
//  riidaa
//
//  Created by Pierre on 2025/02/28.
//

import Foundation
import os
import CoreData

class AppManager : ObservableObject {
    
    static let shared = AppManager()
    
    @Published var isLoading = true
    @Published var dictionaries: [DictionaryDB] = [] {
        didSet { SQLiteManager.shared.setInstalledDictionaries(dictionaries) }
    }

    @Published var deleting: Set<Int64> = []
    @Published var purging: PurgeProgress? = nil

    @Published var working: [Int64: DictionaryProgress] = [:]
    @Published var preparing: DictionaryProgress? = nil
    @Published var lastError: String? = nil
    
    func deleteDictionary(id: Int64) {
        guard !deleting.contains(id) else { return }
        deleting.insert(id)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try SQLiteManager.shared.deleteDictionary(dictionaryId: id)
            } catch {
                Logger.dictionary.error("Failed to delete dictionary: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async { self.deleting.remove(id) }
                self.report(error: "Could not delete this dictionary: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.dictionaries.removeAll { $0.id == id }
                self.deleting.remove(id)
            }
            self.purgeOrphanedEntries()
        }
    }

    func purgeOrphanedEntries() {
        purgeQueue.async {
            SQLiteManager.shared.purgeOrphanedEntries(progress: { cleared, total in
                let update = PurgeProgress(cleared: cleared, total: total)
                DispatchQueue.main.async {
                    self.purging = update.isFinished ? nil : update
                }
            })
            DispatchQueue.main.async { self.purging = nil }
        }
    }

    private let purgeQueue = DispatchQueue(label: "dev.repierre.riidaa.purge", qos: .utility)

    func waitForPendingPurge() {
        purgeQueue.sync {}
    }

    func setProgress(_ progress: DictionaryProgress?, for id: Int64?) {
        DispatchQueue.main.async {
            guard let id = id else {
                self.preparing = progress
                return
            }
            self.preparing = nil
            if let progress = progress {
                self.working[id] = progress
            } else {
                self.working.removeValue(forKey: id)
            }
        }
    }

    func report(error: String?) {
        DispatchQueue.main.async {
            if let error = error, let existing = self.lastError, !existing.contains(error) {
                self.lastError = existing + "\n\n" + error
            } else {
                self.lastError = error
            }
            self.preparing = nil
        }
    }
    
    private init() {
        loadDictionaries()
        discardExtractedDictionaries()
        purgeOrphanedEntries()
    }

    /// Removes leftover extractions
    private func discardExtractedDictionaries() {
        let fileManager = FileManager.default
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let root = documents.appendingPathComponent("dictionaries")

        guard let leftovers = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil),
              !leftovers.isEmpty else {
            return
        }

        DispatchQueue.global(qos: .utility).async {
            for leftover in leftovers {
                try? fileManager.removeItem(at: leftover)
            }
        }
    }

    func loadDictionaries() {
        DispatchQueue.main.async { self.isLoading = true }

        DispatchQueue.global(qos: .userInitiated).async {
            let loaded = SQLiteManager.shared.allDictionaries()
            DispatchQueue.main.async {
                self.dictionaries = loaded
                self.isLoading = false
            }
        }
    }
    
}

struct PurgeProgress: Equatable {
    let cleared: Int
    let total: Int

    var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(cleared) / Double(total))
    }

    var isFinished: Bool { cleared >= total }
}
