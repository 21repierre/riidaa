//
//  MangaVolumeModel+CoreDataClass.swift
//  riidaa
//
//  Created by Pierre on 2025/02/16.
//
//

import Foundation
import CoreData

@objc(MangaVolumeModel)
public class MangaVolumeModel: NSManagedObject {

    var resolvedDirectory: (number: Int64, url: URL)?

}
