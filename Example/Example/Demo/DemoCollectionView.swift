import SwiftUI
import UICollectionViewKit
import UIKit

struct DemoCollectionView: UIViewControllerRepresentable {
    @ObservedObject var favoriteStore: DemoFavoriteStore
    @Binding var selectedItemID: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(favoriteStore: favoriteStore, selectedItemID: $selectedItemID)
    }

    func makeUIViewController(context: Context) -> CategoryItemViewController<DemoCategory, DemoItem, DemoItemPaginationProvider> {
        let coordinator = context.coordinator
        let overlayConfiguration = ItemOverlayConfiguration(
            makeView: { DemoFavoriteOverlay.makeHeartButtonContainer() },
            update: { view, item in
                coordinator.updateHeartButton(view, for: item)
            }
        )

        let viewController = CategoryItemViewController(
            categories: DemoDataSource.categories,
            itemProvider: DemoItemPaginationProvider(),
            pageSize: DemoDataSource.pageSize,
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
        favoriteStore.onFavoritesChanged = { [weak viewController] in
            viewController?.reloadVisibleItemOverlays()
        }
    }

    final class Coordinator {
        let favoriteStore: DemoFavoriteStore
        var selectedItemID: Binding<String?>
        weak var viewController: CategoryItemViewController<DemoCategory, DemoItem, DemoItemPaginationProvider>?

        init(favoriteStore: DemoFavoriteStore, selectedItemID: Binding<String?>) {
            self.favoriteStore = favoriteStore
            self.selectedItemID = selectedItemID
        }

        func updateHeartButton(_ view: UIView, for item: DemoItem) {
            DemoFavoriteOverlay.updateHeartButton(view, for: item, favoriteStore: favoriteStore)
        }
    }
}
