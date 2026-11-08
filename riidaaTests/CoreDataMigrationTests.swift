//
//  CoreDataMigrationTests.swift
//  riidaaTests
//

import CoreData
import Foundation
import Testing
@testable import riidaa

struct CoreDataMigrationTests {

    /// A copy whose entities use plain NSManagedObject, so it doesn't compete with the app's own
    /// model for MangaModel and friends while other tests run alongside.
    private func classless(_ model: NSManagedObjectModel) -> NSManagedObjectModel {
        let copy = model.copy() as! NSManagedObjectModel
        for entity in copy.entities {
            entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        }
        return copy
    }

    /// Core Data won't chain V1 → V2 (mapping model) → V5 (lightweight) on its own, which left
    /// anyone updating from the first release on "Library unavailable".
    @Test func upgradesAFirstVersionLibrary() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("CoreModel.sqlite")

        let bundle = Bundle(for: CoreDataManager.self)
        let models = try #require(bundle.url(forResource: "CoreModel", withExtension: "momd"))
        let v1 = classless(try #require(NSManagedObjectModel(contentsOf: models.appendingPathComponent("CoreModel.mom"))))

        let v1Coordinator = NSPersistentStoreCoordinator(managedObjectModel: v1)
        let v1Store = try v1Coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
        let v1Context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        v1Context.persistentStoreCoordinator = v1Coordinator
        let manga = NSEntityDescription.insertNewObject(forEntityName: "MangaModel", into: v1Context)
        manga.setValue(Int64(30013), forKey: "id")
        manga.setValue("よつばと！", forKey: "title")
        try v1Context.save()
        try v1Coordinator.remove(v1Store)

        try CoreDataManager.migrateFromV1IfNeeded(storeURL: storeURL, bundle: bundle)

        let current = classless(try #require(NSManagedObjectModel(contentsOf: models)))
        let container = NSPersistentContainer(name: "CoreModel", managedObjectModel: current)
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        #expect(loadError == nil)

        let migrated = try container.viewContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "MangaModel"))
        #expect(migrated.count == 1)
        #expect(migrated.first?.value(forKey: "title") as? String == "よつばと！")
        #expect((migrated.first?.value(forKey: "anilist_id") as? NSNumber)?.int64Value == 30013)
        #expect(migrated.first?.value(forKey: "id") is UUID)
        container.persistentStoreCoordinator.persistentStores.forEach { try? container.persistentStoreCoordinator.remove($0) }
    }
}
