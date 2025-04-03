//
//  Inflection.swift
//  redaa
//
//  Created by Pierre on 2025/03/27.
//

public enum WordType: String, Sendable, CaseIterable {
    case v
    case v1
    case v5
    case v5d
    case v1d
    case vs
    case vk
    case vz
    case te_form
    case masu_form
    case adj_i = "adj-i"
    case ba_form
    case ya_form
    
    static let childrenMap: [WordType: [WordType]] = [
        .v: [v1, v5, vs, vk],
        .v1: [v1d],
        .v5: [v5d]
    ]
    
    public var children: [WordType] {
        return WordType.childrenMap[self] ?? []
    }
    
    public static func fromString(s: String) -> WordType? {
        return self.allCases.first{ $0.rawValue == s }
    }
}

public enum InflectionRule: String, Sendable {
    
    case masu = "ーます"
    case te = "ーて"
    case teiru = "ーいる"
    case ba = "ーば"
    case ya = "ーゃ"
    case cya = "ーちゃ"
    case cyau = "ーちゃう"
    case teshimau = "ーてしまう"
    case chimau = "ーちまう"
    
    
}

public struct Inflection : Sendable {
    
    public let base: String
    public let inflection: String
    public let baseTypes: [WordType]
    public let inflectedTypes: [WordType]
    
    public static let inflectionRules: [InflectionRule: [Inflection]] = [
        .masu: [
            Inflection(base: "る", inflection: "ます", baseTypes: [WordType.v1d], inflectedTypes: [WordType.masu_form]),
            
            Inflection(base: "う", inflection: "います", baseTypes: [WordType.v5d], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "つ", inflection: "ちます", baseTypes: [WordType.v5d], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "る", inflection: "ります", baseTypes: [WordType.v5d], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "ぬ", inflection: "にます", baseTypes: [WordType.v5d], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "ぶ", inflection: "びます", baseTypes: [WordType.v5d], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "む", inflection: "みます", baseTypes: [WordType.v5d], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "く", inflection: "きます", baseTypes: [WordType.v5d], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "ぐ", inflection: "ぎます", baseTypes: [WordType.v5d], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "す", inflection: "します", baseTypes: [WordType.v5d], inflectedTypes: [WordType.masu_form]),
            
            Inflection(base: "する", inflection: "します", baseTypes: [WordType.vs], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "為る", inflection: "為ます", baseTypes: [WordType.vs], inflectedTypes: [WordType.masu_form]),
            
            Inflection(base: "くる", inflection: "きます", baseTypes: [WordType.vk], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "来る", inflection: "来ます", baseTypes: [WordType.vk], inflectedTypes: [WordType.masu_form]),
            Inflection(base: "來る", inflection: "來ます", baseTypes: [WordType.vk], inflectedTypes: [WordType.masu_form]),
        ],
        .te: [
            Inflection(base: "る", inflection: "て", baseTypes: [WordType.v1d], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "う", inflection: "って", baseTypes: [WordType.v5d], inflectedTypes: [WordType.te_form]),
            Inflection(base: "つ", inflection: "って", baseTypes: [WordType.v5d], inflectedTypes: [WordType.te_form]),
            Inflection(base: "る", inflection: "って", baseTypes: [WordType.v5d], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "ぬ", inflection: "んで", baseTypes: [WordType.v5d], inflectedTypes: [WordType.te_form]),
            Inflection(base: "ぶ", inflection: "んで", baseTypes: [WordType.v5d], inflectedTypes: [WordType.te_form]),
            Inflection(base: "む", inflection: "んで", baseTypes: [WordType.v5d], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "く", inflection: "いて", baseTypes: [WordType.v5d], inflectedTypes: [WordType.te_form]),
            Inflection(base: "ぐ", inflection: "いで", baseTypes: [WordType.v5d], inflectedTypes: [WordType.te_form]),
            Inflection(base: "す", inflection: "して", baseTypes: [WordType.v5d], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "する", inflection: "して", baseTypes: [WordType.vs], inflectedTypes: [WordType.te_form]),
            Inflection(base: "為る", inflection: "為て", baseTypes: [WordType.vs], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "くる", inflection: "きて", baseTypes: [WordType.vk], inflectedTypes: [WordType.te_form]),
            Inflection(base: "来る", inflection: "来て", baseTypes: [WordType.vk], inflectedTypes: [WordType.te_form]),
            Inflection(base: "來る", inflection: "來て", baseTypes: [WordType.vk], inflectedTypes: [WordType.te_form]),
        ],
        .teiru: [
            Inflection(base: "て", inflection: "ている", baseTypes: [WordType.te_form], inflectedTypes: [WordType.v1d]),
            Inflection(base: "て", inflection: "てる", baseTypes: [WordType.te_form], inflectedTypes: [WordType.v1d]),
            
            Inflection(base: "で", inflection: "でいる", baseTypes: [WordType.te_form], inflectedTypes: [WordType.v1d]),
            Inflection(base: "で", inflection: "でる", baseTypes: [WordType.te_form], inflectedTypes: [WordType.v1d]),
        ],
        .ba: [
            Inflection(base: "い", inflection: "ければ", baseTypes: [WordType.adj_i], inflectedTypes: [WordType.ba_form]),
            Inflection(base: "う", inflection: "えば", baseTypes: [WordType.v5], inflectedTypes: [WordType.ba_form]),
            Inflection(base: "つ", inflection: "てば", baseTypes: [WordType.v5], inflectedTypes: [WordType.ba_form]),
            Inflection(base: "る", inflection: "れば", baseTypes: [WordType.v5, WordType.v1, WordType.vk, WordType.vs, WordType.vz], inflectedTypes: [WordType.ba_form]),
            Inflection(base: "ぬ", inflection: "ねば", baseTypes: [WordType.v5], inflectedTypes: [WordType.ba_form]),
            Inflection(base: "ぶ", inflection: "べば", baseTypes: [WordType.v5], inflectedTypes: [WordType.ba_form]),
            Inflection(base: "む", inflection: "めば", baseTypes: [WordType.v5], inflectedTypes: [WordType.ba_form]),
            Inflection(base: "く", inflection: "けば", baseTypes: [WordType.v5], inflectedTypes: [WordType.ba_form]),
            Inflection(base: "ぐ", inflection: "げば", baseTypes: [WordType.v5], inflectedTypes: [WordType.ba_form]),
            Inflection(base: "す", inflection: "せば", baseTypes: [WordType.v5], inflectedTypes: [WordType.ba_form]),
            Inflection(base: "", inflection: "れば", baseTypes: [WordType.masu_form], inflectedTypes: [WordType.ba_form]),
        ],
        .ya: [
            Inflection(base: "れば", inflection: "りゃ", baseTypes: [WordType.ba_form], inflectedTypes: [WordType.ya_form]),
            Inflection(base: "ければ", inflection: "きゃ", baseTypes: [WordType.ba_form], inflectedTypes: [WordType.ya_form]),
            Inflection(base: "えば", inflection: "や", baseTypes: [WordType.ba_form], inflectedTypes: [WordType.ya_form]),
            Inflection(base: "けば", inflection: "きゃ", baseTypes: [WordType.ba_form], inflectedTypes: [WordType.ya_form]),
            Inflection(base: "げば", inflection: "ぎゃ", baseTypes: [WordType.ba_form], inflectedTypes: [WordType.ya_form]),
            Inflection(base: "せば", inflection: "しゃ", baseTypes: [WordType.ba_form], inflectedTypes: [WordType.ya_form]),
            Inflection(base: "てば", inflection: "ちゃ", baseTypes: [WordType.ba_form], inflectedTypes: [WordType.ya_form]),
            Inflection(base: "ねば", inflection: "にゃ", baseTypes: [WordType.ba_form], inflectedTypes: [WordType.ya_form]),
            Inflection(base: "べば", inflection: "びゃ", baseTypes: [WordType.ba_form], inflectedTypes: [WordType.ya_form]),
            Inflection(base: "めば", inflection: "みゃ", baseTypes: [WordType.ba_form], inflectedTypes: [WordType.ya_form]),
        ],
    ]
    
    public func match(text: String) -> Bool {
        return text.hasSuffix(self.inflection)
    }
    
    public static func deinflect(text: String) -> [Deinflection] {
        var deinflections: [Deinflection] = [Deinflection(text: text, inflections: [], types: [])]
        
        var i = 0
        while i < deinflections.count {
            let current_deinflection = deinflections[i]
            for (ruleName, inflections) in Inflection.inflectionRules {
                for inflection in inflections {
                    if (current_deinflection.types.isEmpty || current_deinflection.types == inflection.inflectedTypes) && inflection.match(text: current_deinflection.text) {
                        
                        let newText = String(current_deinflection.text.dropLast(inflection.inflection.count)) + inflection.base
                        var newInflections = current_deinflection.inflections
                        newInflections.append(ruleName)
                        let newTypes = inflection.baseTypes
                        
                        deinflections.append(Deinflection(text: newText, inflections: newInflections, types: newTypes))
                    }
                }
            }
            i += 1
        }
        
        return deinflections
    }
    
}


public struct Deinflection : Hashable {
    
    public let text: String
    public let inflections: [InflectionRule]
    public let types: [WordType]
    
}
