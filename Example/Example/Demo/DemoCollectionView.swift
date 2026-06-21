import SwiftUI
import UICollectionViewKit
import UIKit

struct DemoCollectionView: UIViewControllerRepresentable {
    @ObservedObject var favoriteStore: DemoFavoriteStore
    @Binding var selectedItemID: String?
    var aspectRatio: ItemAspectRatio
    var backgroundConfiguration: CategoryItemBackgroundConfiguration

    func makeCoordinator() -> Coordinator {
        Coordinator(
            favoriteStore: favoriteStore,
            selectedItemID: $selectedItemID,
            aspectRatio: aspectRatio,
            backgroundConfiguration: backgroundConfiguration
        )
    }

    func makeUIViewController(context: Context) -> CategoryItemViewController<DemoCategory, DemoItem, DemoItemPaginationProvider> {
        let coordinator = context.coordinator
        let overlayConfiguration = ItemOverlayConfiguration(
            makeView: { DemoFavoriteOverlay.makeHeartButtonContainer() },
            update: { view, item in
                coordinator.updateHeartButton(view, for: item)
            }
        )

        var gridConfiguration = ItemGridConfiguration.default
        gridConfiguration.applyAspectRatio(aspectRatio)

        let viewController = CategoryItemViewController(
            categories: DemoDataSource.categories,
            itemProvider: DemoItemPaginationProvider(),
            pageSize: DemoDataSource.pageSize,
            gridConfiguration: gridConfiguration,
            backgroundConfiguration: backgroundConfiguration,
            itemOverlayConfiguration: overlayConfiguration,
            onItemSelected: { item in
                coordinator.selectedItemID.wrappedValue = item.itemID
            }
        )

        coordinator.viewController = viewController
        favoriteStore.onFavoritesChanged = { [weak viewController] in
            viewController?.reloadVisibleItemOverlays()
        }

        return viewController
    }

    func updateUIViewController(
        _ viewController: CategoryItemViewController<DemoCategory, DemoItem, DemoItemPaginationProvider>,
        context: Context
    ) {
        context.coordinator.viewController = viewController
        context.coordinator.aspectRatio = aspectRatio
        context.coordinator.backgroundConfiguration = backgroundConfiguration

        favoriteStore.onFavoritesChanged = { [weak viewController] in
            viewController?.reloadVisibleItemOverlays()
        }

        var gridConfiguration = ItemGridConfiguration.default
        gridConfiguration.applyAspectRatio(aspectRatio)

        viewController.updateAppearance(
            headerConfiguration: .default,
            gridConfiguration: gridConfiguration,
            backgroundConfiguration: backgroundConfiguration
        )
    }

    final class Coordinator {
        let favoriteStore: DemoFavoriteStore
        var selectedItemID: Binding<String?>
        var aspectRatio: ItemAspectRatio
        var backgroundConfiguration: CategoryItemBackgroundConfiguration
        weak var viewController: CategoryItemViewController<DemoCategory, DemoItem, DemoItemPaginationProvider>?

        init(
            favoriteStore: DemoFavoriteStore,
            selectedItemID: Binding<String?>,
            aspectRatio: ItemAspectRatio,
            backgroundConfiguration: CategoryItemBackgroundConfiguration
        ) {
            self.favoriteStore = favoriteStore
            self.selectedItemID = selectedItemID
            self.aspectRatio = aspectRatio
            self.backgroundConfiguration = backgroundConfiguration
        }

        func updateHeartButton(_ view: UIView, for item: DemoItem) {
            DemoFavoriteOverlay.updateHeartButton(view, for: item, favoriteStore: favoriteStore)
        }
    }
}
