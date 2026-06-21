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

    public init(
        categories: [C],
        itemProvider: Provider,
        pageSize: Int,
        itemOverlayConfiguration: ItemOverlayConfiguration<I>? = nil,
        onItemSelected: ((I) -> Void)? = nil
    ) {
        self.categories = categories
        self.itemProvider = itemProvider
        self.pageSize = pageSize
        self.itemOverlayConfiguration = itemOverlayConfiguration
        self.onItemSelected = onItemSelected
    }

    public func makeUIViewController(context: Context) -> CategoryItemViewController<C, I, Provider> {
        CategoryItemViewController(
            categories: categories,
            itemProvider: itemProvider,
            pageSize: pageSize,
            itemOverlayConfiguration: itemOverlayConfiguration,
            onItemSelected: onItemSelected
        )
    }

    public func updateUIViewController(_ viewController: CategoryItemViewController<C, I, Provider>, context: Context) {
        viewController.update(categories: categories)
        viewController.updateItemInteraction(
            overlayConfiguration: itemOverlayConfiguration,
            onItemSelected: onItemSelected
        )
    }
}
