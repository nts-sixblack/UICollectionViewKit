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
    private let customContentContainer = UIView()
    private var headerHeightConstraint: NSLayoutConstraint?
    private var headerTopConstraint: NSLayoutConstraint?
    private var swiftUITopSafeAreaInset: CGFloat?

    private let itemProvider: Provider
    private let pageSize: Int
    private var headerConfiguration: CategoryHeaderConfiguration
    private var gridConfiguration: ItemGridConfiguration
    private var backgroundConfiguration: CategoryItemBackgroundConfiguration
    private var itemOverlayConfiguration: ItemOverlayConfiguration<I>?
    private var overlayStateVersion: AnyHashable = AnyHashable(0)
    private var onItemSelected: ((I) -> Void)?
    private var onCategorySelected: ((C) -> Void)?
    /// Max previous-page batches loaded in one top-edge settle (avoids long main-thread loops).
    private let maxPreviousLoadsPerTopSettle = 12

    private var categories: [C] = []
    private var leadingCategorySlot: CategoryLeadingSlot<C>?
    private var leadingContentView: UIView?
    private var selectedCategoryID: String?
    private var categoryStates: [String: CategoryState] = [:]
    private var lastLaidOutHeaderWidth: CGFloat = 0

    public init(
        categories: [C],
        itemProvider: Provider,
        pageSize: Int,
        leadingCategorySlot: CategoryLeadingSlot<C>? = nil,
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
        self.leadingCategorySlot = leadingCategorySlot
        self.headerConfiguration = headerConfiguration
        self.gridConfiguration = gridConfiguration
        self.backgroundConfiguration = backgroundConfiguration
        self.itemOverlayConfiguration = itemOverlayConfiguration
        self.onCategorySelected = onCategorySelected
        self.onItemSelected = onItemSelected
        self.selectedCategoryID = leadingCategorySlot?.category.categoryID ?? categories.first?.categoryID
        super.init(nibName: nil, bundle: nil)
        edgesForExtendedLayout = []
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundConfiguration.viewBackgroundColor
        setupViews()
        setupCallbacks()
        reloadContent()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderTopInset()

        let headerWidth = headerView.bounds.width
        guard headerWidth > 0, abs(headerWidth - lastLaidOutHeaderWidth) > 0.5 else { return }

        lastLaidOutHeaderWidth = headerWidth
        headerView.invalidateCategoryItemLayout()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateHeaderTopInset()
    }

    public func setHeaderTopInset(_ inset: CGFloat?) {
        swiftUITopSafeAreaInset = inset
        updateHeaderTopInset()
    }

    public func update(categories: [C]) {
        let previousCategoryIDs = self.categories.map(\.categoryID)
        let newCategoryIDs = categories.map(\.categoryID)
        let categoriesChanged = previousCategoryIDs != newCategoryIDs

        self.categories = categories

        var needsReload = categoriesChanged

        if let selectedCategoryID,
           !displayedCategories.contains(where: { $0.categoryID == selectedCategoryID }) {
            self.selectedCategoryID = defaultSelectedCategoryID
            categoryStates.removeAll()
            needsReload = true
        } else if selectedCategoryID == nil {
            self.selectedCategoryID = defaultSelectedCategoryID
            needsReload = true
        }

        guard needsReload else { return }

        reloadContent()
    }

    public func updateLeadingCategorySlot(_ slot: CategoryLeadingSlot<C>?) {
        let previousLeadingID = leadingCategorySlot?.category.categoryID
        let newLeadingID = slot?.category.categoryID
        let slotChanged = previousLeadingID != newLeadingID

        leadingCategorySlot = slot

        if slotChanged {
            leadingContentView?.removeFromSuperview()
            leadingContentView = nil

            if let selectedCategoryID,
               selectedCategoryID == previousLeadingID,
               newLeadingID == nil {
                self.selectedCategoryID = defaultSelectedCategoryID
            } else if selectedCategoryID == nil || selectedCategoryID == previousLeadingID {
                self.selectedCategoryID = defaultSelectedCategoryID
            }

            reloadContent()
        }
    }

    public func updateLeadingContentView(_ view: UIView) {
        leadingContentView?.removeFromSuperview()
        leadingContentView = nil

        installLeadingContentView(view)

        if let selectedCategoryID, isLeadingCategory(selectedCategoryID) {
            customContentContainer.isHidden = false
            gridView.isHidden = true
        }
    }

    public func updateCategoryInteraction(onCategorySelected: ((C) -> Void)?) {
        self.onCategorySelected = onCategorySelected
    }

    public func updateItemInteraction(
        overlayConfiguration: ItemOverlayConfiguration<I>?,
        onItemSelected: ((I) -> Void)?
    ) {
        let newVersion = overlayConfiguration?.stateVersion ?? AnyHashable(0)
        let shouldRefreshOverlays = newVersion != overlayStateVersion

        itemOverlayConfiguration = overlayConfiguration
        self.onItemSelected = onItemSelected
        gridView.itemOverlayConfiguration = overlayConfiguration
        gridView.onItemSelected = onItemSelected

        if shouldRefreshOverlays {
            overlayStateVersion = newVersion
            gridView.reloadVisibleItemOverlays()
        }
    }

    public func reloadVisibleItemOverlays() {
        gridView.reloadVisibleItemOverlays()
    }

    public func updateAppearance(
        headerConfiguration: CategoryHeaderConfiguration,
        gridConfiguration: ItemGridConfiguration,
        backgroundConfiguration: CategoryItemBackgroundConfiguration = .default
    ) {
        self.headerConfiguration = headerConfiguration
        self.gridConfiguration = gridConfiguration
        self.backgroundConfiguration = backgroundConfiguration

        view.backgroundColor = backgroundConfiguration.viewBackgroundColor
        headerHeightConstraint?.constant = headerConfiguration.effectiveHeaderHeight
        headerView.applyConfiguration(headerConfiguration)
        headerView.applyBackgroundColor(backgroundConfiguration.headerBackgroundColor)
        gridView.applyConfiguration(gridConfiguration)
        gridView.applyBackgroundColor(backgroundConfiguration.gridBackgroundColor)
    }

    private func applyBackgroundConfiguration() {
        view.backgroundColor = backgroundConfiguration.viewBackgroundColor
        headerView.applyBackgroundColor(backgroundConfiguration.headerBackgroundColor)
        gridView.applyBackgroundColor(backgroundConfiguration.gridBackgroundColor)
    }

    private var displayedCategories: [C] {
        if let leadingCategory = leadingCategorySlot?.category {
            return [leadingCategory] + categories
        }
        return categories
    }

    private var defaultSelectedCategoryID: String? {
        leadingCategorySlot?.category.categoryID ?? categories.first?.categoryID
    }

    private func isLeadingCategory(_ categoryID: String) -> Bool {
        leadingCategorySlot?.category.categoryID == categoryID
    }

    private func setupViews() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        gridView.translatesAutoresizingMaskIntoConstraints = false
        customContentContainer.translatesAutoresizingMaskIntoConstraints = false
        customContentContainer.isHidden = true

        view.addSubview(headerView)
        view.addSubview(gridView)
        view.addSubview(customContentContainer)

        let headerHeightConstraint = headerView.heightAnchor.constraint(
            equalToConstant: headerConfiguration.effectiveHeaderHeight
        )
        self.headerHeightConstraint = headerHeightConstraint

        let headerTopConstraint = headerView.topAnchor.constraint(
            equalTo: view.topAnchor,
            constant: resolvedHeaderTopInset()
        )
        self.headerTopConstraint = headerTopConstraint

        NSLayoutConstraint.activate([
            headerTopConstraint,
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerHeightConstraint,

            gridView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            customContentContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            customContentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customContentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customContentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        headerView.applyConfiguration(headerConfiguration)
        gridView.applyConfiguration(gridConfiguration)
        applyBackgroundConfiguration()
    }

    private func setupCallbacks() {
        headerView.onCategorySelected = { [weak self] category in
            guard let self else { return }
            switchCategory(to: category.categoryID)
            onCategorySelected?(category)
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
        saveScrollOffsetForCurrentCategory()
        headerView.apply(categories: displayedCategories, selectedCategoryID: selectedCategoryID)

        guard let selectedCategoryID else {
            showEmptyGrid()
            return
        }

        displayCategory(selectedCategoryID)
    }

    private func displayCategory(_ categoryID: String) {
        if isLeadingCategory(categoryID) {
            showLeadingContent()
        } else {
            showGridContent(for: categoryID)
        }
    }

    private func showLeadingContent() {
        gridView.isHidden = true
        customContentContainer.isHidden = false

        guard leadingContentView == nil else { return }

        guard let contentView = leadingCategorySlot?.makeContentView() else { return }
        installLeadingContentView(contentView)
    }

    private func installLeadingContentView(_ contentView: UIView) {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        customContentContainer.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: customContentContainer.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: customContentContainer.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: customContentContainer.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: customContentContainer.bottomAnchor),
        ])
        leadingContentView = contentView
    }

    private func showGridContent(for categoryID: String) {
        customContentContainer.isHidden = true
        gridView.isHidden = false

        let state = categoryState(for: categoryID)
        gridView.apply(items: state.loadedItems, restoreOffset: state.contentOffset)
    }

    private func showEmptyGrid() {
        customContentContainer.isHidden = true
        gridView.isHidden = false
        gridView.apply(items: [])
    }

    private func saveScrollOffsetForCurrentCategory() {
        guard let selectedCategoryID, !isLeadingCategory(selectedCategoryID) else { return }
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
        guard let selectedCategoryID, !isLeadingCategory(selectedCategoryID) else { return }

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
        guard let selectedCategoryID, !isLeadingCategory(selectedCategoryID) else { return }
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

    private func resolvedHeaderTopInset() -> CGFloat {
        if let swiftUITopSafeAreaInset, swiftUITopSafeAreaInset > 0 {
            return swiftUITopSafeAreaInset
        }
        return view.safeAreaInsets.top
    }

    private func updateHeaderTopInset() {
        headerTopConstraint?.constant = resolvedHeaderTopInset()
    }
}

#if DEBUG
extension CategoryItemViewController {
    var test_gridView: ItemGridCollectionView<I> { gridView }
    var test_customContentContainer: UIView { customContentContainer }
    var test_headerView: CategoryHeaderView<C> { headerView }
    var test_headerHeightConstraint: NSLayoutConstraint? { headerHeightConstraint }
    var test_headerTopConstraint: NSLayoutConstraint? { headerTopConstraint }

    func test_selectCategory(at index: Int) {
        headerView.selectCategory(at: index)
    }
}
#endif
