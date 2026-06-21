import SwiftUI
import UICollectionViewKit

private enum DemoUIConfiguration {
    static let header: CategoryHeaderConfiguration = {
        var configuration = CategoryHeaderConfiguration.default

        configuration.normalStyle = CategoryItemStyle(
            backgroundColor: .clear,
            borderColor: .separator,
            textColor: .label,
            font: .systemFont(ofSize: 14, weight: .regular),
            cornerRadius: 16,
            borderWidth: 1,
            contentInsets: NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        )

        configuration.selectedStyle = CategoryItemStyle(
            backgroundColor: .systemIndigo,
            borderColor: .systemIndigo,
            textColor: .white,
            font: .systemFont(ofSize: 14, weight: .semibold),
            cornerRadius: 16,
            borderWidth: 0,
            contentInsets: NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        )

        configuration.itemSpacing = 12
        configuration.sectionInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        configuration.headerHeight = 48

        return configuration
    }()

    static let grid = ItemGridConfiguration(
        columnCountPhone: 4,
        columnCountPad: 5,
        interItemSpacing: 10,
        interGroupSpacing: 10,
        contentInsets: NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20),
        cornerRadius: 12,
        imageBackgroundColor: .secondarySystemBackground
    )
}

struct CategoryItemCollectionDemoView: View {
    @ObservedObject var favoriteStore: DemoFavoriteStore
    @Binding var selectedItemID: String?

    var body: some View {
        CategoryItemCollectionView(
            categories: DemoDataSource.categories,
            itemProvider: DemoItemPaginationProvider(),
            pageSize: DemoDataSource.pageSize,
            headerConfiguration: DemoUIConfiguration.header,
            gridConfiguration: DemoUIConfiguration.grid,
            itemOverlayConfiguration: makeFavoriteOverlayConfiguration(
                favoriteStore: favoriteStore,
                stateVersion: favoriteStore.favorites
            ),
            onItemSelected: { selectedItemID = $0.itemID }
        )
    }
}
