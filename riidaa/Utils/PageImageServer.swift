//
//  PageImageServer.swift
//  riidaa
//

import Foundation
import os
import Network
import UIKit

/// Serves one image over loopback so AnkiMobile can fetch it.
///
/// AnkiMobile only takes media as a URL it downloads itself. Word audio already lives on the
/// web; a manga page exists only on this device, so it is published briefly at
/// `http://127.0.0.1:<port>/<token>.jpg`. Nothing leaves the phone. A background task is held
/// while the listener runs, since opening AnkiMobile suspends riidaa.
final class PageImageServer {

    static let shared = PageImageServer()

    private var listener: NWListener?
    private var payload: Data?
    private var path: String?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var shutdownWork: DispatchWorkItem?
    private let queue = DispatchQueue(label: "dev.repierre.riidaa.pageimage")

    private init() {}

    /// Readiness and the timeout can race
    private final class ResumeOnce {
        private var done = false
        private let lock = NSLock()

        func resume(_ continuation: CheckedContinuation<NWEndpoint.Port?, Never>, with value: NWEndpoint.Port?) {
            lock.lock()
            defer { lock.unlock() }
            guard !done else { return }
            done = true
            continuation.resume(returning: value)
        }
    }

    /// Returns the URL for the Anki field, or nil if the listener could not start.
    func publish(_ image: UIImage, quality: CGFloat = 0.8, duration: TimeInterval = 60) async -> URL? {
        guard let data = image.jpegData(compressionQuality: quality) else { return nil }

        stop()

        let token = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16)
        let path = "/\(token).jpg"

        guard let listener = try? NWListener(using: .tcp, on: .any) else { return nil }
        queue.sync {
            self.payload = data
            self.path = path
        }
        self.listener = listener

        listener.newConnectionHandler = { [weak self] connection in
            self?.serve(connection)
        }

        let port: NWEndpoint.Port? = await withCheckedContinuation { continuation in
            let guardian = ResumeOnce()
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    guardian.resume(continuation, with: listener.port)
                case .failed(let error):
                    Logger.reader.error("Page image server failed: \(error.localizedDescription, privacy: .public)")
                    guardian.resume(continuation, with: nil)
                case .waiting:
                    // Transient; the timeout below covers a listener that never recovers.
                    break
                case .cancelled:
                    guardian.resume(continuation, with: nil)
                default:
                    break
                }
            }
            queue.asyncAfter(deadline: .now() + 5) {
                guardian.resume(continuation, with: nil)
            }
            listener.start(queue: queue)
        }

        guard let port = port else {
            stop()
            return nil
        }

        beginBackgroundTask()
        scheduleShutdown(after: duration)
        return URL(string: "http://127.0.0.1:\(port.rawValue)\(path)")
    }

    func stop() {
        shutdownWork?.cancel()
        shutdownWork = nil
        listener?.cancel()
        listener = nil
        queue.sync {
            payload = nil
            path = nil
        }
        endBackgroundTask()
    }

    private func serve(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            guard let self = self else {
                connection.cancel()
                return
            }
            let request = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let response = self.response(for: request)
            connection.send(content: response, isComplete: true, completion: .contentProcessed { _ in
                self.queue.asyncAfter(deadline: .now() + 1) {
                    connection.cancel()
                }
            })
        }
    }

    private func response(for request: String) -> Data {
        // Only the published path is served.
        guard let path = path, let payload = payload,
              let line = request.split(separator: "\r\n").first,
              line.contains(" \(path) ") else {
            return Data("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8)
        }

        var response = Data("""
        HTTP/1.1 200 OK\r
        Content-Type: image/jpeg\r
        Content-Length: \(payload.count)\r
        Cache-Control: no-store\r
        Connection: close\r
        \r\n
        """.utf8)
        response.append(payload)
        return response
    }

    private func beginBackgroundTask() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.endBackgroundTaskOnMain()
            self.backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "riidaa.pageimage") { [weak self] in
                self?.stop()
            }
        }
    }

    private func endBackgroundTask() {
        DispatchQueue.main.async { [weak self] in
            self?.endBackgroundTaskOnMain()
        }
    }

    private func endBackgroundTaskOnMain() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    private func scheduleShutdown(after duration: TimeInterval) {
        let work = DispatchWorkItem { [weak self] in self?.stop() }
        shutdownWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

}
