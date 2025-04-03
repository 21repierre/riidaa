//
//  DictionaryView.swift
//  redaa
//
//  Created by Pierre on 2025/03/01.
//

import SwiftUI

struct DictionaryView: View {
    
    @ObservedObject var dictionary: Dictionary
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
            case UpdateState.unkown :
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
                    moc.delete(dictionary)
                    let idx = appManager.dictionaries.firstIndex(of: dictionary)!
                    appManager.dictionaries.remove(at: idx)
                    CoreDataManager.shared.saveContext()
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
        .environmentObject(AppManager())
        .onAppear(perform: {
            let dic = Dictionary(context: CoreDataManager.shared.context)
            dic.title = "Jitandex"
            dic.revision = "2025.01.12"
            dic.author = "Jitandex team."
        })
}
