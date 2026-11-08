//
//  WordAudio.swift
//  riidaa
//

import Foundation
import AVFoundation

/// Pronunciation audio from JapanesePod101's dictionary endpoint
public struct WordAudio {

    private static let endpoint = "https://assets.languagepod101.com/dictionary/japanese/audiomp3.php"

    private static let cacheQueue = DispatchQueue(label: "dev.repierre.riidaa.wordaudio")
    private static let recordings: NSCache<NSURL, NSData> = {
        let cache = NSCache<NSURL, NSData>()
        cache.countLimit = 200
        return cache
    }()
    private static var missing: Set<URL> = []
    private static var waiting: [URL: [(Data?) -> Void]] = [:]

    public static func url(term: String, reading: String) -> URL? {
        let kanji = term.trimmingCharacters(in: .whitespacesAndNewlines)
        let kana = reading.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !kanji.isEmpty || !kana.isEmpty else { return nil }

        var components = URLComponents(string: endpoint)
        components?.queryItems = [
            URLQueryItem(name: "kanji", value: kanji.isEmpty ? kana : kanji),
            URLQueryItem(name: "kana", value: kana.isEmpty ? kanji : kana),
            URLQueryItem(name: "fakePath", value: "audio.mp3"),
        ]
        return components?.url
    }

    /// The endpoint never 404s: a word it knows redirects to a CDN copy, one it doesn't serves a
    /// fixed "not found" clip from the requested URL
    static func isRecording(requested: URL, resolved: URL?) -> Bool {
        guard let resolved = resolved else { return false }
        return resolved != requested
    }

    static func recording(at url: URL, completion: @escaping (Data?) -> Void) {
        enum Lookup { case known(Data?), joined, start }
        let lookup: Lookup = cacheQueue.sync {
            if let data = recordings.object(forKey: url as NSURL) { return .known(data as Data) }
            if missing.contains(url) { return .known(nil) }
            if waiting[url] != nil {
                waiting[url]?.append(completion)
                return .joined
            }
            waiting[url] = [completion]
            return .start
        }
        switch lookup {
        case .known(let data):
            DispatchQueue.main.async { completion(data) }
            return
        case .joined:
            return
        case .start:
            break
        }

        URLSession.shared.dataTask(with: url) { data, response, _ in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let answered = (200..<300).contains(status)
            let recording = answered && isRecording(requested: url, resolved: response?.url)
                ? data.flatMap { $0.isEmpty ? nil : $0 }
                : nil
            let callbacks: [(Data?) -> Void] = cacheQueue.sync {
                if let recording = recording {
                    recordings.setObject(recording as NSData, forKey: url as NSURL)
                } else if answered {
                    // Only a real "not found" answer is remembered; an offline moment isn't.
                    missing.insert(url)
                }
                return waiting.removeValue(forKey: url) ?? []
            }
            DispatchQueue.main.async { callbacks.forEach { $0(recording) } }
        }.resume()
    }

    static func prefetch(term: String, reading: String) {
        guard let url = url(term: term, reading: reading) else { return }
        recording(at: url) { _ in }
    }

    private static var sessionReady = false

    static func prepareSession(force: Bool = false) {
        guard force || !sessionReady else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            sessionReady = true
        } catch {
            sessionReady = false
        }
    }

    static func isKnownMissing(_ url: URL) -> Bool {
        cacheQueue.sync { missing.contains(url) }
    }

}
