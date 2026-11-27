//
//  SettingsModel.swift
//  riidaa
//
//  Created by Pierre on 2025/04/15.
//

import Foundation
import SwiftUI
import os

class SettingsModel: ObservableObject {
    
    @AppStorage("backgroundColorEnabled") var backgroundColorEnabled = false
    @AppStorage("backgroundColorRed") private var backgroundColorRed = 1.0
    @AppStorage("backgroundColorGreen") private var backgroundColorGreen = 0.0
    @AppStorage("backgroundColorBlue") private var backgroundColorBlue = 0.0
    @AppStorage("backgroundColorAlpha") private var backgroundColorAlpha = 0.2
    
    @AppStorage("borderColorEnabled") var borderColorEnabled = false
    @AppStorage("borderColorRed") private var borderColorRed = 1.0
    @AppStorage("borderColorGreen") private var borderColorGreen = 0.0
    @AppStorage("borderColorBlue") private var borderColorBlue = 0.0
    @AppStorage("borderColorAlpha") private var borderColorAlpha = 1.0
    @AppStorage("borderSize") var borderSize = 1.0
    
    @AppStorage("padding") var padding = 0.0
    @AppStorage("isLTR") var isLTR = false
    @AppStorage("coverAlone") var coverAlone = true
    @AppStorage("ankiCropPicture") var ankiCropPicture = false

    /// Word audio comes from a third-party service (see `WordAudio`), so it can be turned off.
    @AppStorage("wordAudioEnabled") var wordAudioEnabled = true
    @AppStorage("preloadWordAudio") var preloadWordAudio = false
    
    @Published var ankiInfo: AnkiInfo? {
        didSet { save(ankiInfo, forKey: "ankiInfo") }
    }
    @Published var ankiProfile: AnkiInfo.Profile? {
        didSet { save(ankiProfile, forKey: "ankiProfile") }
    }
    @Published var ankiDeck: AnkiInfo.Deck? {
        didSet { save(ankiDeck, forKey: "ankiDeck") }
    }
    @Published var ankiNoteType: AnkiInfo.NoteType? {
        didSet {
            save(ankiNoteType, forKey: "ankiNoteType")
            if let noteType = ankiNoteType, ankiFieldsByNoteType[noteType.name] == nil {
                adoptAnkiFields(for: noteType)
            }
        }
    }
    @Published var ankiFieldsByNoteType: [String: [String: String]] = [:] {
        didSet { save(ankiFieldsByNoteType, forKey: "ankiFieldsByNoteType") }
    }
    @Published var ankiSetupError: String?
    private var legacyAnkiFields: [String: String]?

    var ankiFields: [String: String] {
        get { ankiNoteType.flatMap { ankiFieldsByNoteType[$0.name] } ?? [:] }
        set {
            guard let name = ankiNoteType?.name else { return }
            ankiFieldsByNoteType[name] = newValue
        }
    }

#if APPSTORE
    var adult = false
#else
    @AppStorage("adult") var adult = false
#endif
    
    var backgroundColor: Binding<Color> {
        Binding<Color>(
            get: {
                Color(red: self.backgroundColorRed, green: self.backgroundColorGreen, blue: self.backgroundColorBlue, opacity: self.backgroundColorAlpha)
            },
            set: { newColor in
                let uiColor = UIColor(newColor)
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                self.backgroundColorRed = Double(red)
                self.backgroundColorGreen = Double(green)
                self.backgroundColorBlue = Double(blue)
                self.backgroundColorAlpha = Double(alpha)
            }
        )
    }
    
    var borderColor: Binding<Color> {
        Binding<Color>(
            get: {
                Color(red: self.borderColorRed, green: self.borderColorGreen, blue: self.borderColorBlue, opacity: self.borderColorAlpha)
            },
            set: { newColor in
                let uiColor = UIColor(newColor)
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                self.borderColorRed = Double(red)
                self.borderColorGreen = Double(green)
                self.borderColorBlue = Double(blue)
                self.borderColorAlpha = Double(alpha)
            }
        )
    }
    
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.ankiInfo = load(forKey: "ankiInfo")
        self.ankiProfile = load(forKey: "ankiProfile")
        self.ankiDeck = load(forKey: "ankiDeck")
        self.ankiNoteType = load(forKey: "ankiNoteType")
        self.ankiFieldsByNoteType = load(forKey: "ankiFieldsByNoteType") ?? [:]
        if ankiFieldsByNoteType.isEmpty {
            let legacy: [String: String] = load(forKey: "ankiFields") ?? SettingsModel.migratedAnkiFields(from: defaults)
            if !legacy.isEmpty, let name = ankiNoteType?.name {
                ankiFieldsByNoteType[name] = legacy
                // didSet doesn't run during init.
                save(ankiFieldsByNoteType, forKey: "ankiFieldsByNoteType")
            } else if !legacy.isEmpty {
                legacyAnkiFields = legacy
            }
        }
    }

    private func adoptAnkiFields(for noteType: AnkiInfo.NoteType) {
        let available = Set(noteType.fields.map(\.name))
        if let legacy = legacyAnkiFields?.filter({ available.contains($0.value) }), !legacy.isEmpty {
            legacyAnkiFields = nil
            ankiFieldsByNoteType[noteType.name] = legacy
        } else {
            autoMapAnkiFields(for: noteType)
        }
    }

    func apply(_ info: AnkiInfo) {
        ankiInfo = info
        ankiProfile = info.profiles.first { $0.name == ankiProfile?.name } ?? info.profiles.first
        ankiDeck = info.decks.first { $0.name == ankiDeck?.name } ?? info.decks.first
        ankiNoteType = info.notetypes.first { $0.name == ankiNoteType?.name } ?? info.notetypes.first
        var pruned = ankiFieldsByNoteType
        for noteType in info.notetypes {
            let available = Set(noteType.fields.map(\.name))
            pruned[noteType.name] = pruned[noteType.name]?.filter { available.contains($0.value) }
        }
        if pruned != ankiFieldsByNoteType {
            ankiFieldsByNoteType = pruned
        }
    }

    func handleAnkiSetupCallback(_ url: URL) {
        guard url.scheme == AnkiExport.callbackScheme, url.host() == "anki-setup" else { return }
        let pasteboardType = "net.ankimobile.json"
        guard let data = UIPasteboard.general.data(forPasteboardType: pasteboardType) else {
            ankiSetupError = "AnkiMobile didn't send its decks and note types. Try again from AnkiMobile's latest version."
            return
        }
        UIPasteboard.general.setData(Data(), forPasteboardType: pasteboardType)
        do {
            apply(try JSONDecoder().decode(AnkiInfo.self, from: data))
        } catch {
            Logger.anki.error("Failed to decode Anki info: \(error.localizedDescription, privacy: .public)")
            ankiSetupError = "AnkiMobile's reply couldn't be read."
        }
    }

    private static func migratedAnkiFields(from defaults: UserDefaults) -> [String: String] {
        let legacyKeys: [(AnkiFieldToken, String)] = [
            (.word, "ankiFieldWord"),
            (.reading, "ankiFieldReading"),
            (.meaning, "ankiFieldMeaning"),
            (.sentence, "ankiFieldExample"),
        ]
        var fields: [String: String] = [:]
        for (token, key) in legacyKeys {
            guard let data = defaults.data(forKey: key),
                  let field = try? JSONDecoder().decode(String.self, from: data) else {
                continue
            }
            fields[token.rawValue] = field
        }
        return fields
    }

    /// Fills unset tokens only, so a deliberate choice is never overwritten.
    func autoMapAnkiFields(for noteType: AnkiInfo.NoteType) {
        let suggestions = AnkiFieldToken.suggestedMapping(for: noteType.fields.map { $0.name })
        var updated = ankiFields
        let taken = Set(updated.values)
        for (token, field) in suggestions where updated[token.rawValue] == nil && !taken.contains(field) {
            updated[token.rawValue] = field
        }
        ankiFields = updated
    }

    func ankiFieldBinding(for token: AnkiFieldToken) -> Binding<String?> {
        Binding(
            get: { self.ankiFields[token.rawValue] },
            set: { newValue in
                if let newValue = newValue {
                    // One field holds one value; a second token pointed at it takes it over.
                    var updated = self.ankiFields.filter { $0.value != newValue }
                    updated[token.rawValue] = newValue
                    self.ankiFields = updated
                } else {
                    self.ankiFields.removeValue(forKey: token.rawValue)
                }
            }
        )
    }

    var ankiExport: AnkiExport? {
        guard let profile = ankiProfile, let deck = ankiDeck, let noteType = ankiNoteType else {
            return nil
        }
        // Never send a field the note type doesn't have, whatever is stored.
        let available = Set(noteType.fields.map { $0.name })
        var fields: [AnkiFieldToken: String] = [:]
        for token in AnkiFieldToken.allCases {
            if let field = ankiFields[token.rawValue], available.contains(field) {
                fields[token] = field
            }
        }
        return AnkiExport(profile: profile.name, deck: deck.name, noteType: noteType.name, fields: fields)
    }

    private func load<T: Codable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func save<T: Codable>(_ value: T?, forKey key: String) {
        if let value = value, let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
    
}
