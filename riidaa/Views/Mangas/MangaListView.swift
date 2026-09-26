//
//  MangaListView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI
import os
import PhotosUI
import CoreData

enum MangaSort: String, CaseIterable, Identifiable {
    case title = "Title"
    case lastRead = "Last read"
    case dateAdded = "Date added"

    var id: String { rawValue }
}

struct MangaListView: View {
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: MangaModel.entity(), sortDescriptors: []) var mangas: FetchedResults<MangaModel>
    
    @State var showMangaAddView: Bool = false
    
    @State var showRenameAlert: Bool = false
    @State var mangaEdit: MangaModel? = nil
    @State var newMangaName: String = ""

    @State private var searchText: String = ""
    @State private var sort: MangaSort = .title
    @State private var ascending: Bool = true
    @State private var lastReadByManga: [NSManagedObjectID: Date] = [:]

    @State private var coverTarget: MangaModel? = nil
    @State private var showCoverPicker: Bool = false
    @State private var pickedCover: PhotosPickerItem? = nil

    private var visibleMangas: [MangaModel] {
        let matches = searchText.isEmpty
            ? Array(mangas)
            : mangas.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        let sorted = matches.sorted { isOrderedBefore($0, $1) }
        return ascending ? sorted : sorted.reversed()
    }

    private func isOrderedBefore(_ a: MangaModel, _ b: MangaModel) -> Bool {
        switch sort {
        case .title:
            return a.title.localizedStandardCompare(b.title) == .orderedAscending
        case .lastRead:
            return byDate(lastReadByManga[a.objectID], lastReadByManga[b.objectID], a, b)
        case .dateAdded:
            return byDate(a.added_at as Date?, b.added_at as Date?, a, b)
        }
    }

    private func byDate(_ left: Date?, _ right: Date?, _ a: MangaModel, _ b: MangaModel) -> Bool {
        switch (left, right) {
        case let (l?, r?) where l != r: return l > r
        case (_?, nil): return true
        case (nil, _?): return false
        default: return a.title.localizedStandardCompare(b.title) == .orderedAscending
        }
    }

    /// Only runs for the sort that needs it
    private func refreshLastRead() {
        guard sort == .lastRead else { return }

        let request = NSFetchRequest<NSDictionary>(entityName: "MangaVolumeModel")
        request.predicate = NSPredicate(format: "last_read_at != nil")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["last_read_at", "manga"]

        let rows: [NSDictionary]
        do {
            rows = try moc.fetch(request)
        } catch {
            Logger.library.error("Failed to load last-read dates: \(error.localizedDescription, privacy: .public)")
            return
        }
        var latest: [NSManagedObjectID: Date] = [:]
        for row in rows {
            guard let date = row["last_read_at"] as? Date,
                  let manga = row["manga"] as? NSManagedObjectID else { continue }
            if let seen = latest[manga], seen >= date { continue }
            latest[manga] = date
        }
        lastReadByManga = latest
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if visibleMangas.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(visibleMangas) { manga in
                            MangaCover(
                                manga: manga,
                                showRenameAlert: $showRenameAlert,
                                mangaEdit: $mangaEdit,
                                newMangaName: $newMangaName,
                                coverTarget: $coverTarget,
                                showCoverPicker: $showCoverPicker
                            )
                        }
                    }.padding()
                }
            }.navigationTitle("Mangas")
                .searchable(text: $searchText, prompt: "Search your library")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Sort by", selection: $sort) {
                                ForEach(MangaSort.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            Divider()
                            Button {
                                ascending.toggle()
                            } label: {
                                Label(
                                    ascending ? "Ascending" : "Descending",
                                    systemImage: ascending ? "arrow.up" : "arrow.down"
                                )
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showMangaAddView = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showMangaAddView) {
                    MangaAddView()
                }
                .onAppear { refreshLastRead() }
                .onChange(of: sort) { _ in refreshLastRead() }
        }
        .alert("Rename manga", isPresented: $showRenameAlert, actions: {
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
        .photosPicker(isPresented: $showCoverPicker, selection: $pickedCover, matching: .images)
        .onChange(of: pickedCover) { item in
            guard let item = item, let manga = coverTarget else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    manga.setCover(image: image)
                    CoreDataManager.shared.saveContext()
                }
                pickedCover = nil
                coverTarget = nil
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: searchText.isEmpty ? "books.vertical" : "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "No manga yet" : "No manga matching “\(searchText)”")
                .font(.headline)
            if searchText.isEmpty {
                Text("Tap + to search for a title and add it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
    
}

struct MangaCover : View {
    
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var manga: MangaModel
    
    @Binding var showRenameAlert: Bool
    @Binding var mangaEdit: MangaModel?
    @Binding var newMangaName: String
    @Binding var coverTarget: MangaModel?
    @Binding var showCoverPicker: Bool
    
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
                    VStack(spacing: 6) {
                        Image(systemName: "book.closed")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No cover")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 110, height: 170)
                    .background(Color(.secondarySystemBackground))
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
                Button {
                    showRenameAlert = true
                    mangaEdit = manga
                    newMangaName = manga.title
                } label: {
                    Label("Rename manga", systemImage: "pencil")
                }
                Button {
                    coverTarget = manga
                    showCoverPicker = true
                } label: {
                    Label("Change cover", systemImage: "photo")
                }
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
            print(CoreDataManager.sampleManga)
        })
}
