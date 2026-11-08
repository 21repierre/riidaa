//
//  MangaPageModel+CoreDataClass.swift
//  riidaa
//
//  Created by Pierre on 2025/02/16.
//
//

import Foundation
import CoreData

@objc(MangaPageModel)
public class MangaPageModel: NSManagedObject {

    var imageURL: URL {
        volume.directoryURL.appendingPathComponent(image)
    }
}
