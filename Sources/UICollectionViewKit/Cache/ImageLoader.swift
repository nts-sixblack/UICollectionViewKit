import UIKit

actor ImageLoader {
    static let shared = ImageLoader()

    private let cache = PersistentImageCache.shared
    private var inFlightTasks: [String: Task<UIImage?, Never>] = [:]
    private var availableDownloadSlots = 4
    private var downloadSlotWaiters: [CheckedContinuation<Void, Never>] = []

    func loadImage(itemID: String, from url: URL) async -> UIImage? {
        if Task.isCancelled { return nil }

        if let cached = await cache.image(for: itemID) {
            return cached
        }

        if Task.isCancelled { return nil }

        if let existing = inFlightTasks[itemID] {
            let image = await existing.value
            if Task.isCancelled { return nil }
            return image
        }

        let task = Task<UIImage?, Never> {
            if Task.isCancelled { return nil }

            if let cached = await cache.image(for: itemID) {
                return cached
            }

            await acquireDownloadSlot()
            defer { releaseDownloadSlot() }

            if Task.isCancelled { return nil }

            if let cached = await cache.image(for: itemID) {
                return cached
            }

            do {
                let (tempURL, _) = try await URLSession.shared.download(from: url)
                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: tempURL)
                    return nil
                }

                let image = await decodeImage(fromFileAt: tempURL)
                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: tempURL)
                    return nil
                }

                if let image {
                    await cache.storeDownloadedFile(from: tempURL, image: image, for: itemID)
                    return image
                }

                try? FileManager.default.removeItem(at: tempURL)
                return nil
            } catch {
                return nil
            }
        }

        inFlightTasks[itemID] = task
        let image = await task.value
        inFlightTasks[itemID] = nil
        return image
    }

    func cancel(itemID: String) {
        inFlightTasks[itemID]?.cancel()
        inFlightTasks[itemID] = nil
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

    private func decodeImage(fromFileAt fileURL: URL) async -> UIImage? {
        await Task.detached(priority: .utility) {
            ImageDownsampler.image(fromFileAt: fileURL)
        }.value
    }
}

@MainActor
enum ImageLoadHandle {
    static func load(
        itemID: String,
        url: URL,
        token: UUID,
        onUpdate: @escaping @MainActor (UUID, UIImage?) -> Void
    ) {
        ImageLoadTaskStore.shared.storeItemID(itemID, for: token)

        let task = Task {
            let image = await ImageLoader.shared.loadImage(itemID: itemID, from: url)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                onUpdate(token, image)
            }
            await ImageLoadTaskStore.shared.finish(token: token)
        }

        ImageLoadTaskStore.shared.store(task, for: token)
    }

    static func cancel(token: UUID, itemID: String?) {
        ImageLoadTaskStore.shared.cancel(token: token)
        if let itemID {
            Task {
                await ImageLoader.shared.cancel(itemID: itemID)
            }
        }
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
