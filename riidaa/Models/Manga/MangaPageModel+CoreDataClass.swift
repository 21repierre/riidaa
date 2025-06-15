//
//  MangaPageModel+CoreDataClass.swift
//  riidaa
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
            let baseDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let mangaDirName: String

            if let anilistId = volume.manga.anilist_id, anilistId != 0 {
                mangaDirName = String(anilistId.intValue)
            } else {
                mangaDirName = volume.manga.id.uuidString
            }

            let volumeDir = baseDir
                .appendingPathComponent("mangas")
                .appendingPathComponent(mangaDirName)
                .appendingPathComponent(String(volume.number))

            var data: Data?
            let imagePath = volumeDir.appendingPathComponent(self.image)

            // Try with anilist_id or id (already chosen)
            data = try? Data(contentsOf: imagePath)

            // If first attempt failed and anilist_id was used, try with id
            if data == nil, volume.manga.anilist_id != nil {
                // Attempt using id
                let fallbackDir = baseDir
                    .appendingPathComponent("mangas")
                    .appendingPathComponent(volume.manga.id.uuidString)
                    .appendingPathComponent(String(volume.number))

                let fallbackPath = fallbackDir.appendingPathComponent(self.image)
                data = try? Data(contentsOf: fallbackPath)
            }

            if let data = data {
                return UIImage(data: data)
            } else {
                return nil
            }
        } catch {
            return nil
        }

    }
}
