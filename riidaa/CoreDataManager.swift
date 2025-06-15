//
//  CoreDataManager.swift
//  riidaa
//
//  Created by Pierre on 2025/02/13.
//

import CoreData

class CoreDataManager: ObservableObject {
    
    private static var runningInstance = CoreDataManager()
    
    static var shared: CoreDataManager {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"{
            return CoreDataManager.preview
        } else{
            return CoreDataManager.runningInstance
        }
    }
    let container = NSPersistentContainer(name: "CoreModel")
    
    private init(inMemory: Bool = false) {
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = false
        }

        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("リーダー Core Data failed to load: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    private static let preview: CoreDataManager = {
        let controller = CoreDataManager(inMemory: true)
        let context = controller.container.viewContext
        
        return controller
    }()
    
    func saveContext() {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Failed to save リーダー Core Data:", error)
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = self.container.newBackgroundContext()
        return context
    }
}
