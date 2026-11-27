//
//  VolumeImporter.swift
//  riidaa
//

import Foundation
import CoreData
import ZIPFoundation
import os

/// Imports mokuro volumes, one zip at a time across the whole app
@MainActor
final class VolumeImporter: ObservableObject {

    static let shared = VolumeImporter()

    @Published private(set) var mangaID: UUID?
    @Published private(set) var progress: DictionaryProgress?
    @Published var errors: [UUID: String] = [:]

    var isImporting: Bool { mangaID != nil }

    private var batchPosition: (index: Int, total: Int)? = nil

    private func label(_ stage: String) -> String {
        guard let position = batchPosition, position.total > 1 else { return stage }
        return "\(stage) — \(position.index) of \(position.total)"
    }

    private func report(_ message: String, value: Int = 0, total: Int = 0) {
        progress = DictionaryProgress(message: label(message), value: value, total: total)
    }

    func importVolumes(at paths: [URL], into mangaID: UUID) {
        guard !isImporting, !paths.isEmpty else { return }
        self.mangaID = mangaID
        report("Starting\u{2026}")
        Task {
            await MangaStorage.waitForOrphanSweep()
            var failures: [String] = []
            let sorted = paths.sorted { $0.lastPathComponent < $1.lastPathComponent }
            for (index, path) in sorted.enumerated() {
                batchPosition = (index: index + 1, total: sorted.count)
                report("Reading")
                do {
                    try await importZip(at: path, into: mangaID)
                } catch {
                    Logger.library.error("\(path.lastPathComponent, privacy: .public) failed to import: \(error.localizedDescription, privacy: .public)")
                    failures.append("\(path.lastPathComponent): \(error.localizedDescription)")
                }
            }
            if let summary = VolumeImporter.summary(failures: failures, of: sorted.count) {
                errors[mangaID] = summary
            }
            progress = nil
            batchPosition = nil
            self.mangaID = nil
        }
    }

    nonisolated static func summary(failures: [String], of total: Int) -> String? {
        guard !failures.isEmpty else { return nil }
        let detail = failures.joined(separator: "\n\n")
        guard failures.count < total else { return detail }
        return "\(total - failures.count) of \(total) imported.\n\n" + detail
    }

    private nonisolated func importZip(at path: URL, into mangaID: UUID) async throws {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let context = CoreDataManager.shared.newBackgroundContext()

        let mangaInContext: MangaModel? = try await context.perform {
            let request: NSFetchRequest<MangaModel> = MangaModel.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mangaID as CVarArg)
            return try context.fetch(request).first
        }
        guard let mangaInContext = mangaInContext else {
            throw ImportFailure("This manga no longer exists.")
        }

        guard path.startAccessingSecurityScopedResource() else {
            throw ImportFailure("Permission to read the file was denied.")
        }
        defer { path.stopAccessingSecurityScopedResource() }

        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDirectory) }
        await report("Extracting\u{2026}")
        try fileManager.unzipItem(at: path, to: tempDirectory)
        await report("Reading pages\u{2026}")

        let mokuroFiles = MokuroArchive.mokuroFiles(in: tempDirectory)
        guard !mokuroFiles.isEmpty else {
            throw MokuroArchive.Failure.noMokuroFile
        }

        var volumeFailures: [String] = []
        for mokuroFile in mokuroFiles {
            var volumeDirectory: URL? = nil
            do {
                try await importVolume(
                    mokuroFile, root: tempDirectory, manga: mangaInContext, context: context,
                    createdDirectory: &volumeDirectory
                )
            } catch {
                await context.perform { context.rollback() }
                if let volumeDirectory = volumeDirectory {
                    try? fileManager.removeItem(at: volumeDirectory)
                }
                volumeFailures.append("\(mokuroFile.lastPathComponent): \(error.localizedDescription)")
            }
        }
        if !volumeFailures.isEmpty {
            throw MokuroArchive.Failure.someVolumes(volumeFailures)
        }
    }

    private nonisolated func importVolume(
        _ mokuroFile: URL, root: URL, manga: MangaModel, context: NSManagedObjectContext,
        createdDirectory: inout URL?
    ) async throws {
        let fileManager = FileManager.default
        let mokuroData = try Data(contentsOf: mokuroFile)
        guard let mokuroJson = try JSONSerialization.jsonObject(with: mokuroData) as? [String: Any],
              let volumeName = mokuroJson["volume"] as? String,
              let titleName = mokuroJson["title"] as? String,
              let pages = mokuroJson["pages"] as? [[String: Any]] else {
            throw MokuroArchive.Failure.unreadable(mokuroFile.lastPathComponent)
        }

        let pagePaths = pages.compactMap { $0["img_path"] as? String }
        guard let firstPage = pagePaths.first else {
            throw MokuroArchive.Failure.unreadable(mokuroFile.lastPathComponent)
        }
        guard let imagesFolder = MokuroArchive.imagesDirectory(for: pagePaths, mokuroFile: mokuroFile, root: root) else {
            throw MokuroArchive.Failure.imagesNotFound(volume: volumeName, page: firstPage)
        }
        guard let volumeNumber = MokuroArchive.volumeNumber(from: volumeName, title: titleName) else {
            throw ImportFailure("Could not tell which volume \"\(volumeName)\" is. Rename the folder you gave mokuro so it ends with the volume number, then run mokuro again.")
        }

        let (volume, pagesDirectory): (MangaVolumeModel, URL) = try await context.perform {
            let existing: NSFetchRequest<MangaVolumeModel> = MangaVolumeModel.fetchRequest()
            existing.predicate = NSPredicate(format: "manga == %@ AND number == %lld", manga, volumeNumber)
            if try context.count(for: existing) > 0 {
                throw ImportFailure("A volume with the same number (\(volumeNumber)) already exists")
            }
            let volume = MangaVolumeModel(context: context)
            volume.number = volumeNumber
            manga.addToVolumes(volume)
            let directory = MangaStorage.newVolumeDirectory(mangaID: manga.id, number: volumeNumber)
            return (volume, directory)
        }

        let stage = "Volume \(volumeNumber)"
        await report(stage, total: pages.count)

        try fileManager.createDirectory(at: pagesDirectory, withIntermediateDirectories: true)
        createdDirectory = pagesDirectory

        for (index, page) in pages.enumerated() {
            guard let imagePath = page["img_path"] as? String,
                  let width = (page["img_width"] as? NSNumber).flatMap(VolumeImporter.pixels),
                  let height = (page["img_height"] as? NSNumber).flatMap(VolumeImporter.pixels) else {
                throw ImportFailure("Page \(index + 1) is missing its image size")
            }
            let destination = try MokuroArchive.destination(for: imagePath, in: pagesDirectory)
            try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? fileManager.removeItem(at: destination)
            try fileManager.moveItem(at: imagesFolder.appendingPathComponent(imagePath), to: destination)

            let blocks = try (page["blocks"] as? [[String: Any]] ?? []).map { block -> (box: [Int32], text: String, rotation: Double) in
                // mokuro writes integers; NSNumber also accepts a float rather than failing the volume.
                guard let numbers = block["box"] as? [NSNumber], numbers.count == 4,
                      case let box = numbers.compactMap(VolumeImporter.pixels), box.count == 4,
                      box[2] >= box[0], box[3] >= box[1],
                      let lines = block["lines"] as? [String] else {
                    throw ImportFailure("A text box on page \(index + 1) couldn't be read")
                }
                return (box, lines.joined(), (block["rotation"] as? NSNumber)?.doubleValue ?? 0)
            }

            await context.perform {
                let newPage = MangaPageModel(context: context)
                volume.addToPages(newPage)
                newPage.number = Int64(index + 1)
                newPage.image = imagePath
                newPage.width = width
                newPage.height = height
                for block in blocks {
                    let pageBlock = PageBoxModel(context: context)
                    pageBlock.x = block.box[0]
                    pageBlock.y = block.box[1]
                    pageBlock.width = block.box[2] - block.box[0]
                    pageBlock.height = block.box[3] - block.box[1]
                    pageBlock.text = block.text
                    pageBlock.rotation = block.rotation
                    newPage.addToBoxes(pageBlock)
                }
            }
            await report(stage, value: index + 1, total: pages.count)
        }

        try await context.perform {
            try context.save()
        }
    }
}

extension VolumeImporter {
    nonisolated static func pixels(_ number: NSNumber) -> Int32? {
        let value = number.doubleValue
        guard value.isFinite, (-1_000_000...1_000_000).contains(value) else { return nil }
        return Int32(value.rounded())
    }
}

struct ImportFailure: LocalizedError {
    let errorDescription: String?

    init(_ message: String) {
        errorDescription = message
    }
}
