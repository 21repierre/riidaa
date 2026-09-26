//
//  Term+CoreDataClass.swift
//  riidaa
//
//  Created by Pierre on 2025/03/08.
//
//

import Foundation
import os
import SwiftUI

public class TermDB: ObservableObject, Hashable, CustomStringConvertible {
    
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
    @Published var exportedToAnki: Bool
    
    @Published var parseDefinition: [ContentDefinition] = []
    
    public var description: String {
        "term=\(term) reading=\(reading) defTags=\(definitionTags) types=\(wordTypes) score=\(score) sequence=\(sequenceNumber) termTags=\(termTags)"
    }
    
    init(term: String, reading: String, definitionTags: [String], wordTypes: [WordType], score: Int64, definitions: Data, sequenceNumber: Int64, termTags: [String], dictionary: DictionaryDB, exportedToAnki: Bool) {
        self.term = term
        self.reading = reading
        self.definitionTags = definitionTags
        self.wordTypes = wordTypes
        self.score = score
        self.definitions = definitions
        self.sequenceNumber = sequenceNumber
        self.termTags = termTags
        self.dictionary = dictionary
        self.exportedToAnki = exportedToAnki
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let decoded = (try JSONSerialization.jsonObject(with: definitions)) as? [Any] else {
                    DispatchQueue.main.async { self.parseDefinition = [] }
                    return
                }

                let ret: [ContentDefinition] = decoded.compactMap { (x: Any) in
                    if let def = x as? String {
                        return .text(StringContent(content: def))
                    }
                    if let deinflection = x as? [Any] {
                        guard deinflection.count == 2 else {
                            Logger.dictionary.debug("Unhandled definition element: \(String(describing: x))")
                            return nil
                        }
                        guard let uninflected = deinflection[0] as? String else {
                            Logger.dictionary.debug("Unhandled definition element: \(String(describing: x))")
                            return nil
                        }
                        guard let inflectionRulesStr = deinflection[1] as? [String] else {
                            Logger.dictionary.debug("Unhandled definition element: \(String(describing: x))")
                            return nil
                        }
                        let inflectionRules = inflectionRulesStr.compactMap { ir in
                            InflectionRule(rawValue: ir)
                        }
                        return .deinflection(Deinflection(text: uninflected, inflections: inflectionRules, types: []))
                    }
                    if let detailedDef = x as? [String: Any] {
                        guard let type = detailedDef["type"] as? String else {
                            Logger.dictionary.debug("Detailed definition with no type")
                            return nil
                        }
                        if type == "text" {
                            guard let text = detailedDef["text"] as? String else {
                                Logger.dictionary.debug("Text definition with no text")
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
                    Logger.dictionary.debug("Unrecognised definition shape: \(String(describing: x))")
                    return nil
                }
                DispatchQueue.main.async { self.parseDefinition = ret }
            } catch {
                Logger.dictionary.debug("Definition decoding failed: \(error.localizedDescription)")
                DispatchQueue.main.async { self.parseDefinition = [.text(StringContent(content: "\(error)"))] }
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
            
            var result: [[StructuredContent]] = []
            var inlines: [StructuredContent] = []
            
            for element in res {
                switch element {
                case .inlineContainer(_), .text(_), .link(_):
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
            return .array(result)
        }
        if let submap = map as? [String: Any] {
            guard let tag = submap["tag"] as? String else {
                Logger.dictionary.debug("Structured content with no tag: \(String(describing: submap))")
                return nil
            }
            if tag == "br" {
                return .newline
            }
            guard let content = submap["content"] else { return nil }
            guard let parsedContent = parseContent(map: content) else {
                return nil
            }
            
            
            switch tag {
            case "rt", "rp":
                return nil
            case "table", "thead", "tbody", "tfoot", "tr", "div", "li", "details", "summary":
                if
                    let data = submap["data"] as? [String: Any],
                    let content = data["content"] as? String,
                    content == "example-sentence" || content == "extra-info" || content == "attribution" {
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
            case "ruby", "span":
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
                default:
                    return .numberedList(StructuredContentList(content: [[parsedContent]]))
                }
            case "td", "th":
                let cols = (submap["colSpan"] as? Int) ?? 1
                let rows = (submap["rowSpan"] as? Int) ?? 1
                return .table(StructuredContentTable(data: parsedContent, cols: cols, rows: rows))
            case "a":
                guard let href = submap["href"] as? String else {return nil}
                return .link(LinkContent(href: href, data: parsedContent))
            default:
                Logger.dictionary.debug("Unhandled structured content tag: \(tag)")
                return nil
            }
        }
        return nil
    }
}

public struct LinkContent: Hashable {
    public var id: UUID { UUID() }
    var href: String
    let data: StructuredContent

    /// The `query` parameter encoded in the link's href (the word the link points to),
    /// parsed without touching the database so it is safe to read during view rendering.
    public var query: String? {
        guard let url = URLComponents(string: self.href),
              let queryItems = url.queryItems
        else {
            return nil
        }
        return queryItems.first(where: { $0.name == "query" })?.value
    }

    /// Resolves the linked dictionary entry. Performs a synchronous SQLite lookup, so call
    /// this off the main/render thread (see `ParserLink`), never from a view's `body`.
    public var linkedWord: TermDB? {
        guard let query = query else { return nil }
        return SQLiteManager.shared.findTerms(texts: [query]).first
    }
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

public struct StructuredContentList: Hashable, CustomStringConvertible {
    public var id: UUID { UUID() }
    let content: [[StructuredContent]]
    var prefix = "\u{2022}"
    
    public var description: String {
        return content.map({ x in
            x.map({ y in
                y.description
            }).joined(separator: " ")
        }).joined(separator: ", ")
    }
}

public indirect enum StructuredContent: Hashable, Identifiable, CustomStringConvertible {
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
    
    public var description: String {
        switch self {
        case .text(let stringContent):
            return stringContent.content
        case .array(let array):
            return array.compactMap({ x in
                let desc = x.compactMap({ y in
                    let desc = y.description
                    if desc != "" {
                        return desc
                    } else {
                        return nil
                    }
                }).joined(separator: ", ")
                if desc != "" {
                    return desc
                } else {
                    return nil
                }
            }).joined(separator: "<br>")
        case .newline:
            return "<br>"
        case .container(let structuredContentContainer):
            return structuredContentContainer.data.description
        case .inlineContainer(let structuredContentContainer):
            return structuredContentContainer.data.description
        case .table(let structuredContentTable):
            return structuredContentTable.data.description
        case .numberedList(let structuredContentList):
            return structuredContentList.description
        case .list(let structuredContentList):
            return structuredContentList.description
        case .link(let linkContent):
            return linkContent.data.description
        }
    }
}

public enum ContentDefinition: Hashable, CustomStringConvertible {
    public var description: String {
        switch self {
        case .text(let stringContent):
            return stringContent.content
        case .deinflection(let deinflection):
            return deinflection.text
        case .detailed(let structuredContent):
            return structuredContent.description
        }
    }
    
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
