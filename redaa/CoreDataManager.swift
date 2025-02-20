//
//  CoreDataManager.swift
//  redaa
//
//  Created by Pierre on 2025/02/13.
//

import CoreData

class CoreDataManager: ObservableObject {
    
    static let shared = CoreDataManager()
    let container = NSPersistentContainer(name: "CoreModel")
    
    private init() {
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Redaa Core Data failed to load: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    func saveContext() {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Failed to save Redaa Core Data:", error)
        }
    }
}
