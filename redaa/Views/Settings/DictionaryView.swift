//
//  DictionaryView.swift
//  redaa
//
//  Created by Pierre on 2025/03/01.
//

import SwiftUI
import redaaDic

struct DictionaryView: View {
    
    @ObservedObject var dictionary: RedaaDictionary
    
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
    }
    
}

//#Preview {
//    DictionaryView()
//}
