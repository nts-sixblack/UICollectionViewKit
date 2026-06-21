import Combine
import Foundation

final class DemoFavoriteStore: ObservableObject {
    @Published private(set) var favorites: Set<String> = []
    var onFavoritesChanged: (() -> Void)?

    func isFavorite(_ itemID: String) -> Bool {
        favorites.contains(itemID)
    }

    func toggle(_ itemID: String) {
        if favorites.contains(itemID) {
            favorites.remove(itemID)
        } else {
            favorites.insert(itemID)
        }
        onFavoritesChanged?()
    }
}
