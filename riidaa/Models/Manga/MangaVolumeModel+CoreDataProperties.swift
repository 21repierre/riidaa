//
//  MangaVolumeModel+CoreDataProperties.swift
//  riidaa
//
//  Created by Pierre on 2025/02/16.
//
//

import Foundation
import os
import CoreData


extension MangaVolumeModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MangaVolumeModel> {
        return NSFetchRequest<MangaVolumeModel>(entityName: "MangaVolumeModel")
    }

    @NSManaged public var number: Int64
    @NSManaged public var pages: NSOrderedSet
    @NSManaged public var manga: MangaModel
    @NSManaged public var lastReadPage: Int64
    @NSManaged public var last_read_at: NSDate?

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
    
    var directoryURL: URL {
        if let resolved = resolvedDirectory, resolved.number == number {
            return resolved.url
        }
        let url = MangaStorage.volumeDirectory(
            mangaID: manga.id, anilistID: manga.anilist_id, number: number,
            samplePage: (pages.firstObject as? MangaPageModel)?.image
        )
        if FileManager.default.fileExists(atPath: url.path) {
            resolvedDirectory = (number, url)
        }
        return url
    }

    enum RenumberError: LocalizedError {
        case taken(Int64)

        var errorDescription: String? {
            switch self {
            case .taken(let number): return "There is already a volume \(number)."
            }
        }
    }

    func changeVolumeNumber(newNumber: Int64) throws {
        guard newNumber != number else { return }
        MangaStorage.waitForOrphanSweepToFinish()
        let siblings = manga.volumes.array as? [MangaVolumeModel] ?? []
        if siblings.contains(where: { $0 !== self && $0.number == newNumber }) {
            throw RenumberError.taken(newNumber)
        }
        let fileManager = FileManager.default
        let source = directoryURL
        let mangaDirectories = MangaStorage.ownedDirectories(of: manga)
        let destination = MangaStorage.newVolumeDirectory(mangaID: manga.id, number: newNumber)

        let aside = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var setAside: [(original: URL, moved: URL)] = []
        func restore() {
            for item in setAside {
                try? fileManager.moveItem(at: item.moved, to: item.original)
            }
            try? fileManager.removeItem(at: aside)
        }

        let moved = fileManager.fileExists(atPath: source.path)
        // A legacy folder another entry for the same series still uses is copied, not taken.
        let sourceShared = !mangaDirectories.contains {
            $0.standardizedFileURL.path == source.deletingLastPathComponent().standardizedFileURL.path
        }
        do {
            for (index, leftover) in MangaStorage.ownedVolumeDirectories(of: manga, number: newNumber).enumerated()
            where fileManager.fileExists(atPath: leftover.path) {
                try fileManager.createDirectory(at: aside, withIntermediateDirectories: true)
                let target = aside.appendingPathComponent(String(index))
                try fileManager.moveItem(at: leftover, to: target)
                setAside.append((leftover, target))
            }
            if moved {
                try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                if sourceShared {
                    try fileManager.copyItem(at: source, to: destination)
                } else {
                    try fileManager.moveItem(at: source, to: destination)
                }
            }
        } catch {
            restore()
            throw error
        }

        number = newNumber
        resolvedDirectory = nil
        do {
            try managedObjectContext?.save()
        } catch {
            managedObjectContext?.rollback()
            resolvedDirectory = nil
            if moved {
                if sourceShared {
                    try? fileManager.removeItem(at: destination)
                } else {
                    try? fileManager.moveItem(at: destination, to: source)
                }
            }
            restore()
            throw error
        }
        try? fileManager.removeItem(at: aside)
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
        
        for i in 0...150 {
            let p1 = MangaPageModel(context: CoreDataManager.shared.context)
            p1.number = Int64(i)+1
            p1.image = "yamada01_\(i).jpg"
            p1.height = 3000
            p1.width = 1500
            
            let box = PageBoxModel(context: CoreDataManager.shared.context)
            box.height = 50
            box.width = 100
            box.text = "俺"
            box.x = 100
            box.y = 200
            p1.addToBoxes(box)
            
            volume.insertIntoPages(p1, at: i)
        }
        
        return volume
    }
    
}
