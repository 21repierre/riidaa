//
//  CoreDataManager.swift
//  redaa
//
//  Created by Pierre on 2025/02/13.
//

import CoreData

class CoreDataManager: ObservableObject {
    
//    static let shared = CoreDataManager()
    private static var runningInstance = CoreDataManager()
    
    static var shared: CoreDataManager {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"{
            return CoreDataManager.preview
        }else{
            return CoreDataManager.runningInstance
        }
    }
    let container = NSPersistentContainer(name: "CoreModel")
    
    private init(inMemory: Bool = false) {
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Redaa Core Data failed to load: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    static let preview: CoreDataManager = {
        let controller = CoreDataManager(inMemory: true)
        let context = controller.container.viewContext
        
//        let m1 = MangaModel(context: context)
//        m1.title = "This is a really long title for a manga"
//        m1.id = 1
//        let entity = NSEntityDescription.entity(forEntityName: "MangaModel", in: context)!
//        let manga = NSManagedObject(entity: entity, insertInto: context)
//        
//        manga.setValue("This is a really long title for a manga", forKey: "title")
//        manga.setValue(1, forKey: "id")
        
//        do {
//                try context.save()
//            } catch {
//                print("Failed to save preview context:", error)
//            }
        return controller
    }()
    
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
