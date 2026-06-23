import UIKit

actor ImageLoader {
    static let shared = ImageLoader()

    private let cache = PersistentImageCache.shared
    private var inFlightTasks: [String: Task<LoadedImage?, Never>] = [:]
    private var availableDownloadSlots = 4
    private var downloadSlotWaiters: [CheckedContinuation<Void, Never>] = []

    func loadImage(itemID: String, from url: URL, isAnimatedWebP: Bool) async -> LoadedImage? {
        if Task.isCancelled { return nil }

        if let cached = await cache.loadedImage(for: itemID, isAnimatedWebP: isAnimatedWebP) {
            return cached
        }

        if Task.isCancelled { return nil }

        let taskKey = Self.taskKey(itemID: itemID, isAnimatedWebP: isAnimatedWebP)
        if let existing = inFlightTasks[taskKey] {
            let loadedImage = await existing.value
            if Task.isCancelled { return nil }
            return loadedImage
        }

        let task = Task<LoadedImage?, Never> {
            if Task.isCancelled { return nil }

            if let cached = await cache.loadedImage(for: itemID, isAnimatedWebP: isAnimatedWebP) {
                return cached
            }

            await acquireDownloadSlot()
            defer { releaseDownloadSlot() }

            if Task.isCancelled { return nil }

            if let cached = await cache.loadedImage(for: itemID, isAnimatedWebP: isAnimatedWebP) {
                return cached
            }

            do {
                let (tempURL, _) = try await URLSession.shared.download(from: url)
                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: tempURL)
                    return nil
                }

                let loadedImage = await decodeImage(fromFileAt: tempURL, isAnimatedWebP: isAnimatedWebP)
                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: tempURL)
                    return nil
                }

                if let loadedImage {
                    await cache.storeDownloadedFile(
                        from: tempURL,
                        loadedImage: loadedImage,
                        for: itemID,
                        isAnimatedWebP: isAnimatedWebP
                    )
                    return loadedImage
                }

                try? FileManager.default.removeItem(at: tempURL)
                return nil
            } catch {
                return nil
            }
        }

        inFlightTasks[taskKey] = task
        let loadedImage = await task.value
        inFlightTasks[taskKey] = nil
        return loadedImage
    }

    func cancel(itemID: String) {
        inFlightTasks.filter { $0.key.hasPrefix(itemID + "|") }.keys.forEach { key in
            inFlightTasks[key]?.cancel()
            inFlightTasks[key] = nil
        }
    }

    private static func taskKey(itemID: String, isAnimatedWebP: Bool) -> String {
        "\(itemID)|\(isAnimatedWebP ? "animated" : "static")"
    }

    private func acquireDownloadSlot() async {
        if availableDownloadSlots > 0 {
            availableDownloadSlots -= 1
            return
        }

        await withCheckedContinuation { continuation in
            downloadSlotWaiters.append(continuation)
        }
    }

    private func releaseDownloadSlot() {
        if let waiter = downloadSlotWaiters.first {
            downloadSlotWaiters.removeFirst()
            waiter.resume()
        } else {
            availableDownloadSlots += 1
        }
    }

    private func decodeImage(fromFileAt fileURL: URL, isAnimatedWebP: Bool) async -> LoadedImage? {
        await Task.detached(priority: .utility) {
            ImageDownsampler.loadedImage(fromFileAt: fileURL, isAnimatedWebP: isAnimatedWebP)
        }.value
    }
}

@MainActor
enum ImageLoadHandle {
    static func load(
        itemID: String,
        url: URL,
        isAnimatedWebP: Bool,
        token: UUID,
        onUpdate: @escaping @MainActor (UUID, LoadedImage?) -> Void
    ) {
        ImageLoadTaskStore.shared.storeItemID(itemID, for: token)

        let task = Task {
            let loadedImage = await ImageLoader.shared.loadImage(
                itemID: itemID,
                from: url,
                isAnimatedWebP: isAnimatedWebP
            )
            guard !Task.isCancelled else { return }
            await MainActor.run {
                onUpdate(token, loadedImage)
            }
            await ImageLoadTaskStore.shared.finish(token: token)
        }

        ImageLoadTaskStore.shared.store(task, for: token)
    }

    static func cancel(token: UUID) {
        ImageLoadTaskStore.shared.cancel(token: token)
    }
}

@MainActor
private final class ImageLoadTaskStore {
    static let shared = ImageLoadTaskStore()

    private var tasks: [UUID: Task<Void, Never>] = [:]
    private var itemIDs: [UUID: String] = [:]

    func store(_ task: Task<Void, Never>, for token: UUID) {
        tasks[token]?.cancel()
        tasks[token] = task
    }

    func storeItemID(_ itemID: String, for token: UUID) {
        itemIDs[token] = itemID
    }

    func finish(token: UUID) {
        tasks[token] = nil
        itemIDs[token] = nil
    }

    func cancel(token: UUID) {
        tasks[token]?.cancel()
        tasks[token] = nil
        itemIDs[token] = nil
    }
}
