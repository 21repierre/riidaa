//
//  DictionariesView.swift
//  redaa
//
//  Created by Pierre on 2025/02/21.
//

import SwiftUI
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
                DictionaryView(dictionary: dictionary.wrappedValue)
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
                let sequenced = dicJson["sequenced"] as? Bool
                let format = dicJson["format"] as? Int
                let author = dicJson["author"] as? String
                let isUpdatable = dicJson["isUpdatable"] as? Bool
                let indexUrl = dicJson["indexUrl"] as? String
                let downloadUrl = dicJson["downloadUrl"] as? String
                let url = dicJson["url"] as? String
                let description = dicJson["description"] as? String
                let attribution = dicJson["attribution"] as? String
                let sourceLanguage = dicJson["sourceLanguage"] as? String
                let targetLanguage = dicJson["targetLanguage"] as? String
                let frequencyMode = dicJson["frequencyMode"] as? String
                
                guard let dictionary = SQLiteManager.shared.insertDictionary(revision: revision, title: title, sequenced: sequenced ?? false, format: format ?? 3, author: author, isUpdatable: isUpdatable ?? false, indexUrl: indexUrl, downloadUrl: downloadUrl, url: url, description: description, attribution: attribution, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, frequencyMode: frequencyMode) else {
                    throw NSError(domain: "DictionaryImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error saving dictionary"])
                }
                
                
                DispatchQueue.main.async {
                    self.processingProgress += 1
                }
                
                
                var i = 1
                while true {
                    
                    let filename = "term_bank_\(i).json"
                    let filepath = dicDirectory.appending(component: filename)
                    
                    guard let fileContent = try? Data(contentsOf: filepath) else {
                        break
                    }
                    try autoreleasepool {
                        let termsJson = try? JSONSerialization.jsonObject(with: fileContent)
                        guard let termsJson = termsJson as? [[Any]] else {
                            throw NSError(domain: "DictionaryImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error decoding terms"])
                        }
                        let insertTerms: [TermInsertion] = termsJson.compactMap({ t in
                            guard let term = t[0] as? String,
                                  let reading = t[1] as? String,
                                  let wordTypesJson = t[3] as? String,
                                  let score = t[4] as? Int64,
                                  let definitions = t[5] as? [Any],
                                  let sequence  = t[6] as? Int64,
                                  let termTagsJson = t[7]  as? String
                            else {
                                return nil
                            }
                            guard let definitionsEncoded = try? JSONSerialization.data(withJSONObject: definitions, options: []) else {
                                return nil
                            }
                            let definitionTags = t[2] as? String ?? ""
                            return TermInsertion(term: term, reading: reading, definitionTags: definitionTags, wordTypes: wordTypesJson, score: score, definitions: definitionsEncoded, sequence: sequence, termTags: termTagsJson, dictionaryId: dictionary.id)
                        })
                        guard SQLiteManager.shared.insertTerms(termsInsert: insertTerms) != nil else {
                            throw NSError(domain: "DictionaryImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error saving terms"])
                        }
                        
                        i += 1
                        
                        DispatchQueue.main.async {
                            self.processingProgress += 1
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    appManager.dictionaries.append(dictionary)
                    self.processingProgress = self.processingProgressMax
                    self.processingMessage = "Dictionary processed."
                    self.processingStatus = ProcessingStatus.FINISHED
                }
            } catch {
                self.processingStatus = ProcessingStatus.ERROR
                self.processingMessage = error.localizedDescription
                return
            }
        }
    }
    
}

#Preview {
    DictionariesView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
        .environmentObject(AppManager.shared)
        .onAppear(perform: {
            let dic = DictionaryDB(
                id: 1,
                revision: "2025.01.10.0",
                title: "Jitandex",
                sequenced: true,
                format: 3,
                author: "Stephen Kraus",
                isUpdatable: true,
                indexUrl: "https://jitendex.org/static/yomitan.json",
                downloadUrl: "https://github.com/stephenmk/stephenmk.github.io/releases/latest/download/jitendex-yomitan.zip",
                url: "https://jitendex.org",
                description: "Jitendex is updated with new content every week. Click the 'Check for Updates' button in the Yomitan 'Dictionaries' menu to upgrade to the latest version.\n\nIf Jitendex is useful for you, please consider giving the project a star on GitHub. You can also leave a tip on Ko-fi.\nVisit https://ko-fi.com/jitendex\n\nMany thanks to everyone who has helped to fund Jitendex.\n\n• epistularum\n• 昭玄大统\n• Maciej Jur\n• Ian Strandberg\n• Kip\n• Lanwara\n• Sky\n• Adam\n• Emanuel",
                attribution: "© CC BY-SA 4.0 Stephen Kraus 2023-2025\n\nYou are free to use, modify, and redistribute Jitendex files under the terms of the Creative Commons Attribution-ShareAlike License (V4.0)\n\nJitendex includes material from several copyrighted sources in compliance with the terms and conditions of those projects.\n\n• JMdict (EDICT, etc.) dictionary data is provided by the Electronic Dictionaries Research Group. Visit edrdg.org for more information.\n• Example sentences (Japanese and English) are provided by Tatoeba (https://tatoeba.org/). This data is licensed CC BY 2.0 FR.\n• Positional information for the furigana displayed in headwords is provided by the JmdictFurigana project. This data is distributed under a Creative Commons Attribution-ShareAlike License.",
                sourceLanguage: "ja",
                targetLanguage: "en",
                frequencyMode: nil
            )
            AppManager.shared.dictionaries.append(dic)
        })
}
