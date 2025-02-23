//
//  MangaAddView.swift
//  redaa
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
    
    
    var body: some View {
        VStack {
            TextField("Manga title...", text: $mangaTitle, onCommit: searchMangas)
                .padding(10)
                .background(Color(.systemGray6))
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
                } else if searchMangasList.isEmpty {
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
                    MangaAddResultView(searchMangasList: $searchMangasList)
                }
            }
            
        }
        //        .padding(5)
        .padding(.top, 20)
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    func searchMangas() {
        self.isSearching = true
        Network.shared.apollo.fetch(query: MangaSearchQuery(page: 1, search: .some(mangaTitle))) { result in
            switch result {
            case .success(let data):
                if let medias = data.data?.page?.media {
                    let mangaIDs = MangaModel.fetchMangaIDs(moc: moc)
                    
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

#Preview {
    MangaAddView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}

