//
//  AnkiView.swift
//  riidaa
//
//  Created by Pierre on 2025/11/10.
//

import SwiftUI

struct AnkiView: View {

    @EnvironmentObject var settings: SettingsModel

    var body: some View {
        Form {
            Section {
                Button(settings.ankiInfo == nil ? "Connect to AnkiMobile" : "Refresh from AnkiMobile") {
                    fetchAnkiDecks()
                }
            } footer: {
                Text("Opens AnkiMobile to read your profiles, decks and note types, then comes back here. Your choices below are kept.")
            }

            if let infos = settings.ankiInfo {
                Section("Destination") {
                    Picker("Profile", selection: $settings.ankiProfile) {
                        ForEach(infos.profiles) { profile in
                            Text(profile.name).tag(profile as AnkiInfo.Profile?)
                        }
                    }
                    Picker("Deck", selection: $settings.ankiDeck) {
                        ForEach(infos.decks) { deck in
                            Text(deck.name).tag(deck as AnkiInfo.Deck?)
                        }
                    }
                    Picker("Note type", selection: $settings.ankiNoteType) {
                        ForEach(infos.notetypes) { noteType in
                            Text(noteType.name).tag(noteType as AnkiInfo.NoteType?)
                        }
                    }
                }

                if let noteType = settings.ankiNoteType {
                    Section {
                        Button {
                            settings.autoMapAnkiFields(for: noteType)
                        } label: {
                            Label("Match fields automatically", systemImage: "wand.and.stars")
                        }
                        ForEach(AnkiFieldToken.allCases) { token in
                            Picker(token.label.capitalizedFirst, selection: settings.ankiFieldBinding(for: token)) {
                                Text("None").tag(nil as String?)
                                ForEach(noteType.fields) { field in
                                    Text(field.name).tag(field.name as String?)
                                }
                            }
                        }
                    } header: {
                        Text("Fields")
                    } footer: {
                        Text("Each note type keeps its own field choices.")
                    }

                    Section {
                        Toggle("Crop Picture to Bubble", isOn: settings.$ankiCropPicture)
                    } footer: {
                        Text("Sends the speech bubble you looked up and the art around it, rather than the whole page.")
                    }
                }
            }
        }
        .navigationTitle("Anki")
    }

    func fetchAnkiDecks() {
        let callback = "\(AnkiExport.callbackScheme)://anki-setup"
        var components = URLComponents(string: "anki://x-callback-url/infoForAdding")
        components?.queryItems = [URLQueryItem(name: "x-success", value: callback)]
        guard let url = components?.url else { return }
        UIApplication.shared.open(url, options: [:]) { opened in
            if !opened {
                settings.ankiSetupError = "AnkiMobile isn't installed. riidaa adds cards through it, so install it from the App Store first."
            }
        }
    }
}

private extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}

#Preview {
    NavigationStack {
        AnkiView()
            .environmentObject(SettingsModel())
    }
}
