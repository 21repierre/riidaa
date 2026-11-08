//
//  CoreDataManager.swift
//  riidaa
//
//  Created by Pierre on 2025/02/13.
//

import CoreData
import GameplayKit
import os

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

    private(set) var loadError: Error?
    @Published var saveError: String?
    
    private init(inMemory: Bool = false) {
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            if !inMemory, let url = description.url {
                do {
                    try CoreDataManager.migrateFromV1IfNeeded(storeURL: url)
                } catch {
                    loadError = error
                    return
                }
            }
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                self.loadError = error
            }
        }
        if !inMemory && loadError == nil {
            MangaStorage.removeOrphans(in: newBackgroundContext())
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
            Logger.database.error("Failed to save: \(error.localizedDescription, privacy: .public)")
            context.rollback()
            saveError = error.localizedDescription
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = self.container.newBackgroundContext()
        // A rename or cover change during an import must not fail every remaining volume.
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func delete(_ object: NSManagedObject, removing directories: [URL]) {
        let id = object.objectID
        let context = newBackgroundContext()
        context.perform {
            context.delete(context.object(with: id))
            do {
                try context.save()
                MangaStorage.removeFiles(at: directories)
            } catch {
                Logger.database.error("Failed to delete: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async {
                    self.saveError = error.localizedDescription
                }
            }
        }
    }

    static func migrateFromV1IfNeeded(storeURL: URL, bundle: Bundle = .main) throws {
        guard FileManager.default.fileExists(atPath: storeURL.path),
              let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType, at: storeURL
              ),
              let models = bundle.url(forResource: "CoreModel", withExtension: "momd"),
              let v1 = NSManagedObjectModel(contentsOf: models.appendingPathComponent("CoreModel.mom")),
              let v2 = NSManagedObjectModel(contentsOf: models.appendingPathComponent("CoreModelV2.mom")),
              v1.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata),
              let mapping = NSMappingModel(from: [bundle], forSourceModel: v1, destinationModel: v2)
        else {
            return
        }

        let migrated = storeURL.deletingLastPathComponent().appendingPathComponent("CoreModel-v1-migration.sqlite")
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: v2)
        try? coordinator.destroyPersistentStore(at: migrated, ofType: NSSQLiteStoreType)
        try NSMigrationManager(sourceModel: v1, destinationModel: v2).migrateStore(
            from: storeURL, sourceType: NSSQLiteStoreType, options: nil, with: mapping,
            toDestinationURL: migrated, destinationType: NSSQLiteStoreType, destinationOptions: nil
        )
        try coordinator.replacePersistentStore(
            at: storeURL, destinationOptions: nil, withPersistentStoreFrom: migrated,
            sourceOptions: nil, ofType: NSSQLiteStoreType
        )
        try? coordinator.destroyPersistentStore(at: migrated, ofType: NSSQLiteStoreType)
    }
}
