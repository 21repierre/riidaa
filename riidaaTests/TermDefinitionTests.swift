//
//  TermDefinitionTests.swift
//  riidaaTests
//

import Foundation
import Testing
@testable import riidaa

@MainActor
struct TermDefinitionTests {

    private func definitions(_ json: String) async -> [ContentDefinition] {
        let term = TermDB(
            term: "猫", reading: "ねこ", definitionTags: [], wordTypes: [], score: 0,
            definitions: Data(json.utf8), sequenceNumber: 0, termTags: [],
            dictionary: DictionaryDB(id: 1, revision: "", title: "Test", format: 3),
            exportedToAnki: false
        )
        // Parsing is kicked off on a background queue by init and published on the main one.
        for _ in 0..<120 where term.parseDefinition.isEmpty {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        return term.parseDefinition
    }

    @Test func readsPlainGlosses() async {
        let parsed = await definitions(#"["to think", "to consider"]"#)
        #expect(parsed.count == 2)
        #expect(parsed.map(\.description) == ["to think", "to consider"])
    }

    @Test func readsTheTypedTextForm() async {
        let parsed = await definitions(#"[{"type": "text", "text": "to reckon"}]"#)
        #expect(parsed.map(\.description) == ["to reckon"])
    }

    @Test func readsARedirect() async {
        let parsed = await definitions(#"[["そう言う", ["redirected from そーゆー"]]]"#)
        guard case .deinflection(let d)? = parsed.first else {
            Issue.record("expected a deinflection, got \(parsed)"); return
        }
        #expect(d.text == "そう言う")
    }

    @Test func readsStructuredContent() async {
        let parsed = await definitions(#"""
        [{"type": "structured-content", "content": {"tag": "ul", "content": [
            {"tag": "li", "content": "to think"}, {"tag": "li", "content": "to believe"}]}}]
        """#)
        guard case .detailed(let content)? = parsed.first else {
            Issue.record("expected detailed content, got \(parsed)"); return
        }
        #expect(content.description.contains("to think"))
        #expect(content.description.contains("to believe"))
    }

    @Test func readsRubyText() async {
        let parsed = await definitions(#"""
        [{"type": "structured-content", "content":
            {"tag": "ruby", "content": ["猫", {"tag": "rt", "content": "ねこ"}]}}]
        """#)
        guard case .detailed(let content)? = parsed.first else {
            Issue.record("expected detailed content, got \(parsed)"); return
        }
        #expect(content.description.contains("猫"))
    }

    @Test func skipsWhatItCannotRead() async {
        let parsed = await definitions(#"[123, {}, {"type": "unknown"}, ["one element"], "to think"]"#)
        #expect(parsed.map(\.description) == ["to think"])
    }

    /// Malformed JSON is shown to the reader as the definition rather than dropped, so a broken
    /// dictionary looks broken instead of looking empty.
    @Test func surfacesADecodeFailure() async {
        let parsed = await definitions("not json at all")
        #expect(parsed.count == 1)
        #expect(!(parsed.first?.description.isEmpty ?? true))
    }

    @Test func keepsTheGoodPartsOfAMixedEntry() async {
        let parsed = await definitions(#"["to think", 123, {"type": "unknown"}, "to consider"]"#)
        #expect(parsed.map(\.description) == ["to think", "to consider"])
    }

}
