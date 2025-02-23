//
//  MangaPage+CoreDataProperties.swift
//  redaa
//
//  Created by Pierre on 2025/02/16.
//
//

import Foundation
import CoreData
import UIKit


extension MangaPageModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MangaPageModel> {
        return NSFetchRequest<MangaPageModel>(entityName: "MangaPageModel")
    }

    @NSManaged public var number: Int64
    @NSManaged public var image: String
    @NSManaged public var volume: MangaVolumeModel
    @NSManaged public var boxes: NSSet
    @NSManaged public var width: Int32
    @NSManaged public var height: Int32
    
    

}

extension MangaPageModel {
    
//    public func setImage(image: UIImage) {
//        let pngImage = image.pngData()
//        self.image = pngImage!
//    }

    
    public func getBoxes() -> [PageBoxModel] {
        return boxes.allObjects as! [PageBoxModel]
    }
    
    
    @objc(addBoxesObject:)
    @NSManaged public func addToBoxes(_ value: PageBoxModel)

    @objc(removeBoxesObject:)
    @NSManaged public func removeFromBoxes(_ value: PageBoxModel)

    @objc(addBoxes:)
    @NSManaged public func addToBoxes(_ values: NSOrderedSet)

    @objc(removeBoxes:)
    @NSManaged public func removeFromBoxes(_ values: NSOrderedSet)
}

extension MangaPageModel : Identifiable {

}
