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
        
        while l < text.count - 1 {
            var possibilities: [ParsingResult] = []
            
            for i in (l...text.count-1) {
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
                    (deinflection.types.count == 0 || term.wordTypes.count == 0 || term.wordTypes == deinflection.types) {
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
                parts.append(possibilities[0])
                l += possibilities[0].original.count
            } else {
                break
            }
        }
        return parts
    }
    
}
