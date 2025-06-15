//
//  V1toV2.swift
//  riidaa
//
//  Created by Pierre on 2025/06/15.
//

import CoreData

class V1toV2: NSEntityMigrationPolicy {
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        let dest = NSEntityDescription.insertNewObject(
            forEntityName: mapping.destinationEntityName!,
            into: manager.destinationContext
        )
        
        for (key, _) in sInstance.entity.attributesByName {
            if key == "id" {
                let oldId = sInstance.value(forKey: key)
                dest.setValue(oldId, forKey: "anilist_id")
            } else {
                dest.setValue(sInstance.value(forKey: key), forKey: key)
            }
        }
        dest.setValue(UUID(), forKey: "id")
        
        manager.associate(sourceInstance: sInstance, withDestinationInstance: dest, for: mapping)
    }
    
}
