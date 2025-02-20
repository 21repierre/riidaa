//
//  MangaModel+CoreDataProperties.swift
//  redaa
//
//  Created by Pierre on 2025/02/16.
//
//

import Foundation
import CoreData
import UIKit


extension MangaModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MangaModel> {
        return NSFetchRequest<MangaModel>(entityName: "MangaModel")
    }

    @NSManaged public var cover: Data?
    @NSManaged public var id: Int64
    @NSManaged public var title: String
    @NSManaged public var volumes: NSOrderedSet

}

// MARK: Generated accessors for volumes
extension MangaModel {

    @objc(insertObject:inVolumesAtIndex:)
    @NSManaged public func insertIntoVolumes(_ value: MangaVolumeModel, at idx: Int)

    @objc(removeObjectFromVolumesAtIndex:)
    @NSManaged public func removeFromVolumes(at idx: Int)

    @objc(insertVolumes:atIndexes:)
    @NSManaged public func insertIntoVolumes(_ values: [MangaVolumeModel], at indexes: NSIndexSet)

    @objc(removeVolumesAtIndexes:)
    @NSManaged public func removeFromVolumes(at indexes: NSIndexSet)

    @objc(replaceObjectInVolumesAtIndex:withObject:)
    @NSManaged public func replaceVolumes(at idx: Int, with value: MangaVolumeModel)

    @objc(replaceVolumesAtIndexes:withVolumes:)
    @NSManaged public func replaceVolumes(at indexes: NSIndexSet, with values: [MangaVolumeModel])

    @objc(addVolumesObject:)
    @NSManaged public func addToVolumes(_ value: MangaVolumeModel)

    @objc(removeVolumesObject:)
    @NSManaged public func removeFromVolumes(_ value: MangaVolumeModel)

    @objc(addVolumes:)
    @NSManaged public func addToVolumes(_ values: NSOrderedSet)

    @objc(removeVolumes:)
    @NSManaged public func removeFromVolumes(_ values: NSOrderedSet)

}

extension MangaModel {
    
    public func setCover(image: UIImage) {
        let pngImage = image.pngData()
        self.cover = pngImage
    }
    
    public func getCover() -> UIImage? {
        print("has cover \(self.cover != nil)")
        if let cover = self.cover {
            return UIImage(data: cover)
        } else {
            return nil
        }
    }
    
    public func downloadCover(url: String, completion: @escaping (Bool) -> Void) {
        let url = URL(string: url)
        URLSession.shared.dataTask(with: url!) { data, response, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            self.cover = data
            DispatchQueue.main.async {
                completion(true)
            }
        }.resume()
        
    }
    
}

extension MangaModel : Identifiable {

}
