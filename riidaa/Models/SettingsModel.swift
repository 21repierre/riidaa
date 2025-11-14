//
//  SettingsModel.swift
//  riidaa
//
//  Created by Pierre on 2025/04/15.
//

import Foundation
import SwiftUI

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
        didSet { save(ankiNoteType, forKey: "ankiNoteType") }
    }
    @Published var ankiFieldWord: String? {
        didSet { save(ankiFieldWord, forKey: "ankiFieldWord") }
    }
    @Published var ankiFieldMeaning: String? {
        didSet { save(ankiFieldMeaning, forKey: "ankiFieldMeaning") }
    }
    @Published var ankiFieldReading: String? {
        didSet { save(ankiFieldReading, forKey: "ankiFieldReading") }
    }
    @Published var ankiFieldExample: String? {
        didSet { save(ankiFieldExample, forKey: "ankiFieldExample") }
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
    
    init() {
        self.ankiInfo = load(forKey: "ankiInfo")
        self.ankiProfile = load(forKey: "ankiProfile")
        self.ankiDeck = load(forKey: "ankiDeck")
        self.ankiNoteType = load(forKey: "ankiNoteType")
        self.ankiFieldWord = load(forKey: "ankiFieldWord")
        self.ankiFieldReading = load(forKey: "ankiFieldReading")
        self.ankiFieldMeaning = load(forKey: "ankiFieldMeaning")
        self.ankiFieldExample = load(forKey: "ankiFieldExample")
    }
    
    private func load<T: Codable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func save<T: Codable>(_ value: T?, forKey key: String) {
        if let value = value, let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
}
