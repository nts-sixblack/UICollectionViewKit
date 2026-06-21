import SwiftUI

public struct CategoryItemCollectionView<
    C: CategoryDisplayable,
    I: ItemDisplayable,
    Provider: CategoryItemPaginationProviding
>: UIViewControllerRepresentable where Provider.I == I {
    let categories: [C]
    let itemProvider: Provider
    let pageSize: Int
    let itemOverlayConfiguration: ItemOverlayConfiguration<I>?
    let onItemSelected: ((I) -> Void)?
    let overlayReloadToken: Int

    public init(
        categories: [C],
        itemProvider: Provider,
        pageSize: Int,
        itemOverlayConfiguration: ItemOverlayConfiguration<I>? = nil,
        onItemSelected: ((I) -> Void)? = nil,
        overlayReloadToken: Int = 0
    ) {
        self.categories = categories
        self.itemProvider = itemProvider
        self.pageSize = pageSize
        self.itemOverlayConfiguration = itemOverlayConfiguration
        self.onItemSelected = onItemSelected
        self.overlayReloadToken = overlayReloadToken
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIViewController(context: Context) -> CategoryItemViewController<C, I, Provider> {
        let viewController = CategoryItemViewController(
            categories: categories,
            itemProvider: itemProvider,
            pageSize: pageSize,
            itemOverlayConfiguration: itemOverlayConfiguration,
            onItemSelected: onItemSelected
        )
        context.coordinator.lastOverlayReloadToken = overlayReloadToken
        return viewController
    }

    public func updateUIViewController(_ viewController: CategoryItemViewController<C, I, Provider>, context: Context) {
        viewController.update(categories: categories)
        viewController.updateItemInteraction(
            overlayConfiguration: itemOverlayConfiguration,
            onItemSelected: onItemSelected
        )

        if overlayReloadToken != context.coordinator.lastOverlayReloadToken {
            viewController.reloadVisibleItemOverlays()
            context.coordinator.lastOverlayReloadToken = overlayReloadToken
        }
    }

    public final class Coordinator {
        var lastOverlayReloadToken: Int = 0
    }
}
