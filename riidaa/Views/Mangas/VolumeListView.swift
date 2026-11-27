//
//  VolumeListView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/16.
//

import SwiftUI
import os
import CoreData

struct VolumeListView: View {
    
    @ObservedObject var manga: MangaModel
    @ObservedObject private var importer = VolumeImporter.shared
    @State private var isPickingVolume = false

    @State private var readingVolume: MangaVolumeModel? = nil
    @State private var volumeToDelete: MangaVolumeModel? = nil
    
    @State private var editVolume: MangaVolumeModel? = nil
    @State private var editVolumeNumber: String = ""
    @State private var renameError: String? = nil

    private var importingHere: Bool {
        importer.mangaID == manga.id
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No volumes yet")
                .font(.headline)
            Text("Add a zip containing the .mokuro file mokuro produced, along with its folder of page images.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Link("How to OCR a volume with mokuro",
                 destination: URL(string: "https://github.com/kha-white/mokuro")!)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
        .padding(.top, 60)
    }

    @ViewBuilder
    private var importBanner: some View {
        if importingHere, let progress = importer.progress {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(progress.message)
                        .font(.subheadline)
                    Spacer()
                    if let fraction = progress.fraction {
                        Text("\(Int(fraction * 100))%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                if let fraction = progress.fraction {
                    ProgressView(value: fraction)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    var body: some View {
        ScrollView {
            importBanner
            if manga.volumes.count == 0 && !importingHere {
                emptyState
            }
            ForEach((manga.volumes.array as! [MangaVolumeModel]).sorted()) { volume in
                Button {
                    readingVolume = volume
                } label: {
                    VolumeComponent(volume: volume)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.vertical, 5)
                .contextMenu {
                    Button {
                        editVolume = volume
                        editVolumeNumber = String(volume.number)
                    } label: {
                        Label("Edit volume number", systemImage: "pencil")
                    }
                    .disabled(importingHere)
                    Button(role: .destructive) {
                        volumeToDelete = volume
                    } label: {
                        Label("Delete volume", systemImage: "trash")
                    }
                    .disabled(importingHere)
                }
            }
        }
        .navigationTitle(manga.title)
        .toolbar {
            Button {
                isPickingVolume = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add volumes")
            .disabled(importer.isImporting)
        }
        .fileImporter(
            isPresented: $isPickingVolume,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let files):
                importer.importVolumes(at: files, into: manga.id)
            case .failure(let error):
                Logger.library.error("Could not open the picked volumes: \(error.localizedDescription, privacy: .public)")
            }
        }
        .fullScreenCover(item: $readingVolume) { volume in
            MangaReader(volume: .constant(volume), currentPage: Int(volume.lastReadPage))
        }
        .confirmationDialog(
            "Delete volume \(volumeToDelete?.number ?? 0)?",
            isPresented: Binding(
                get: { volumeToDelete != nil },
                set: { shown in if !shown { volumeToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let volume = volumeToDelete {
                    CoreDataManager.shared.delete(volume, removing: MangaStorage.ownedVolumeDirectories(
                        of: manga, number: volume.number
                    ))
                }
                volumeToDelete = nil
            }
        } message: {
            Text("Its pages and reading progress are removed from this device.")
        }
        .alert(
            "Import problem",
            isPresented: Binding(
                get: { importer.errors[manga.id] != nil },
                set: { shown in if !shown { importer.errors[manga.id] = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(importer.errors[manga.id] ?? "") }
        )
        .alert("Edit volume", isPresented: .init(get: {editVolume != nil}, set: { v in
            if !v {
                editVolume = nil
            }
        }), actions: {
            TextField("New Volume Number", text: $editVolumeNumber)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {
                editVolume = nil
            }
            Button("OK") {
                if let newNumber = Int64(editVolumeNumber.trimmingCharacters(in: .whitespacesAndNewlines)),
                   newNumber > 0 {
                    do {
                        try editVolume?.changeVolumeNumber(newNumber: newNumber)
                    } catch {
                        let message = error.localizedDescription
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            renameError = message
                        }
                    }
                }
                editVolume = nil
            }
        })
        .alert(
            "Could not change the volume number",
            isPresented: Binding(
                get: { renameError != nil },
                set: { shown in if !shown { renameError = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(renameError ?? "") }
        )
    }
}

#Preview {
    VolumeListView(
        manga: CoreDataManager.sampleManga
    )
    .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
}
