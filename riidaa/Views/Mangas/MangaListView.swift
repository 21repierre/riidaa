//
//  MangaListView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI

struct MangaListView: View {
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: MangaModel.entity(), sortDescriptors: []) var mangas: FetchedResults<MangaModel>
    
    @State var showMangaAddView: Bool = false
    
    @State var showRenameAlert: Bool = false
    @State var mangaEdit: MangaModel? = nil
    @State var newMangaName: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(mangas) { manga in
                        MangaCover(
                            manga: manga,
                            showRenameAlert: $showRenameAlert,
                            mangaEdit: $mangaEdit,
                            newMangaName: $newMangaName
                        )
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
        .alert("test", isPresented: $showRenameAlert, actions: {
            TextField("New manga name", text: $newMangaName)
            Button("Cancel", role: .cancel) {}
            Button {
                let trimmed = newMangaName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    mangaEdit?.title = trimmed
                    CoreDataManager.shared.saveContext()
                }
            } label: {
                Text("Save")
            }
        })
    }
    
}

struct MangaCover : View {
    
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var manga: MangaModel
    
    @Binding var showRenameAlert: Bool
    @Binding var mangaEdit: MangaModel?
    @Binding var newMangaName: String
    
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
                Button {
                    showRenameAlert = true
                    mangaEdit = manga
                    newMangaName = manga.title
                } label: {
                    Label("Rename manga", systemImage: "pencil")
                }
            }
        }
    }
    
}

#Preview {
    MangaListView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
        .onAppear(perform: {
            print(CoreDataManager.sampleManga)
        })
}
