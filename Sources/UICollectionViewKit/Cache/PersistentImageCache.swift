import CryptoKit
import ImageIO
import UIKit

enum ImageDownsampler {
    static let maxPixelSize: CGFloat = 300
    static let defaultFrameDelay: TimeInterval = 0.1

    static func loadedImage(fromFileAt fileURL: URL, isAnimatedWebP: Bool) -> LoadedImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, options as CFDictionary) else {
            return nil
        }

        if isAnimatedWebP, let sequence = animatedSequence(from: source) {
            return .animated(sequence)
        }

        guard let image = thumbnail(from: source, at: 0) else {
            return nil
        }
        return .static(image)
    }

    static func image(fromFileAt fileURL: URL) -> UIImage? {
        loadedImage(fromFileAt: fileURL, isAnimatedWebP: false)?.posterImage
    }

    private static func animatedSequence(from source: CGImageSource) -> AnimatedImageSequence? {
        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 1 else { return nil }

        var frames: [UIImage] = []
        var totalDuration: TimeInterval = 0

        for index in 0..<frameCount {
            guard let frame = thumbnail(from: source, at: index) else { continue }
            frames.append(frame)
            totalDuration += frameDelay(at: index, in: source)
        }

        guard frames.count > 1 else { return nil }
        if totalDuration <= 0 {
            totalDuration = Double(frames.count) * defaultFrameDelay
        }

        return AnimatedImageSequence(frames: frames, duration: totalDuration)
    }

    private static func thumbnail(from source: CGImageSource, at index: Int) -> UIImage? {
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, index, downsampleOptions as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private static func frameDelay(at index: Int, in source: CGImageSource) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] else {
            return defaultFrameDelay
        }

        if let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
            if let delay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval, delay > 0 {
                return delay
            }
            if let delay = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval, delay > 0 {
                return delay
            }
        }

        if let webpProperties = properties[kCGImagePropertyWebPDictionary] as? [CFString: Any] {
            if let delay = webpProperties[kCGImagePropertyWebPUnclampedDelayTime] as? TimeInterval, delay > 0 {
                return delay
            }
            if let delay = webpProperties[kCGImagePropertyWebPDelayTime] as? TimeInterval, delay > 0 {
                return delay
            }
        }

        return defaultFrameDelay
    }
}

actor PersistentImageCache {
    static let shared = PersistentImageCache()

    nonisolated(unsafe) private let memoryCache = NSCache<NSString, LoadedImageBox>()

    nonisolated func memoryLoadedImage(for itemID: String, isAnimatedWebP: Bool) -> LoadedImage? {
        memoryCache.object(forKey: Self.cacheKey(for: itemID, isAnimatedWebP: isAnimatedWebP) as NSString)?.value
    }

    nonisolated func memoryImage(for itemID: String) -> UIImage? {
        memoryLoadedImage(for: itemID, isAnimatedWebP: false)?.posterImage
    }

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        memoryCache.totalCostLimit = 100 * 1024 * 1024
        memoryCache.countLimit = 250

        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func loadedImage(for itemID: String, isAnimatedWebP: Bool) -> LoadedImage? {
        let key = Self.cacheKey(for: itemID, isAnimatedWebP: isAnimatedWebP) as NSString

        if let cached = memoryCache.object(forKey: key)?.value {
            return cached
        }

        let fileURL = diskURL(for: itemID, isAnimatedWebP: isAnimatedWebP)
        guard fileManager.fileExists(atPath: fileURL.path),
              let loadedImage = ImageDownsampler.loadedImage(fromFileAt: fileURL, isAnimatedWebP: isAnimatedWebP)
        else {
            return nil
        }

        cacheInMemory(loadedImage, forKey: key)
        return loadedImage
    }

    func image(for itemID: String) -> UIImage? {
        loadedImage(for: itemID, isAnimatedWebP: false)?.posterImage
    }

    /// Moves a downloaded temp file into the disk cache and stores the decoded image in memory.
    func storeDownloadedFile(from sourceURL: URL, loadedImage: LoadedImage, for itemID: String, isAnimatedWebP: Bool = false) {
        let key = Self.cacheKey(for: itemID, isAnimatedWebP: isAnimatedWebP) as NSString
        let fileURL = diskURL(for: itemID, isAnimatedWebP: isAnimatedWebP)

        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: sourceURL)
        } else if !moveDownloadedFile(from: sourceURL, to: fileURL) {
            try? fileManager.removeItem(at: sourceURL)
        }

        cacheInMemory(loadedImage, forKey: key)
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

    private func cacheInMemory(_ loadedImage: LoadedImage, forKey key: NSString) {
        memoryCache.setObject(
            LoadedImageBox(loadedImage),
            forKey: key,
            cost: Self.estimatedMemoryCost(for: loadedImage)
        )
    }

    private static func estimatedMemoryCost(for loadedImage: LoadedImage) -> Int {
        switch loadedImage {
        case let .static(image):
            return estimatedMemoryCost(for: image)
        case let .animated(sequence):
            return sequence.frames.reduce(0) { $0 + estimatedMemoryCost(for: $1) }
        }
    }

    private static func estimatedMemoryCost(for image: UIImage) -> Int {
        guard let cgImage = image.cgImage else {
            return Int(image.size.width * image.size.height * 4 * image.scale * image.scale)
        }
        return cgImage.bytesPerRow * cgImage.height
    }

    private static func cacheKey(for itemID: String, isAnimatedWebP: Bool) -> String {
        "\(itemID)|\(isAnimatedWebP ? "a" : "s")"
    }

    private func diskURL(for itemID: String, isAnimatedWebP: Bool) -> URL {
        let hash = SHA256.hash(data: Data(Self.cacheKey(for: itemID, isAnimatedWebP: isAnimatedWebP).utf8))
        let filename = hash.map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent(filename)
    }
}
