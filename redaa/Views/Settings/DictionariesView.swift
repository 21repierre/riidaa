//
//  DictionariesView.swift
//  redaa
//
//  Created by Pierre on 2025/02/21.
//

import SwiftUI

class Dic: Identifiable {
    public var title: String
    public var revision: String
    public var hasUpdate: Bool
    
    init(title: String, revision: String, hasUpdate: Bool) {
        self.title = title
        self.revision = revision
        self.hasUpdate = hasUpdate
    }
    
}

struct DictionariesView: View {
    
    @State var dictionaries: [Dic]
    
    init() {
        let d1 = Dic(title: "Jitandex", revision: "2024.02.2", hasUpdate: true)
        self.dictionaries = [
            d1,
            d1,
            d1
        ]
    }
    
    var body: some View {
        List(dictionaries) { dictionary in
            HStack {
                VStack(alignment: .leading) {
                    Text(dictionary.title).font(.headline)
                    Text("Version: \(dictionary.revision)").font(.subheadline)
                }
                Spacer()
                if dictionary.hasUpdate {
                    Button("Update") {
                        print("Updating \(dictionary.title)")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    DictionariesView()
}
