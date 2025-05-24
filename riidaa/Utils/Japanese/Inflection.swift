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
    case n_form
    case ku_form
    
    static let childrenMap: [WordType: [WordType]] = [
        .v: [.v1, .v5, .vs, .vk, .vz],
        .v1: [.v1d, .v1p],
        .v5: [.v5d, .v5s],
        .v5s: [.v5ss, .v5sp],
    ]
    
    public var children: [WordType] {
        guard var c = WordType.childrenMap[self] else { return [] }
        c.append(contentsOf: c.flatMap { $0.children })
        return c
    }
    
    public static func fromString(s: String) -> WordType? {
        return self.allCases.first{ $0.rawValue == s }
    }
}

extension Array where Element == WordType {
    
    public func inflectionMatch(wl: [WordType]) -> Bool {
        if self.isEmpty {
            return true
        }
        for element in self {
            for element2 in wl {
                if element == element2 || element2.children.firstIndex(of: element) != nil {
                    return true
                }
            }
        }
        return false
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
            InflectionDescription(
                short: "ーば",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Conditional form; shows that the previous stated condition's establishment is the condition for the latter stated condition to occur."))],
                            [.text(StringContent(content: "Shows a trigger for a latter stated perception or judgment."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
                        ]))
                    ]
                ])
            )
        case .ya:
            InflectionDescription(
                short: "ーゃ",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Contraction of ーば.")), tag: "span", font: .body))],
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Conditional form; shows that the previous stated condition's establishment is the condition for the latter stated condition to occur."))],
                            [.text(StringContent(content: "Shows a trigger for a latter stated perception or judgment."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
                            [.text(StringContent(content: "ければ → けりゃ (i-adjective)"))],
                            [.text(StringContent(content: "ければ → きゃ (一段)"))],
                            [.text(StringContent(content: "えば → や (五段)"))],
                            [.text(StringContent(content: "けば → きゃ (五段)"))],
                            [.text(StringContent(content: "げば → ぎゃ (五段)"))],
                            [.text(StringContent(content: "せば → しゃ (五段)"))],
                            [.text(StringContent(content: "てば → ちゃ (五段)"))],
                            [.text(StringContent(content: "ねば → にゃ (五段)"))],
                            [.text(StringContent(content: "べば → びゃ (五段)"))],
                            [.text(StringContent(content: "めば → みゃ (五段)"))],
                            [.text(StringContent(content: "れば → りゃ (五段)"))],
                        ]))
                    ]
                ])
            ) // ok
        case .cha:
            InflectionDescription(
                short: "ーちゃ",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Contraction of ーては.")), tag: "span", font: .body))],
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Explains how something always happens under the condition that it marks."))],
                            [.text(StringContent(content: "Expresses the repetition (of a series of) actions."))],
                            [.text(StringContent(content: "Indicates a hypothetical situation in which the speaker gives a (negative) evaluation about the other party's intentions."))],
                            [.text(StringContent(content: "Used in \"must not\" patterns like ーてはいけない."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach は after the て-form of verbs."))],
                            [.text(StringContent(content: "Contract ては into ちゃ."))],
                        ]))
                    ]
                ])
            )
        case .chau:
            InflectionDescription(
                short: "ーちゃう",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Contraction of ーてしまう.")), tag: "span", font: .body))],
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Shows a sense of regret/surprise when you did have volition in doing something, but it turned out to be bad to do."))],
                            [.text(StringContent(content: "Shows perfective/punctual achievement. This shows that an action has been completed."))],
                            [.text(StringContent(content: "Shows unintentional action–“accidentally."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach しまう after the て-form of verbs."))],
                            [.text(StringContent(content: "Contract てしまう into ちゃう."))],
                        ]))
                    ]
                ])
            )
        case .shimau:
            InflectionDescription(
                short: "ーしまう",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Shows a sense of regret/surprise when you did have volition in doing something, but it turned out to be bad to do."))],
                            [.text(StringContent(content: "Shows perfective/punctual achievement. This shows that an action has been completed."))],
                            [.text(StringContent(content: "Shows unintentional action–“accidentally."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach しまう after the て-form of verbs."))],
                        ]))
                    ]
                ])
            )
        case .chimau:
            InflectionDescription(
                short: "ーちまう",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Contraction of ーてしまう.")), tag: "span", font: .body))],
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Shows a sense of regret/surprise when you did have volition in doing something, but it turned out to be bad to do."))],
                            [.text(StringContent(content: "Shows perfective/punctual achievement. This shows that an action has been completed."))],
                            [.text(StringContent(content: "Shows unintentional action–“accidentally."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach しまう after the て-form of verbs."))],
                            [.text(StringContent(content: "Contract てしまう into ちまう."))],
                        ]))
                    ]
                ])
            )
        case .nasai:
            InflectionDescription(
                short: "ーなさい",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Polite imperative suffix."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach なさい after the continuative form (連用形) of verbs."))],
                        ]))
                    ]
                ])
            )
        case .sou:
            InflectionDescription(
                short: "ーそう",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Appearing that; looking like."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach そう to the continuative form (連用形) of verbs, or to the stem of adjectives."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Example:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "雨が降りそうです。→ It looks like it's raining."))],
                        ]))
                    ]
                ])
            )
        case .sugiru:
            InflectionDescription(
                short: "ーすぎる",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Shows something \"is too...\" or someone is doing something \"too much\"."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach すぎる to the continuative form (連用形) of verbs, or to the stem of adjectives."))],
                        ]))
                    ]
                ])
            )
        case .ta:
            InflectionDescription(
                short: "ーた",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Indicates a reality that has happened in the past."))],
                            [.text(StringContent(content: "Indicates the completion of an action."))],
                            [.text(StringContent(content: "Indicates the confirmation of a matter."))],
                            [.text(StringContent(content: "Indicates the speaker's confidence that the action will definitely be fulfilled."))],
                            [.text(StringContent(content: "Indicates the events that occur before the main clause are represented as relative past."))],
                            [.text(StringContent(content: "Indicates a mild imperative/command."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach た to the continuative form (連用形) of verbs after euphonic change form."))],
                            [.text(StringContent(content: "Attach かった to the stem of i-adjectives."))],
                        ]))
                    ]
                ])
            )
        case .negative:
            InflectionDescription(
                short: "negative",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Negative form of verbs."))],
                            [.text(StringContent(content: "Expresses a feeling of solicitation to the other party."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach ない to the irrealis form (未然形) of verbs."))],
                            [.text(StringContent(content: "Attach くない to the stem of i-adjectives."))],
                            [.text(StringContent(content: "Transform ます in ません."))],
                        ]))
                    ]
                ])
            )
        case .causative:
            InflectionDescription(
                short: "causative",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Describes the intention to make someone do something."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach させる to the irrealis form (未然形) of ichidan (一段) verbs and くる."))],
                            [.text(StringContent(content: "Attach せる to the irrealis form (未然形) of godan (五段) verbs and する."))],
                            [.text(StringContent(content: "It itself conjugates as an ichidan (一段) verb."))],
                        ]))
                    ]
                ])
            ) // ok
        case .short_causative:
            InflectionDescription(
                short: "short-causative",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Contraction of the causative form.")), tag: "span", font: .body))],
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Describes the intention to make someone do something."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach さす to the irrealis form (未然形) of ichidan (一段) verbs."))],
                            [.text(StringContent(content: "Attach す to the irrealis form (未然形) of godan (五段) verbs."))],
                            [.text(StringContent(content: "する becomes さす."))],
                            [.text(StringContent(content: "くる becomes こさす."))],
                            [.text(StringContent(content: "It itself conjugates as an godan (五段) verb."))],
                        ]))
                    ]
                ])
            ) // ok
        case .tai:
            InflectionDescription(
                short: "ーたい",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Expresses the feeling of desire or hope."))],
                            [.text(StringContent(content: "Used in ...たいと思います, an indirect way of saying what the speaker intends to do."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach たい to the continuative form (連用形) of verbs."))],
                            [.text(StringContent(content: "たい itself conjugates as i-adjective."))],
                        ]))
                    ]
                ])
            ) // ok
        case .tara:
            InflectionDescription(
                short: "ーたら",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Denotes the latter stated event is a continuation of the previous stated event."))],
                            [.text(StringContent(content: "Assumes that a matter has been completed or concluded."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach たら to the continuative form (連用形) of verbs after euphonic change form."))],
                            [.text(StringContent(content: "Attach かったら to the stem of i-adjectives."))],
                        ]))
                    ]
                ])
            )
        case .tari:
            InflectionDescription(
                short: "ーたり",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Shows two actions occurring back and forth (when used with two verbs)."))],
                            [.text(StringContent(content: "Shows examples of actions and states (when used with multiple verbs and adjectives)."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach たり to the continuative form (連用形) of verbs after euphonic change form."))],
                            [.text(StringContent(content: "Attach かったり to the stem of i-adjectives."))],
                        ]))
                    ]
                ])
            )
        case .zu:
            InflectionDescription(
                short: "ーず",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Negative form of verbs."))],
                            [.text(StringContent(content: "Continuative form (連用形) of the particle ぬ (nu)."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach ず to the irrealis form (未然形) of verbs."))],
                        ]))
                    ]
                ])
            )
        case .nu:
            InflectionDescription(
                short: "ーぬ",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Negative form of verbs."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach ぬ to the irrealis form (未然形) of verbs."))],
                            [.text(StringContent(content: "する becomes せぬ."))],
                        ]))
                    ]
                ])
            )
        case .n:
            InflectionDescription(
                short: "ーん",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Negative form of verbs; a sound change of ぬ."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach ん to the irrealis form (未然形) of verbs."))],
                            [.text(StringContent(content: "する becomes せん."))],
                        ]))
                    ]
                ])
            )
        case .nbakari:
            InflectionDescription(
                short: "ーんばかり",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Shows an action or condition is on the verge of occurring, or an excessive/extreme degree."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach んばかり to the irrealis form (未然形) of verbs."))],
                            [.text(StringContent(content: "する becomes せんばかり."))],
                        ]))
                    ]
                ])
            )
        case .ntosuru:
            InflectionDescription(
                short: "ーんとする",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Shows the speaker's will or intention."))],
                            [.text(StringContent(content: "Shows an action or condition is on the verge of occurring."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach んとする to the irrealis form (未然形) of verbs."))],
                            [.text(StringContent(content: "する becomes せんとする."))],
                        ]))
                    ]
                ])
            )
        case .mu:
            InflectionDescription(
                short: "ーむ",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Archaic.")), tag: "span", font: .body))],
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Shows an inference of a certain matter."))],
                            [.text(StringContent(content: "Shows speaker's intention."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach む to the irrealis form (未然形) of verbs."))],
                            [.text(StringContent(content: "する becomes せむ."))],
                        ]))
                    ]
                ])
            )
        case .zaru:
            InflectionDescription(
                short: "ーざる",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Negative form of verbs."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach ざる to the irrealis form (未然形) of verbs."))],
                            [.text(StringContent(content: "する becomes せざる."))],
                        ]))
                    ]
                ])
            )
        case .neba:
            InflectionDescription(
                short: "ーねば",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Shows a hypothetical negation; if not ..."))],
                            [.text(StringContent(content: "Shows a must. Used with or without ならぬ."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach ねば to the irrealis form (未然形) of verbs."))],
                            [.text(StringContent(content: "する becomes せねば."))],
                        ]))
                    ]
                ])
            )
        case .ku:
            InflectionDescription(
                short: "ーく",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Adverbial form of i-adjectives."))],
                        ]))
                    ],
                ])
            )
        case .imperative:
            InflectionDescription(
                short: "imperative",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "To give orders."))],
                            [.text(StringContent(content: "(As あれ) Represents the fact that it will never change no matter the circumstances."))],
                            [.text(StringContent(content: "Express a feeling of hope."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
//                    [
//                        .list(StructuredContentList(content: [
//                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
//                        ]))
//                    ]
                    // TODO
                ])
            )
        case .continuative:
            InflectionDescription(
                short: "continuative",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Used to indicate actions that are (being) carried out."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Refers to 連用形, the part of the verb after conjugating with -ます and dropping ます")), tag: "span", font: .body))],
//                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
//                    [
//                        .list(StructuredContentList(content: [
//                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
//                        ]))
//                    ]
                ])
            )
        case .sa:
            InflectionDescription(
                short: "ーさ",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Nominalizing suffix of i-adjectives indicating nature, state, mind or degree."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach さ to the stem of i-adjectives."))],
                        ]))
                    ]
                ])
            ) // ok
        case .passive:
            InflectionDescription(
                short: "passive",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Indicates an action received from an action performer."))],
                            [.text(StringContent(content: "Expresses respect for the subject of action performer."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach れる to the irrealis form (未然形) of godan verbs."))],
                        ]))
                    ]
                ])
            )
        case .potential:
            InflectionDescription(
                short: "potential",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Indicates a state of being (naturally) capable of doing an action."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach (ら)れる to the irrealis form (未然形) of ichidan verbs."))],
                            [.text(StringContent(content: "Attach る to the imperative form (命令形) of godan verbs."))],
                            [.text(StringContent(content: "する becomes できる."))],
                            [.text(StringContent(content: "くる becomes こ(ら)れる."))],
                        ]))
                    ]
                ])
            )
        case .potential_passive:
            InflectionDescription(
                short: "potential-passive",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Indicates an action received from an action performer."))],
                            [.text(StringContent(content: "Expresses respect for the subject of action performer."))],
                            [.text(StringContent(content: "Indicates a state of being (naturally) capable of doing an action."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach られる to the irrealis form (未然形) of ichidan verbs."))],
                            [.text(StringContent(content: "する becomes せられる."))],
                            [.text(StringContent(content: "くる becomes こられる."))],
                        ]))
                    ]
                ])
            )
        case .volitional:
            InflectionDescription(
                short: "volutional",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Expresses speaker's will or intention."))],
                            [.text(StringContent(content: "Expresses an invitation to the other party."))],
                            [.text(StringContent(content: "(Used in …ようとする) Indicates being on the verge of initiating an action or transforming a state."))],
                            [.text(StringContent(content: "Indicates an inference of a matter."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach よう to the irrealis form (未然形) of ichidan verbs."))],
                            [.text(StringContent(content: "Attach う to the irrealis form (未然形) of godan verbs after -o euphonic change form."))],
                            [.text(StringContent(content: "Attach かろう to the stem of i-adjectives (4th meaning only)."))],
                        ]))
                    ]
                ])
            )
        case .volitional_slang:
            InflectionDescription(
                short: "volitional-slang",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Expresses speaker's will or intention."))],
                            [.text(StringContent(content: "Expresses an invitation to the other party."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Replace final う of volitional form with っ then add か (よう → よっか)."))],
                        ]))
                    ]
                ])
            )
        case .mai:
            InflectionDescription(
                short: "ーまい",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Negative volitional form of verbs")), tag: "span", font: .body))],
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Expresses speaker's assumption that something is likely not true."))],
                            [.text(StringContent(content: "Expresses speaker's will or intention not to do something."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach まい to the dictionary form (終止形) of verbs."))],
                            [.text(StringContent(content: "Attach まい to the irrealis form (未然形) of ichidan verbs."))],
                            [.text(StringContent(content: "する becomes しまい."))],
                            [.text(StringContent(content: "くる becomes こまい."))],
                        ]))
                    ]
                ])
            )
        case .oku:
            InflectionDescription(
                short: "ーおく",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "To do certain things in advance in preparation (or in anticipation) of latter needs."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach おく to the て-form of verbs."))],
                            [.text(StringContent(content: "Attach でおく after ない negative form of verbs."))],
                            [.text(StringContent(content: "Contracts to とく・どく in speech."))],
                        ]))
                    ]
                ])
            )
        case .ki:
            InflectionDescription(
                short: "ーき",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Attributive form (連体形) of i-adjectives. An archaic form that remains in modern Japanese")), tag: "span", font: .body))],
                ])
            )
        case .ge:
            InflectionDescription(
                short: "ーげ",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Describes a person's appearance. Shows feelings of the person."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach げ or 気 to the stem of i-adjectives."))],
                        ]))
                    ]
                ])
            )
        case .garu:
            InflectionDescription(
                short: "ーがる",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Shows subject’s feelings contrast with what is thought/known about them."))],
                            [.text(StringContent(content: "Indicates subject's behavior (stands out)."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "Attach がる to the stem of i-adjectives."))],
                            [.text(StringContent(content: "It itself conjugates as a godan verb."))],
                        ]))
                    ]
                ])
            )
        case .e:
            InflectionDescription(
                short: "ーえ",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Slang")), tag: "span", font: .body))],
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "A sound change of i-adjectives."))],
                        ]))
                    ],
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
                    [
                        .list(StructuredContentList(content: [
                            [.text(StringContent(content: "ai：やばい → やべぇ."))],
                            [.text(StringContent(content: "ui：さむい → さみぃ/さめぇ."))],
                            [.text(StringContent(content: "oi：すごい → すげぇ."))],
                        ]))
                    ]
                ])
            )
        case .n_slang:
            InflectionDescription(
                short: "ーん-slang",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Slang")), tag: "span", font: .body))],
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Sound change of r-column syllables to n (when before an n-sound, usually の or な)."))],
                        ]))
                    ],
                ])
            )
        case .imperative_negative_slang:
            InflectionDescription(
                short: "imperative-negative-slang",
                description: .array([
                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Imperative negative slang")), tag: "span", font: .body))],
                ])
            )
        case .kansai_negative:
            InflectionDescription(
                short: "negative（関西弁）",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Negative form of kansai-ben verbs."))],
                        ]))
                    ],
//                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
//                    [
//                        .list(StructuredContentList(content: [
//                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
//                        ]))
//                    ]
                    // TODO
                ])
            )
        case .kansai_te:
            InflectionDescription(
                short: "ーて（関西弁）",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "ーて form of kansai-ben verbs."))],
                        ]))
                    ],
//                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
//                    [
//                        .list(StructuredContentList(content: [
//                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
//                        ]))
//                    ]
                ])
            )
        case .kansai_ta:
            InflectionDescription(
                short: "ーた（関西弁）",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "ーた form of kansai-ben terms."))],
                        ]))
                    ],
//                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
//                    [
//                        .list(StructuredContentList(content: [
//                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
//                        ]))
//                    ]
                ])
            )
        case .kansai_tara:
            InflectionDescription(
                short: "ーたら（関西弁）",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "ーたら form of kansai-ben terms."))],
                        ]))
                    ],
//                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
//                    [
//                        .list(StructuredContentList(content: [
//                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
//                        ]))
//                    ]
                ])
            )
        case .kansai_tari:
            InflectionDescription(
                short: "ーたり（関西弁）",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "ーたり form of kansai-ben terms."))],
                        ]))
                    ],
//                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
//                    [
//                        .list(StructuredContentList(content: [
//                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
//                        ]))
//                    ]
                ])
            )
        case .kansai_ku:
            InflectionDescription(
                short: "ーく（関西弁）",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "ーく stem of kansai-ben adjectives."))],
                        ]))
                    ],
//                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
//                    [
//                        .list(StructuredContentList(content: [
//                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
//                        ]))
//                    ]
                ])
            )
        case .kansai_adj_te:
            InflectionDescription(
                short: "adjーて（関西弁）",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "ーて form of kansai-ben adjectives."))],
                        ]))
                    ],
//                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
//                    [
//                        .list(StructuredContentList(content: [
//                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
//                        ]))
//                    ]
                ])
            )
        case .kansai_adj_negative:
            InflectionDescription(
                short: "adj-negative (関西弁)",
                description: .array([
                    [
                        .numberedList(StructuredContentList(content: [
                            [.text(StringContent(content: "Negative form of kansai-ben adjectives."))],
                        ]))
                    ],
//                    [.inlineContainer(StructuredContentContainer(data: .text(StringContent(content: "Usage:")), tag: "span", font: .title))],
//                    [
//                        .list(StructuredContentList(content: [
//                            [.text(StringContent(content: "Attach ば to the hypothetical form (仮定形) of verbs and i-adjectives."))],
//                        ]))
//                    ]
                ])
            )
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
    case sa = "ーさ"
    case passive = "passive"
    case potential = "potential"
    case potential_passive = "potential or passive"
    case volitional = "volitional"
    case volitional_slang = "volitional slang"
    case mai = "ーまい"
    case oku = "ーおく"
    case ki = "ーき"
    case ge = "ーげ"
    case garu = "ーがる"
    case e = "ーえ"
    case n_slang = "ーんな"
    case imperative_negative_slang = "imperative negative slang"
    case kansai_negative = "関西弁 negative" //
    case kansai_te = "関西弁　ーて" //
    case kansai_ta = "関西弁　ーた" //
    case kansai_tara = "関西弁　ーたら" //
    case kansai_tari = "関西弁　ーたり" //
    case kansai_ku = "関西弁 ーく" //
    case kansai_adj_te = "関西弁 adjective ーて" //
    case kansai_adj_negative = "関西弁 adjective negative" //
    
}


public struct Deinflection : Hashable {
    
    public let text: String
    public let inflections: [InflectionRule]
    public let types: [WordType]
    
}
