//
//  AppManager.swift
//  redaa
//
//  Created by Pierre on 2025/02/28.
//

import Foundation
import CoreData

class AppManager : ObservableObject {
    
    @Published var isLoading = true
    @Published var dictionaries: [Dictionary] = []
    
    init() {
        DispatchQueue.main.async {
            self.loadDictionaries()
        }
    }
    
    func loadDictionaries() {
        self.isLoading = true
        let request: NSFetchRequest<Dictionary> = Dictionary.fetchRequest()
        
        self.dictionaries = try! CoreDataManager.shared.context.fetch(request)
        
        for dictionary in dictionaries {
            print("dic \(dictionary.terms.count)")
        }
        
        self.isLoading = false
    }
    
}
