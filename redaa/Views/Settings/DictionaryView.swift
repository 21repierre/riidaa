//
//  DictionaryView.swift
//  redaa
//
//  Created by Pierre on 2025/03/01.
//

import SwiftUI

struct DictionaryView: View {
    
    @ObservedObject var dictionary: DictionaryDB
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var appManager: AppManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(dictionary.title).font(.headline)
                Text("Version: \(dictionary.revision)").font(.subheadline)
            }
            Spacer()
            switch dictionary.hasUpdate {
            case UpdateState.updateAvailable:
                Button("Update") {
                    print("Updating \(dictionary.title)")
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(.blue)
            case UpdateState.unknown :
                ProgressView()
                    .padding()
            case UpdateState.upToDate:
                Text("Up to date")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
//        .onAppear(perform: {
//            DispatchQueue.global(qos: .userInitiated).async {
//                try! await dictionary.fetchUpdate()
//                print(dictionary.hasUpdate)
//            }
//        })
        .task {
            await dictionary.fetchUpdate()
        }
        .contextMenu {
            Button(role: .destructive) {
                autoreleasepool {
//                    moc.delete(dictionary)
                    try? SQLiteManager.shared.deleteDictionary(dictionaryId: dictionary.id)
                    
                    let idx = appManager.dictionaries.firstIndex(of: dictionary)!
                    appManager.dictionaries.remove(at: idx)
//                    CoreDataManager.shared.saveContext()
                }
            } label: {
                Label("Delete dictionary", systemImage: "trash")
            }
        }
    }
    
}

//#Preview {
//    DictionaryView()
//}
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
