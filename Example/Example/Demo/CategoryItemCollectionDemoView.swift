import SwiftUI
import UICollectionViewKit

struct CategoryItemCollectionDemoView: View {
    @ObservedObject var favoriteStore: DemoFavoriteStore
    @Binding var selectedItemID: String?
    @State private var overlayReloadToken = 0

    var body: some View {
        CategoryItemCollectionView(
            categories: DemoDataSource.categories,
            itemProvider: DemoItemPaginationProvider(),
            pageSize: DemoDataSource.pageSize,
            itemOverlayConfiguration: makeFavoriteOverlayConfiguration(favoriteStore: favoriteStore),
            onItemSelected: { selectedItemID = $0.itemID },
            overlayReloadToken: overlayReloadToken
        )
        .onAppear {
            favoriteStore.onFavoritesChanged = {
                overlayReloadToken += 1
            }
        }
    }
}
