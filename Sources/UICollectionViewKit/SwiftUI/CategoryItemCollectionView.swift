import SwiftUI

public struct CategoryItemCollectionView<
    C: CategoryDisplayable,
    I: ItemDisplayable,
    Provider: CategoryItemPaginationProviding
>: UIViewControllerRepresentable where Provider.I == I {
    let categories: [C]
    let itemProvider: Provider
    let pageSize: Int
    let headerConfiguration: CategoryHeaderConfiguration
    let gridConfiguration: ItemGridConfiguration
    let itemOverlayConfiguration: ItemOverlayConfiguration<I>?
    let onItemSelected: ((I) -> Void)?

    public init(
        categories: [C],
        itemProvider: Provider,
        pageSize: Int,
        headerConfiguration: CategoryHeaderConfiguration = .default,
        gridConfiguration: ItemGridConfiguration = .default,
        itemOverlayConfiguration: ItemOverlayConfiguration<I>? = nil,
        onItemSelected: ((I) -> Void)? = nil
    ) {
        self.categories = categories
        self.itemProvider = itemProvider
        self.pageSize = pageSize
        self.headerConfiguration = headerConfiguration
        self.gridConfiguration = gridConfiguration
        self.itemOverlayConfiguration = itemOverlayConfiguration
        self.onItemSelected = onItemSelected
    }

    public func makeUIViewController(context: Context) -> CategoryItemViewController<C, I, Provider> {
        CategoryItemViewController(
            categories: categories,
            itemProvider: itemProvider,
            pageSize: pageSize,
            headerConfiguration: headerConfiguration,
            gridConfiguration: gridConfiguration,
            itemOverlayConfiguration: itemOverlayConfiguration,
            onItemSelected: onItemSelected
        )
    }

    public func updateUIViewController(_ viewController: CategoryItemViewController<C, I, Provider>, context: Context) {
        viewController.update(categories: categories)
        viewController.updateAppearance(
            headerConfiguration: headerConfiguration,
            gridConfiguration: gridConfiguration
        )
        viewController.updateItemInteraction(
            overlayConfiguration: itemOverlayConfiguration,
            onItemSelected: onItemSelected
        )
    }
}
