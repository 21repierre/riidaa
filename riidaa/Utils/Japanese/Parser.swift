//
//  JapaneseParser.swift
//  riidaa
//
//  Created by Pierre on 2025/03/27.
//

import CoreData

public struct TermDeinflection : Hashable {
    public static func == (lhs: TermDeinflection, rhs: TermDeinflection) -> Bool {
        return lhs.term == rhs.term && lhs.deinflection == rhs.deinflection
    }
    
    public let term: TermDB
    public let deinflection: Deinflection
    
}

public struct ParsingResult : Hashable {
    
    public let original: String
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
         
                let results = SQLiteManager.shared.findTerms(texts: deinflections.compactMap({ di in
                    di.text
                }))
                for deinflection in deinflections {
                    for term in results where
                    (term.term == deinflection.text || term.reading == deinflection.text) &&
                    (deinflection.types.count == 0 || term.wordTypes.count == 0 ||  deinflection.types.inflectionMatch(wl: term.wordTypes)) {
                        terms.append(TermDeinflection(term: term, deinflection: deinflection))
                    }
                }
                if !terms.isEmpty {
                    possibilities.append(ParsingResult(
                        original: cut,
                        results: terms.sorted{ $0.term.score > $1.term.score }
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
                let cutBefore = text.index(text.startIndex, offsetBy: l)
                let cutAfter = text.index(text.endIndex, offsetBy: 0)
                let cut = String(text[cutBefore..<cutAfter])
                parts.append(ParsingResult(original: cut, results: []))
                break
            }
        }
        return parts
    }
    
}
