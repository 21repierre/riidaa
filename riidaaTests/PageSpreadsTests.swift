//
//  PageSpreadsTests.swift
//  riidaaTests
//

import Foundation
import Testing
@testable import riidaa

struct PageSpreadsTests {

    private let tall = CGSize(width: 800, height: 1200)
    private let wide = CGSize(width: 1600, height: 1200)

    @Test func showsEveryPageOnceInSinglePageMode() {
        #expect(PageSpreads.make(sizes: Array(repeating: tall, count: 3), dual: false, coverAlone: true)
            == [[0], [1], [2]])
    }

    /// An odd page count used to drop the last page in right-to-left two-page mode.
    @Test func keepsEveryPageWhateverTheCount() {
        for count in 1...7 {
            for coverAlone in [true, false] {
                let spreads = PageSpreads.make(sizes: Array(repeating: tall, count: count), dual: true, coverAlone: coverAlone)
                #expect(spreads.flatMap { $0 } == Array(0..<count))
            }
        }
    }

    @Test func pairsFacingPagesAfterAStandaloneCover() {
        let sizes = Array(repeating: tall, count: 6)
        #expect(PageSpreads.make(sizes: sizes, dual: true, coverAlone: true) == [[0], [1, 2], [3, 4], [5]])
        #expect(PageSpreads.make(sizes: sizes, dual: true, coverAlone: false) == [[0, 1], [2, 3], [4, 5]])
    }

    /// A page that is already a two-page spread isn't squeezed into half the screen.
    @Test func showsWidePagesAlone() {
        let sizes = [tall, tall, wide, tall, tall]
        #expect(PageSpreads.make(sizes: sizes, dual: true, coverAlone: false) == [[0, 1], [2], [3, 4]])
        #expect(PageSpreads.make(sizes: sizes, dual: true, coverAlone: true) == [[0], [1], [2], [3, 4]])
    }
}
