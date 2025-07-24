//
//  JapaneseParser.swift
//  riidaa
//
//  Created by Pierre on 2025/03/27.
//

import CoreData

public struct TermDeinflection : Hashable {
    public static func == (lhs: TermDeinflection, rhs: TermDeinflection) -> Bool {
        return lhs.term == rhs.term && lhs.deinflections == rhs.deinflections
    }
    
    public let term: TermDB
    public let deinflections: [Deinflection]
    
}

public struct ParsingResult : Hashable {
    
    public var original: String
    public let results: [TermDeinflection]
    
}

public struct Parser {
    
    
    public static func parse(text: String) -> [ParsingResult] {
        var l = 0
        var parts: [ParsingResult] = []
        
        var endText = text.count - 1
        
        while l < endText {
            var possibilities: [ParsingResult] = []
            
            for i in (l...text.count - 1) {
                let cutBefore = text.index(text.startIndex, offsetBy: l)
                let cutAfter = text.index(text.endIndex, offsetBy: l-i)
                let cut = String(text[cutBefore..<cutAfter])
                let deinflections = Inflection.deinflect(text: cut)
                
                var terms: [TermDeinflection] = []
         
                let mappedTerms: [[String]] = deinflections.compactMap({ di in
                    [di.text, di.text.katakanaToHiragana()]
                })
                
                let results = SQLiteManager.shared.findTerms(texts: mappedTerms.flatMap { $0 })
                for deinflection in deinflections {
                    for term in results where
                        (term.term.katakanaToHiragana() == deinflection.text.katakanaToHiragana() ||
                            term.reading.katakanaToHiragana() == deinflection.text.katakanaToHiragana()) &&
                        (deinflection.types.count == 0 ||
                             term.wordTypes.count == 0 ||
                             deinflection.types.inflectionMatch(wl: term.wordTypes)) {
                        terms.append(TermDeinflection(term: term, deinflections: [deinflection]))
                    }
                }
                if !terms.isEmpty {
                    let groupedTerms = Dictionary(grouping: terms, by: { $0.term })
                    let mergedTerms: [TermDeinflection] = groupedTerms.map { (term, group) in
                        let combinedDeinflections = group.flatMap { $0.deinflections }
                        return TermDeinflection(term: term, deinflections: combinedDeinflections)
                    }
                    
                    possibilities.append(ParsingResult(
                        original: cut,
                        results: mergedTerms.sorted{
                            if $0.term.reading == cut && $1.term.reading != cut {
                                return true
                            } else if $0.term.reading != cut && $1.term.reading == cut {
                                return false
                            } else {
                                return $0.term.score > $1.term.score
                            }
                        }
                    ))
                }
            }
            
            if !possibilities.isEmpty {
                guard let bestPos = possibilities.max(by: {a, b in
                    guard let af = a.results.first, let bf = b.results.first else {return false}
                    return (af.term.score >= 0 && bf.term.score >= 0 ? a.original.count < b.original.count : af.term.score < bf.term.score)
                }) else { break }
                parts.append(bestPos)
                l += bestPos.original.count
                if l == text.count-1 {
                    endText += 1
                }
            } else {
                let c = text[text.index(text.startIndex, offsetBy: l)]
                if var lastPart = parts.last, lastPart.results.isEmpty {
                    lastPart.original += String(c)
                } else {
                    parts.append(ParsingResult(original: String(c), results: []))
                }
                if l >= text.count-1 {
                    break
                }
                l += 1
            }
        }
//        print(parts)
        return parts
    }
    
}
