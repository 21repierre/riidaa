//
//  InflectionTests.swift
//  riidaaTests
//

import Testing
@testable import riidaa

struct InflectionTests {

    private func candidates(_ text: String) -> [Deinflection] {
        Inflection.deinflect(text: text)
    }

    private func recovers(_ inflected: String, _ dictionaryForm: String, _ type: WordType) -> Bool {
        candidates(inflected).contains { $0.text == dictionaryForm && $0.types.contains(type) }
    }

    @Test func recoversGodanStems() {
        #expect(recovers("読まない", "読む", .v5))
        #expect(recovers("泳ごう", "泳ぐ", .v5))
        #expect(recovers("分からん", "分かる", .v5))
        #expect(recovers("思っている", "思う", .v5))
        #expect(recovers("行って", "行く", .v5))
    }

    @Test func recoversIchidanAndIrregularStems() {
        #expect(recovers("食べた", "食べる", .v1))
        #expect(recovers("来た", "来る", .vk))
        #expect(recovers("してた", "する", .vs))
    }

    @Test func recoversAdjectiveStems() {
        #expect(recovers("大きくない", "大きい", .adj_i))
        #expect(recovers("高くて", "高い", .adj_i))
        #expect(recovers("買いたかった", "買いたい", .adj_i))
    }

    @Test func unwindsStackedInflections() {
        #expect(recovers("手伝わされる", "手伝う", .v5))
        #expect(recovers("言われたら", "言う", .v5))
        #expect(recovers("食べさせられた", "食べる", .v1))
        #expect(recovers("させられなかった", "する", .vs))
        #expect(recovers("飲みすぎた", "飲む", .v5))
        #expect(recovers("買いたかった", "買う", .v5))
        #expect(recovers("やっちゃった", "やる", .v5))
    }

    @Test func namesTheRulesItApplied() {
        let stacked = candidates("食べさせられた").first { $0.text == "食べる" && $0.types.contains(.v1) }
        #expect(stacked?.inflections == [.ta, .potential_passive, .causative])
        #expect(candidates("読まない").first { $0.text == "読む" }?.inflections == [.negative])
    }

    @Test func keepsTheOriginalWord() {
        for word in ["食べる", "本", "手伝わされる"] {
            #expect(candidates(word).contains { $0.text == word })
        }
    }

}
