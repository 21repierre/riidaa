//
//  SettingsView.swift
//  riidaa
//
//  Created by Pierre on 2025/02/12.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var settings: SettingsModel
    @Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Reader")) {
                    NavigationLink(destination: DictionariesView()) {
                        Text("Manage Dictionaries")
                    }
                    NavigationLink(destination: ReaderSettings()) {
                        Text("Reader Settings")
                    }
                    Toggle("Enable adult content", isOn: settings.$adult)
                }
                .listRowBackground(Color(.systemGray6))
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("You can contact me on:")

                        HStack(spacing: 10) {
                            Image(systemName: "link")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.blue)
                            Text("GitHub")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                        .onTapGesture {
                            openURL(URL(string: "https://github.com/21repierre/riidaa")!)
                        }

                        HStack(spacing: 10) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.blue)
                            Text("Discord")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                        .onTapGesture {
                            openURL(URL(string: "https://discordapp.com/users/250301061435228160")!)
                        }

                        HStack(spacing: 10) {
                            Image(systemName: "envelope")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.blue)
                            Text("Email")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                        .onTapGesture {
                            openURL(URL(string: "mailto:riidaa@repierre.dev")!)
                        }
                    }


                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This app’s reader feature is inspired by the open-source project Yomitan.")
                            .font(.body)
                        
                        Link("View Yomitan on GitHub", destination: URL(string: "https://github.com/yomidevs/yomitan")!)
                    }
                    .padding(.vertical, 4)
                    
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            .background(.background)
            .scrollContentBackground(.hidden)
        }
    }
    
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
        .environmentObject(AppManager.shared)
        .environmentObject(SettingsModel())
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
