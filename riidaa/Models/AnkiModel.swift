//
//  AnkiModel.swift
//  riidaa
//
//  Created by Pierre on 2025/11/11.
//
import SwiftUI

struct AnkiInfo: Codable {
    struct Profile: Codable, Identifiable, Hashable {
        let name: String
        var id: String { name }
    }
    struct Deck: Codable, Identifiable, Hashable {
        let name: String
        var id: String { name }
    }
    struct NoteType: Codable, Identifiable, Hashable {
        struct Field: Codable, Identifiable, Hashable {
            let name: String
            var id: String { name }
        }
        
        let name: String
        let kind: String
        let fields: [Field]
        var id: String { name }
    }
    let profiles: [Profile]
    let decks: [Deck]
    let notetypes: [NoteType]
}
