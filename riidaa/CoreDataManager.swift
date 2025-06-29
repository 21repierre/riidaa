//
//  CoreDataManager.swift
//  riidaa
//
//  Created by Pierre on 2025/02/13.
//

import CoreData
import GameplayKit

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
//            description.shouldInferMappingModelAutomatically = false
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
        
        initFakeData(context)
        
        return controller
    }()
    
    static func initFakeData(_ context: NSManagedObjectContext) {
        let manga = MangaModel(context: context)
        manga.id = UUID()
        manga.title = "manga-\(manga.id.uuidString)"
        
        for _ in 0...Int.random(in: 1..<10) {
            let volume = MangaVolumeModel(context: context)
            
            let page_read = Int.random(in: 0..<100)
            let page_read_s = 1750852800
            let random = GKRandomSource()
            let page_read_gen = GKGaussianDistribution(randomSource: random, lowestValue: -3600 * 24 * 7, highestValue: 3600 * 24 * 7)
            
            for j in 0...Int.random(in: max(30, page_read)..<100) {
                
                let page = MangaPageModel(context: context)
                page.height = 100
                page.width = 100
                page.number = Int64(j)
                if j < page_read {
                    page.read_at = NSDate(timeIntervalSince1970: TimeInterval(page_read_s + page_read_gen.nextInt()))
                }
                volume.insertIntoPages(page, at: j)
            }
            
            manga.addToVolumes(volume)
        }
        
        
        try? context.save()
    }
    
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
