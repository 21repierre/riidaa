//
//  MangaPageModel+CoreDataClass.swift
//  redaa
//
//  Created by Pierre on 2025/02/16.
//
//

import Foundation
import CoreData
import UIKit

@objc(MangaPageModel)
public class MangaPageModel: NSManagedObject {

    private var uiImage: UIImage? = nil
    
    public func getImage() -> UIImage? {
        if self.uiImage != nil {
            return self.uiImage
        }
        do {
            let fileManager = FileManager.default
            let volumeDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("mangas")
                .appendingPathComponent(String(volume.manga.id))
                .appendingPathComponent(String(volume.number))
            let data = try Data(contentsOf: volumeDir.appendingPathComponent(self.image))
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
