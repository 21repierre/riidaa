//
//  String.swift
//  riidaa
//
//  Created by Pierre on 2025/04/04.
//

import Foundation

extension String: @retroactive Identifiable {
    public var id: String {self}
}

extension String {
    
    public func katakanaToHiragana() -> String {
        var hiragana = ""
        for scalar in self.unicodeScalars {
            let value = scalar.value
            if (0x30A1...0x30F6).contains(value) {
                if let hiraganaScalar = UnicodeScalar(value - 0x60) {
                    hiragana.append(Character(hiraganaScalar))
                    continue
                }
            }
            hiragana.append(Character(scalar))
        }
        return hiragana
    }
    
}
