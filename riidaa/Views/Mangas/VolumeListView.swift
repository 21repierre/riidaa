//
//  VolumeListView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/16.
//

import SwiftUI
import os
import ZIPFoundation
import CoreData

struct VolumeListView: View {
    
    @Environment(\.managedObjectContext) var moc
    
    @ObservedObject var manga: MangaModel
    @State private var isPickingVolume = false
    @StateObject var processingModel = VolumeProcessingModel()
    @State private var stageMessage = ""
    @State private var batchPosition: (index: Int, total: Int)? = nil
    
    nonisolated func batchLabel(_ stage: String) -> String {
        guard let position = batchPosition, position.total > 1 else { return stage }
        return "\(stage) — \(position.index) of \(position.total)"
    }

    @State private var readingVolume: MangaVolumeModel? = nil
    
    @State private var editVolume: MangaVolumeModel? = nil
    @State private var editVolumeNumber: String = ""
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No volumes yet")
                .font(.headline)
            Text("Add a zip containing the .mokuro file mokuro produced, along with its folder of page images.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Link("How to OCR a volume with mokuro",
                 destination: URL(string: "https://github.com/kha-white/mokuro")!)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
        .padding(.top, 60)
    }

    @ViewBuilder
    private var importBanner: some View {
        if let progress = processingModel.progress {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(progress.message)
                        .font(.subheadline)
                    Spacer()
                    if let fraction = progress.fraction {
                        Text("\(Int(fraction * 100))%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                if let fraction = progress.fraction {
                    ProgressView(value: fraction)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    var body: some View {
        ScrollView {
            importBanner
            if manga.volumes.count == 0 && processingModel.progress == nil {
                emptyState
            }
            // TODO: word tracker
            ForEach((manga.volumes.array as! [MangaVolumeModel]).sorted()) { volume in
                Button {
                    readingVolume = volume
                } label: {
                    VolumeComponent(volume: volume)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.vertical, 5)
                .contextMenu {
                    Button(role: .destructive) {
                        moc.delete(volume)
                        CoreDataManager.shared.saveContext()
                    } label: {
                        Label("Delete volume", systemImage: "trash")
                    }
                    Button {
                        editVolume = volume
                        editVolumeNumber = String(volume.number)
                    } label: {
                        Label("Edit volume number", systemImage: "pencil")
                    }
                }
            }
        }
        .navigationTitle(manga.title)
        .toolbar {
            Button(action: {
                self.isPickingVolume = true
            }) {
                Image(systemName: "plus")
            }
            .disabled(processingModel.progress != nil)
        }
        .fileImporter(
            isPresented: $isPickingVolume,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let files):
                guard !files.isEmpty else { return }
                self.processingModel.progress = DictionaryProgress(message: "Starting\u{2026}", value: 0, total: 0)
                Task {
                    await processZipFiles(paths: files.sorted { $0.lastPathComponent < $1.lastPathComponent })
                }
            case .failure(let error):
                Logger.library.error("Could not open the picked volumes: \(error.localizedDescription, privacy: .public)")
            }
        }
        .fullScreenCover(item: $readingVolume) { volume in
            MangaReader(volume: .constant(volume), currentPage: Int(volume.lastReadPage))
        }
        .alert(
            "Import problem",
            isPresented: Binding(
                get: { processingModel.error != nil },
                set: { shown in if !shown { processingModel.error = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(processingModel.error ?? "") }
        )
        .alert("Edit volume", isPresented: .init(get: {editVolume != nil}, set: { v in
            if !v {
                editVolume = nil
            }
        }), actions: {
            TextField("New Volume Number", text: $editVolumeNumber)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {
                editVolume = nil
            }
            Button("OK") {
                if let newNumber = Int64(editVolumeNumber.trimmingCharacters(in: .whitespacesAndNewlines)),
                   newNumber > 0 {
                    editVolume?.changeVolumeNumber(newNumber: newNumber)
                    CoreDataManager.shared.saveContext()
                }
                editVolume = nil
            }
        })
    }
}

extension VolumeListView {
    
    nonisolated func processZipFile(path: URL) async throws {
        let mangaId = await manga.id
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let backgroundContext = CoreDataManager.shared.container.newBackgroundContext()
        
        do {
            var mangaInContext: MangaModel? = nil
            try await backgroundContext.perform {
                let fetchRequest: NSFetchRequest<MangaModel> = MangaModel.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", mangaId as CVarArg)
                mangaInContext = try backgroundContext.fetch(fetchRequest).first
            }
            guard let mangaInContext = mangaInContext else {
                throw NSError(domain: "VolumeProcessing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Manga not found ??"])
            }
            
            if !path.startAccessingSecurityScopedResource() {
                throw NSError(domain: "VolumeProcessing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
            }
            defer {
                path.stopAccessingSecurityScopedResource()
            }
            try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            await MainActor.run {
                self.processingModel.progress = DictionaryProgress(message: "Extracting\u{2026}", value: 0, total: 0)
            }
            try fileManager.unzipItem(at: path, to: tempDirectory)
            await MainActor.run {
                self.processingModel.progress = DictionaryProgress(message: "Reading pages\u{2026}", value: 0, total: 0)
            }
            
            defer {
                try? fileManager.removeItem(at: tempDirectory)
            }

            let mokuroFiles = MokuroArchive.mokuroFiles(in: tempDirectory)
            guard !mokuroFiles.isEmpty else {
                throw MokuroArchive.Failure.noMokuroFile
            }

            var volumeFailures: [String] = []
            for mokuroFile in mokuroFiles {
                do {
                    let mokuroData = try Data(contentsOf: mokuroFile)
                    guard let mokuroJson = try JSONSerialization.jsonObject(with: mokuroData, options: []) as? [String: Any] else {
                        throw MokuroArchive.Failure.unreadable(mokuroFile.lastPathComponent)
                    }

                    guard let volumeName = mokuroJson["volume"] as? String,
                          let titleName = mokuroJson["title"] as? String else {
                        throw MokuroArchive.Failure.unreadable(mokuroFile.lastPathComponent)
                    }

                    // Located from the pages the file itself lists, not from the folder's name.
                    let pagePaths = (mokuroJson["pages"] as? [[String: Any]])?
                        .compactMap { $0["img_path"] as? String } ?? []
                    guard let firstPage = pagePaths.first else {
                        throw MokuroArchive.Failure.unreadable(mokuroFile.lastPathComponent)
                    }
                    guard let imagesFolder = MokuroArchive.imagesDirectory(
                        for: pagePaths, mokuroFile: mokuroFile, root: tempDirectory
                    ) else {
                        throw MokuroArchive.Failure.imagesNotFound(volume: volumeName, page: firstPage)
                    }

                    guard let volumeNumber = MokuroArchive.volumeNumber(from: volumeName, title: titleName) else {
                        throw NSError(domain: "VolumeProcessing", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not tell which volume \"\(volumeName)\" is. Rename the folder you gave mokuro so it ends with the volume number, then run mokuro again."])
                    }
                
                    try await backgroundContext.perform {
                        for vol in mangaInContext.volumes.array as! [MangaVolumeModel] {
                            if vol.number == volumeNumber {
                                throw NSError(domain: "VolumeProcessing", code: 5, userInfo: [NSLocalizedDescriptionKey: "A volume with the same number (\(volumeNumber)) already exists"])
                            }
                        }
                    }
                
                    var newVolume: MangaVolumeModel? = nil
                    await backgroundContext.perform {
                        newVolume = MangaVolumeModel(context: backgroundContext)
                        newVolume!.number = volumeNumber
                        mangaInContext.addToVolumes(newVolume!)
                    }
                    guard let newVolume = newVolume else {
                        throw NSError(domain: "VolumeProcessing", code: 0, userInfo: [NSLocalizedDescriptionKey: "newVolume is nil"])
                    }
                
                    // pages
                    guard let pages = mokuroJson["pages"] as? [[String: Any]] else {
                        throw NSError(domain: "VolumeProcessing", code: 6, userInfo: [NSLocalizedDescriptionKey: "Missing pages in mokuro"])
                    }
                
                    await MainActor.run {
                        self.stageMessage = "Volume \(volumeNumber)"
                        self.processingModel.progress = DictionaryProgress(
                            message: self.batchLabel(self.stageMessage), value: 0, total: pages.count
                        )
                    }
                
                    let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("mangas")
                    let volumeDirectory = documents.appendingPathComponent(mangaInContext.id.uuidString).appendingPathComponent(String(newVolume.number))
                
                    try fileManager.createDirectory(at: volumeDirectory, withIntermediateDirectories: true)
                
                    for (i, page) in pages.enumerated() {
                        guard let img_path = page["img_path"] as? String,
                              let img_width = page["img_width"] as? Int32,
                              let img_height = page["img_height"] as? Int32 else {
                            throw NSError(domain: "VolumeProcessing", code: 6, userInfo: [NSLocalizedDescriptionKey: "Missing image infos"])
                        }
                        let img = imagesFolder.appendingPathComponent(img_path)
                        let destImg = volumeDirectory.appendingPathComponent(img_path)
                        try? fileManager.removeItem(at: destImg)
                        try fileManager.moveItem(at: img, to: destImg)
                    
                        var newPage: MangaPageModel? = nil
                        await backgroundContext.perform {
                            newPage = MangaPageModel(context: backgroundContext)
                            newVolume.addToPages(newPage!)
                            newPage!.number = Int64(i + 1)
                            newPage!.image = img_path
                            newPage!.width = img_width
                            newPage!.height = img_height
                        }
                        guard let newPage = newPage else {
                            throw NSError(domain: "VolumeProcessing", code: 6, userInfo: [NSLocalizedDescriptionKey: "newPage is nil"])
                        }
                    
                        // Text boxes
                        guard let blocks = page["blocks"] as? [[String: Any]] else {
                            continue
                        }
                    
                        for block in blocks {
                            guard let box = block["box"] as? [Int32], let lines = block["lines"] as? [String] else {
                                throw NSError(domain: "VolumeProcessing", code: 6, userInfo: [NSLocalizedDescriptionKey: "Error while parsing OCR block"])
                            }
                            let rotation = block["rotation"] as? Double
                        
                            await backgroundContext.perform {
                                let pageBlock = PageBoxModel(context: backgroundContext)
                                pageBlock.x = box[0]
                                pageBlock.y = box[1]
                                pageBlock.width = (box[2] - box[0])
                                pageBlock.height = (box[3] - box[1])
                                pageBlock.text = lines.joined()
                                pageBlock.rotation = rotation ?? 0
                            
                                newPage.addToBoxes(pageBlock)
                            }
                        }
                        await MainActor.run {
                            self.processingModel.progress = DictionaryProgress(
                                message: self.batchLabel(self.stageMessage), value: i + 1, total: pages.count
                            )
                        }
                    }
                } catch {
                    volumeFailures.append("\(mokuroFile.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            try await backgroundContext.perform {
                try backgroundContext.save()
            }

            if !volumeFailures.isEmpty {
                throw MokuroArchive.Failure.someVolumes(volumeFailures)
            }
        }
    }

    /// One at a time: running several would multiply peak memory
    nonisolated func processZipFiles(paths: [URL]) async {
        guard await !processingModel.isImporting else { return }
        await MainActor.run { processingModel.isImporting = true }
        defer { Task { @MainActor in processingModel.isImporting = false } }

        var failures: [String] = []

        for (index, path) in paths.enumerated() {
            await MainActor.run {
                self.batchPosition = (index: index + 1, total: paths.count)
                self.processingModel.progress = DictionaryProgress(
                    message: self.batchLabel("Reading"), value: 0, total: 0
                )
            }
            do {
                try await processZipFile(path: path)
            } catch {
                Logger.library.error("\(path.lastPathComponent, privacy: .public) failed to import: \(error.localizedDescription, privacy: .public)")
                failures.append("\(path.lastPathComponent): \(error.localizedDescription)")
            }
        }

        let summary = VolumeProcessingModel.summary(failures: failures, of: paths.count)
        await MainActor.run {
            self.processingModel.progress = nil
            self.batchPosition = nil
            self.processingModel.error = summary
        }
    }
    
}

class VolumeProcessingModel: ObservableObject {
    @Published var progress: DictionaryProgress?
    @Published var isImporting = false
    @Published var error: String?

    /// Nil when everything imported; otherwise which volumes failed and why.
    static func summary(failures: [String], of total: Int) -> String? {
        guard !failures.isEmpty else { return nil }
        let detail = failures.joined(separator: "\n\n")
        guard failures.count < total else { return detail }
        return "\(total - failures.count) of \(total) imported.\n\n" + detail
    }
}

#Preview {
    VolumeListView(
        manga: CoreDataManager.sampleManga
    )
    .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
    .onAppear(perform: {
        print(CoreDataManager.sampleManga)
    })
}
