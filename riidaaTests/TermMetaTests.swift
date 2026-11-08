//
//  TermMetaTests.swift
//  riidaaTests
//

import Foundation
import Testing
@testable import riidaa

struct TermMetaTests {

    private func json(_ raw: String) -> Any {
        try! JSONSerialization.jsonObject(with: raw.data(using: .utf8)!, options: [.fragmentsAllowed])
    }

    private func dictionary(_ title: String) -> DictionaryDB {
        DictionaryDB(id: 1, revision: "", title: title, format: 3)
    }

    /// Both shapes JPDB ships: a bare rating for kana entries and a reading-scoped one for
    /// words written in kanji. The spec also allows a plain number or string.
    @Test func parsesTheFrequencyShapesRealDictionariesUse() throws {
        let bare = try #require(TermMetaParser.parse(mode: "freq", data: json(#"{"value": 1, "displayValue": "1㋕"}"#)))
        #expect(bare.reading == "")
        guard case .frequency(let a) = bare.content else { Issue.record("not a frequency"); return }
        #expect(a.value == 1 && a.display == "1㋕")

        let scoped = try #require(TermMetaParser.parse(
            mode: "freq", data: json(#"{"reading": "おもう", "frequency": {"value": 20, "displayValue": "20"}}"#)
        ))
        #expect(scoped.reading == "おもう")

        let number = try #require(TermMetaParser.parse(mode: "freq", data: json("1234")))
        guard case .frequency(let b) = number.content else { Issue.record("not a frequency"); return }
        #expect(b.value == 1234)

        #expect(TermMetaParser.parse(mode: "ipa", data: json(#"{"reading":"x"}"#)) == nil)
        #expect(TermMetaParser.parse(mode: "freq", data: json(#"{"nonsense": true}"#)) == nil)
    }

    @Test func parsesPitchWithDevoicing() throws {
        let parsed = try #require(TermMetaParser.parse(
            mode: "pitch", data: json(#"{"reading": "しんぴ", "pitches": [{"position": 1, "devoice": [2]}]}"#)
        ))
        #expect(parsed.reading == "しんぴ")
        guard case .pitch(let accents) = parsed.content else { Issue.record("not a pitch"); return }
        #expect(accents == [PitchAccent(position: 1, devoice: [2])])
    }

    @Test func namesThePitchPatternFromTheMoraCount() {
        #expect(PitchAccent(position: 0, devoice: []).category(moraCount: 4) == "heiban")
        #expect(PitchAccent(position: 1, devoice: []).category(moraCount: 4) == "atamadaka")
        #expect(PitchAccent(position: 2, devoice: []).category(moraCount: 4) == "nakadaka")
        #expect(PitchAccent(position: 4, devoice: []).category(moraCount: 4) == "odaka")

        #expect(PitchAccent.moraCount(of: "きょう") == 2)
        #expect(PitchAccent.moraCount(of: "がっこう") == 4)
    }

    /// The Manabi deck's dot graph, with larger kana centred under their dots.
    @Test func drawsTheDotGraphAsTheManabiDeckDoes() {
        let heiban = PitchAccent(position: 0, devoice: []).dotGraph(reading: "へいきん")
        #expect(heiban == #"<svg xmlns="http://www.w3.org/2000/svg" class="pitch" width="150.00px" height="63.00px" viewBox="0 0 200 84"><text x="16" y="76" text-anchor="middle" style="font-size:26px;font-family:sans-serif;fill:currentColor;">へ</text><text x="58" y="76" text-anchor="middle" style="font-size:26px;font-family:sans-serif;fill:currentColor;">い</text><text x="100" y="76" text-anchor="middle" style="font-size:26px;font-family:sans-serif;fill:currentColor;">き</text><text x="142" y="76" text-anchor="middle" style="font-size:26px;font-family:sans-serif;fill:currentColor;">ん</text><path d="m 16,30 42,-25" style="fill:none;stroke:currentColor;stroke-width:1.5;" /><path d="m 58,5 42,0" style="fill:none;stroke:currentColor;stroke-width:1.5;" /><path d="m 100,5 42,0" style="fill:none;stroke:currentColor;stroke-width:1.5;" /><path d="m 142,5 42,0" style="fill:none;stroke:currentColor;stroke-width:1.5;" /><circle r="5" cx="16" cy="30" style="opacity:1;fill:currentColor;" /><circle r="5" cx="58" cy="5" style="opacity:1;fill:currentColor;" /><circle r="5" cx="100" cy="5" style="opacity:1;fill:currentColor;" /><circle r="5" cx="142" cy="5" style="opacity:1;fill:currentColor;" /><circle r="4" cx="184" cy="5" style="opacity:1;fill:none;stroke:currentColor;stroke-width:1.75;" /></svg>"#)

        let nakadaka = PitchAccent(position: 2, devoice: []).dotGraph(reading: "うける")
        #expect(nakadaka == #"<svg xmlns="http://www.w3.org/2000/svg" class="pitch" width="118.50px" height="63.00px" viewBox="0 0 158 84"><text x="16" y="76" text-anchor="middle" style="font-size:26px;font-family:sans-serif;fill:currentColor;">う</text><text x="58" y="76" text-anchor="middle" style="font-size:26px;font-family:sans-serif;fill:currentColor;">け</text><text x="100" y="76" text-anchor="middle" style="font-size:26px;font-family:sans-serif;fill:currentColor;">る</text><path d="m 16,30 42,-25" style="fill:none;stroke:currentColor;stroke-width:1.5;" /><path d="m 58,5 42,25" style="fill:none;stroke:currentColor;stroke-width:1.5;" /><path d="m 100,30 42,0" style="fill:none;stroke:currentColor;stroke-width:1.5;" /><circle r="5" cx="16" cy="30" style="opacity:1;fill:currentColor;" /><circle r="5" cx="58" cy="5" style="opacity:1;fill:currentColor;" /><circle r="5" cx="100" cy="30" style="opacity:1;fill:currentColor;" /><circle r="4" cx="142" cy="30" style="opacity:1;fill:none;stroke:currentColor;stroke-width:1.75;" /></svg>"#)

        let combined = PitchAccent(position: 1, devoice: []).dotGraph(reading: "きょう")
        #expect(combined.contains(">きょ</text>"))
        #expect(combined.components(separatedBy: "<text").count - 1 == 2)
    }

    /// 夫妻 carries two ratings under one reading in JPDB, so neither may be collapsed — but a
    /// rating filed under both the term and its reading comes back twice and must be.
    @Test func summarisesWithoutLosingOrDuplicatingRatings() {
        let meta = [
            TermMetaDB(term: "夫妻", reading: "ふさい", dictionary: dictionary("JPDB"),
                       content: .frequency(TermFrequency(value: 6923, display: "6923"))),
            TermMetaDB(term: "夫妻", reading: "ふさい", dictionary: dictionary("JPDB"),
                       content: .frequency(TermFrequency(value: 55898, display: "55898㋕"))),
            TermMetaDB(term: "夫妻", reading: "ふさい", dictionary: dictionary("JPDB"),
                       content: .frequency(TermFrequency(value: 6923, display: "6923"))),
            TermMetaDB(term: "夫妻", reading: "ふうさい", dictionary: dictionary("JPDB"),
                       content: .frequency(TermFrequency(value: 1, display: "1"))),
        ]
        let summary = TermMetaSummary(meta: meta, term: "夫妻", reading: "ふさい")
        #expect(summary.frequencyLabels == ["JPDB: 6923 (55898㋕)"])
        #expect(summary.frequencySortValue == 6923)
        #expect(TermMetaSummary(meta: [], term: "猫", reading: "ねこ").isEmpty)
    }

    /// 紙 is fetched by its reading too, which brings back rows filed under the bare かみ.
    @Test func ignoresMetadataFiledUnderAnotherWordWithTheSameReading() {
        let meta = [
            TermMetaDB(term: "紙", reading: "かみ", dictionary: dictionary("Pitch"),
                       content: .pitch([PitchAccent(position: 2, devoice: [])])),
            TermMetaDB(term: "かみ", reading: "かみ", dictionary: dictionary("Pitch"),
                       content: .pitch([PitchAccent(position: 1, devoice: [])])),
        ]
        #expect(TermMetaSummary(meta: meta, term: "紙", reading: "かみ").pitchNumbers == ["2"])
    }

}
