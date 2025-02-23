//
//  SettingsView.swift
//  redaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Dictionaries")) {
                    NavigationLink(destination: DictionariesView()) {
                        Text("Manage Dictionaries")
                    }
                }
                .listRowBackground(Color(.systemGray6))
                
                Section(header: Text("About")) {
//                    NavigationLink(destination: CreditsView()) {
//                        Text("Credits")
//                    }
//                    NavigationLink(destination: LicensesView()) {
//                        Text("Licenses")
//                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            .background(.background)
            .scrollContentBackground(.hidden)
        }
    }
    
}

#Preview {
    SettingsView()
}
