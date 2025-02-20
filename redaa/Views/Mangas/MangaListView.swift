//
//  MangaListView.swift
//  redaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI

struct MangaListView: View {
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: MangaModel.entity(), sortDescriptors: []) var mangas: FetchedResults<MangaModel>
    
    @State var showMangaAddView: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(mangas) { manga in
                        MangaCover(manga: manga)
                    }
                }.padding()
            }.navigationTitle("Mangas")
                .toolbar {
                    Button(action: {
                        showMangaAddView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                .sheet(isPresented: $showMangaAddView) {
                    MangaAddView()
                }
        }
    }
    
}

#Preview {
    MangaListView()
}

struct MangaCover : View {
    
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var manga: MangaModel
    
    var body: some View {
        NavigationLink(destination: VolumeListView(manga: manga)) {
            VStack {
                if let image = manga.getCover() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("failed to load image")
                }
                Text(manga.title).font(.caption)
            }
            .contextMenu {
                Button(role: .destructive) {
                    moc.delete(manga)
                    CoreDataManager.shared.saveContext()
                } label: {
                    Label("Delete manga", systemImage: "trash")
                }
            }
        }
    }
    
}
