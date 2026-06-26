import SwiftUI
import UIKit

public struct CategoryItemCollectionView<
    C: CategoryDisplayable,
    I: ItemDisplayable,
    Provider: CategoryItemPaginationProviding,
    LeadingContent: View
>: UIViewControllerRepresentable where Provider.I == I {
    let categories: [C]
    let itemProvider: Provider
    let pageSize: Int
    let leadingCategory: C?
    let leadingCategoryContent: LeadingContent
    let headerConfiguration: CategoryHeaderConfiguration
    let gridConfiguration: ItemGridConfiguration
    let backgroundConfiguration: CategoryItemBackgroundConfiguration
    let itemOverlayConfiguration: ItemOverlayConfiguration<I>?
    let onCategorySelected: ((C) -> Void)?
    let onItemSelected: ((I) -> Void)?

    public init(
        categories: [C],
        itemProvider: Provider,
        pageSize: Int,
        leadingCategory: C? = nil,
        @ViewBuilder leadingCategoryContent: () -> LeadingContent,
        headerConfiguration: CategoryHeaderConfiguration = .default,
        gridConfiguration: ItemGridConfiguration = .default,
        backgroundConfiguration: CategoryItemBackgroundConfiguration = .default,
        itemOverlayConfiguration: ItemOverlayConfiguration<I>? = nil,
        onCategorySelected: ((C) -> Void)? = nil,
        onItemSelected: ((I) -> Void)? = nil
    ) {
        self.categories = categories
        self.itemProvider = itemProvider
        self.pageSize = pageSize
        self.leadingCategory = leadingCategory
        self.leadingCategoryContent = leadingCategoryContent()
        self.headerConfiguration = headerConfiguration
        self.gridConfiguration = gridConfiguration
        self.backgroundConfiguration = backgroundConfiguration
        self.itemOverlayConfiguration = itemOverlayConfiguration
        self.onCategorySelected = onCategorySelected
        self.onItemSelected = onItemSelected
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIViewController(context: Context) -> CategoryItemViewController<C, I, Provider> {
        let leadingSlot = makeLeadingSlot(coordinator: context.coordinator)
        let viewController = CategoryItemViewController(
            categories: categories,
            itemProvider: itemProvider,
            pageSize: pageSize,
            leadingCategorySlot: leadingSlot,
            headerConfiguration: headerConfiguration,
            gridConfiguration: gridConfiguration,
            backgroundConfiguration: backgroundConfiguration,
            itemOverlayConfiguration: itemOverlayConfiguration,
            onCategorySelected: onCategorySelected,
            onItemSelected: onItemSelected
        )
        context.coordinator.viewController = viewController
        return viewController
    }

    public func updateUIViewController(_ viewController: CategoryItemViewController<C, I, Provider>, context: Context) {
        context.coordinator.viewController = viewController
        context.coordinator.updateLeadingContent(leadingCategoryContent)

        viewController.update(categories: categories)
        viewController.updateLeadingCategorySlot(makeLeadingSlot(coordinator: context.coordinator))

        let appearanceChanged = context.coordinator.lastHeaderConfiguration != headerConfiguration
            || context.coordinator.lastGridConfiguration != gridConfiguration
            || context.coordinator.lastBackgroundConfiguration != backgroundConfiguration

        if appearanceChanged {
            context.coordinator.lastHeaderConfiguration = headerConfiguration
            context.coordinator.lastGridConfiguration = gridConfiguration
            context.coordinator.lastBackgroundConfiguration = backgroundConfiguration
            viewController.updateAppearance(
                headerConfiguration: headerConfiguration,
                gridConfiguration: gridConfiguration,
                backgroundConfiguration: backgroundConfiguration
            )
        }
        viewController.updateCategoryInteraction(onCategorySelected: onCategorySelected)
        viewController.updateItemInteraction(
            overlayConfiguration: itemOverlayConfiguration,
            onItemSelected: onItemSelected
        )
    }

    private func makeLeadingSlot(coordinator: Coordinator) -> CategoryLeadingSlot<C>? {
        guard let leadingCategory else { return nil }

        if coordinator.hostingController == nil {
            coordinator.hostingController = UIHostingController(rootView: AnyView(leadingCategoryContent))
            coordinator.hostingController?.view.backgroundColor = .clear
        } else {
            coordinator.hostingController?.rootView = AnyView(leadingCategoryContent)
        }

        guard let hostingController = coordinator.hostingController else { return nil }

        return CategoryLeadingSlot(category: leadingCategory) { [weak hostingController] in
            hostingController?.view ?? UIView()
        }
    }

    public final class Coordinator {
        weak var viewController: CategoryItemViewController<C, I, Provider>?
        var hostingController: UIHostingController<AnyView>?
        var lastHeaderConfiguration: CategoryHeaderConfiguration?
        var lastGridConfiguration: ItemGridConfiguration?
        var lastBackgroundConfiguration: CategoryItemBackgroundConfiguration?

        func updateLeadingContent(_ content: some View) {
            hostingController?.rootView = AnyView(content)
        }
    }
}

extension CategoryItemCollectionView where LeadingContent == EmptyView {
    public init(
        categories: [C],
        itemProvider: Provider,
        pageSize: Int,
        headerConfiguration: CategoryHeaderConfiguration = .default,
        gridConfiguration: ItemGridConfiguration = .default,
        backgroundConfiguration: CategoryItemBackgroundConfiguration = .default,
        itemOverlayConfiguration: ItemOverlayConfiguration<I>? = nil,
        onCategorySelected: ((C) -> Void)? = nil,
        onItemSelected: ((I) -> Void)? = nil
    ) {
        self.init(
            categories: categories,
            itemProvider: itemProvider,
            pageSize: pageSize,
            leadingCategory: nil,
            leadingCategoryContent: { EmptyView() },
            headerConfiguration: headerConfiguration,
            gridConfiguration: gridConfiguration,
            backgroundConfiguration: backgroundConfiguration,
            itemOverlayConfiguration: itemOverlayConfiguration,
            onCategorySelected: onCategorySelected,
            onItemSelected: onItemSelected
        )
    }
}
