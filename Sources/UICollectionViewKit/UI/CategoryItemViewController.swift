import UIKit

@MainActor
public final class CategoryItemViewController<
    C: CategoryDisplayable,
    I: ItemDisplayable,
    Provider: CategoryItemPaginationProviding
>: UIViewController where Provider.I == I {
    private struct CategoryState {
        var loadedItems: [I]
        var baseOffset: Int
        var nextOffset: Int
        var hasMore: Bool
        var contentOffset: CGPoint
        var isLoadingMore: Bool
        var isLoadingPrevious: Bool
    }

    private let headerView = CategoryHeaderView<C>()
    private let gridView = ItemGridCollectionView<I>()

    private let itemProvider: Provider
    private let pageSize: Int
    private var itemOverlayConfiguration: ItemOverlayConfiguration<I>?
    private var onItemSelected: ((I) -> Void)?
    /// Max previous-page batches loaded in one top-edge settle (avoids long main-thread loops).
    private let maxPreviousLoadsPerTopSettle = 12

    private var categories: [C] = []
    private var selectedCategoryID: String?
    private var categoryStates: [String: CategoryState] = [:]

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
        self.selectedCategoryID = categories.first?.categoryID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        setupCallbacks()
        reloadContent()
    }

    public func update(categories: [C]) {
        self.categories = categories

        if let selectedCategoryID,
           !categories.contains(where: { $0.categoryID == selectedCategoryID }) {
            self.selectedCategoryID = categories.first?.categoryID
            categoryStates.removeAll()
        } else if selectedCategoryID == nil {
            self.selectedCategoryID = categories.first?.categoryID
        }

        reloadContent()
    }

    public func updateItemInteraction(
        overlayConfiguration: ItemOverlayConfiguration<I>?,
        onItemSelected: ((I) -> Void)?
    ) {
        itemOverlayConfiguration = overlayConfiguration
        self.onItemSelected = onItemSelected
        gridView.itemOverlayConfiguration = overlayConfiguration
        gridView.onItemSelected = onItemSelected
    }

    public func reloadVisibleItemOverlays() {
        gridView.reloadVisibleItemOverlays()
    }

    private func setupViews() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        gridView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerView)
        view.addSubview(gridView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            gridView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupCallbacks() {
        headerView.onCategorySelected = { [weak self] category in
            guard let self else { return }
            switchCategory(to: category.categoryID)
        }

        gridView.onNearBottom = { [weak self] in
            self?.loadMoreIfNeeded()
        }

        gridView.onNearTop = { [weak self] in
            self?.loadPreviousIfNeeded()
        }

        gridView.itemOverlayConfiguration = itemOverlayConfiguration
        gridView.onItemSelected = onItemSelected
    }

    private func switchCategory(to categoryID: String) {
        saveScrollOffsetForCurrentCategory()
        selectedCategoryID = categoryID
        headerView.updateSelection(selectedCategoryID: categoryID)
        displayCategory(categoryID)
    }

    private func reloadContent() {
        headerView.apply(categories: categories, selectedCategoryID: selectedCategoryID)

        guard let selectedCategoryID else {
            gridView.apply(items: [])
            return
        }

        displayCategory(selectedCategoryID)
    }

    private func displayCategory(_ categoryID: String) {
        let state = categoryState(for: categoryID)
        gridView.apply(items: state.loadedItems, restoreOffset: state.contentOffset)
    }

    private func saveScrollOffsetForCurrentCategory() {
        guard let selectedCategoryID else { return }
        var state = categoryState(for: selectedCategoryID)
        state.contentOffset = gridView.contentOffset
        categoryStates[selectedCategoryID] = state
    }

    private func categoryState(for categoryID: String) -> CategoryState {
        if let existing = categoryStates[categoryID] {
            return existing
        }

        let initialItems = itemProvider.items(for: categoryID, offset: 0, limit: pageSize)
        let totalCount = itemProvider.totalCount(for: categoryID)
        let state = CategoryState(
            loadedItems: initialItems,
            baseOffset: 0,
            nextOffset: initialItems.count,
            hasMore: initialItems.count < totalCount,
            contentOffset: .zero,
            isLoadingMore: false,
            isLoadingPrevious: false
        )
        categoryStates[categoryID] = state
        return state
    }

    private func finishLoadingMore(for categoryID: String) {
        var state = categoryStates[categoryID] ?? categoryState(for: categoryID)
        state.isLoadingMore = false
        categoryStates[categoryID] = state
    }

    private func finishLoadingPrevious(for categoryID: String) {
        var state = categoryStates[categoryID] ?? categoryState(for: categoryID)
        state.isLoadingPrevious = false
        categoryStates[categoryID] = state
    }

    private func loadMoreIfNeeded() {
        guard let selectedCategoryID else { return }

        var state = categoryStates[selectedCategoryID] ?? categoryState(for: selectedCategoryID)
        guard state.hasMore, !state.isLoadingMore, !state.isLoadingPrevious else { return }

        state.isLoadingMore = true
        categoryStates[selectedCategoryID] = state

        let newItems = itemProvider.items(
            for: selectedCategoryID,
            offset: state.nextOffset,
            limit: pageSize
        )

        state.loadedItems.append(contentsOf: newItems)
        state.nextOffset += newItems.count
        state.hasMore = state.nextOffset < itemProvider.totalCount(for: selectedCategoryID)
        categoryStates[selectedCategoryID] = state

        gridView.append(items: newItems) { [weak self] in
            self?.finishLoadingMore(for: selectedCategoryID)
        }
    }

    private func loadPreviousIfNeeded() {
        guard let selectedCategoryID else { return }
        loadPreviousPagesWhileAtTop(for: selectedCategoryID)
    }

    private func loadPreviousPagesWhileAtTop(for categoryID: String) {
        for _ in 0..<maxPreviousLoadsPerTopSettle {
            guard loadPreviousPage(for: categoryID) else { break }
            guard gridView.isAtTopEdge else { return }
        }

        guard gridView.isAtTopEdge else { return }
        let baseOffset = categoryStates[categoryID]?.baseOffset ?? 0
        guard baseOffset > 0 else { return }

        // Large `baseOffset` values need more than one batch — continue on the next
        // run loop while the user remains pinned to the top edge.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.selectedCategoryID == categoryID else { return }
            self.loadPreviousPagesWhileAtTop(for: categoryID)
        }
    }

    @discardableResult
    private func loadPreviousPage(for categoryID: String) -> Bool {
        var state = categoryStates[categoryID] ?? categoryState(for: categoryID)
        guard state.baseOffset > 0, !state.isLoadingPrevious, !state.isLoadingMore else { return false }

        state.isLoadingPrevious = true
        categoryStates[categoryID] = state

        let previousOffset = max(0, state.baseOffset - pageSize)
        let limit = state.baseOffset - previousOffset
        guard limit > 0 else {
            finishLoadingPrevious(for: categoryID)
            return false
        }

        let previousItems = itemProvider.items(
            for: categoryID,
            offset: previousOffset,
            limit: limit
        )

        state.loadedItems.insert(contentsOf: previousItems, at: 0)
        state.baseOffset = previousOffset
        categoryStates[categoryID] = state

        gridView.prepend(items: previousItems) { [weak self] in
            self?.finishLoadingPrevious(for: categoryID)
        }

        return true
    }
}
