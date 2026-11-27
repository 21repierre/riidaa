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
    @State private var adding = false
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                Button {
                    createManga(cover: nil)
                } label: {
                    card(title: "Create without cover") {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                PhotosPicker(
                    selection: $customImage,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    card(title: "Create with a photo") {
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                ForEach(searchMangasList) { manga in
                    Button {
                        add(manga)
                    } label: {
                        card(title: manga.title) {
                            AsyncImage(url: URL(string: manga.coverImage)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Image(systemName: "book.closed")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                default:
                                    ProgressView()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .disabled(adding)
        }
        .overlay {
            if adding {
                ProgressView("Adding\u{2026}")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .interactiveDismissDisabled(adding)
        .onChange(of: customImage) { value in
            guard let value = value else { return }
            customImage = nil
            Task {
                if let data = try? await value.loadTransferable(type: Data.self) {
                    createManga(cover: data)
                }
            }
        }
    }

    private func card<Cover: View>(title: String, @ViewBuilder cover: () -> Cover) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Color(.systemGray5)
                .aspectRatio(110.0 / 170.0, contentMode: .fit)
                .overlay { cover() }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(title)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(2, reservesSpace: true)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private func add(_ manga: MangaResultModel) {
        guard !adding else { return }
        adding = true
        let newManga = MangaModel(context: self.moc)
        newManga.id = UUID()
        newManga.added_at = NSDate()
        newManga.anilist_id = manga.id as NSNumber
        newManga.title = manga.title
        newManga.downloadCover(url: manga.coverImage) { _ in
            CoreDataManager.shared.saveContext()
            adding = false
            dismiss()
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
