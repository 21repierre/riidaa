//
//  PageBoxModel+CoreDataProperties.swift
//  riidaa
//
//  Created by Pierre on 2025/02/18.
//
//

import Foundation
import CoreData


extension PageBoxModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PageBoxModel> {
        return NSFetchRequest<PageBoxModel>(entityName: "PageBoxModel")
    }

    @NSManaged public var x: Int32
    @NSManaged public var y: Int32
    @NSManaged public var width: Int32
    @NSManaged public var height: Int32
    @NSManaged public var text: String
    @NSManaged public var page: MangaPageModel
    @NSManaged public var rotation: Double

}

extension PageBoxModel : Identifiable {

}
