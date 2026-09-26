//
//  ContentView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI

struct HomeView: View {

    var body: some View {
        TabView {
            MangaListView()
                .tabItem {
                    Label("List", systemImage: "book")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }

}

#Preview {
    HomeView()
}
