//
//  Term+CoreDataClass.swift
//  riidaa
//
//  Created by Pierre on 2025/03/08.
//
//

import Foundation
import SwiftUI

public class TermDB: Hashable, CustomStringConvertible {
    
    public static func == (lhs: TermDB, rhs: TermDB) -> Bool {
        return lhs.term == rhs.term && lhs.reading == rhs.reading && lhs.dictionary.id == rhs.dictionary.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(term)
        hasher.combine(reading)
        hasher.combine(dictionary.id)
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
    
    @Published var parseDefinition: [ContentDefinition] = []
    
    public var description: String {
        "term=\(term) reading=\(reading) defTags=\(definitionTags) types=\(wordTypes) score=\(score) sequence=\(sequenceNumber) termTags=\(termTags)"
    }
    
    init(term: String, reading: String, definitionTags: [String], wordTypes: [WordType], score: Int64, definitions: Data, sequenceNumber: Int64, termTags: [String], dictionary: DictionaryDB) {
        self.term = term
        self.reading = reading
        self.definitionTags = definitionTags
        self.wordTypes = wordTypes
        self.score = score
        self.definitions = definitions
        self.sequenceNumber = sequenceNumber
        self.termTags = termTags
        self.dictionary = dictionary
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let decoded = (try JSONSerialization.jsonObject(with: definitions)) as? [Any]
                
                let ret: [ContentDefinition] = decoded!.compactMap { (x: Any) in
                    if let def = x as? String {
                        return .text(StringContent(content: def))
                    }
                    if let deinflection = x as? [Any] {
                        guard deinflection.count == 2 else {
                            print("error deinflect1: \(x)")
                            return nil
                        }
                        guard let uninflected = deinflection[0] as? String else {
                            print("error deinflect2: \(x)")
                            return nil
                        }
                        guard let inflectionRulesStr = deinflection[1] as? [String] else {
                            print("error deinflect3: \(x)")
                            return nil
                        }
                        let inflectionRules = inflectionRulesStr.compactMap { ir in
                            InflectionRule(rawValue: ir)
                        }
                        return .deinflection(Deinflection(text: uninflected, inflections: inflectionRules, types: []))
                    }
                    if let detailedDef = x as? [String: Any] {
                        guard let type = detailedDef["type"] as? String else {
                            print("error detailed without type")
                            return nil
                        }
                        if type == "text" {
                            guard let text = detailedDef["text"] as? String else {
                                print("Error text without text")
                                return nil
                            }
                            return .text(StringContent(content: text))
                        }
                        if type == "structured-content" {
                            guard let content = detailedDef["content"] else { return nil }
                            guard let parsedContent = TermDB.parseContent(map: content) else {return nil}
                            return .detailed(parsedContent)
                        }
                    }
                    print("else1: \(x)")
                    return nil
                }
                //            print(ret)
                self.parseDefinition = ret
            } catch {
                print(error)
                self.parseDefinition = [.text(StringContent(content: "\(error)"))]
            }
        }
    }
    
    var parseDefinitionTags: [String] {
        []
    }
    
    private static func parseContent(map: Any) -> StructuredContent? {
        if let text = map as? String {
            return .text(StringContent(content: text))
        }
        if let arr = map as? [Any] {
            let res = arr.compactMap { elem in
                parseContent(map: elem)
            }
//            print("parsed: \(res)")
            
            var result: [[StructuredContent]] = []
            var inlines: [StructuredContent] = []
            
            for element in res {
                switch element {
                case .inlineContainer(_), .text(_):
                    inlines.append(element)
                default:
                    if inlines.count > 0 {
                        result.append(inlines)
                    }
                    inlines = []
                    result.append([element])
                }
            }
            if inlines.count > 0 {
                result.append(inlines)
            }
//            print("result: \(result)\n-----------------------")
            return .array(result)
        }
        if let submap = map as? [String: Any] {
            guard let tag = submap["tag"] as? String else {
                print("submap without tag: \(submap)")
                return nil
            }
            if tag == "br" {
                return .newline
            }
            guard let content = submap["content"] else { return nil }
            guard let parsedContent = parseContent(map: content) else {
//                print("sub-submap error? \(map)")
                return nil
            }
            
            
            switch tag {
            case "ruby", "rt", "rp", "table", "thead", "tbody", "tfoot", "tr", "div", "li", "details", "summary":
                if
                    let data = submap["data"] as? [String: Any],
                   let content = data["content"] as? String,
                    content == "example-sentence" || content == "extra-info" || content == "forms" || content == "attribution" {
                    return nil
                }
                var tmpSCC = StructuredContentContainer(data: parsedContent, tag: tag)
                if let style = submap["style"] as? [String: Any] {
                    if let bg = style["backgroundColor"] as? String {
                        tmpSCC.backgroundColor = Color(hex: bg)
                    }
                    if let fontSize = style["fontSize"] as? String {
                        let parsedSize = fontSize.replacing(/([^0-9\.])+/, with: "")
                        let size = Float(parsedSize) ?? 1
                        tmpSCC.font = .system(size: CGFloat(size * 16))
                    }
                }
                return .container(tmpSCC)
            case "span":
                var tmpSCC = StructuredContentContainer(data: parsedContent, tag: tag)
                if let style = submap["style"] as? [String: Any] {
                    if let bg = style["backgroundColor"] as? String {
                        tmpSCC.backgroundColor = Color(hex: bg)
                    }
                    if let fontSize = style["fontSize"] as? String {
                        let parsedSize = fontSize.replacing(/([^0-9\.])+/, with: "")
                        let size = Float(parsedSize) ?? 1
                        tmpSCC.font = .system(size: CGFloat(size * 16))
                    }
                }
                return .inlineContainer(tmpSCC)
            case "ul":
                switch parsedContent {
                case .array(let arrayCnt):
                    var list = StructuredContentList(content: arrayCnt)
                    
                    if let style = submap["style"] as? [String: Any], let dotStyle = style["listStyleType"] as? String {
                        list.prefix = dotStyle.replacingOccurrences(of: "\"", with: "")
                    }
                    return .list(list)
                default:
                    return .list(StructuredContentList(content: [[parsedContent]]))
                }
            case "ol":
                switch parsedContent {
                case .array(let arrayCnt):
                    var list = StructuredContentList(content: arrayCnt)
                    
                    if let style = submap["style"] as? [String: Any] {
                        if let dotStyle = style["listStyleType"] as? String {
                            list.prefix = dotStyle.replacingOccurrences(of: "\"", with: "")
                        }
                    }
                    return .numberedList(list)
//                case .container(let container):
//                    switch container.data {
//                    case .text(_):
//                        return .numberedList(StructuredContentList(content: [[container.data]]))
////                    case .list(let list):
////                        return .numberedList(list)
//                    default:
//                        print("ol>c default ? \(parsedContent)")
//                        return .numberedList(StructuredContentList(content: [[container.data]]))
//                    }
                default:
                    return .numberedList(StructuredContentList(content: [[parsedContent]]))
//                    print("ol default ? \(parsedContent)")
//                    return nil
                }
            case "td", "th":
                guard let rows = submap["rowSpan"] as? Int,
                      let cols = submap["colSpan"] as? Int else {return nil}
                return .table(StructuredContentTable(data: parsedContent, cols: cols, rows: rows))
            case "a":
                guard let href = submap["href"] as? String else {return nil}
                return .link(LinkContent(href: href, data: parsedContent))
            default:
                print("default: ", tag)
                return nil
            }
        }
//        print("else?? \(type(of: map)) \(map as? [String: Any]) | \(map as? [String: Any?])")
        return nil
    }
}

public struct LinkContent: Hashable {
    public var id: UUID { UUID() }
    var href: String
    let data: StructuredContent
}

public struct StructuredContentContainer: Hashable {
    public var id: UUID { UUID() }
    let data: StructuredContent
    let tag: String
    
    public var color = Color.primary
    public var backgroundColor: Color = Color.white.opacity(0)
    public var borders = [0]
    public var font: Font = .footnote
    
}

public struct StructuredContentTable: Hashable {
    public var id: UUID { UUID() }
    
    let data: StructuredContent
    let cols: Int
    let rows: Int
}

public struct StructuredContentList: Hashable {
    public var id: UUID { UUID() }
    let content: [[StructuredContent]]
    var prefix = "\u{2022}"
}

public indirect enum StructuredContent: Hashable, Identifiable {
    public var id: UUID { UUID() }

    case text(StringContent)
    case array([[StructuredContent]])
    
    case newline
    case container(StructuredContentContainer)
    case inlineContainer(StructuredContentContainer)
    case table(StructuredContentTable)
    case numberedList(StructuredContentList)
    case list(StructuredContentList)
    case link(LinkContent)
}

public enum ContentDefinition: Hashable {
    public var id: UUID { UUID() }
    
    case text(StringContent)
    case deinflection(Deinflection)
    case detailed(StructuredContent)
}

public struct StringContent: Hashable, Identifiable {
    public var id: UUID { UUID() }
    
    public var content: String
}

extension Array: @retroactive Identifiable where Element == StructuredContent {
    public var id: UUID { UUID() }
    
}
