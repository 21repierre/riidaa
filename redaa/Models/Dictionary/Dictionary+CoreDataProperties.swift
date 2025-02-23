//
//  Dictionary+CoreDataProperties.swift
//  redaa
//
//  Created by Pierre on 2025/02/21.
//
//

import Foundation
import CoreData


extension Dictionary {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dictionary> {
        return NSFetchRequest<Dictionary>(entityName: "Dictionary")
    }

    @NSManaged public var title: String
    @NSManaged public var revision: String
    @NSManaged public var d_description: String
    @NSManaged public var sequenced: Bool
    @NSManaged public var format: Int16
    @NSManaged public var indexUrl: String
    @NSManaged public var downloadUrl: String
    @NSManaged public var url: String
    @NSManaged public var attribution: String
    @NSManaged public var sourceLanguage: String
    @NSManaged public var targetLanguage: String
    @NSManaged public var frequencyMode: String
    @NSManaged public var entries: NSSet

}

// MARK: Generated accessors for entries
extension Dictionary {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: DictionaryEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: DictionaryEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSSet)

}

extension Dictionary : Identifiable {

}
