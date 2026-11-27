//
//  AnkiExportTests.swift
//  riidaaTests
//

import Foundation
import Testing
@testable import riidaa

struct AnkiExportTests {

    private func makeTerm(term: String, reading: String) -> TermDB {
        TermDB(
            term: term, reading: reading, definitionTags: [], wordTypes: [], score: 0,
            definitions: Data(), sequenceNumber: 0, termTags: [],
            dictionary: DictionaryDB(id: 1, revision: "", title: "Jitendex", format: 3),
            exportedToAnki: false
        )
    }

    /// Waits for the definitions, which `TermDB` decodes on a background queue.
    @MainActor
    private func makeTerm(term: String, reading: String, definitions json: String) async -> TermDB {
        let made = TermDB(
            term: term, reading: reading, definitionTags: [], wordTypes: [], score: 0,
            definitions: Data(json.utf8), sequenceNumber: 0, termTags: [],
            dictionary: DictionaryDB(id: 1, revision: "", title: "Jitendex", format: 3),
            exportedToAnki: false
        )
        made.loadDefinitions()
        for _ in 0..<120 where made.parseDefinition.isEmpty {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        return made
    }

    private func exported(_ tokens: [AnkiFieldToken: String], _ context: AnkiNoteContext) throws -> [String: String] {
        exportedFields(try #require(makeExport(fields: tokens).addNoteURL(context: context, callback: "x")))
    }

    private func makeExport(fields: [AnkiFieldToken: String]) -> AnkiExport {
        AnkiExport(profile: "ユーザー 1", deck: "Mining", noteType: "Lapis", fields: fields)
    }

    /// Fields AnkiMobile receives, keyed by name (`fldWord=…` → `Word`).
    private func exportedFields(_ url: URL) -> [String: String] {
        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return [:]
        }
        var fields: [String: String] = [:]
        for item in items where item.name.hasPrefix("fld") {
            fields[String(item.name.dropFirst(3))] = item.value ?? ""
        }
        return fields
    }

    @Test func exportsMappedFieldsAndSkipsTheRest() throws {
        let context = AnkiNoteContext(
            term: makeTerm(term: "番地", reading: "ばんち"),
            sentence: "この番地はどこですか",
            source: MangaSource(title: "よつばと！", volume: 3, page: 42),
            audioURL: WordAudio.url(term: "番地", reading: "ばんち")
        )
        let url = try #require(makeExport(fields: [
            .word: "Word", .reading: "Word Reading", .furigana: "Word Furigana",
            .sentence: "Sentence", .source: "Notes", .audio: "Word Audio", .glossary: "Glossary",
        ]).addNoteURL(context: context, callback: "riidaa://done"))
        let fields = exportedFields(url)

        #expect(fields["Word"] == "番地")
        #expect(fields["Word Reading"] == "ばんち")
        #expect(fields["Word Furigana"] == "番地[ばんち]")
        #expect(fields["Sentence"] == "この番地はどこですか")
        #expect(fields["Notes"] == "よつばと！ vol.3 p.42")
        #expect(fields["Word Audio"]?.hasPrefix("https://assets.languagepod101.com/") == true)
        // Mapped but with nothing to put in it.
        #expect(fields["Glossary"] == nil)

        #expect(makeExport(fields: [:]).addNoteURL(context: context, callback: "x") == nil)
    }

    /// `&`, `=` and `+` in a value used to split it into extra fields, and the callback carries
    /// its own query string that has to survive as one value.
    @Test func escapesQueryDelimiters() throws {
        let context = AnkiNoteContext(
            term: makeTerm(term: "猫", reading: "ねこ"), sentence: "A&B=C+D", source: nil
        )
        let url = try #require(makeExport(fields: [.word: "Word", .sentence: "Sentence"])
            .addNoteURL(context: context, callback: "riidaa://anki-callback?term=42"))

        #expect(exportedFields(url)["Sentence"] == "A&amp;B=C+D")
        #expect(exportedFields(url).count == 2)
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(items.first { $0.name == "x-success" }?.value == "riidaa://anki-callback?term=42")
    }

    /// The bolded word is the inflected form the parser matched, at its exact offset — and a
    /// match that doesn't land there must leave the sentence alone.
    @Test func boldsTheLookedUpWord() throws {
        func sentence(_ match: SentenceMatch?, in text: String) throws -> String? {
            let context = AnkiNoteContext(
                term: makeTerm(term: "思う", reading: "おもう"), sentence: text, source: nil, match: match
            )
            let url = try #require(makeExport(fields: [.sentence: "Sentence"])
                .addNoteURL(context: context, callback: "x"))
            return exportedFields(url)["Sentence"]
        }

        #expect(try sentence(SentenceMatch(surface: "思っている", offset: 8), in: "君は学校を何だと思っているのかね")
            == "君は学校を何だと<b>思っている</b>のかね")
        // The second occurrence, not the first.
        #expect(try sentence(SentenceMatch(surface: "猫", offset: 2), in: "猫と猫") == "猫と<b>猫</b>")

        for bad in [SentenceMatch(surface: "犬", offset: 0), SentenceMatch(surface: "猫", offset: 99)] {
            #expect(try sentence(bad, in: "猫がいる") == "猫がいる")
        }
    }

    /// Alias order is what puts the sentence in `Sentence` rather than Lapis's `SelectionText`,
    /// and no two tokens may claim the same field.
    @Test func mapsRealNoteTypesAutomatically() {
        let lapis = ["Expression", "ExpressionFurigana", "ExpressionReading", "ExpressionAudio",
                     "SelectionText", "MainDefinition", "DefinitionPicture", "Sentence",
                     "SentenceFurigana", "SentenceAudio", "Picture", "Glossary", "Hint",
                     "PitchPosition", "PitchCategories", "Frequency", "FreqSort", "MiscInfo"]
        let mapped = AnkiFieldToken.suggestedMapping(for: lapis)
        #expect(mapped[.word] == "Expression")
        #expect(mapped[.sentence] == "Sentence")
        #expect(mapped[.furigana] == "ExpressionFurigana")
        #expect(mapped[.audio] == "ExpressionAudio")
        #expect(mapped[.picture] == "Picture")
        #expect(mapped[.pitch] == "PitchPosition")
        #expect(mapped[.pitchGraph] == nil)
        #expect(mapped[.frequency] == "Frequency")
        #expect(mapped[.source] == "MiscInfo")
        #expect(Set(mapped.values).count == mapped.count)

        let kaishi = AnkiFieldToken.suggestedMapping(
            for: ["Word", "Word Reading", "Word Meaning", "Word Furigana", "Word Audio",
                  "Sentence", "Sentence Furigana", "Notes", "Pitch Accent", "Frequency", "Picture"]
        )
        #expect(kaishi[.word] == "Word")
        #expect(kaishi[.meaning] == "Word Meaning")
        // A field called "Pitch Accent" wants the diagram; Lapis names its numeric one
        // "PitchPosition".
        #expect(kaishi[.pitchGraph] == "Pitch Accent")
        #expect(kaishi[.pitch] == nil)
        #expect(kaishi[.source] == "Notes")
        #expect(kaishi[.sentenceFurigana] == "Sentence Furigana")

        let manabi = AnkiFieldToken.suggestedMapping(
            for: ["Word", "Word Hiragana", "Word Furigana", "Word Romaji", "Word Meaning", "Word Audio",
                  "Sentence", "Sentence Furigana", "Notes", "Frequency", "Pitch Accent", "Pitch Number",
                  "Picture"]
        )
        #expect(manabi[.hiragana] == "Word Hiragana")
        #expect(manabi[.romaji] == "Word Romaji")
        #expect(manabi[.pitchNumber] == "Pitch Number")
        #expect(manabi[.pitchDotGraph] == "Pitch Accent")
        #expect(manabi[.pitchGraph] == nil)
        #expect(manabi[.picture] == "Picture")
        #expect(kaishi[.reading] == "Word Reading")

        #expect(AnkiFieldToken.suggestedMapping(for: ["Champ1", "Zzz"]).isEmpty)
    }

    /// Cards from the owner's Manabi deck: mokuro's ．．． read as …, a bubble's other sentences
    /// dropped, and the bold word given its reading in the furigana field.
    @Test func tidiesTheSentenceForTheCard() throws {
        let bubble = "本日は当機を．．．ありがとうござ．．．イギリス上空にて大気圏に突入します。ご搭乗の皆様はシートハーネスを．．．"
        let tidied = try exported([.sentence: "Sentence", .sentenceFurigana: "Sentence Furigana"], AnkiNoteContext(
            term: makeTerm(term: "当機", reading: "とうき"), sentence: bubble, source: nil,
            match: SentenceMatch(surface: "当機", offset: 3)
        ))
        #expect(tidied["Sentence"] == "本日は<b>当機</b>を…ありがとうござ…イギリス上空にて大気圏に突入します。")
        #expect(tidied["Sentence Furigana"] == "本日は<b>当機[とうき]</b>を…ありがとうござ…イギリス上空にて大気圏に突入します。")

        let inflected = try exported([.sentenceFurigana: "Sentence Furigana"], AnkiNoteContext(
            term: makeTerm(term: "流れ出る", reading: "ながれでる"), sentence: "全ては地上から流れ出たもの．．．",
            source: nil, match: SentenceMatch(surface: "流れ出た", offset: 7)
        ))
        #expect(inflected["Sentence Furigana"] == "全ては地上から<b>流[なが]れ 出[で]た</b>もの…")

        let later = try exported([.sentence: "Sentence"], AnkiNoteContext(
            term: makeTerm(term: "お前", reading: "おまえ"), sentence: "やめろ！！お前が悪い。そうだろ？",
            source: nil, match: SentenceMatch(surface: "お前", offset: 5)
        ))
        #expect(later["Sentence"] == "<b>お前</b>が悪い。")

        // A closing quote mid-sentence is not a sentence end.
        let quoted = try exported([.sentence: "Sentence"], AnkiNoteContext(
            term: makeTerm(term: "言う", reading: "いう"), sentence: "「行くぞ」と言った",
            source: nil, match: SentenceMatch(surface: "言った", offset: 6)
        ))
        #expect(quoted["Sentence"] == "「行くぞ」と<b>言った</b>")

        // Nor is a ！ inside a quote that と or って carries on from.
        let exclaimed = try exported([.sentence: "Sentence"], AnkiNoteContext(
            term: makeTerm(term: "言う", reading: "いう"), sentence: "えっ。「やめろ！」って言ったのに",
            source: nil, match: SentenceMatch(surface: "言った", offset: 11)
        ))
        #expect(exclaimed["Sentence"] == "「やめろ！」って<b>言った</b>のに")

        let speaker = try exported([.sentence: "Sentence"], AnkiNoteContext(
            term: makeTerm(term: "行く", reading: "いく"), sentence: "「行くぞ！」と言った。次だ",
            source: nil, match: SentenceMatch(surface: "行く", offset: 1)
        ))
        #expect(speaker["Sentence"] == "「<b>行く</b>ぞ！」と言った。")
    }

    /// Fixtures are the real Jitendex entries: the forms table must not leak into the card, and
    /// the meaning is the first sense's first few glosses.
    @Test func keepsTheMeaningToTheFirstFewGlosses() async throws {
        let mijinko = await makeTerm(term: "微塵子", reading: "みじんこ", definitions: #"[{"type":"structured-content","content":[{"tag":"div","data":{"content":"sense-group"},"content":[{"tag":"span","data":{"class":"tag","code":"n","content":"part-of-speech-info"},"content":"noun"},{"tag":"div","data":{"content":"sense"},"content":{"tag":"ul","data":{"content":"glossary"},"content":{"tag":"li","content":"water flea (Daphnia spp.)"}}}]},{"tag":"div","data":{"content":"forms"},"content":[{"tag":"span","data":{"class":"tag","content":"forms-label"},"content":"forms"},{"tag":"table","content":[{"tag":"tr","data":{"content":"forms-header-row"},"content":[{"tag":"th"},{"tag":"th","content":{"tag":"span","data":{"class":"form-special"},"content":"∅"}},{"tag":"th","content":"微塵子"},{"tag":"th","content":"水蚤"}]},{"tag":"tr","content":[{"tag":"th","content":"みじんこ"},{"tag":"td","data":{"class":"form-valid"},"content":{"tag":"span"}}]}]}]}]}]"#)
        let mijinkoFields = try exported([.meaning: "Meaning", .glossary: "Glossary"],
                                         AnkiNoteContext(term: mijinko, sentence: "", source: nil))
        #expect(mijinkoFields["Meaning"] == "water flea (Daphnia spp.)")
        #expect(mijinkoFields["Glossary"]?.contains("水蚤") == false)

        let nagarederu = await makeTerm(term: "流れ出る", reading: "ながれでる", definitions: #"[{"type":"structured-content","content":[{"tag":"div","data":{"content":"sense-group"},"content":[{"tag":"span","data":{"class":"tag","code":"v1","content":"part-of-speech-info"},"content":"1-dan"},{"tag":"div","data":{"content":"sense"},"content":[{"tag":"ul","data":{"content":"glossary"},"content":[{"tag":"li","content":"to flow out"},{"tag":"li","content":"to stream out"},{"tag":"li","content":"to pour out"},{"tag":"li","content":"to gush forth"},{"tag":"li","content":"to leak"}]}]}]}]}]"#)
        let nagarederuFields = try exported([.meaning: "Meaning"],
                                            AnkiNoteContext(term: nagarederu, sentence: "", source: nil))
        #expect(nagarederuFields["Meaning"] == "to flow out, to stream out, to pour out")
    }

    /// Manabi's Word Hiragana holds hiragana even for katakana words. Its romaji mixes ō and ou;
    /// the system transliteration writes ou.
    @Test func exportsHiraganaAndRomaji() throws {
        let fields: [AnkiFieldToken: String] = [.hiragana: "Word Hiragana", .romaji: "Word Romaji"]
        let konbini = try exported(fields, AnkiNoteContext(term: makeTerm(term: "コンビニ", reading: "コンビニ"), sentence: "", source: nil))
        #expect(konbini["Word Hiragana"] == "こんびに")
        #expect(konbini["Word Romaji"] == "konbini")
        let daijoubu = try exported(fields, AnkiNoteContext(term: makeTerm(term: "大丈夫", reading: "だいじょうぶ"), sentence: "", source: nil))
        #expect(daijoubu["Word Romaji"] == "daijoubu")
    }

    /// Fields are HTML: a title or word with `<` or `&` must not open a tag or an entity.
    @Test func escapesPlainTextFields() throws {
        let fields = try exported([.word: "Word", .source: "Notes"], AnkiNoteContext(
            term: makeTerm(term: "A&B", reading: "えーびー"), sentence: "",
            source: MangaSource(title: "Foo <Bar>", volume: 1, page: 2)
        ))
        #expect(fields["Word"] == "A&amp;B")
        #expect(fields["Notes"] == "Foo &lt;Bar&gt; vol.1 p.2")
    }

    /// A field named by two tokens used to be sent twice, leaving AnkiMobile to pick one.
    @Test func sendsEachFieldOnce() throws {
        let url = try #require(makeExport(fields: [.word: "Word", .reading: "Word"]).addNoteURL(
            context: AnkiNoteContext(term: makeTerm(term: "猫", reading: "ねこ"), sentence: "", source: nil),
            callback: "x"
        ))
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(items.filter { $0.name == "fldWord" }.map(\.value) == ["猫"])

        let settings = SettingsModel(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        settings.ankiNoteType = AnkiInfo.NoteType(name: "Manabi", kind: "normal", fields: [.init(name: "Pitch Accent")])
        settings.ankiFieldBinding(for: .pitchGraph).wrappedValue = "Pitch Accent"
        settings.ankiFieldBinding(for: .pitchDotGraph).wrappedValue = "Pitch Accent"
        #expect(settings.ankiFields[AnkiFieldToken.pitchGraph.rawValue] == nil)
        #expect(settings.ankiFields[AnkiFieldToken.pitchDotGraph.rawValue] == "Pitch Accent")
    }

    /// Each note type keeps its own mapping, so switching between them neither carries field
    /// names across ("field MiscInfo does not exist" on export) nor, like refreshing from
    /// AnkiMobile once did, resets to the first note type's.
    @Test func keepsAMappingPerNoteType() {
        let settings = SettingsModel(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let lapis = AnkiInfo.NoteType(name: "Lapis", kind: "normal",
            fields: [.init(name: "Expression"), .init(name: "MiscInfo"), .init(name: "Sentence")])
        let kaishi = AnkiInfo.NoteType(name: "Kaishi", kind: "normal",
            fields: [.init(name: "Word"), .init(name: "Sentence"), .init(name: "Notes")])
        let basic = AnkiInfo.NoteType(name: "Basic", kind: "normal", fields: [.init(name: "Front")])

        settings.ankiNoteType = lapis
        settings.autoMapAnkiFields(for: lapis)
        #expect(settings.ankiFields["source"] == "MiscInfo")

        settings.ankiNoteType = kaishi
        #expect(settings.ankiFields["source"] == "Notes")

        settings.apply(AnkiInfo(profiles: [.init(name: "User 1")], decks: [.init(name: "Default"), .init(name: "Mining")],
                                notetypes: [basic, lapis, kaishi]))
        #expect(settings.ankiNoteType?.name == "Kaishi")
        #expect(settings.ankiFields["source"] == "Notes")

        settings.ankiNoteType = lapis
        #expect(settings.ankiFields["source"] == "MiscInfo")
    }

    /// A mapping saved by an older version with no note type chosen is used once one is picked,
    /// rather than replaced by automatic matching.
    @Test func adoptsAnOldMappingWhenANoteTypeIsFirstPicked() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(try JSONEncoder().encode(["word": "Front", "meaning": "Back"]), forKey: "ankiFields")
        let settings = SettingsModel(defaults: defaults)

        settings.ankiNoteType = AnkiInfo.NoteType(name: "Basic", kind: "normal",
            fields: [.init(name: "Front"), .init(name: "Back")])

        #expect(settings.ankiFields == ["word": "Front", "meaning": "Back"])
    }

    /// A field renamed or deleted in AnkiMobile drops out of the mapping on the next refresh.
    @Test func refreshDropsFieldsTheNoteTypeNoLongerHas() {
        let settings = SettingsModel(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let before = AnkiInfo.NoteType(name: "Kaishi", kind: "normal",
            fields: [.init(name: "Word"), .init(name: "Picture")])
        settings.ankiNoteType = before
        settings.ankiFieldBinding(for: .word).wrappedValue = "Word"
        settings.ankiFieldBinding(for: .picture).wrappedValue = "Picture"

        let after = AnkiInfo.NoteType(name: "Kaishi", kind: "normal",
            fields: [.init(name: "Word"), .init(name: "Image")])
        settings.apply(AnkiInfo(profiles: [.init(name: "User 1")], decks: [.init(name: "Default")], notetypes: [after]))

        #expect(settings.ankiFields == [AnkiFieldToken.word.rawValue: "Word"])
    }

}
