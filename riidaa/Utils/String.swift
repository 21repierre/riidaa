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

    /// Replaces each long-vowel mark (ー / chōonpu) with the vowel kana of the preceding
    /// character, so casual spellings (そー, めんどくせー, …) can be matched against their
    /// standard dictionary forms (そう, …). Operates on hiragana; combine with
    /// `katakanaToHiragana()` first. After an お-row kana it is usually う (そー → そう), but
    /// some words want お (とーり → とおり).
    public func expandLongVowels(oRowAs oVowel: Character = "う") -> String {
        var result = ""
        var previous: Character? = nil
        for ch in self {
            guard ch == "ー", let p = previous else {
                result.append(ch)
                previous = ch
                continue
            }
            let vowel: Character?
            if LongVowelRows.a.contains(p) { vowel = "あ" }
            else if LongVowelRows.i.contains(p) { vowel = "い" }
            else if LongVowelRows.u.contains(p) { vowel = "う" }
            else if LongVowelRows.e.contains(p) { vowel = "え" }
            else if LongVowelRows.o.contains(p) { vowel = oVowel }
            else { vowel = nil }

            if let vowel = vowel {
                result.append(vowel)
                previous = vowel
            } else {
                result.append(ch)
                previous = ch
            }
        }
        return result
    }

    public func fullwidthAlphanumericsToASCII() -> String {
        String(String.UnicodeScalarView(unicodeScalars.map { scalar in
            switch scalar.value {
            case 0xFF10...0xFF19, 0xFF21...0xFF3A, 0xFF41...0xFF5A:
                return UnicodeScalar(scalar.value - 0xFEE0) ?? scalar
            default:
                return scalar
            }
        }))
    }

    var isKana: Bool {
        unicodeScalars.allSatisfy { (0x3041...0x309F).contains($0.value) || (0x30A1...0x30FF).contains($0.value) }
    }

}

private enum LongVowelRows {
    static let a: Set<Character> = ["あ","か","が","さ","ざ","た","だ","な","は","ば","ぱ","ま","や","ら","わ","ゃ","ぁ"]
    static let i: Set<Character> = ["い","き","ぎ","し","じ","ち","ぢ","に","ひ","び","ぴ","み","り","ぃ"]
    static let u: Set<Character> = ["う","く","ぐ","す","ず","つ","づ","ぬ","ふ","ぶ","ぷ","む","ゆ","る","ゅ","ぅ"]
    static let e: Set<Character> = ["え","け","げ","せ","ぜ","て","で","ね","へ","べ","ぺ","め","れ","ぇ"]
    static let o: Set<Character> = ["お","こ","ご","そ","ぞ","と","ど","の","ほ","ぼ","ぽ","も","よ","ろ","を","ょ","ぉ"]
}
