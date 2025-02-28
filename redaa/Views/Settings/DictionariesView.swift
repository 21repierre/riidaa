//
//  DictionariesView.swift
//  redaa
//
//  Created by Pierre on 2025/02/21.
//

import SwiftUI
import redaaDic

struct DictionariesView: View {
    
    @EnvironmentObject var appManager: AppManager
    @State private var isPickingDictionary = false
    @State private var processingStatus = ProcessingStatus.NOTHING
    @State private var processingMessage: String = "Processing dictionary..."
    @State private var processingProgress: Progress = Progress()
    
    private var dismissDisabled: Bool {
        return processingStatus == ProcessingStatus.STARTED
    }
    
    var body: some View {
        ScrollView {
            ForEach($appManager.dictionaries) { dictionary in
                let dictionary = dictionary.wrappedValue
                if let redaaDic = dictionary.dictionary {
                    DictionaryView(dictionary: redaaDic)
                }
                else {
                    Text("failed to load \(dictionary.name)")
                }
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
            self.processingProgress = Progress()
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
                        CircularProgressView(progress: processingProgress.fractionCompleted)
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
            var newDic: Dictionary? = nil
            do {
                let fileManager = FileManager.default
                let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("dictionaries")
                let dicDirectory = documents.appendingPathComponent(UUID().uuidString)
                try fileManager.createDirectory(at: dicDirectory, withIntermediateDirectories: true)
                
                try fileManager.unzipItem(at: path, to: dicDirectory)
                
                let tmpDic = try RedaaDictionary.loadFromJson(path: dicDirectory.appendingPathComponent("index.json"))
                
                newDic = Dictionary(context: CoreDataManager.shared.context)
                newDic?.name = tmpDic.title
                newDic?.path = dicDirectory.lastPathComponent
                
                try newDic?.loadDictionary()
                self.processingMessage = "Dictionary processed."
            } catch {
                self.processingStatus = ProcessingStatus.ERROR
                self.processingMessage = error.localizedDescription
            }
            
            DispatchQueue.main.async {
                if self.processingStatus != ProcessingStatus.ERROR {
                    CoreDataManager.shared.saveContext()
                    appManager.dictionaries.append(newDic!)
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
            dic.name = "Jitandex"
            dic.path = "/Users/repierre/Documents/mangas/Mokuro/YamadaKun To 7Nin No Majo/jitendex-yomitan"
        })
}
