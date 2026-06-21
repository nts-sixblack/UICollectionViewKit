import SwiftUI

public struct CategoryItemCollectionView<
    C: CategoryDisplayable,
    I: ItemDisplayable,
    Provider: CategoryItemPaginationProviding
>: UIViewControllerRepresentable where Provider.I == I {
    let categories: [C]
    let itemProvider: Provider
    let pageSize: Int

    public init(categories: [C], itemProvider: Provider, pageSize: Int) {
        self.categories = categories
        self.itemProvider = itemProvider
        self.pageSize = pageSize
    }

    public func makeUIViewController(context: Context) -> CategoryItemViewController<C, I, Provider> {
        CategoryItemViewController(categories: categories, itemProvider: itemProvider, pageSize: pageSize)
    }

    public func updateUIViewController(_ viewController: CategoryItemViewController<C, I, Provider>, context: Context) {
        viewController.update(categories: categories)
    }
}
