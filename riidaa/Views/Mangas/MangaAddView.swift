//
//  MangaAddView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI
import Anilist

struct MangaAddView: View {
    
    @State var mangaTitle = ""
    @State var searchMangasList: [MangaResultModel] = []
    @Environment(\.dismiss) var dismiss
    @State var isSearching = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.managedObjectContext) var moc
    
    @EnvironmentObject var settings: SettingsModel
    
    
    var body: some View {
        VStack {
            TextField("Manga title...", text: $mangaTitle, onCommit: searchMangas)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    HStack {
                        Spacer()
                        Button(action: {
                            mangaTitle = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .scaleEffect(mangaTitle.isEmpty ? 0.5 : 1.2)
                                .opacity(mangaTitle.isEmpty ? 0 : 1)
                        }
                        .padding(.trailing, 8)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: mangaTitle)
                    }
                )
                .padding(.horizontal)
                .focused($isTextFieldFocused)
            
            ScrollView {
                if isSearching {
                    VStack {
                        ProgressView()
                            .controlSize(.regular)
                            .scaleEffect(2)
                        Text("Searching...")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                } else if searchMangasList.isEmpty && mangaTitle == "" {
                    VStack {
                        Image(systemName: "book.closed")
                        //                            .font(.largeTitle)
                            .scaleEffect(2)
                            .foregroundColor(.gray)
                        Text("Start searching for a manga")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    MangaAddResultView(searchMangasList: $searchMangasList, title: $mangaTitle)
                }
            }
            
        }
        .padding(.top, 20)
        .onAppear {
            isTextFieldFocused = true
        }
        .background(Color(.systemBackground))
    }
    
    func searchMangas() {
        self.isSearching = true

        if settings.adult {
            Network.shared.apollo.fetch(query: MangaSearchQueryAdultQuery(page: 1, search: .some(mangaTitle))) { result in
                switch result {
                case .success(let data):
                    if let medias = data.data?.page?.media {
                        let mangaIDs = MangaModel.fetchMangaAnilistIDs(moc: moc)
                        
                        self.searchMangasList = medias.compactMap({ media in
                            guard let id = media?.id, !mangaIDs.contains(Int64(id)) else {
                                return nil
                            }
                            return MangaResultModel(
                                id: Int64(id),
                                title: media?.title?.native ?? "",
                                coverImage: media?.coverImage?.large ?? ""
                            )
                        })
                    }
                case .failure(let err):
                    print("error: \(err)")
                }
                self.isSearching = false
            }
        } else {
            Network.shared.apollo.fetch(query: MangaSearchQuery(page: 1, search: .some(mangaTitle))) { result in
                switch result {
                case .success(let data):
                    if let medias = data.data?.page?.media {
                        let mangaIDs = MangaModel.fetchMangaAnilistIDs(moc: moc)
                        
                        self.searchMangasList = medias.compactMap({ media in
                            guard let id = media?.id, !mangaIDs.contains(Int64(id)) else {
                                return nil
                            }
                            return MangaResultModel(
                                id: Int64(id),
                                title: media?.title?.native ?? "",
                                coverImage: media?.coverImage?.large ?? ""
                            )
                        })
                    }
                case .failure(let err):
                    print("error: \(err)")
                }
                self.isSearching = false
            }
        }
    }
    
}

#Preview {
    MangaAddView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
}

