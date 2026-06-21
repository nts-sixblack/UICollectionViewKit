import CryptoKit
import ImageIO
import UIKit

enum ImageDownsampler {
    static let maxPixelSize: CGFloat = 300

    static func image(fromFileAt fileURL: URL) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, options as CFDictionary) else {
            return nil
        }
        return thumbnail(from: source)
    }

    private static func thumbnail(from source: CGImageSource) -> UIImage? {
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

actor PersistentImageCache {
    static let shared = PersistentImageCache()

    nonisolated(unsafe) private let memoryCache = NSCache<NSString, UIImage>()

    nonisolated func memoryImage(for itemID: String) -> UIImage? {
        memoryCache.object(forKey: itemID as NSString)
    }

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        memoryCache.totalCostLimit = 50 * 1024 * 1024
        memoryCache.countLimit = 150

        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func image(for itemID: String) -> UIImage? {
        let key = itemID as NSString

        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        let fileURL = diskURL(for: itemID)
        guard fileManager.fileExists(atPath: fileURL.path),
              let image = ImageDownsampler.image(fromFileAt: fileURL)
        else {
            return nil
        }

        cacheInMemory(image, forKey: key)
        return image
    }

    /// Moves a downloaded temp file into the disk cache and stores the already-decoded thumbnail in memory.
    func storeDownloadedFile(from sourceURL: URL, image: UIImage, for itemID: String) {
        let key = itemID as NSString
        let fileURL = diskURL(for: itemID)

        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: sourceURL)
        } else if !moveDownloadedFile(from: sourceURL, to: fileURL) {
            try? fileManager.removeItem(at: sourceURL)
        }

        cacheInMemory(image, forKey: key)
    }

    private func moveDownloadedFile(from sourceURL: URL, to destinationURL: URL) -> Bool {
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            do {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                try fileManager.removeItem(at: sourceURL)
                return true
            } catch {
                return false
            }
        }
    }

    private func cacheInMemory(_ image: UIImage, forKey key: NSString) {
        memoryCache.setObject(image, forKey: key, cost: Self.estimatedMemoryCost(for: image))
    }

    private static func estimatedMemoryCost(for image: UIImage) -> Int {
        guard let cgImage = image.cgImage else {
            return Int(image.size.width * image.size.height * 4 * image.scale * image.scale)
        }
        return cgImage.bytesPerRow * cgImage.height
    }

    private func diskURL(for itemID: String) -> URL {
        let hash = SHA256.hash(data: Data(itemID.utf8))
        let filename = hash.map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent(filename)
    }
}
