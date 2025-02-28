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
            let request: NSFetchRequest<Dictionary> = Dictionary.fetchRequest()
            
            self.dictionaries = try! CoreDataManager.shared.context.fetch(request)
            
            for dic in self.dictionaries {
                try? dic.loadDictionary()
            }
            
            self.isLoading = false
        }
    }
    
}
