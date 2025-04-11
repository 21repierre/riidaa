//
//  VolumeListView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/16.
//

import SwiftUI
import ZIPFoundation

struct VolumeListView: View {
    
    @Environment(\.managedObjectContext) var moc
    
    @ObservedObject var manga: MangaModel
    @State private var isPickingVolume = false
    @State private var processingStatus = ProcessingStatus.NOTHING
    @State private var processingMessage: String = "Processing volume..."
    @State private var processingProgress: Int = 0
    @State private var processingProgressMax: Int = 0
    
    private var dismissDisabled: Bool {
        return processingStatus == ProcessingStatus.STARTED
    }
    
    var body: some View {
        ScrollView {
            // TODO: word tracker
            ForEach((manga.volumes.array as! [MangaVolumeModel]).sorted()) { volume in
                VolumeComponent(volume: volume)
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
            self.processingMessage = "Processing volume..."
            self.processingStatus = ProcessingStatus.STARTED
            self.processingProgress = 0
            self.processingProgressMax = 0
            switch result {
            case .success(let file):
                processZipFile(path: file)
            case .failure(let error):
                print("error while picking volume file: \(error)")
            }
        }
        .sheet(
            isPresented: .init(get: {
                return self.processingStatus != ProcessingStatus.NOTHING
            }, set: { _ in }),
            onDismiss: {
                if self.processingStatus != ProcessingStatus.STARTED {
                    self.processingStatus = ProcessingStatus.NOTHING
                }
            }
            
        ) {
            VolumeProcessing(message: $processingMessage, status: $processingStatus, progressValue: $processingProgress, progressMaxValue: $processingProgressMax)
                .interactiveDismissDisabled(dismissDisabled)
        }.onAppear(perform: {
            print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("mangas"))
        })
    }
}

extension VolumeListView {
    
    func processZipFile(path: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            
            do {
                if !path.startAccessingSecurityScopedResource() {
                    throw NSError(domain: "VolumeProcessing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
                }
                defer {
                    path.stopAccessingSecurityScopedResource()
                }
                try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
                try fileManager.unzipItem(at: path, to: tempDirectory)
                
                let extractedItems = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
                let mokuroFile = extractedItems.first { $0.pathExtension == "mokuro" }
                let imagesFolder = extractedItems.first { fileManager.isDirectory(at: $0) }
                
                defer {
                    try? fileManager.removeItem(at: tempDirectory)
                }
                
                guard let mokuroFile = mokuroFile, let imagesFolder = imagesFolder else {
                    throw NSError(domain: "VolumeProcessing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing .mokuro file or folder in ZIP"])
                }
                let mokuroData = try Data(contentsOf: mokuroFile)
                guard let mokuroJson = try JSONSerialization.jsonObject(with: mokuroData, options: []) as? [String: Any] else {
                    throw NSError(domain: "VolumeProcessing", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
                }
                
                guard let volumeName = mokuroJson["volume"] as? String,
                      let titleName = mokuroJson["title"] as? String else {
                    throw NSError(domain: "VolumeProcessing", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing 'volume' or 'title' in mokuro"])
                }
                
                let v1 = volumeName.replacingOccurrences(of: titleName, with: "").dropFirst(2)
                guard let volumeNumber = Int64(v1) else {
                    throw NSError(domain: "VolumeProcessing", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid volume number: \(v1)"])
                }
                print("Volume number \(volumeNumber)")
                for vol in manga.volumes.array as! [MangaVolumeModel] {
                    if vol.number == volumeNumber {
                        throw NSError(domain: "VolumeProcessing", code: 5, userInfo: [NSLocalizedDescriptionKey: "A volume with the same number already exists"])
                    }
                }
                
                let newVolume = MangaVolumeModel(context: moc)
                newVolume.number = volumeNumber
                
                // pages
                guard let pages = mokuroJson["pages"] as? [[String: Any]] else {
                    throw NSError(domain: "VolumeProcessing", code: 6, userInfo: [NSLocalizedDescriptionKey: "Missing pages in mokuro"])
                }
                self.processingProgressMax = pages.count
                
                let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("mangas")
                let volumeDirectory = documents.appendingPathComponent(String(manga.id)).appendingPathComponent(String(newVolume.number))
                try fileManager.createDirectory(at: volumeDirectory, withIntermediateDirectories: true)
                
                for (i, page) in pages.enumerated() {
                    guard let img_path = page["img_path"] as? String,
                          let img_width = page["img_width"] as? Int32,
                          let img_height = page["img_height"] as? Int32 else {
                        throw NSError(domain: "VolumeProcessing", code: 6, userInfo: [NSLocalizedDescriptionKey: "Missing image infos"])
                    }
                    let img = imagesFolder.appendingPathComponent(img_path)
                    let destImg = volumeDirectory.appendingPathComponent(img_path)
//                    print(destImg)
                    try? fileManager.removeItem(at: destImg)
                    try fileManager.moveItem(at: img, to: destImg)
                    
                    let newPage = MangaPageModel(context: moc)
                    newVolume.insertIntoPages(newPage, at: i)
                    newPage.number = Int64(i + 1)
                    newPage.image = img_path
                    
                    newPage.width = img_width
                    newPage.height = img_height
                    
                    // Text boxes
                    guard let blocks = page["blocks"] as? [[String: Any]] else {
                        continue
                    }
                    
                    for block in blocks {
                        guard let box = block["box"] as? [Int32], let lines = block["lines"] as? [String] else {
                            throw NSError(domain: "VolumeProcessing", code: 6, userInfo: [NSLocalizedDescriptionKey: "Error while parsing OCR block"])
                        }
                        let rotation = block["rotation"] as? Double
                        
                        let pageBlock = PageBoxModel(context: moc)
                        pageBlock.x = box[0]
                        pageBlock.y = box[1]
                        pageBlock.width = (box[2] - box[0])
                        pageBlock.height = (box[3] - box[1])
                        pageBlock.text = lines.joined()
                        pageBlock.rotation = rotation ?? 0
                        
                        newPage.addToBoxes(pageBlock)
                    }
//                    print(newPage.number, newPage.boxes.count)
                    self.processingProgress = i
                }
                
                
                manga.addToVolumes(newVolume)
                
                self.processingMessage = "Volume processed."
            } catch {
                self.processingStatus = ProcessingStatus.ERROR
                self.processingMessage = error.localizedDescription
            }
            
            DispatchQueue.main.async {
                if self.processingStatus != ProcessingStatus.ERROR {
                    try? moc.save()
                    self.processingStatus = ProcessingStatus.FINISHED
                }
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

struct VolumeProcessing: View {
    
    @Binding var message: String
    @Binding var status: ProcessingStatus
    @Binding var progressValue: Int
    @Binding var progressMaxValue: Int
    
    var body: some View {
        VStack(spacing: 40) {
            switch self.status {
            case .STARTED:
                CircularProgressView(progress: progressValue, progressMax: progressMaxValue)
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
            Text(message)
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
