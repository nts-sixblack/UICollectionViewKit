import SwiftUI
import UICollectionViewKit

struct CategoryItemCollectionDemoView: View {
    @ObservedObject var favoriteStore: DemoFavoriteStore
    @Binding var selectedItemID: String?

    var body: some View {
        CategoryItemCollectionView(
            categories: DemoDataSource.categories,
            itemProvider: DemoItemPaginationProvider(),
            pageSize: DemoDataSource.pageSize,
            itemOverlayConfiguration: makeFavoriteOverlayConfiguration(
                favoriteStore: favoriteStore,
                stateVersion: favoriteStore.favorites
            ),
            onItemSelected: { selectedItemID = $0.itemID }
        )
    }
}
