//
//  CoreDataModelTests.swift
//  riidaaTests
//

import CoreData
import ObjectiveC
import Testing
@testable import riidaa

struct CoreDataModelTests {

    private func declaredProperties(of type: NSManagedObject.Type) -> [String] {
        var count: UInt32 = 0
        guard let list = class_copyPropertyList(type, &count) else { return [] }
        defer { free(list) }
        return (0..<Int(count)).map { String(cString: property_getName(list[$0])) }
    }

    @Test(arguments: [
        MangaModel.self, MangaVolumeModel.self, MangaPageModel.self, PageBoxModel.self,
    ] as [NSManagedObject.Type])
    func theCompiledModelBacksEveryManagedProperty(_ type: NSManagedObject.Type) throws {
        let name = String(describing: type)
        let model = CoreDataManager.shared.container.managedObjectModel
        let entity = try #require(model.entitiesByName[name], "the compiled model has no \(name) entity")

        let backed = Set(entity.propertiesByName.keys)
        let missing = declaredProperties(of: type).filter { !backed.contains($0) }.sorted()

        #expect(missing.isEmpty, """
            \(name) declares \(missing.joined(separator: ", ")) but the compiled model has no such \
            property — the build is using an older model version than the project specifies. \
            Clean the build folder and rebuild.
            """)
    }

}
