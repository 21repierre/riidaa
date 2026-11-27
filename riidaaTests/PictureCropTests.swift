//
//  PictureCropTests.swift
//  riidaaTests
//

import CoreGraphics
import Testing
@testable import riidaa

struct PictureCropTests {

    private let page = CGSize(width: 1000, height: 1500)

    @Test func centresOnTheBubbleWithAtLeastHalfThePage() {
        let crop = PictureCrop.rect(around: CGRect(x: 450, y: 700, width: 100, height: 100), in: page)
        #expect(crop == CGRect(x: 250, y: 375, width: 500, height: 750))
    }

    /// A bubble in a corner shifts the crop inward rather than cutting it off at the edge.
    @Test func staysOnThePage() {
        let crop = PictureCrop.rect(around: CGRect(x: 20, y: 1400, width: 80, height: 90), in: page)
        #expect(crop == CGRect(x: 0, y: 750, width: 500, height: 750))
    }

    /// A bubble bigger than half the page keeps a margin around it.
    @Test func growsAroundALargeBubble() {
        let crop = PictureCrop.rect(around: CGRect(x: 100, y: 100, width: 700, height: 200), in: page)
        #expect(crop.width == 940)
        #expect(crop.contains(CGRect(x: 100, y: 100, width: 700, height: 200)))
    }
}
