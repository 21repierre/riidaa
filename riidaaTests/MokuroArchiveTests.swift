//
//  MokuroArchiveTests.swift
//  riidaaTests
//

import Foundation
import Testing
@testable import riidaa

struct MokuroArchiveTests {

    private func tree(_ paths: [String]) throws -> URL {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        for path in paths {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try Data("x".utf8).write(to: url)
        }
        return root
    }

    @Test func readsTheVolumeNumberFromHowMokuroNamesThings() {
        #expect(MokuroArchive.volumeNumber(from: "One Piece v012", title: "One Piece") == 12)
        #expect(MokuroArchive.volumeNumber(from: "のんのんびより 第03巻", title: "のんのんびより") == 3)
        #expect(MokuroArchive.volumeNumber(from: "ONE PIECE 1 [aKraa]", title: "ONE PIECE") == 1)
        #expect(MokuroArchive.volumeNumber(from: "ONE PIECE 10 [aKraa]", title: "ONE PIECE") == 10)
    }

    /// A year in brackets would otherwise win the "last number" race and import as volume 1988.
    @Test func ignoresYearsAndReleaseTags() {
        #expect(MokuroArchive.volumeNumber(from: "Akira 3 (1988) [Epic]", title: "Akira") == 3)
        #expect(MokuroArchive.volumeNumber(from: "Yotsuba v03 (2005)", title: "Yotsuba") == 3)
    }

    @Test func givesUpRatherThanGuessing() {
        #expect(MokuroArchive.volumeNumber(from: "no digits here", title: "no digits") == nil)
    }

    /// One level deep was all riidaa used to look.
    @Test func findsMokuroFilesAtAnyDepth() throws {
        let root = try tree([
            "a/b/c/Yotsuba v01.mokuro",
            "top.mokuro",
            "__MACOSX/._hidden.mokuro",
            "a/notes.txt",
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let found = MokuroArchive.mokuroFiles(in: root).map { $0.lastPathComponent }
        #expect(found.sorted() == ["Yotsuba v01.mokuro", "top.mokuro"])
    }

    @Test func findsImagesInTheFolderNamedAfterTheMokuroFile() throws {
        let root = try tree(["Yotsuba v01.mokuro", "Yotsuba v01/page000.jpg"])
        defer { try? FileManager.default.removeItem(at: root) }

        let found = MokuroArchive.imagesDirectory(
            for: ["page000.jpg"], mokuroFile: root.appendingPathComponent("Yotsuba v01.mokuro"), root: root
        )
        #expect(found?.lastPathComponent == "Yotsuba v01")
    }

    /// The case that used to import nothing at all, without a word of explanation.
    @Test func findsImagesWhenTheFolderIsNamedSomethingElse() throws {
        let root = try tree(["Yotsuba v01.mokuro", "scans/renamed by me/page000.jpg"])
        defer { try? FileManager.default.removeItem(at: root) }

        let found = MokuroArchive.imagesDirectory(
            for: ["page000.jpg"], mokuroFile: root.appendingPathComponent("Yotsuba v01.mokuro"), root: root
        )
        #expect(found?.lastPathComponent == "renamed by me")
    }

    @Test func reportsWhenThePagesAreGenuinelyMissing() throws {
        let root = try tree(["Yotsuba v01.mokuro", "Yotsuba v01/somethingelse.jpg"])
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(MokuroArchive.imagesDirectory(
            for: ["page000.jpg"], mokuroFile: root.appendingPathComponent("Yotsuba v01.mokuro"), root: root
        ) == nil)
    }


}

/// A batch has to say which volumes failed, not just that something did.
struct BulkImportSummaryTests {

    @Test func saysNothingWhenEverythingImported() {
        #expect(VolumeProcessingModel.summary(failures: [], of: 5) == nil)
    }

    @Test func namesTheFailuresAndHowManySurvived() throws {
        let summary = try #require(
            VolumeProcessingModel.summary(failures: ["v03.zip: no .mokuro file"], of: 5)
        )
        #expect(summary.contains("4 of 5 imported"))
        #expect(summary.contains("v03.zip"))
    }

    @Test func reportsOnlyTheReasonsWhenNothingImported() throws {
        let summary = try #require(
            VolumeProcessingModel.summary(failures: ["a.zip: bad", "b.zip: worse"], of: 2)
        )
        #expect(!summary.contains("of 2 imported"))
        #expect(summary.contains("a.zip") && summary.contains("b.zip"))
    }

}
