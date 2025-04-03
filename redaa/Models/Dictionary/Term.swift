//
//  Term+CoreDataClass.swift
//  redaa
//
//  Created by Pierre on 2025/03/08.
//
//

import Foundation

public struct TermDB: Hashable {
    public static func == (lhs: TermDB, rhs: TermDB) -> Bool {
        return lhs.term == rhs.term && lhs.reading == rhs.reading && lhs.dictionary.id == rhs.dictionary.id
    }
    
    let term: String
    let reading: String
    let definitionTags: [String]
    let wordTypes: [WordType]
    let score: Int64
    let definitions: /*[Any]*/Data
    let sequenceNumber: Int64
    let termTags: [String]
    let dictionary: DictionaryDB
    
    var parseDefinition: [ContentDefinition] {
        do {
//            print(String(data: self.definitions, encoding: .utf8)!)
            let decoded = (try JSONSerialization.jsonObject(with: self.definitions)) as? [Any]
            
            let ret: [ContentDefinition] = decoded!.compactMap { (x: Any) in
//                print(x)
                if let def = x as? String {
                    return .text(def)
                }
                if let deinflection = x as? [Any] {
                    guard deinflection.count == 2 else {
                        return nil
                    }
                    guard let uninflected = deinflection[0] as? String else {
                        return nil
                    }
                    guard let inflectionRulesStr = deinflection[1] as? [String] else {
                        return nil
                    }
                    let inflectionRules = inflectionRulesStr.compactMap { ir in
                        InflectionRule(rawValue: ir)
                    }
                    return .deinflection(Deinflection(text: uninflected, inflections: inflectionRules, types: []))
                }
                if let detailedDef = x as? [String: Any] {
                    guard let type = detailedDef["type"] as? String else {
                        return nil
                    }
                    if type == "text" {
                        guard let text = detailedDef["text"] as? String else {
                            return nil
                        }
                        return .detailed(.text(text))
                    }
                    if type == "structured-content" {
                        guard let content = detailedDef["content"] else { return nil }
                        guard let parsedContent = parseContent(map: content) else {return nil}
                        return .detailed(.structured(parsedContent))
                    }
                }
                return nil
            }
            print(ret)
            return ret
        } catch {
            print(error)
            return [.text("\(error)")]
        }
    }
    
    private func parseContent(map: Any) -> StructuredContent? {
        if let text = map as? String {
            return .text(text)
        }
        if let arr = map as? [Any] {
            return .array(arr.compactMap { elem in
                parseContent(map: elem)
            })
        }
        if let submap = map as? [String: Any] {
            guard let tag = submap["tag"] as? String else {return nil}
            if tag == "br" {
                return .newline
            }
            guard let content = submap["content"] else { return nil }
            guard let parsedContent = parseContent(map: content) else {return nil}
            switch tag {
            case "ruby", "rt", "rp", "table", "thead", "tbody", "tfoot", "tr", "span", "div", "li", "details", "summary":
                return .container(StructuredContentContainer(data: parsedContent))
            case "ul":
                return .list(StructuredContentContainer(data: parsedContent))
            case "ol":
                return .list(StructuredContentContainer(data: parsedContent))
            case "td", "th":
                guard let rows = submap["rowSpan"] as? Int,
                      let cols = submap["colSpan"] as? Int else {return nil}
                return .table(StructuredContentTable(data: parsedContent, cols: cols, rows: rows))
            default:
                print(tag)
                return nil
            }
        }
        return nil
    }
}

struct StructuredContentContainer: Hashable {
    let data: StructuredContent
}

struct StructuredContentTable: Hashable {
    let data: StructuredContent
    let cols: Int
    let rows: Int
}

indirect enum StructuredContent: Hashable {
    case text(String)
    case array([StructuredContent])
    
    case newline
    case container(StructuredContentContainer)
    case table(StructuredContentTable)
    case numberedList(StructuredContentContainer)
    case list(StructuredContentContainer)
}

enum DetailedDefinition: Hashable {
    case text(String)
    case structured(StructuredContent)
}

enum ContentDefinition: Hashable {
    
    case text(String)
    case deinflection(Deinflection)
    case detailed(DetailedDefinition)
}
