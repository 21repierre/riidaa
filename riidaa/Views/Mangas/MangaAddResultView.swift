//
//  MangaAddResultView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/22.
//

import SwiftUI
import PhotosUI

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
    @Binding var title: String
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    
    @State var customImage: PhotosPickerItem? = nil
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                Button {
                    createManga(cover: nil)
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Image(systemName: "plus")
                            .scaleEffect(2)
                            .foregroundColor(.gray)
                            .frame(width: 110, height: 170)
                            .background(Color(.systemGray3))
                            .cornerRadius(10)

                        VStack() {
                            Text("Create without cover")
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
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                PhotosPicker(
                    selection: $customImage,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(alignment: .leading,spacing: 0) {
                        Image(systemName: "photo")
                            .scaleEffect(2)
                            .foregroundColor(.gray)
                            .frame(width: 110, height: 170)
                            .background(Color(.systemGray3))
                            .cornerRadius(10)
                        
                        
                        VStack() {
                            Text("Create with a photo")
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
                }
                ForEach($searchMangasList) { manga in
                    Button(action: {
                        let newManga = MangaModel(
                            context: self.moc
                        )
                        newManga.id = UUID()
                        newManga.added_at = NSDate()
                        newManga.anilist_id = manga.id as NSNumber
                        newManga.title = manga.title.wrappedValue
                        newManga.downloadCover(url: manga.wrappedValue.coverImage, completion: { _ in
                            CoreDataManager.shared.saveContext()
                            dismiss()
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
        .onChange(of: customImage) { value in
            Task {
                if let value = value, let data = try? await value.loadTransferable(type: Data.self) {
                    createManga(cover: data)
                }
            }
        }
    }

    /// Creates a manga from the typed title. A nil cover shows a placeholder image
    private func createManga(cover: Data?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newManga = MangaModel(context: self.moc)
        newManga.id = UUID()
                        newManga.added_at = NSDate()
        newManga.title = trimmed
        newManga.cover = cover
        CoreDataManager.shared.saveContext()
        dismiss()
    }
    
    
    
    
    private func addManga(manga: MangaResultModel) {
        let newManga = MangaModel(context: self.moc)
        newManga.id = UUID()
                        newManga.added_at = NSDate()
        newManga.anilist_id = manga.id as NSNumber
        newManga.title = manga.title
        newManga.downloadCover(url: manga.coverImage) { _ in
            CoreDataManager.shared.saveContext()
            dismiss()
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
    ]), title: .constant("test"))
    .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
    
}
