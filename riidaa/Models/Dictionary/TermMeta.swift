//
//  TermMeta.swift
//  riidaa
//

import Foundation

public struct PitchAccent: Hashable {
    public let position: Int
    public let devoice: [Int]

    public func category(moraCount: Int) -> String {
        if position == 0 { return "heiban" }
        if position == 1 { return "atamadaka" }
        if position >= moraCount { return "odaka" }
        return "nakadaka"
    }

    /// Small kana combine with the preceding mora
    public static func moraCount(of reading: String) -> Int {
        morae(of: reading).count
    }

    static func morae(of reading: String, katakana: Bool = true) -> [String] {
        let combining: Set<Character> = [
            "ャ", "ュ", "ョ", "ァ", "ィ", "ゥ", "ェ", "ォ", "ヮ",
        ]
        var morae: [String] = []
        for character in reading {
            var shifted = character
            if let scalar = character.unicodeScalars.first,
               character.unicodeScalars.count == 1,
               (0x3041...0x3096).contains(scalar.value),
               let katakanaScalar = UnicodeScalar(scalar.value + 0x60) {
                shifted = Character(katakanaScalar)
            }
            let kana = katakana ? shifted : character
            if combining.contains(shifted), !morae.isEmpty {
                morae[morae.count - 1].append(kana)
            } else {
                morae.append(String(kana))
            }
        }
        return morae
    }

    private func isHigh(_ mora: Int) -> Bool {
        if position == 0 { return mora > 1 }
        if position == 1 { return mora == 1 }
        return mora >= 2 && mora <= position
    }

    /// The pattern drawn as Yomitan and the Kaishi deck draw it
    public func graph(reading: String) -> String {
        let overline = "border-color:currentColor;display:block;user-select:none;"
            + "pointer-events:none;position:absolute;top:0.1em;left:0;right:0;height:0;"
            + "border-top-width:0.1em;border-top-style:solid;"
        let drop = "right:-0.1em;height:0.4em;border-right-width:0.1em;border-right-style:solid;"

        let morae = PitchAccent.morae(of: reading)
        guard !morae.isEmpty else { return "" }

        var html = ""
        var index = 0
        while index < morae.count {
            let high = isHigh(index + 1)
            var end = index
            while end < morae.count, isHigh(end + 1) == high { end += 1 }
            let text = morae[index..<end].joined()

            if high {
                let dropsHere = position > 0 && end == position
                let outer = dropsHere
                    ? "display:inline-block;position:relative;padding-right:0.1em;margin-right:0.1em;"
                    : "display:inline-block;position:relative;"
                html += "<span style=\"\(outer)\"><span style=\"display:inline;\">\(text)</span>"
                    + "<span style=\"\(overline)\(dropsHere ? drop : "")\"></span></span>"
            } else {
                html += text
            }
            index = end
        }
        return html
    }

    public func dotGraph(reading: String) -> String {
        let morae = PitchAccent.morae(of: reading, katakana: false)
        guard !morae.isEmpty else { return "" }

        let step = 42
        let viewWidth = step * morae.count + 32
        let viewHeight = 84
        func x(_ index: Int) -> Int { 16 + step * index }
        func y(_ index: Int) -> Int { isHigh(index + 1) ? 5 : 30 }

        let stroke = "fill:none;stroke:currentColor;stroke-width:1.5;"
        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pitch\" "
            + "width=\"\(String(format: "%.2f", Double(viewWidth) * 0.75))px\" "
            + "height=\"\(String(format: "%.2f", Double(viewHeight) * 0.75))px\" "
            + "viewBox=\"0 0 \(viewWidth) \(viewHeight)\">"
        for (index, mora) in morae.enumerated() {
            svg += "<text x=\"\(x(index))\" y=\"76\" text-anchor=\"middle\" "
                + "style=\"font-size:26px;font-family:sans-serif;fill:currentColor;\">\(mora)</text>"
        }
        for index in morae.indices {
            svg += "<path d=\"m \(x(index)),\(y(index)) \(step),\(y(index + 1) - y(index))\" style=\"\(stroke)\" />"
        }
        for index in morae.indices {
            svg += "<circle r=\"5\" cx=\"\(x(index))\" cy=\"\(y(index))\" style=\"opacity:1;fill:currentColor;\" />"
        }
        let particle = morae.count
        svg += "<circle r=\"4\" cx=\"\(x(particle))\" cy=\"\(y(particle))\" "
            + "style=\"opacity:1;fill:none;stroke:currentColor;stroke-width:1.75;\" />"
        return svg + "</svg>"
    }
}

public struct TermFrequency: Hashable {
    public let value: Int64?
    public let display: String
}

public struct TermMetaDB: Hashable {
    public enum Content: Hashable {
        case frequency(TermFrequency)
        case pitch([PitchAccent])
    }

    public let term: String
    public let reading: String
    let dictionary: DictionaryDB
    public let content: Content

    public func applies(toReading termReading: String) -> Bool {
        reading.isEmpty || reading == termReading
    }
}

public struct TermMetaParser {

    /// Decodes the `data` element of a `[term, mode, data]` triple, or nil
    /// doesn't handle and data that doesn't match the spec.
    public static func parse(mode: String, data: Any) -> (reading: String, content: TermMetaDB.Content)? {
        switch mode {
        case "freq":
            return parseFrequency(data)
        case "pitch":
            return parsePitch(data)
        default:
            return nil
        }
    }

    private static func parseFrequency(_ data: Any) -> (reading: String, content: TermMetaDB.Content)? {
        if let map = data as? [String: Any], let reading = map["reading"] as? String {
            guard let inner = map["frequency"], let frequency = frequencyValue(inner) else { return nil }
            return (reading, .frequency(frequency))
        }
        guard let frequency = frequencyValue(data) else { return nil }
        return ("", .frequency(frequency))
    }

    private static func frequencyValue(_ data: Any) -> TermFrequency? {
        if let number = data as? Int64 {
            return TermFrequency(value: number, display: String(number))
        }
        if let number = data as? Int {
            return TermFrequency(value: Int64(number), display: String(number))
        }
        if let number = data as? Double {
            return TermFrequency(value: Int64(number), display: String(Int64(number)))
        }
        if let text = data as? String {
            return TermFrequency(value: Int64(text), display: text)
        }
        if let map = data as? [String: Any] {
            let value = (map["value"] as? Int).map(Int64.init) ?? (map["value"] as? Int64)
            let display = map["displayValue"] as? String ?? value.map(String.init)
            guard let display = display else { return nil }
            return TermFrequency(value: value, display: display)
        }
        return nil
    }

    private static func parsePitch(_ data: Any) -> (reading: String, content: TermMetaDB.Content)? {
        guard let map = data as? [String: Any],
              let reading = map["reading"] as? String,
              let pitches = map["pitches"] as? [[String: Any]] else {
            return nil
        }
        let accents: [PitchAccent] = pitches.compactMap { pitch in
            guard let position = pitch["position"] as? Int else { return nil }
            return PitchAccent(position: position, devoice: pitch["devoice"] as? [Int] ?? [])
        }
        guard !accents.isEmpty else { return nil }
        return (reading, .pitch(accents))
    }

}

/// Collapses the metadata applying to one term into the strings the lookup panel and the Anki
/// export both read, so the two can't drift apart.
public struct TermMetaSummary {
    let pitches: [PitchAccent]
    let frequencies: [(dictionary: String, frequency: TermFrequency)]
    let reading: String

    init(meta: [TermMetaDB], term: String, reading: String) {
        self.reading = reading
        let applicable = meta.filter { $0.term == term && $0.applies(toReading: reading) }
        self.pitches = applicable.flatMap { entry -> [PitchAccent] in
            if case .pitch(let accents) = entry.content { return accents }
            return []
        }
        self.frequencies = applicable.compactMap { entry in
            if case .frequency(let frequency) = entry.content {
                return (entry.dictionary.title, frequency)
            }
            return nil
        }
    }

    public var isEmpty: Bool { pitches.isEmpty && frequencies.isEmpty }

    public var pitchPositions: [String] {
        deduplicated(pitches.map { "[\($0.position)]" })
    }

    public var pitchNumbers: [String] {
        deduplicated(pitches.map { String($0.position) })
    }

    public var pitchGraphs: [String] {
        deduplicated(pitches.map { $0.graph(reading: reading) })
    }

    public var pitchDotGraphs: [String] {
        deduplicated(pitches.map { $0.dotGraph(reading: reading) })
    }

    public var pitchCategories: [String] {
        let mora = PitchAccent.moraCount(of: reading)
        return deduplicated(pitches.map { $0.category(moraCount: mora) })
    }

    public var frequencyLabels: [String] {
        let dictionaries = deduplicated(frequencies.map(\.dictionary))
        return dictionaries.map { dictionary in
            let ratings = frequencies.filter { $0.dictionary == dictionary }.map(\.frequency)
            let ordered = ratings.sorted { left, right in
                let leftKana = left.display.contains("㋕"), rightKana = right.display.contains("㋕")
                if leftKana != rightKana { return !leftKana }
                return (left.value ?? .max) < (right.value ?? .max)
            }
            let displays = deduplicated(ordered.map(\.display))
            let rest = displays.dropFirst()
            return "\(dictionary): \(displays[0])" + (rest.isEmpty ? "" : " (\(rest.joined(separator: ", ")))")
        }
    }

    /// Lower means more common.
    public var frequencySortValue: Int64? {
        frequencies.compactMap { $0.frequency.value }.min()
    }

    private func deduplicated(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}
