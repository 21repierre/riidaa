//
//  FuriganaTests.swift
//  riidaaTests
//

import Testing
import riidaa

struct FuriganaTests {

    @Test func annotatesKanjiAndOkurigana() {
        #expect(Furigana.annotate(term: "番地", reading: "ばんち") == "番地[ばんち]")
        #expect(Furigana.annotate(term: "人々", reading: "ひとびと") == "人々[ひとびと]")
        #expect(Furigana.annotate(term: "思う", reading: "おもう") == "思[おも]う")
        #expect(Furigana.annotate(term: "気持ち", reading: "きもち") == "気持[きも]ち")
        #expect(Furigana.annotate(term: "勉強する", reading: "べんきょうする") == "勉強[べんきょう]する")
    }

    /// Anki reads a group's base back to the previous space, and interior kana have to keep
    /// their place rather than being swallowed into one group.
    @Test func spacesGroupsAndDistributesAroundInteriorKana() {
        #expect(Furigana.annotate(term: "お茶", reading: "おちゃ") == "お 茶[ちゃ]")
        #expect(Furigana.annotate(term: "お兄さん", reading: "おにいさん") == "お 兄[にい]さん")
        #expect(Furigana.annotate(term: "引っ越し", reading: "ひっこし") == "引[ひ]っ 越[こ]し")
        #expect(Furigana.annotate(term: "見た目", reading: "みため") == "見[み]た 目[め]")
        #expect(Furigana.annotate(term: "持ち込む", reading: "もちこむ") == "持[も]ち 込[こ]む")
        #expect(Furigana.annotate(term: "立ち上がる", reading: "たちあがる") == "立[た]ち 上[あ]がる")
    }

    /// The reading of the dictionary form carries over to the stem the inflected form shares.
    @Test func annotatesInflectedForms() {
        #expect(Furigana.annotate(surface: "流れ出た", term: "流れ出る", reading: "ながれでる") == "流[なが]れ 出[で]た")
        #expect(Furigana.annotate(surface: "飛び移った", term: "飛び移る", reading: "とびうつる") == "飛[と]び 移[うつ]った")
        #expect(Furigana.annotate(surface: "似合う", term: "似合い", reading: "にあい") == "似合[にあ]う")
        #expect(Furigana.annotate(surface: "当機", term: "当機", reading: "とうき") == "当機[とうき]")
        #expect(Furigana.annotate(surface: "おもった", term: "思う", reading: "おもう") == nil)
        #expect(Furigana.annotate(surface: "来た", term: "来る", reading: "くる") == nil)
        #expect(Furigana.annotate(surface: "帰って来た", term: "帰って来る", reading: "かえってくる") == nil)
    }

    /// ヶ reads か, so the kana can't be anchored; one coarse group is still valid furigana.
    @Test func handlesReadingsThatDoNotLineUp() {
        #expect(Furigana.annotate(term: "ヶ月", reading: "かげつ") == "ヶ月[かげつ]")
        #expect(Furigana.annotate(term: "コーヒー", reading: "こーひー") == "コーヒー[こーひー]")
        #expect(Furigana.annotate(term: "ある", reading: "ある") == "ある")
        #expect(Furigana.annotate(term: "猫", reading: "") == "猫")
        #expect(Furigana.annotate(term: "", reading: "ねこ") == nil)
    }

}
