//
//  AppManager.swift
//  redaa
//
//  Created by Pierre on 2025/02/28.
//

import Foundation
import CoreData

class AppManager : ObservableObject {
    
    static let shared = AppManager()
    
    @Published var isLoading = true
    @Published var dictionaries: [DictionaryDB] = []
    
    private init() {
        DispatchQueue.main.async {
            self.loadDictionaries()
        }
    }
    
    func loadDictionaries() {
        self.isLoading = true
        
        do {
            for row in try SQLiteManager.shared.getDatabase()!.prepare(SQLiteManager.shared.dictionaries) {
                dictionaries.append(DictionaryDB(
                    id: row[SQLiteManager.shared.id],
                    revision: row[SQLiteManager.shared.revision],
                    title: row[SQLiteManager.shared.title],
                    sequenced: row[SQLiteManager.shared.sequenced],
                    format: row[SQLiteManager.shared.format],
                    author: row[SQLiteManager.shared.author],
                    isUpdatable: row[SQLiteManager.shared.isUpdatable],
                    indexUrl: row[SQLiteManager.shared.indexUrl],
                    downloadUrl: row[SQLiteManager.shared.downloadUrl],
                    url: row[SQLiteManager.shared.url],
                    description: row[SQLiteManager.shared.description],
                    attribution: row[SQLiteManager.shared.attribution],
                    sourceLanguage: row[SQLiteManager.shared.sourceLanguage],
                    targetLanguage: row[SQLiteManager.shared.targetLanguage],
                    frequencyMode: row[SQLiteManager.shared.frequencyMode]
                ))
            }
//            for row in try SQLiteManager.shared.getDatabase()!.prepare(SQLiteManager.shared.terms) {
//                readings.append(row[SQLiteManager.shared.reading])
//            }
        } catch {
            
        }
        
        self.isLoading = false
    }
    
}
