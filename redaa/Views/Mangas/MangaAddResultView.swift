//
//  MangaAddResultView.swift
//  redaa
//
//  Created by Pierre on 2025/02/22.
//

import SwiftUI

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

struct MangaAddResultView : View {
    
    @Binding var searchMangasList: [MangaResultModel]
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
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
                        VStack(alignment: .leading,spacing: 0) {
                            AsyncImage(url: URL(string: manga.coverImage.wrappedValue)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame( height: 170)
                                        .clipped()
                                case .failure(let error):
                                    Text("Failed to load image: \(error)")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                @unknown default:
                                    Text("Failed to load image")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                            .frame(width: 110, height: 170)
                            .cornerRadius(10)
                            
                            VStack() {
                                Text(manga.wrappedValue.title)
                                    .font(.callout)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                Spacer()
                            }
                            .frame(height: 49)
                                .padding(.top, 7)
                                .padding([.leading, .trailing], 1)
//                                .border(.green)
                        }
                        .frame(height: 226)
//                        .border(.blue)
                    }
                }
            }.padding()
        }
    }
    
    
    
    
    private func addManga(manga: MangaResultModel) {
        let newManga = MangaModel(context: self.moc)
        newManga.id = manga.id
        newManga.title = manga.title
        newManga.downloadCover(url: manga.coverImage) { result in
            if result {
                CoreDataManager.shared.saveContext()
                dismiss()
            }
        }
    }
    
}

#Preview {
    MangaAddResultView(searchMangasList: .constant([
        MangaResultModel(id: 30013, title: "ONE PIECE", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx30013-ulXvn0lzWvsz.jpg"),
        MangaResultModel(id: 30014, title: "わんぴいす", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx95552-UbNjuCvgmBBM.jpg"),
        MangaResultModel(id: 30015, title: "ONE PIECE episode A", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx117802-CsCjUyuG4lSB.jpg"),
        MangaResultModel(id: 30016, title: "This is a very long title that should be cut by Swift", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/nx102533-YLT9eI1BH2a1.jpg2"),
        MangaResultModel(id: 3001, title: "ONE PIECE", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx30013-ulXvn0lzWvsz.jpg"),
        MangaResultModel(id: 3014, title: "わんぴいす", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx95552-UbNjuCvgmBBM.jpg"),
        MangaResultModel(id: 3005, title: "ONE PIECE episode A", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx117802-CsCjUyuG4lSB.jpg"),
        MangaResultModel(id: 300132, title: "ONE PIECE", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx30013-ulXvn0lzWvsz.jpg"),
        MangaResultModel(id: 302014, title: "わんぴいす", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx95552-UbNjuCvgmBBM.jpg"),
        MangaResultModel(id: 300315, title: "ONE PIECE episode A", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx117802-CsCjUyuG4lSB.jpg"),
        MangaResultModel(id: 350016, title: "This is a very long title that should be cut by Swift", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/nx102533-YLT9eI1BH2a1.jpg2"),
        MangaResultModel(id: 30101, title: "ONE PIECE", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx30013-ulXvn0lzWvsz.jpg"),
        MangaResultModel(id: 36014, title: "わんぴいす", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx95552-UbNjuCvgmBBM.jpg"),
        MangaResultModel(id: 39005, title: "ONE PIECE episode A", coverImage: "https://s4.anilist.co/file/anilistcdn/media/manga/cover/medium/bx117802-CsCjUyuG4lSB.jpg"),
    ]))
    .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
    
}
