//
//  MokuroArchive.swift
//  riidaa
//

import Foundation

/// Pages are located by the `img_path` the .mokuro file records, not by folder name
enum MokuroArchive {

    enum Failure: LocalizedError {
        case noMokuroFile
        case unreadable(String)
        case imagesNotFound(volume: String, page: String)
        case someVolumes([String])

        var errorDescription: String? {
            switch self {
            case .noMokuroFile:
                return "This zip has no .mokuro file in it. It should contain the .mokuro file mokuro produced, along with the folder of page images."
            case .unreadable(let name):
                return "\(name) could not be read as a mokuro file."
            case .imagesNotFound(let volume, let page):
                return "Found \(volume) but not its page images - nothing in the zip contains \(page)."
            case .someVolumes(let reasons):
                return reasons.joined(separator: "\n\n")
            }
        }
    }

    /// Every `.mokuro` file in the tree, at any depth.
    static func mokuroFiles(in root: URL) -> [URL] {
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            return []
        }
        return walker.compactMap { $0 as? URL }
            .filter { $0.pathExtension.lowercased() == "mokuro" && !$0.path.contains("__MACOSX") }
            .sorted { $0.path < $1.path }
    }

    static func imagesDirectory(for pages: [String], mokuroFile: URL, root: URL) -> URL? {
        let fileManager = FileManager.default
        guard !pages.isEmpty else { return nil }
        let samples = Set([pages[0], pages[pages.count / 2], pages[pages.count - 1]])

        func holds(_ directory: URL) -> Bool {
            samples.allSatisfy {
                fileManager.fileExists(atPath: directory.appendingPathComponent($0).path)
            }
        }

        let sibling = mokuroFile.deletingPathExtension()
        if holds(sibling) { return sibling }

        guard let walker = fileManager.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return nil
        }
        for case let url as URL in walker where !url.path.contains("__MACOSX") {
            guard fileManager.isDirectory(at: url), holds(url) else { continue }
            return url
        }
        return nil
    }

    static func volumeNumber(from volume: String, title: String) -> Int64? {
        let cleaned = volume.replacingOccurrences(
            of: "[\\[(][^\\])]*[\\])]", with: " ", options: .regularExpression
        )
        let patterns = ["第\\s*(\\d{1,4})\\s*巻", "(?:^|[\\s._-])v(?:ol(?:ume)?)?[\\s._-]*(\\d{1,4})(?![\\d])", "(\\d{1,4})(?!.*\\d)"]
        for pattern in patterns {
            guard let match = cleaned.range(of: pattern, options: .regularExpression) else { continue }
            let digits = cleaned[match].filter { $0.isNumber }
            if let number = Int64(digits) { return number }
        }
        // Last resort
        return Int64(cleaned.replacingOccurrences(of: title, with: "").dropFirst(2))
    }

}
