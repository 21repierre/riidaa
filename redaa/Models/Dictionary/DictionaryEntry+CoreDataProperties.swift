//
//  DictionaryEntry+CoreDataProperties.swift
//  redaa
//
//  Created by Pierre on 2025/02/21.
//
//

import Foundation
import CoreData


extension DictionaryEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DictionaryEntry> {
        return NSFetchRequest<DictionaryEntry>(entityName: "DictionaryEntry")
    }

    @NSManaged public var kanji: String
    @NSManaged public var reading: String
    @NSManaged public var definition_tags: NSObject
    @NSManaged public var deinflection_ids: NSObject
    @NSManaged public var score: Int64
    @NSManaged public var sequence_id: Int64
    @NSManaged public var term_tags: NSObject
    @NSManaged public var definitions: NSObject
    @NSManaged public var dictionary: Dictionary

}

extension DictionaryEntry : Identifiable {

}
