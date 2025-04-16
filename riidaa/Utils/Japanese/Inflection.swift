//
//  Inflection.swift
//  riidaa
//
//  Created by Pierre on 2025/03/27.
//

public enum WordType: String, Sendable, CaseIterable {
    case v
    case v1
    case v1d
    case v1p
    
    case v5
    case v5d
    case v5s
    case v5ss
    case v5sp
    
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
    case ku_form
    
    static let childrenMap: [WordType: [WordType]] = [
        .v: [.v1, .v5, .vs, .vk, .vz],
        .v1: [.v1d, .v1p],
        .v5: [.v5d, .v5s],
        .v5s: [.v5ss, .v5sp],
    ]
    
    public var children: [WordType] {
        return (WordType.childrenMap[self] ?? []).flatMap { $0.children }
    }
    
    public static func fromString(s: String) -> WordType? {
        return self.allCases.first{ $0.rawValue == s }
    }
}

public struct InflectionDescription: Hashable {
    
    public let short: String
    public let description: StructuredContent
    
}

public enum InflectionRule: String, Sendable, Identifiable {
    public var id: Self { self }
    
    public var description: InflectionDescription {
        switch self {
        case .masu:
            InflectionDescription(
                short: "ーます",
                description: .array([
                    [
                        .text(StringContent(content: "Polite conjugation of verbs and adjectives."))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach ます to the continuative form (連用形) of verbs."))]
                        ]))
                    ]
                ])
            )
        case .te:
            InflectionDescription(
                short: "ーて",
                description: .array([
                    [
                        .text(StringContent(content: "Conjunctive particle that connects two clauses together."))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach て to the continuative form (連用形) of verbs after euphonic change form."))],
                            [.text(StringContent(content: "Attach くて to the stem of i-adjectives."))]
                        ]))
                    ]
                ])
            )
        case .iru:
            InflectionDescription(
                short: "ーいる",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Indicates an action continues or progresses to a point in time."))],
                            [.text(StringContent(content: "Indicates an action is completed and remains as is."))],
                            [.text(StringContent(content: "Indicates a state or condition that can be taken to be the result of undergoing some change."))]
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach いる to the て-form of verbs. い can be dropped in speech."))],
                            [.text(StringContent(content: "Attach でいる after ない negative form of verbs."))],
                            [.text(StringContent(content: "(Slang) Attach おる to the て-form of verbs. Contracts to とる・でる in speech."))]
                        ]))
                    ]
                ])
            )
        case .ba:
            InflectionDescription(short: "ーば", description: .text(StringContent(content: "")))
        case .ya:
            InflectionDescription(short: "ーゃ", description: .text(StringContent(content: "")))
        case .cha:
            InflectionDescription(short: "ーちゃ", description: .text(StringContent(content: "")))
        case .chau:
            InflectionDescription(short: "ーちゃう", description: .text(StringContent(content: "")))
        case .shimau:
            InflectionDescription(short: "ーしまう", description: .text(StringContent(content: "")))
        case .chimau:
            InflectionDescription(short: "ーちまう", description: .text(StringContent(content: "")))
        case .nasai:
            InflectionDescription(short: "ーなさい", description: .text(StringContent(content: "")))
        case .sou:
            InflectionDescription(short: "ーそう", description: .text(StringContent(content: "")))
        case .sugiru:
            InflectionDescription(short: "ーすぎる", description: .text(StringContent(content: "")))
        case .ta:
            InflectionDescription(short: "ーた", description: .text(StringContent(content: "")))
        case .negative:
            InflectionDescription(short: "negative", description: .text(StringContent(content: "")))
        case .causative:
            InflectionDescription(short: "causative", description: .text(StringContent(content: "")))
        case .short_causative:
            InflectionDescription(short: "short-causative", description: .text(StringContent(content: "")))
        case .tai:
            InflectionDescription(short: "ーたい", description: .text(StringContent(content: "")))
        case .tara:
            InflectionDescription(short: "ーたら", description: .text(StringContent(content: "")))
        case .tari:
            InflectionDescription(short: "ーたり", description: .text(StringContent(content: "")))
        case .zu:
            InflectionDescription(short: "ーず", description: .text(StringContent(content: "")))
        case .nu:
            InflectionDescription(short: "ーぬ", description: .text(StringContent(content: "")))
        case .n:
            InflectionDescription(short: "ーん", description: .text(StringContent(content: "")))
        case .nbakari:
            InflectionDescription(short: "ーんばかり", description: .text(StringContent(content: "")))
        case .ntosuru:
            InflectionDescription(short: "ーんとする", description: .text(StringContent(content: "")))
        case .mu:
            InflectionDescription(short: "ーむ", description: .text(StringContent(content: "")))
        case .zaru:
            InflectionDescription(short: "ーざる", description: .text(StringContent(content: "")))
        case .neba:
            InflectionDescription(short: "ーねば", description: .text(StringContent(content: "")))
        case .ku:
            InflectionDescription(short: "ーく", description: .text(StringContent(content: "")))
        case .imperative:
            InflectionDescription(short: "imperative", description: .text(StringContent(content: "")))
        case .continuative:
            InflectionDescription(short: "continuative", description: .text(StringContent(content: "")))
        case .sa:
            InflectionDescription(short: "ーさ", description: .text(StringContent(content: "")))
        case .passive:
            InflectionDescription(short: "passive", description: .text(StringContent(content: "")))
        case .potential:
            InflectionDescription(short: "potential", description: .text(StringContent(content: "")))
        case .potential_passive:
            InflectionDescription(short: "potential-passive", description: .text(StringContent(content: "")))
        case .volitional:
            InflectionDescription(short: "volutional", description: .text(StringContent(content: "")))
        case .volitional_slang:
            InflectionDescription(short: "volitional-slang", description: .text(StringContent(content: "")))
        case .mai:
            InflectionDescription(short: "ーまい", description: .text(StringContent(content: "")))
        case .oku:
            InflectionDescription(short: "ーおく", description: .text(StringContent(content: "")))
        case .ki:
            InflectionDescription(short: "ーき", description: .text(StringContent(content: "")))
        case .ge:
            InflectionDescription(short: "ーげ", description: .text(StringContent(content: "")))
        case .garu:
            InflectionDescription(short: "ーがる", description: .text(StringContent(content: "")))
        case .e:
            InflectionDescription(short: "ーえ", description: .text(StringContent(content: "")))
        case .n_slang:
            InflectionDescription(short: "ーん-slang", description: .text(StringContent(content: "")))
        case .imperative_negative_slang:
            InflectionDescription(short: "imperative-negative-slang", description: .text(StringContent(content: "")))
        case .kansai_negative:
            InflectionDescription(short: "negative（関西弁）", description: .text(StringContent(content: "")))
        case .kansai_te:
            InflectionDescription(short: "ーて（関西弁）", description: .text(StringContent(content: "")))
        case .kansai_ta:
            InflectionDescription(short: "ーた（関西弁）", description: .text(StringContent(content: "")))
        case .kansai_tara:
            InflectionDescription(short: "ーたら（関西弁）", description: .text(StringContent(content: "")))
        case .kansai_tari:
            InflectionDescription(short: "ーたり（関西弁）", description: .text(StringContent(content: "")))
        case .kansai_adj_te:
            InflectionDescription(short: "adjーて（関西弁）", description: .text(StringContent(content: "")))
        case .kansai_adj_negative:
            InflectionDescription(short: "adj-negative (関西弁)", description: .text(StringContent(content: "")))
        }
    }
    
    case masu = "ーます"
    case te = "ーて"
    case iru = "ーいる"
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
    case causative = "causative"
    case short_causative = "short causative"
    case tai = "ーたい"
    case tara = "ーたら"
    case tari = "ーたり"
    case zu = "ーず"
    case nu = "ーぬ"
    case n = "ーん"
    case nbakari = "ーんばかり"
    case ntosuru = "ーんとする"
    case mu = "ーむ"
    case zaru = "ーざる" 
    case neba = "ーねば"
    case ku = "ーく"
    case imperative = "imperative"
    case continuative = "continuative"
    case sa = "ーさ" //
    case passive = "passive" //
    case potential = "potential" //
    case potential_passive = "potential or passive" //
    case volitional = "volitional" //
    case volitional_slang = "volitional slang" //
    case mai = "ーまい" //
    case oku = "ーおく" //
    case ki = "ーき" //
    case ge = "ーげ" //
    case garu = "ーがる" //
    case e = "ーえ" //
    case n_slang = "ーんな" //
    case imperative_negative_slang = "imperative negative slang" //
    case kansai_negative = "関西弁 negative" //
    case kansai_te = "関西弁　ーて" //
    case kansai_ta = "関西弁　ーた" //
    case kansai_tara = "関西弁　ーたら" //
    case kansai_tari = "関西弁　ーたり" //
    case kansai_adj_te = "関西弁 adjective ーて" //
    case kansai_adj_negative = "関西弁 adjective negative" //
    
}


public struct Deinflection : Hashable {
    
    public let text: String
    public let inflections: [InflectionRule]
    public let types: [WordType]
    
}
