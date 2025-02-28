//
//  Dictionary+CoreDataProperties.swift
//  redaa
//
//  Created by Pierre on 2025/02/28.
//
//

import Foundation
import CoreData


extension Dictionary {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dictionary> {
        return NSFetchRequest<Dictionary>(entityName: "Dictionary")
    }

    @NSManaged public var path: String
    @NSManaged public var name: String

}

extension Dictionary : Identifiable {

}
