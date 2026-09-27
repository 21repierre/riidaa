//
//  DictionariesView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/21.
//

import SwiftUI
import os
import CoreData

struct DictionariesView: View {
    
    @EnvironmentObject var appManager: AppManager
    @State private var isPickingDictionary = false
    
    var body: some View {
        ScrollView {
            if let preparing = appManager.preparing {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(preparing.message)
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
            }

            if let purging = appManager.purging {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Clearing deleted dictionary")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(purging.fraction * 100))%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: purging.fraction)
                    Text("\((purging.total - purging.cleared).formatted()) entries left. Lookups keep working while this finishes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
            }

            ForEach(appManager.dictionaries) { dictionary in
                DictionaryView(dictionary: dictionary, onUpdate: updateDictionary)
            }
        }
        .navigationTitle("Dictionaries")
        .toolbar {
            Button(action: {
                self.isPickingDictionary = true
            }) {
                Image(systemName: "plus")
            }
        }
        .fileImporter(
            isPresented: $isPickingDictionary,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let files):
                importer.importArchives(at: files.sorted { $0.lastPathComponent < $1.lastPathComponent })
            case .failure(let error):
                Logger.dictionary.error("Could not open the picked dictionary: \(error.localizedDescription, privacy: .public)")
            }
        }
        .alert(
            "Dictionary error",
            isPresented: Binding(
                get: { appManager.lastError != nil },
                set: { shown in if !shown { appManager.lastError = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(appManager.lastError ?? "") }
        )
    }

    private var importer: DictionaryImporter { DictionaryImporter(appManager: appManager) }

    /// Downloads `downloadUrl` and re-imports it, replacing the existing copy.
    func updateDictionary(_ dictionary: DictionaryDB) {
        guard let downloadUrl = dictionary.downloadUrl, let url = URL(string: downloadUrl) else {
            appManager.report(error: "This dictionary does not publish a download link.")
            return
        }

        let replacing = dictionary.id
        appManager.setProgress(DictionaryProgress(message: "Downloading\u{2026}", value: 0, total: 0), for: replacing)

        Task {
            do {
                let (temporary, _) = try await URLSession.shared.download(from: url)
                // The importer keys off the extension, and a download has none.
                let archive = temporary.deletingPathExtension().appendingPathExtension("zip")
                try? FileManager.default.removeItem(at: archive)
                try FileManager.default.moveItem(at: temporary, to: archive)

                await MainActor.run {
                    self.importer.importArchive(at: archive, securityScoped: false, replacing: replacing)
                }
            } catch {
                appManager.setProgress(nil, for: replacing)
                appManager.report(error: "Download failed: \(error.localizedDescription)")
            }
        }
    }

}

#Preview {
    DictionariesView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
        .environmentObject(AppManager.shared)
        .onAppear(perform: {
            let dic = DictionaryDB(
                id: 1,
                revision: "2025.01.10.0",
                title: "Jitandex",
                sequenced: true,
                format: 3,
                author: "Stephen Kraus",
                isUpdatable: true,
                indexUrl: "https://jitendex.org/static/yomitan.json",
                downloadUrl: "https://github.com/stephenmk/stephenmk.github.io/releases/latest/download/jitendex-yomitan.zip",
                url: "https://jitendex.org",
                description: "Jitendex is updated with new content every week. Click the 'Check for Updates' button in the Yomitan 'Dictionaries' menu to upgrade to the latest version.\n\nIf Jitendex is useful for you, please consider giving the project a star on GitHub. You can also leave a tip on Ko-fi.\nVisit https://ko-fi.com/jitendex\n\nMany thanks to everyone who has helped to fund Jitendex.\n\n• epistularum\n• 昭玄大统\n• Maciej Jur\n• Ian Strandberg\n• Kip\n• Lanwara\n• Sky\n• Adam\n• Emanuel",
                attribution: "© CC BY-SA 4.0 Stephen Kraus 2023-2025\n\nYou are free to use, modify, and redistribute Jitendex files under the terms of the Creative Commons Attribution-ShareAlike License (V4.0)\n\nJitendex includes material from several copyrighted sources in compliance with the terms and conditions of those projects.\n\n• JMdict (EDICT, etc.) dictionary data is provided by the Electronic Dictionaries Research Group. Visit edrdg.org for more information.\n• Example sentences (Japanese and English) are provided by Tatoeba (https://tatoeba.org/). This data is licensed CC BY 2.0 FR.\n• Positional information for the furigana displayed in headwords is provided by the JmdictFurigana project. This data is distributed under a Creative Commons Attribution-ShareAlike License.",
                sourceLanguage: "ja",
                targetLanguage: "en",
                frequencyMode: nil
            )
            AppManager.shared.dictionaries.append(dic)
        })
}
