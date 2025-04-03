//
//  Inflection.swift
//  riidaa
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
    case nasai_form
    case ta_form
    case masen_form
    
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

public enum InflectionRule: String, Sendable, Identifiable {
    public var id: Self { self }
    
    case masu = "ーます"
    case te = "ーて"
    case teiru = "ーいる"
    case ba = "ーば"
    case ya = "ーゃ"
    case cha = "ーちゃ"
    case chau = "ーちゃう"
    case shimau = "ーしまう"
    case chimau = "ーちまう"
    case nasai = "ーなさい"
    case sou = "ーそう"
    case sugiru = "ーすぎる"
    case ta = "ーた"
    case negative = "negative"
    
    
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
            Inflection(base: "い", inflection: "くて", baseTypes: [WordType.adj_i], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "る", inflection: "て", baseTypes: [WordType.v1], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "う", inflection: "って", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "つ", inflection: "って", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "る", inflection: "って", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "ぬ", inflection: "んで", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "ぶ", inflection: "んで", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "む", inflection: "んで", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "く", inflection: "いて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "ぐ", inflection: "いで", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "す", inflection: "して", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "ずる", inflection: "じて", baseTypes: [WordType.vk], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "する", inflection: "して", baseTypes: [WordType.vs], inflectedTypes: [WordType.te_form]),
            Inflection(base: "為る", inflection: "為て", baseTypes: [WordType.vs], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "くる", inflection: "きて", baseTypes: [WordType.vk], inflectedTypes: [WordType.te_form]),
            Inflection(base: "来る", inflection: "来て", baseTypes: [WordType.vk], inflectedTypes: [WordType.te_form]),
            Inflection(base: "來る", inflection: "來て", baseTypes: [WordType.vk], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "いく", inflection: "いって", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "行く", inflection: "行って", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "逝く", inflection: "逝って", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "往く", inflection: "往って", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "こう", inflection: "こうて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "とう", inflection: "とうて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "請う", inflection: "請うて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "乞う", inflection: "乞うて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "恋う", inflection: "恋うて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "問う", inflection: "問うて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "訪う", inflection: "訪うて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "宣う", inflection: "宣うて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "曰う", inflection: "曰うて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "給う", inflection: "給うて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "賜う", inflection: "賜うて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "揺蕩う", inflection: "揺蕩うて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            
            Inflection(base: "のたまう", inflection: "のたもうて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "たまう", inflection: "たもうて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
            Inflection(base: "たゆたう", inflection: "たゆとうて", baseTypes: [WordType.v5], inflectedTypes: [WordType.te_form]),
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
        .cha: [
            Inflection(base: "る", inflection: "ちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
            Inflection(base: "ぐ", inflection: "いじゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "く", inflection: "いちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "す", inflection: "しちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "う", inflection: "っちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "く", inflection: "っちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "つ", inflection: "っちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "る", inflection: "っちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "ぬ", inflection: "んじゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "ぶ", inflection: "んじゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "む", inflection: "んじゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "ずる", inflection: "じちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.vz]),
            Inflection(base: "する", inflection: "しちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.vs]),
            Inflection(base: "為る", inflection: "為ちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.vs]),
            Inflection(base: "くる", inflection: "きちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.vk]),
            Inflection(base: "来る", inflection: "来ちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.vk]),
            Inflection(base: "來る", inflection: "來ちゃ", baseTypes: [WordType.v5], inflectedTypes: [WordType.vk]),
        ],
        
            .chau: [
                Inflection(base: "る", inflection: "ちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
                Inflection(base: "ぐ", inflection: "いじゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
                Inflection(base: "く", inflection: "いちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
                Inflection(base: "す", inflection: "しちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
                Inflection(base: "う", inflection: "っちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
                Inflection(base: "く", inflection: "っちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
                Inflection(base: "つ", inflection: "っちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
                Inflection(base: "る", inflection: "っちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
                Inflection(base: "ぬ", inflection: "んじゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
                Inflection(base: "ぶ", inflection: "んじゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
                Inflection(base: "む", inflection: "んじゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
                Inflection(base: "ずる", inflection: "じちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.vz]),
                Inflection(base: "する", inflection: "しちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.vs]),
                Inflection(base: "為る", inflection: "為ちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.vs]),
                Inflection(base: "くる", inflection: "きちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.vk]),
                Inflection(base: "来る", inflection: "来ちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.vk]),
                Inflection(base: "來る", inflection: "來ちゃう", baseTypes: [WordType.v5], inflectedTypes: [WordType.vk]),
            ],
        .chimau: [
            Inflection(base: "る", inflection: "ちまう", baseTypes: [WordType.v1], inflectedTypes: [WordType.v5]),
            Inflection(base: "ぐ", inflection: "いじまう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "く", inflection: "いちまう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "す", inflection: "しちまう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "う", inflection: "っちまう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "ぬ", inflection: "んじまう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "ぶ", inflection: "んじまう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "む", inflection: "んじまう", baseTypes: [WordType.v5], inflectedTypes: [WordType.v5]),
            Inflection(base: "ずる", inflection: "じちまう", baseTypes: [WordType.vz], inflectedTypes: [WordType.v5]),
            Inflection(base: "する", inflection: "しちまう", baseTypes: [WordType.vs], inflectedTypes: [WordType.v5]),
            Inflection(base: "為る", inflection: "為ちまう", baseTypes: [WordType.vs], inflectedTypes: [WordType.v5]),
            Inflection(base: "くる", inflection: "きちまう", baseTypes: [WordType.vk], inflectedTypes: [WordType.v5]),
            Inflection(base: "来る", inflection: "来ちまう", baseTypes: [WordType.vk], inflectedTypes: [WordType.v5]),
            Inflection(base: "來る", inflection: "來ちまう", baseTypes: [WordType.vk], inflectedTypes: [WordType.v5]),
        ],
        .shimau: [
            Inflection(base: "て", inflection: "てしまう", baseTypes: [WordType.te_form], inflectedTypes: [WordType.v5]),
            Inflection(base: "で", inflection: "でしまう", baseTypes: [WordType.te_form], inflectedTypes: [WordType.v5]),
        ],
        .nasai: [
            Inflection(base: "る", inflection: "なさい", baseTypes: [WordType.v1], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "う", inflection: "いなさい", baseTypes: [WordType.v5], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "く", inflection: "きなさい", baseTypes: [WordType.v5], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "す", inflection: "しなさい", baseTypes: [WordType.v5], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "つ", inflection: "ちなさい", baseTypes: [WordType.v5], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "ぬ", inflection: "になさい", baseTypes: [WordType.v5], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "ぶ", inflection: "びなさい", baseTypes: [WordType.v5], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "む", inflection: "みなさい", baseTypes: [WordType.v5], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "る", inflection: "りなさい", baseTypes: [WordType.v5], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "ずる", inflection: "じなさい", baseTypes: [WordType.vz], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "する", inflection: "しなさい", baseTypes: [WordType.vs], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "為る", inflection: "為なさい", baseTypes: [WordType.vs], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "くる", inflection: "きなさい", baseTypes: [WordType.vk], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "来る", inflection: "来なさい", baseTypes: [WordType.vk], inflectedTypes: [WordType.nasai_form]),
            Inflection(base: "來る", inflection: "來なさい", baseTypes: [WordType.vk], inflectedTypes: [WordType.nasai_form]),
        ],
        .sou: [
            Inflection(base: "い", inflection: "そう", baseTypes: [WordType.adj_i], inflectedTypes: []),
            Inflection(base: "る", inflection: "そう", baseTypes: [WordType.v1], inflectedTypes: []),
            Inflection(base: "う", inflection: "いそう", baseTypes: [WordType.v5], inflectedTypes: []),
            Inflection(base: "つ", inflection: "ちそう", baseTypes: [WordType.v5], inflectedTypes: []),
            Inflection(base: "る", inflection: "りそう", baseTypes: [WordType.v5], inflectedTypes: []),
            Inflection(base: "ぬ", inflection: "にそう", baseTypes: [WordType.v5], inflectedTypes: []),
            Inflection(base: "ぶ", inflection: "びそう", baseTypes: [WordType.v5], inflectedTypes: []),
            Inflection(base: "む", inflection: "みそう", baseTypes: [WordType.v5], inflectedTypes: []),
            Inflection(base: "く", inflection: "きそう", baseTypes: [WordType.v5], inflectedTypes: []),
            Inflection(base: "ぐ", inflection: "ぎそう", baseTypes: [WordType.v5], inflectedTypes: []),
            Inflection(base: "す", inflection: "しそう", baseTypes: [WordType.v5], inflectedTypes: []),
            Inflection(base: "ずる", inflection: "じそう", baseTypes: [WordType.vz], inflectedTypes: []),
            Inflection(base: "する", inflection: "しそう", baseTypes: [WordType.vs], inflectedTypes: []),
            Inflection(base: "為る", inflection: "為そう", baseTypes: [WordType.vs], inflectedTypes: []),
            Inflection(base: "くる", inflection: "きそう", baseTypes: [WordType.vk], inflectedTypes: []),
            Inflection(base: "来る", inflection: "来そう", baseTypes: [WordType.vk], inflectedTypes: []),
            Inflection(base: "來る", inflection: "來そう", baseTypes: [WordType.vk], inflectedTypes: []),
        ],
        .sugiru: [
            Inflection(base: "い", inflection: "すぎる", baseTypes: [WordType.adj_i], inflectedTypes: [WordType.v1]),
            Inflection(base: "る", inflection: "すぎる", baseTypes: [WordType.v1], inflectedTypes: [WordType.v1]),
            Inflection(base: "う", inflection: "いすぎる", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
            Inflection(base: "つ", inflection: "ちすぎる", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
            Inflection(base: "る", inflection: "りすぎる", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
            Inflection(base: "ぬ", inflection: "にすぎる", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
            Inflection(base: "ぶ", inflection: "びすぎる", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
            Inflection(base: "む", inflection: "みすぎる", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
            Inflection(base: "く", inflection: "きすぎる", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
            Inflection(base: "ぐ", inflection: "ぎすぎる", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
            Inflection(base: "す", inflection: "しすぎる", baseTypes: [WordType.v5], inflectedTypes: [WordType.v1]),
            Inflection(base: "ずる", inflection: "じすぎる", baseTypes: [WordType.vz], inflectedTypes: [WordType.v1]),
            Inflection(base: "する", inflection: "しすぎる", baseTypes: [WordType.vs], inflectedTypes: [WordType.v1]),
            Inflection(base: "為る", inflection: "為すぎる", baseTypes: [WordType.vs], inflectedTypes: [WordType.v1]),
            Inflection(base: "くる", inflection: "きすぎる", baseTypes: [WordType.vk], inflectedTypes: [WordType.v1]),
            Inflection(base: "来る", inflection: "来すぎる", baseTypes: [WordType.vk], inflectedTypes: [WordType.v1]),
            Inflection(base: "來る", inflection: "來すぎる", baseTypes: [WordType.vk], inflectedTypes: [WordType.v1]),
        ],
        .ta: [
            Inflection(base: "い", inflection: "かった", baseTypes: [WordType.adj_i], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "る", inflection: "た", baseTypes: [WordType.v1], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "う", inflection: "った", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "つ", inflection: "った", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "る", inflection: "った", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "ぬ", inflection: "んだ", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "ぶ", inflection: "んだ", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "む", inflection: "んだ", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "く", inflection: "いた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "ぐ", inflection: "いだ", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "す", inflection: "した", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "ずる", inflection: "じた", baseTypes: [WordType.vz], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "する", inflection: "した", baseTypes: [WordType.vs], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "為る", inflection: "為た", baseTypes: [WordType.vs], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "くる", inflection: "きた", baseTypes: [WordType.vk], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "来る", inflection: "来た", baseTypes: [WordType.vk], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "來る", inflection: "來た", baseTypes: [WordType.vk], inflectedTypes: [WordType.ta_form]),
            
            Inflection(base: "いく", inflection: "いった", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "行く", inflection: "行った", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "逝く", inflection: "逝った", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "往く", inflection: "往った", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            
            Inflection(base: "こう", inflection: "こうた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "とう", inflection: "とうた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "請う", inflection: "請うた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "乞う", inflection: "乞うた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "恋う", inflection: "恋うた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "問う", inflection: "問うた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "訪う", inflection: "訪うた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "宣う", inflection: "宣うた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "曰う", inflection: "曰うた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "給う", inflection: "給うた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "賜う", inflection: "賜うた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "揺蕩う", inflection: "揺蕩うた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            
            Inflection(base: "のたまう", inflection: "のたもうた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "たまう", inflection: "たもうた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
            Inflection(base: "たゆたう", inflection: "たゆとうた", baseTypes: [WordType.v5], inflectedTypes: [WordType.ta_form]),
        ],
        .negative: [
            Inflection(base: "い", inflection: "ない", baseTypes: [WordType.adj_i], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "る", inflection: "ない", baseTypes: [WordType.v1], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "う", inflection: "わない", baseTypes: [WordType.v5], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "く", inflection: "かない", baseTypes: [WordType.v5], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "す", inflection: "さない", baseTypes: [WordType.v5], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "つ", inflection: "たない", baseTypes: [WordType.v5], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "ぬ", inflection: "なない", baseTypes: [WordType.v5], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "ぶ", inflection: "ばない", baseTypes: [WordType.v5], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "む", inflection: "まない", baseTypes: [WordType.v5], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "る", inflection: "らない", baseTypes: [WordType.v5], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "ずる", inflection: "じない", baseTypes: [WordType.vz], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "する", inflection: "しない", baseTypes: [WordType.vs], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "為る", inflection: "為ない", baseTypes: [WordType.vs], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "くる", inflection: "こない", baseTypes: [WordType.vk], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "来る", inflection: "来ない", baseTypes: [WordType.vk], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "來る", inflection: "來ない", baseTypes: [WordType.vk], inflectedTypes: [WordType.adj_i]),
            Inflection(base: "ます", inflection: "ません", baseTypes: [WordType.masu_form], inflectedTypes: [WordType.masen_form]),
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
