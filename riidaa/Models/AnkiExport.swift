//
//  AnkiExport.swift
//  riidaa
//

import Foundation

/// One value a lookup can contribute to an Anki note. Raw values are persisted in
/// `SettingsModel.ankiFields`, so renaming a case drops that mapping for existing users.
enum AnkiFieldToken: String, CaseIterable, Identifiable {
    case word
    case reading
    case hiragana
    case furigana
    case romaji
    case audio
    case picture
    case pitch
    case pitchNumber
    case pitchGraph
    case pitchDotGraph
    case pitchCategories
    case frequency
    case frequencySort
    case meaning
    case glossary
    case sentence
    case sentenceFurigana
    case source

    var id: String { rawValue }

    var label: String {
        switch self {
        case .word: return "word"
        case .reading: return "reading"
        case .hiragana: return "reading (hiragana)"
        case .furigana: return "furigana"
        case .romaji: return "romaji"
        case .audio: return "word audio"
        case .picture: return "page image"
        case .pitch: return "pitch accent (position)"
        case .pitchNumber: return "pitch accent (number)"
        case .pitchGraph: return "pitch accent (diagram)"
        case .pitchDotGraph: return "pitch accent (dot graph)"
        case .pitchCategories: return "pitch pattern"
        case .frequency: return "frequency"
        case .frequencySort: return "frequency (sort value)"
        case .meaning: return "meaning"
        case .glossary: return "full glossary"
        case .sentence: return "sentence"
        case .sentenceFurigana: return "sentence (furigana field)"
        case .source: return "source"
        }
    }
}

extension AnkiFieldToken {

    /// Field names
    var fieldNameAliases: [String] {
        switch self {
        case .word:
            return ["word", "expression", "term", "vocab", "vocabulary", "kanji", "front"]
        case .reading:
            return ["reading", "wordreading", "expressionreading", "kana", "yomi"]
        case .hiragana:
            return ["wordhiragana", "hiragana", "readinghiragana"]
        case .furigana:
            return ["furigana", "wordfurigana", "expressionfurigana", "kanafurigana", "reading furigana"]
        case .romaji:
            return ["romaji", "wordromaji", "readingromaji"]
        case .audio:
            return ["wordaudio", "expressionaudio", "audio", "termaudio", "pronunciation"]
        case .picture:
            return ["picture", "image", "screenshot", "definitionpicture"]
        case .pitch:
            return ["pitchposition", "pitch", "accent"]
        case .pitchNumber:
            return ["pitchnumber", "pitchaccentnumber"]
        case .pitchGraph:
            return ["pitchaccent", "pitchgraph", "pitchdiagram"]
        case .pitchDotGraph:
            return []
        case .pitchCategories:
            return ["pitchcategories", "pitchpattern", "pitchaccentcategories"]
        case .frequency:
            return ["frequency", "freq", "frequencies"]
        case .frequencySort:
            return ["freqsort", "frequencysort", "sortfrequency"]
        case .meaning:
            return ["meaning", "maindefinition", "definition", "wordmeaning", "back"]
        case .glossary:
            return ["glossary", "glossaries", "definitions", "fullglossary"]
        case .sentence:
            return ["sentence", "examplesentence", "example", "context"]
        case .sentenceFurigana:
            return ["sentencefurigana", "examplesentencefurigana"]
        case .source:
            return ["source", "miscinfo", "notes", "book", "title"]
        }
    }

    /// Exact matches only, so an unfamiliar note type maps nothing rather than misfiling.
    static func suggestedMapping(for fields: [String]) -> [AnkiFieldToken: String] {
        func normalized(_ name: String) -> String {
            name.lowercased().filter { $0.isLetter || $0.isNumber }
        }
        let candidates = fields.map { (name: $0, key: normalized($0)) }

        var mapping: [AnkiFieldToken: String] = [:]
        var claimed = Set<String>()
        for token in AnkiFieldToken.allCases {
            for alias in token.fieldNameAliases.map(normalized) {
                guard let match = candidates.first(where: { !claimed.contains($0.name) && $0.key == alias })
                else {
                    continue
                }
                mapping[token] = match.name
                claimed.insert(match.name)
                break
            }
        }
        if candidates.contains(where: { $0.key == "pitchnumber" }), let field = mapping[.pitchGraph] {
            mapping[.pitchGraph] = nil
            mapping[.pitchDotGraph] = field
        }
        return mapping
    }
}

struct MangaSource: Equatable {
    let title: String
    let volume: Int64
    let page: Int64

    var formatted: String {
        "\(title) vol.\(volume) p.\(page)"
    }
}

/// The word as it appears in the sentence
struct SentenceMatch {
    let surface: String
    let offset: Int
}

/// The lookup being exported.
struct AnkiNoteContext {
    let term: TermDB
    let sentence: String
    let source: MangaSource?
    var match: SentenceMatch? = nil
    var meta: [TermMetaDB] = []
    var audioURL: URL? = nil
    var pictureURL: URL? = nil

    private var summary: TermMetaSummary {
        TermMetaSummary(meta: meta, term: term.term, reading: term.effectiveReading)
    }

    private var hiraganaReading: String {
        term.effectiveReading.katakanaToHiragana()
    }

    private var sentenceAroundMatch: (before: String, surface: String, after: String)? {
        guard let match = match, !match.surface.isEmpty else { return nil }
        let characters = Array(sentence)
        let end = match.offset + match.surface.count
        guard match.offset >= 0, end <= characters.count,
              String(characters[match.offset..<end]) == match.surface else {
            return nil
        }
        return (
            SentenceText.clauseEnding(String(characters[0..<match.offset])),
            match.surface,
            SentenceText.clauseStarting(String(characters[end...]))
        )
    }

    private func emphasizedSentence(furigana: Bool) -> String {
        guard let (before, surface, after) = sentenceAroundMatch else {
            return SentenceText.html(sentence)
        }
        let word = furigana
            ? Furigana.annotate(surface: surface, term: term.term, reading: term.reading) ?? surface
            : surface
        return SentenceText.html(before) + "<b>" + SentenceText.escaped(word) + "</b>" + SentenceText.html(after)
    }

    static func meaning(_ definition: ContentDefinition, limit: Int = 3) -> String {
        guard case .detailed(let content) = definition, let list = firstGlossaryList(in: content) else {
            return glossary(definition)
        }
        return list.content
            .map { row in row.map(glossary).joined(separator: " ") }
            .filter { !$0.isEmpty }
            .prefix(limit)
            .joined(separator: ", ")
    }

    private static func firstGlossaryList(in content: StructuredContent) -> StructuredContentList? {
        switch content {
        case .list(let list), .numberedList(let list):
            if list.role == "glossary" { return list }
            return list.content.joined().lazy.compactMap(firstGlossaryList).first
        case .array(let rows):
            return rows.joined().lazy.compactMap(firstGlossaryList).first
        case .container(let container), .inlineContainer(let container):
            return container.role == "forms" ? nil : firstGlossaryList(in: container.data)
        case .table, .link, .text, .newline:
            return nil
        }
    }

    static func glossary(_ definition: ContentDefinition) -> String {
        if case .detailed(let content) = definition {
            return glossary(content)
        }
        return SentenceText.html(definition.description)
    }

    private static func glossary(_ content: StructuredContent) -> String {
        switch content {
        case .array(let rows):
            return rows
                .filter { row in
                    row.contains { element in
                        if case .inlineContainer = element { return false }
                        return true
                    }
                }
                .map { row in row.map(glossary).filter { !$0.isEmpty }.joined(separator: ", ") }
                .filter { !$0.isEmpty }
                .joined(separator: "<br>")
        case .container(let container), .inlineContainer(let container):
            return container.role == "forms" ? "" : glossary(container.data)
        case .table(let table):
            return glossary(table.data)
        case .link(let link):
            return glossary(link.data)
        case .numberedList(let list), .list(let list):
            return list.content
                .map { row in row.map(glossary).joined(separator: " ") }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
        case .text(let string):
            return SentenceText.html(string.content)
        case .newline:
            return "<br>"
        }
    }

    func value(for token: AnkiFieldToken) -> String? {
        let value: String?
        switch token {
        case .word:
            value = SentenceText.escaped(term.term)
        case .reading:
            value = SentenceText.escaped(term.effectiveReading)
        case .hiragana:
            value = SentenceText.escaped(hiraganaReading)
        case .furigana:
            value = Furigana.annotate(term: term.term, reading: term.reading).map(SentenceText.escaped)
        case .romaji:
            value = hiraganaReading.applyingTransform(.toLatin, reverse: false).map(SentenceText.escaped)
        case .audio:
            value = audioURL?.absoluteString
        case .picture:
            value = pictureURL?.absoluteString
        case .pitch:
            value = summary.pitchPositions.joined(separator: " ")
        case .pitchNumber:
            value = summary.pitchNumbers.joined(separator: ", ")
        case .pitchGraph:
            value = summary.pitchGraphs.joined(separator: " ")
        case .pitchDotGraph:
            value = summary.pitchDotGraphs.joined(separator: " ")
        case .pitchCategories:
            value = summary.pitchCategories.joined(separator: ",")
        case .frequency:
            value = summary.frequencyLabels.map(SentenceText.escaped).joined(separator: "<br>")
        case .frequencySort:
            value = summary.frequencySortValue.map(String.init)
        case .meaning:
            value = term.loadedDefinitions.first(where: { definition in
                if case .deinflection = definition { return false }
                return true
            }).map { AnkiNoteContext.meaning($0) }
        case .glossary:
            // Deinflection entries are navigation hints, not meanings.
            value = term.loadedDefinitions
                .filter { definition in
                    if case .deinflection = definition { return false }
                    return true
                }
                .map(AnkiNoteContext.glossary)
                .joined(separator: "<br>")
        case .sentence:
            value = emphasizedSentence(furigana: false)
        case .sentenceFurigana:
            value = emphasizedSentence(furigana: true)
        case .source:
            value = source.map { SentenceText.escaped($0.formatted) }
        }
        guard let value = value, !value.isEmpty else { return nil }
        return value
    }
}

/// Builds the `anki://x-callback-url/addnote` URL. Media can't be embedded: AnkiMobile
/// downloads a field whose value is a URL to an image or audio file, so it travels by reference.
struct AnkiExport {

    /// Taken from Info.plist so a dev build with its own scheme still gets its callbacks.
    static var callbackScheme: String {
        let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]]
        return types?.compactMap { ($0["CFBundleURLSchemes"] as? [String])?.first }.first ?? "riidaa"
    }

    /// Built with `URLComponents` so kanji and kana in the values are percent-encoded.
    static func callbackURL(_ items: [URLQueryItem]) -> String {
        var components = URLComponents()
        components.scheme = callbackScheme
        components.host = "anki-callback"
        components.queryItems = items
        return components.string ?? "\(callbackScheme)://anki-callback"
    }

    /// The term and reading AnkiMobile's success callback names, nil for any other URL.
    static func exportedWord(in url: URL) -> (term: String, reading: String)? {
        guard url.scheme == callbackScheme, url.host() == "anki-callback",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let term = items.first(where: { $0.name == "term" })?.value,
              let reading = items.first(where: { $0.name == "reading" })?.value else {
            return nil
        }
        return (term, reading)
    }

    static func handleCallback(_ url: URL) {
        guard url.scheme == callbackScheme, url.host() == "anki-callback" else { return }
        PageImageServer.shared.stop()
        guard let word = exportedWord(in: url) else { return }
        // Waits on the write queue, which a dictionary import can hold for a while.
        DispatchQueue.global(qos: .utility).async {
            SQLiteManager.shared.markExported(term: word.term, reading: word.reading)
        }
    }

    let profile: String
    let deck: String
    let noteType: String
    let fields: [AnkiFieldToken: String]

    private static let queryValueAllowed = CharacterSet.urlQueryAllowed
        .subtracting(CharacterSet(charactersIn: "&=+?#"))

    /// Nil when the note would carry no fields.
    func addNoteURL(context: AnkiNoteContext, callback: String) -> URL? {
        guard
            let profileEncoded = AnkiExport.encoded(profile),
            let deckEncoded = AnkiExport.encoded(deck),
            let noteTypeEncoded = AnkiExport.encoded(noteType),
            let callbackEncoded = AnkiExport.encoded(callback)
        else {
            return nil
        }

        var query = ""
        var sent = Set<String>()
        for token in AnkiFieldToken.allCases {
            guard
                let field = fields[token],
                !sent.contains(field),
                let fieldEncoded = AnkiExport.encoded(field),
                let value = context.value(for: token),
                let valueEncoded = AnkiExport.encoded(value)
            else {
                continue
            }
            sent.insert(field)
            query += "&fld\(fieldEncoded)=\(valueEncoded)"
        }
        if query.isEmpty {
            return nil
        }

        return URL(string: "anki://x-callback-url/addnote?profile=\(profileEncoded)&deck=\(deckEncoded)&type=\(noteTypeEncoded)&x-success=\(callbackEncoded)\(query)")
    }

    private static func encoded(_ value: String) -> String? {
        value.addingPercentEncoding(withAllowedCharacters: queryValueAllowed)
    }
}

/// Tidies OCR'd bubble text for a card.
enum SentenceText {

    private static let enders: Set<Character> = ["。", "！", "？", "!", "?"]
    private static let closers: Set<Character> = ["」", "』", "）", ")", "】"]

    /// What follows the last sentence end (and its closing brackets), so a bubble's earlier
    /// sentences are dropped.
    static func clauseEnding(_ text: String) -> String {
        let characters = Array(text)
        guard let last = characters.indices.last(where: { endsSentence(characters, at: $0) }) else { return text }
        return String(characters[(last + 1)...].drop(while: { enders.contains($0) || closers.contains($0) }))
    }

    /// Up to and including the first sentence end and anything closing it (！！」).
    static func clauseStarting(_ text: String) -> String {
        let characters = Array(text)
        guard var end = characters.indices.first(where: { endsSentence(characters, at: $0) }) else { return text }
        while end < characters.count, enders.contains(characters[end]) || closers.contains(characters[end]) {
            end += 1
        }
        return String(characters[..<end])
    }

    private static func endsSentence(_ characters: [Character], at index: Int) -> Bool {
        guard enders.contains(characters[index]) else { return false }
        var next = index + 1
        while next < characters.count, enders.contains(characters[next]) {
            next += 1
        }
        var closed = false
        while next < characters.count, closers.contains(characters[next]) {
            closed = true
            next += 1
        }
        guard closed, next < characters.count else { return true }
        return !quotatives.contains(characters[next])
    }

    private static let quotatives: Set<Character> = ["と", "っ", "て"]

    /// Anki fields are HTML, so a manga titled `Foo <Bar>` would otherwise open a tag.
    static func escaped(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    static func html(_ text: String) -> String {
        escaped(text)
            .replacingOccurrences(of: "\n", with: "<br>")
            .replacingOccurrences(of: "[．・]{2,}|\\.{3,}", with: "…", options: .regularExpression)
    }
}
