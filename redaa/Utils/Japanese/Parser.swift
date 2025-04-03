//
//  JapaneseParser.swift
//  redaa
//
//  Created by Pierre on 2025/03/27.
//

import CoreData

public struct TermDeinflection : Hashable {
    public static func == (lhs: TermDeinflection, rhs: TermDeinflection) -> Bool {
        return lhs.term == rhs.term && lhs.deinflection == rhs.deinflection
    }
    
    public let term: Term
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
                let cut = String(text.dropFirst(l).dropLast(i-l))
                let deinflections = Inflection.deinflect(text: cut)
                
                var terms: [TermDeinflection] = []
                
                for deinflection in deinflections {
                    //                    var matchingTerms: [TermJson] = []
                    let fetchRequest: NSFetchRequest<Term> = Term.fetchRequest()
                    let termPredicate = NSPredicate(format: "term == %@", deinflection.text)
                    let definitionPredicate = NSPredicate(format: "reading == %@", deinflection.text)
                    let orPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [termPredicate, definitionPredicate])
                    //                    let wordTypesCountPredicate = NSPredicate(format: "wordTypes[SIZE] = %d", deinflection.types.count)
                    //
                    //                    let finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [orPredicate, wordTypesCountPredicate])
                    fetchRequest.predicate = orPredicate
                    
                    let results = try? CoreDataManager.shared.context.fetch(fetchRequest)
                    if let results = results {
                        for term in results {
//                            print("\(term.wordTypes) - \(deinflection.types)")
                            if term.wordTypes.count != deinflection.types.count && !(term.wordTypes.count == 1 && term.wordTypes[0] == "") {
                                continue
                            }
                            var allTypesIncluded = true
                            for dType in deinflection.types {
                                if let _ = term.getWordTypes().firstIndex(of: dType) {
                                    
                                } else {
                                    allTypesIncluded = false
                                    break
                                }
                            }
                            if allTypesIncluded {
                                terms.append(TermDeinflection(term: term, deinflection: deinflection))
                            }
                        }
                    }
                    
                    
                }
                if !terms.isEmpty {
                    possibilities.append(ParsingResult(original: cut, results: terms.sorted(by: {a, b in
                        return a.term.score > b.term.score
                    })))
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
