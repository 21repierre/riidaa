//
//  Dictionary+CoreDataProperties.swift
//  redaa
//
//  Created by Pierre on 2025/03/08.
//
//

import Foundation
import CoreData


extension Dictionary {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dictionary> {
        return NSFetchRequest<Dictionary>(entityName: "Dictionary")
    }

    @NSManaged public var revision: String
    @NSManaged public var title: String
    @NSManaged public var sequenced: Bool
    @NSManaged public var format: Int16
    @NSManaged public var author: String?
    @NSManaged public var isUpdatable: Bool
    @NSManaged public var indexUrl: String?
    @NSManaged public var downloadUrl: String?
    @NSManaged public var url: String?
    @NSManaged public var description_: String?
    @NSManaged public var attribution: String?
    @NSManaged public var sourceLanguage: String?
    @NSManaged public var targetLanguage: String?
    @NSManaged public var frequencyMode: String?
    @NSManaged public var terms: NSOrderedSet

    public func getTerms() -> [Term] {
        return terms.array as! [Term]
    }
    
}

// MARK: Generated accessors for terms
extension Dictionary {

    @objc(insertObject:inTermsAtIndex:)
    @NSManaged public func insertIntoTerms(_ value: Term, at idx: Int)

    @objc(removeObjectFromTermsAtIndex:)
    @NSManaged public func removeFromTerms(at idx: Int)

    @objc(insertTerms:atIndexes:)
    @NSManaged public func insertIntoTerms(_ values: [Term], at indexes: NSIndexSet)

    @objc(removeTermsAtIndexes:)
    @NSManaged public func removeFromTerms(at indexes: NSIndexSet)

    @objc(replaceObjectInTermsAtIndex:withObject:)
    @NSManaged public func replaceTerms(at idx: Int, with value: Term)

    @objc(replaceTermsAtIndexes:withTerms:)
    @NSManaged public func replaceTerms(at indexes: NSIndexSet, with values: [Term])

    @objc(addTermsObject:)
    @NSManaged public func addToTerms(_ value: Term)

    @objc(removeTermsObject:)
    @NSManaged public func removeFromTerms(_ value: Term)

    @objc(addTerms:)
    @NSManaged public func addToTerms(_ values: NSOrderedSet)

    @objc(removeTerms:)
    @NSManaged public func removeFromTerms(_ values: NSOrderedSet)

}

extension Dictionary : Identifiable {

}
