//
//  MangaStorage.swift
//  riidaa
//

import Foundation
import CoreData
import os

enum MangaStorage {

    static var root: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("mangas")
    }

    static func mangaDirectories(id: UUID, anilistID: NSNumber?) -> [URL] {
        var directories = [root.appendingPathComponent(id.uuidString)]
        if let anilistID = anilistID, anilistID != 0 {
            directories.append(root.appendingPathComponent(String(anilistID.intValue)))
        }
        return directories
    }

    static func volumeDirectory(mangaID: UUID, anilistID: NSNumber?, number: Int64, samplePage: String? = nil) -> URL {
        let fileManager = FileManager.default
        let candidates = volumeDirectoryCandidates(mangaID: mangaID, anilistID: anilistID, number: number)
        if let samplePage = samplePage,
           let holding = candidates.first(where: { fileManager.fileExists(atPath: $0.appendingPathComponent(samplePage).path) }) {
            return holding
        }
        return candidates.first { fileManager.fileExists(atPath: $0.path) } ?? candidates[0]
    }

    static func volumeDirectoryCandidates(mangaID: UUID, anilistID: NSNumber?, number: Int64) -> [URL] {
        mangaDirectories(id: mangaID, anilistID: anilistID).map { $0.appendingPathComponent(String(number)) }
    }

    static func ownedDirectories(of manga: MangaModel) -> [URL] {
        let directories = mangaDirectories(id: manga.id, anilistID: manga.anilist_id)
        guard directories.count > 1, let anilistID = manga.anilist_id, let context = manga.managedObjectContext else {
            return directories
        }
        let others: NSFetchRequest<MangaModel> = MangaModel.fetchRequest()
        others.predicate = NSPredicate(format: "anilist_id == %@ AND id != %@", anilistID, manga.id as CVarArg)
        let shared = ((try? context.count(for: others)) ?? 1) > 0
        return shared ? [directories[0]] : directories
    }

    /// Where a volume imported or renumbered now goes.
    static func newVolumeDirectory(mangaID: UUID, number: Int64) -> URL {
        root.appendingPathComponent(mangaID.uuidString).appendingPathComponent(String(number))
    }

    static func ownedVolumeDirectories(of manga: MangaModel, number: Int64) -> [URL] {
        ownedDirectories(of: manga).map { $0.appendingPathComponent(String(number)) }
    }

    static func removeFiles(at directories: [URL]) {
        for directory in directories where FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.removeItem(at: directory)
            } catch {
                Logger.library.error("Could not remove \(directory.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private static let orphanSweep = DispatchGroup()

    static func waitForOrphanSweepToFinish() {
        _ = orphanSweep.wait(timeout: .now() + 10)
    }

    static func waitForOrphanSweep() async {
        await withCheckedContinuation { continuation in
            orphanSweep.notify(queue: .global(qos: .userInitiated)) { continuation.resume() }
        }
    }

    static func removeOrphans(in context: NSManagedObjectContext) {
        orphanSweep.enter()
        context.perform {
            defer { orphanSweep.leave() }
            guard let mangas = try? context.fetch(MangaModel.fetchRequest()) else { return }
            let fileManager = FileManager.default
            guard let folders = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
                return
            }
            for folder in folders {
                let owners = mangas.filter { manga in
                    mangaDirectories(id: manga.id, anilistID: manga.anilist_id)
                        .contains { $0.standardizedFileURL.path == folder.standardizedFileURL.path }
                }
                guard !owners.isEmpty else {
                    removeFiles(at: [folder])
                    continue
                }
                let volumes = owners.flatMap { $0.volumes.array as? [MangaVolumeModel] ?? [] }
                let allFound = volumes.allSatisfy { volume in
                    volumeDirectoryCandidates(mangaID: volume.manga.id, anilistID: volume.manga.anilist_id, number: volume.number)
                        .contains { fileManager.fileExists(atPath: $0.path) }
                }
                guard allFound else { continue }
                let kept = Set(volumes.flatMap { volume in
                    volumeDirectoryCandidates(mangaID: volume.manga.id, anilistID: volume.manga.anilist_id, number: volume.number)
                        .map { $0.standardizedFileURL.path }
                })
                let volumeFolders = (try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
                removeFiles(at: volumeFolders.filter { !kept.contains($0.standardizedFileURL.path) })
            }
        }
    }
}
