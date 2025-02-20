//
//  MangaAddView.swift
//  redaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI
import Anilist
import CoreData

struct MangaAddView: View {
    
    @Environment(\.managedObjectContext) var moc
    @State var mangaTitle = ""
    @State var searchMangasList: [MangaResultModel] = []
    @Environment(\.dismiss) var dismiss
//    @EnvironmentObject var mangas: MangaList
    @State var isSearching = false
    
    var body: some View {
        VStack {
            TextField("Manga title...", text: $mangaTitle, onCommit: searchMangas)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(5)
            ScrollView {
                if isSearching {
                    ProgressView()
                        .controlSize(.large)
                } else if searchMangasList.isEmpty {
                    Text("Search your manga")
                        .foregroundColor(Color(.systemGray))
                } else {
                    MangaSearhResultView(searchMangasList: $searchMangasList)
                }
            }
            
        }.padding(10)
    }
    
    func searchMangas() {
        self.isSearching = true
        Network.shared.apollo.fetch(query: MangaSearchQuery(page: 1, search: .some(mangaTitle))) { result in
            switch result {
            case .success(let data):
                if let medias = data.data?.page?.media {
                    self.searchMangasList = []
                    for media in medias {
                        let manga = MangaResultModel(
                            id: Int64(media?.id ?? 0),
                            title: media?.title?.native ?? "",
                            coverImage: media?.coverImage?.large ?? ""
                        )
                        self.searchMangasList.append(manga)
                    }
                }
            case .failure(let err):
                print("error: \(err)")
            }
        }
        self.isSearching = false
    }
    
}

#Preview {
    MangaAddView()
}

class MangaResultModel : Identifiable {
    var id: Int64
    var title: String
    var coverImage: String
    
    init(id: Int64, title: String, coverImage: String) {
        self.id = id
        self.title = title
        self.coverImage = coverImage
    }
}

struct MangaSearhResultView : View {
    
    @Binding var searchMangasList: [MangaResultModel]
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible())], spacing: 16) {
            ForEach($searchMangasList) { manga in
                Button(action: {
                    let newManga = MangaModel(
                        context: self.moc
                    )
                    newManga.id = manga.id
                    newManga.title = manga.title.wrappedValue
                    newManga.downloadCover(url: manga.wrappedValue.coverImage, completion: { result in
                        if result {
                            CoreDataManager.shared.saveContext()
                            dismiss()
                        }
                    })
                }) {
                    VStack {
                        AsyncImage(url: URL(string: manga.coverImage.wrappedValue)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable()
                                    .scaledToFit()
                            case .failure(let error):
                                Text("Failed to load image: \(error)")
                            }
                        }
                        Text(manga.wrappedValue.title).font(.caption)
                    }
                }
            }
        }.padding()
    }
    
}
