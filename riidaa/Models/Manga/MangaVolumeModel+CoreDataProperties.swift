//
//  MangaVolumeModel+CoreDataProperties.swift
//  riidaa
//
//  Created by Pierre on 2025/02/16.
//
//

import Foundation
import CoreData


extension MangaVolumeModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MangaVolumeModel> {
        return NSFetchRequest<MangaVolumeModel>(entityName: "MangaVolumeModel")
    }

    @NSManaged public var number: Int64
    @NSManaged public var pages: NSOrderedSet
    @NSManaged public var manga: MangaModel
    @NSManaged public var lastReadPage: Int64

}

extension MangaVolumeModel {

    @objc(insertObject:inPagesAtIndex:)
    @NSManaged public func insertIntoPages(_ value: MangaPageModel, at idx: Int)

    @objc(removeObjectFromPagesAtIndex:)
    @NSManaged public func removeFromPages(at idx: Int)

    @objc(insertPages:atIndexes:)
    @NSManaged public func insertIntoPages(_ values: [MangaPageModel], at indexes: NSIndexSet)

    @objc(removePagesAtIndexes:)
    @NSManaged public func removeFromPages(at indexes: NSIndexSet)

    @objc(replaceObjectInPagesAtIndex:withObject:)
    @NSManaged public func replacePages(at idx: Int, with value: MangaPageModel)

    @objc(replacePagesAtIndexes:withPages:)
    @NSManaged public func replacePages(at indexes: NSIndexSet, with values: [MangaPageModel])

    @objc(addPagesObject:)
    @NSManaged public func addToPages(_ value: MangaPageModel)

    @objc(removePagesObject:)
    @NSManaged public func removeFromPages(_ value: MangaPageModel)

    @objc(addPages:)
    @NSManaged public func addToPages(_ values: NSOrderedSet)

    @objc(removePages:)
    @NSManaged public func removeFromPages(_ values: NSOrderedSet)
    
    func latestReadPage() -> MangaPageModel? {
        if self.pages.count > self.lastReadPage {
            return self.pages[Int(self.lastReadPage)] as! MangaPageModel?
        }
        return nil
    }
    
}

extension MangaVolumeModel : Identifiable, Comparable {
    public static func < (lhs: MangaVolumeModel, rhs: MangaVolumeModel) -> Bool {
        return lhs.number < rhs.number
    }
    

}


extension CoreDataManager {
    
    static var sampleVolume: MangaVolumeModel {
        let volume = MangaVolumeModel(context: CoreDataManager.shared.context)
        volume.number = 1
        volume.lastReadPage = 10
        
        
        for i in 0...50 {
            let p1 = MangaPageModel(context: CoreDataManager.shared.context)
            p1.number = Int64(i)
            p1.image = ""
            volume.insertIntoPages(p1, at: i)
        }
        
        return volume
    }
    
}
