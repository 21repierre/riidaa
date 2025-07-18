//
//  VolumeListView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/16.
//

import SwiftUI
import ZIPFoundation
import CoreData

struct VolumeListView: View {
    
    @Environment(\.managedObjectContext) var moc
    
    @ObservedObject var manga: MangaModel
    @State private var isPickingVolume = false
    @StateObject var processingModel = VolumeProcessingModel()
    
    private var dismissDisabled: Bool {
        return processingModel.status == ProcessingStatus.STARTED
    }
    
    @State private var readingVolume: MangaVolumeModel? = nil
    
    @State private var editVolume: MangaVolumeModel? = nil
    @State private var editVolumeNumber: String = ""
    
    var body: some View {
        ScrollView {
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
        }
        .fileImporter(isPresented: $isPickingVolume, allowedContentTypes: [.zip]) { result in
            self.processingModel.message = "Processing volume..."
            self.processingModel.status = ProcessingStatus.STARTED
            self.processingModel.progressValue = 0
            self.processingModel.progressMaxValue = 0
            switch result {
            case .success(let file):
                Task {
                    await processZipFile(path: file)
                }
            case .failure(let error):
                print("error while picking volume file: \(error)")
            }
        }
        .sheet(
            isPresented: .init(get: {
                return self.processingModel.status != ProcessingStatus.NOTHING
            }, set: { _ in }),
            onDismiss: {
                if self.processingModel.status != ProcessingStatus.STARTED {
                    self.processingModel.status = ProcessingStatus.NOTHING
                }
            }
            
        ) {
            VolumeProcessing(processingModel: processingModel)
                .interactiveDismissDisabled(dismissDisabled)
        }
        .fullScreenCover(item: $readingVolume) { v in
            MangaReader(volume: .constant(v), currentPage: Int(v.lastReadPage))
        }
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
    
    nonisolated func processZipFile(path: URL) async {
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
                self.processingModel.message = "Extracting zip file..."
                self.processingModel.progressMaxValue = 1
            }
            try fileManager.unzipItem(at: path, to: tempDirectory)
            await MainActor.run {
                self.processingModel.message = "Extracted zip file."
                self.processingModel.progressValue = 1
            }
            
            var extractedItems = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil).filter { $0.lastPathComponent != "__MACOSX" }
            
            if extractedItems.count == 1,
               fileManager.isDirectory(at: extractedItems[0]) {
                let nestedFolder = extractedItems[0]
                extractedItems = try fileManager.contentsOfDirectory(at: nestedFolder, includingPropertiesForKeys: nil)
            }
            defer {
                try? fileManager.removeItem(at: tempDirectory)
            }
            
            let mokuroFiles = extractedItems.filter { $0.pathExtension == "mokuro" }
            for mokuroFile in mokuroFiles {
                let imagesFolder = URL(string: mokuroFile.absoluteString.replacingOccurrences(of: ".\(mokuroFile.pathExtension)", with: ""))
                guard let imagesFolder = imagesFolder else {
                    throw NSError(domain: "VolumeProcessing", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(mokuroFile) doesn't have an associated image folder"])
                }
                if !fileManager.isDirectory(at: imagesFolder) {
                    continue
                }
                let mokuroData = try Data(contentsOf: mokuroFile)
                guard let mokuroJson = try JSONSerialization.jsonObject(with: mokuroData, options: []) as? [String: Any] else {
                    throw NSError(domain: "VolumeProcessing", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
                }
                
                guard let volumeName = mokuroJson["volume"] as? String,
                      let titleName = mokuroJson["title"] as? String else {
                    throw NSError(domain: "VolumeProcessing", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing 'volume' or 'title' in mokuro \(mokuroFile)"])
                }
                
                // Try to extract the first integer found in volumeName
                let volumeNum: Int64?
                
                // Use regex to find the first sequence of digits in volumeName
                if let range = volumeName.range(of: "\\d+", options: .regularExpression) {
                    let numberString = String(volumeName[range])
                    volumeNum = Int64(numberString)
                } else {
                    // Fallback: your original logic if regex fails
                    let v1 = volumeName.replacingOccurrences(of: titleName, with: "").dropFirst(2)
                    volumeNum = Int64(v1)
                }
                guard let volumeNumber = volumeNum else {
                    throw NSError(domain: "VolumeProcessing", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid volume number in: \(volumeName)"])
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
                    self.processingModel.message = "Processing volume \(volumeNumber)."
                    self.processingModel.progressMaxValue = pages.count
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
                        self.processingModel.progressValue = i
                    }
                }
            }
            
            try await backgroundContext.perform {
                try backgroundContext.save()
            }
        } catch {
            await MainActor.run {
                self.processingModel.status = ProcessingStatus.ERROR
                self.processingModel.message = error.localizedDescription
            }
        }
        await MainActor.run {
            if self.processingModel.status != ProcessingStatus.ERROR {
                self.processingModel.status = ProcessingStatus.FINISHED
            }
        }
    }
    
}

enum ProcessingStatus {
    case NOTHING,
         STARTED,
         FINISHED,
         ERROR
}

class VolumeProcessingModel: ObservableObject {
    @Published var status: ProcessingStatus = .NOTHING
    @Published var message: String = "Processing volume..."
    @Published var progressValue: Int = 0
    @Published var progressMaxValue: Int = 0
}


struct VolumeProcessing: View {
    
    @ObservedObject var processingModel: VolumeProcessingModel
    
    var body: some View {
        VStack(spacing: 40) {
            switch processingModel.status {
            case .STARTED:
                CircularProgressView(progress: processingModel.progressValue, progressMax: processingModel.progressMaxValue)
                    .frame(width: 150, height: 150)
                
            case .FINISHED:
                Image(systemName: "checkmark")
                    .scaleEffect(4)
                    .frame(width: 150, height: 150)
            case .ERROR:
                Image(systemName: "xmark")
                    .scaleEffect(4)
                    .frame(width: 150, height: 150)
            case .NOTHING:
                EmptyView()
            }
            Text(processingModel.message)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding()
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
