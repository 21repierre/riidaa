//
//  DictionariesView.swift
//  redaa
//
//  Created by Pierre on 2025/02/21.
//

import SwiftUI
import redaaDic
import CoreData

struct DictionariesView: View {
    
    @EnvironmentObject var appManager: AppManager
    @State private var isPickingDictionary = false
    @State private var processingStatus = ProcessingStatus.NOTHING
    @State private var processingMessage: String = "Processing dictionary..."
    @State private var processingProgress: Int = 0
    @State private var processingProgressMax: Int = 0
    
    private var dismissDisabled: Bool {
        return processingStatus == ProcessingStatus.STARTED
    }
    
    var body: some View {
        ScrollView {
            ForEach($appManager.dictionaries) { dictionary in
                let dictionary = dictionary.wrappedValue
                DictionaryView(dictionary: dictionary)
            }
        }
        .navigationTitle("Dictionaries")
        .toolbar {
            Button(action: {
                self.isPickingDictionary = true
            }) {
                Image(systemName: "plus")
            }
        }
        .fileImporter(isPresented: $isPickingDictionary, allowedContentTypes: [.zip]) { result in
            self.processingMessage = "Processing dictionary..."
            self.processingStatus = ProcessingStatus.STARTED
            self.processingProgress = 0
            self.processingProgressMax = 0
            switch result {
            case .success(let file):
                processZipFile(path: file)
            case .failure(let error):
                print("error while picking dictionary file: \(error)")
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
            VStack{
                VStack(spacing: 40) {
                    switch processingStatus {
                    case .STARTED:
                        CircularProgressView(progress: self.processingProgress, progressMax: self.processingProgressMax)
                            .frame(width: 150, height: 150)
                        Text("\(processingProgress) / \(processingProgressMax)")
                        
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
                    Text(processingMessage)
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .interactiveDismissDisabled(dismissDisabled)
        }
    }
    
    func processZipFile(path: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            var dicId: NSManagedObjectID? = nil
            let fileManager = FileManager.default
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("dictionaries")
            let dicDirectory = documents.appendingPathComponent(UUID().uuidString)
            
            do {
                if !path.startAccessingSecurityScopedResource() {
                    throw NSError(domain: "DictionaryImport", code: 0, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
                }
                defer {
                    path.stopAccessingSecurityScopedResource()
                }
                
                try fileManager.createDirectory(at: dicDirectory, withIntermediateDirectories: true)
                try fileManager.unzipItem(at: path, to: dicDirectory)
                
                let dicContent = try fileManager.contentsOfDirectory(at: dicDirectory, includingPropertiesForKeys: nil)
                self.processingProgressMax = (dicContent.count)
                
                guard let fileContent = try? Data(contentsOf: dicDirectory.appendingPathComponent("index.json")) else {
                    throw NSError(domain: "DictionaryImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find dictionary index.json"])
                }
                let dicJson = try JSONSerialization.jsonObject(with: fileContent)
                guard let dicJson = dicJson as? [String: Any] else {
                    throw NSError(domain: "DictionaryImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid file format"])
                }
                guard let revision = dicJson["revision"] as? String,
                      let title = dicJson["title"] as? String
                else {
                    throw NSError(domain: "DictionaryImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing mandatory properties"])
                }
                
                
                let newDic = Dictionary(context: CoreDataManager.shared.context)
                newDic.title = title
                newDic.revision = revision
                
                if let sequenced = dicJson["sequenced"] as? Bool {
                    newDic.sequenced = sequenced
                }
                if let format = dicJson["format"] as? Int16 {
                    newDic.format = format
                }
                if let author = dicJson["author"] as? String {
                    newDic.author = author
                }
                if let isUpdatable = dicJson["isUpdatable"] as? Bool {
                    newDic.isUpdatable = isUpdatable
                }
                if let indexUrl = dicJson["indexUrl"] as? String {
                    newDic.indexUrl = indexUrl
                }
                if let downloadUrl = dicJson["downloadUrl"] as? String {
                    newDic.downloadUrl = downloadUrl
                }
                if let url = dicJson["url"] as? String {
                    newDic.url = url
                }
                if let description = dicJson["description"] as? String {
                    newDic.description_ = description
                }
                if let attribution = dicJson["attribution"] as? String {
                    newDic.attribution = attribution
                }
                if let sourceLanguage = dicJson["sourceLanguage"] as? String {
                    newDic.sourceLanguage = sourceLanguage
                }
                if let targetLanguage = dicJson["targetLanguage"] as? String {
                    newDic.targetLanguage = targetLanguage
                }
                if let frequencyMode = dicJson["frequencyMode"] as? String {
                    newDic.frequencyMode = frequencyMode
                }
                
                try CoreDataManager.shared.context.save()
                dicId = newDic.objectID
                self.processingProgress += 1
            } catch {
                self.processingStatus = ProcessingStatus.ERROR
                self.processingMessage = error.localizedDescription
                return
            }
            
            guard let dicId = dicId else {
                self.processingStatus = ProcessingStatus.ERROR
                return
            }
            
            let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            backgroundContext.retainsRegisteredObjects = false
            backgroundContext.parent = CoreDataManager.shared.context
            
            backgroundContext.perform {
                var i = 1
                var tI = 0
                var dic = backgroundContext.object(with: dicId) as! Dictionary
                
                while true {
                    let filename = "term_bank_\(i).json"
                    let filepath = dicDirectory.appending(component: filename)
                    
                    guard let fileContent = try? Data(contentsOf: filepath) else {
                        break
                    }
                    autoreleasepool {
                        let termsJson = try? JSONSerialization.jsonObject(with: fileContent)
                        guard let termsJson = termsJson as? [[Any]] else {
                            //TODO: error
                            return
                        }
                        
                        for t in termsJson {
                            guard let term = t[0] as? String,
                                  let reading = t[1] as? String,
                                  let wordTypesJson = t[3] as? String,
                                  let score = t[4] as? Int64,
                                  let definitions = t[5] as? [Any],
                                  let sequence  = t[6] as? Int64,
                                  let termTagsJson = t[7]  as? String
                            else {
                                continue
                            }
                            let definitionTagsJson = t[2] as? String ?? ""
                            let definitionTags = definitionTagsJson.components(separatedBy: " ")
                            let termTags = termTagsJson.components(separatedBy: " ")
                            let wordTypesArray = wordTypesJson.components(separatedBy: " ")
                            guard let definitionsEncoded = try? JSONSerialization.data(withJSONObject: definitions, options: []) else {
                                continue
                            }
                            
                            let newTerm = Term(context: backgroundContext)
                            newTerm.term = term
                            newTerm.reading = reading
                            newTerm.definitionTags = definitionTags
                            newTerm.wordTypes = wordTypesArray
                            newTerm.score = score
                            newTerm.definitions = definitionsEncoded
                            newTerm.termTags = termTags
                            newTerm.sequenceNumber = sequence
                            
                            newTerm.dictionary = dic
                            
                            tI += 1
                        }
                    }
                    i += 1
                    
                    if tI % 20000 == 0 {
                        try! backgroundContext.save()
                        backgroundContext.reset()
                        try! CoreDataManager.shared.context.save()
                        CoreDataManager.shared.context.reset()
                        dic = backgroundContext.object(with: dicId) as! Dictionary
                    }
                    self.processingProgress += 1
                }
                try! backgroundContext.save()
                backgroundContext.reset()
                try! CoreDataManager.shared.context.save()
                CoreDataManager.shared.context.reset()
                
                DispatchQueue.main.async {
                    appManager.loadDictionaries()
                    self.processingProgress = self.processingProgressMax
                    self.processingMessage = "Dictionary processed."
                    self.processingStatus = ProcessingStatus.FINISHED
                }
            }
        }
    }
    
}

#Preview {
    DictionariesView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
        .environmentObject(AppManager())
        .onAppear(perform: {
            let dic = Dictionary(context: CoreDataManager.shared.context)
            dic.title = "Jitandex"
            dic.revision = "2025.01.12"
            dic.author = "Jitandex team"
        })
}
