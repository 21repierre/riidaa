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
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
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

//#Preview {
//    MangaListView()
//}

struct MangaCover : View {
    
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var manga: MangaModel
    
    var body: some View {
        NavigationLink(destination: VolumeListView(manga: manga)) {
            VStack(alignment: .leading, spacing: 0) {
                if let image = manga.getCover() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame( height: 170)
                        .clipped()
                    
                        .frame(width: 110, height: 170)
                        .cornerRadius(10)
                } else {
                    Text("failed to load image")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                        .padding(.top, 5)
                        .frame(width: 110, height: 170)
                        .cornerRadius(10)
                }
                
                
                
                VStack() {
                    Text(manga.title)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                    Spacer()
                }
                .frame(height: 49)
                    .padding(.top, 7)
                    .padding([.leading, .trailing], 1)
            }
            .frame(height: 226)
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

#Preview {
    
    MangaListView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
        .onAppear(perform: {
//            let m1 = MangaModel(context: CoreDataManager.shared.container.viewContext)
//            m1.title = "A very long title that should not fit"
//            m1.id = 1
            print(CoreDataManager.sampleManga)
        })
    
}
