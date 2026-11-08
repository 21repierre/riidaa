//
//  PageImageCache.swift
//  riidaa
//

import UIKit
import CoreData
import ImageIO

final class PageImageCache {

    static let shared = PageImageCache()

    static let pagePixelSize: CGFloat = {
        let bounds = UIScreen.main.bounds
        return max(bounds.width, bounds.height) * UIScreen.main.scale * 2
    }()

    private let cache = NSCache<NSManagedObjectID, UIImage>()
    @MainActor private var loading: [NSManagedObjectID: Task<UIImage?, Never>] = [:]

    private init() {
        cache.countLimit = 8
    }

    func cachedImage(for page: MangaPageModel) -> UIImage? {
        cache.object(forKey: page.objectID)
    }

    @MainActor
    func image(for page: MangaPageModel) async -> UIImage? {
        if let cached = cache.object(forKey: page.objectID) {
            return cached
        }
        let id = page.objectID
        if let inFlight = loading[id] {
            return await inFlight.value
        }
        let url = page.imageURL
        let load = Task { await Self.load(url, maxPixelSize: Self.pagePixelSize) }
        loading[id] = load
        let image = await load.value
        loading[id] = nil
        if let image = image {
            cache.setObject(image, forKey: id)
        }
        return image
    }

    @MainActor
    func uncachedImage(for page: MangaPageModel, maxPixelSize: CGFloat, crop: CGRect? = nil) async -> UIImage? {
        let url = page.imageURL
        let pageWidth = CGFloat(page.width)
        guard let crop = crop, pageWidth > 0, page.height > 0 else {
            return await Self.load(url, maxPixelSize: maxPixelSize)
        }
        let fraction = max(crop.width / pageWidth, crop.height / CGFloat(page.height), 0.01)
        return await Task.detached(priority: .userInitiated) {
            guard let image = Self.downsample(url, maxPixelSize: maxPixelSize / fraction)?.cgImage else { return nil }
            let scale = CGFloat(image.width) / pageWidth
            let scaled = CGRect(x: crop.minX * scale, y: crop.minY * scale,
                                width: crop.width * scale, height: crop.height * scale).integral
            return image.cropping(to: scaled).map(UIImage.init(cgImage:)) ?? UIImage(cgImage: image)
        }.value
    }

    private static func load(_ url: URL, maxPixelSize: CGFloat) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            downsample(url, maxPixelSize: maxPixelSize)
        }.value
    }

    static func downsample(_ url: URL, maxPixelSize: CGFloat) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: image)
    }
}

enum PictureCrop {

    static func rect(around box: CGRect, in page: CGSize, minimumFraction: CGFloat = 0.5) -> CGRect {
        guard page.width > 0, page.height > 0 else { return CGRect(origin: .zero, size: page) }
        let margin = 0.08 * max(page.width, page.height)
        let width = min(page.width, max(box.width + 2 * margin, page.width * minimumFraction))
        let height = min(page.height, max(box.height + 2 * margin, page.height * minimumFraction))
        let x = min(max(box.midX - width / 2, 0), page.width - width)
        let y = min(max(box.midY - height / 2, 0), page.height - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
