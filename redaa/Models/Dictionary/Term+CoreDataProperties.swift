//
//  Term+CoreDataProperties.swift
//  redaa
//
//  Created by Pierre on 2025/03/08.
//
//

import Foundation
import CoreData


extension Term {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Term> {
        return NSFetchRequest<Term>(entityName: "Term")
    }

    @NSManaged public var term: String
    @NSManaged public var reading: String
    @NSManaged public var definitionTags: [String]
    @NSManaged public var wordTypes: [String]
    @NSManaged public var score: Int64
    @NSManaged public var definitions: Data
    @NSManaged public var sequenceNumber: Int64
    @NSManaged public var termTags: [String]
    
    @NSManaged public var dictionary: Dictionary


    public func getWordTypes() -> [WordType] {
        return self.wordTypes.compactMap({ w in
            WordType.fromString(s: w)
        })
    }
    
}

extension Term : Identifiable {

}
