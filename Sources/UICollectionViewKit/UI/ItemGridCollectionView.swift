import UIKit

@MainActor
final class ItemGridCollectionView<I: ItemDisplayable>: UIView, UICollectionViewDelegate {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, I>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, I>

    struct LayoutMetrics {
        let columnCount: Int
        let itemWidth: CGFloat
        let rowHeight: CGFloat
        let rowSpacing: CGFloat
        let sectionTopInset: CGFloat
    }

    var onNearBottom: (() -> Void)?
    var onNearTop: (() -> Void)?
    var itemOverlayConfiguration: ItemOverlayConfiguration<I>?
    var onItemSelected: ((I) -> Void)?

    private var configuration = ItemGridConfiguration.default

    private enum ScrollDirection {
        case up
        case down
        case none
    }

    private let bottomEdgeThreshold = 24
    private let scrollDirectionThreshold: CGFloat = 0.5
    private var isUpdatingContent = false
    private var isUserInteracting = false
    private var pendingNearBottom = false
    private var lastContentOffsetY: CGFloat = 0
    private var lastScrollDirection: ScrollDirection = .none
    /// Bumped whenever `apply(items:)` replaces content so stale async completions are ignored.
    private var contentGeneration = 0

    private struct ScrollAnchor {
        let item: I
        let offsetFromItemTop: CGFloat
    }

    private struct PendingPrependOperation {
        let items: [I]
        let completion: (() -> Void)?
    }

    private var pendingPrependOperations: [PendingPrependOperation] = []

    var contentOffset: CGPoint {
        collectionView.contentOffset
    }

    var layoutMetrics: LayoutMetrics {
        currentLayoutMetrics()
    }

    var displayedItemCount: Int {
        dataSource.snapshot().numberOfItems(inSection: 0)
    }

    /// Whether the collection view is scrolled to the top edge (used to chain previous-page loads).
    var isAtTopEdge: Bool {
        let itemCount = dataSource.snapshot().numberOfItems(inSection: 0)
        guard itemCount > 0 else { return false }
        return isNearTop(itemCount: itemCount, contentOffsetY: collectionView.contentOffset.y)
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(ItemImageCell.self, forCellWithReuseIdentifier: ItemImageCell.reuseIdentifier)
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var dataSource: DataSource = {
        DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self else {
                return UICollectionViewCell()
            }
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ItemImageCell.reuseIdentifier,
                for: indexPath
            ) as? ItemImageCell else {
                return UICollectionViewCell()
            }
            cell.configure(
                with: item.imageURL,
                isAnimatedWebP: self.configuration.shouldPlayAnimatedWebP(
                    itemSupportsAnimation: item.isAnimatedWebP,
                    itemIndex: indexPath.item
                ),
                overlayConfiguration: self.itemOverlayConfiguration,
                item: item,
                appearance: self.configuration
            )
            return cell
        }
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyConfiguration(_ configuration: ItemGridConfiguration) {
        let layoutChanged = self.configuration.columnCountPhone != configuration.columnCountPhone
            || self.configuration.columnCountPad != configuration.columnCountPad
            || self.configuration.interItemSpacing != configuration.interItemSpacing
            || self.configuration.interGroupSpacing != configuration.interGroupSpacing
            || self.configuration.contentInsets != configuration.contentInsets
            || self.configuration.itemHeightMultiplier != configuration.itemHeightMultiplier

        let appearanceChanged = self.configuration.cornerRadius != configuration.cornerRadius
            || self.configuration.imageBackgroundColor != configuration.imageBackgroundColor
            || self.configuration.animatedWebPInterval != configuration.animatedWebPInterval

        self.configuration = configuration

        if layoutChanged {
            collectionView.setCollectionViewLayout(makeLayout(), animated: false)
            collectionView.layoutIfNeeded()
        }

        if appearanceChanged || layoutChanged {
            reloadVisibleCells()
        }
    }

    func applyBackgroundColor(_ color: UIColor) {
        collectionView.backgroundColor = color
    }

    private func setupViews() {
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    func apply(items: [I], restoreOffset: CGPoint = .zero, completion: (() -> Void)? = nil) {
        contentGeneration += 1
        let generation = contentGeneration
        pendingPrependOperations = []
        pendingNearBottom = false

        isUpdatingContent = true
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        applySnapshot(snapshot, generation: generation) { [weak self] in
            guard let self else { return }
            collectionView.layoutIfNeeded()
            collectionView.setContentOffset(restoreOffset, animated: false)
            isUpdatingContent = false
            completion?()
        }
    }

    func append(items: [I], completion: (() -> Void)? = nil) {
        guard !items.isEmpty else {
            completion?()
            return
        }

        performAppend(items: items, completion: completion)
    }

    private func performAppend(items: [I], completion: (() -> Void)? = nil) {
        // Appending to the end preserves scroll position automatically.
        isUpdatingContent = true

        var snapshot = dataSource.snapshot()
        snapshot.appendItems(items, toSection: 0)
        applySnapshot(snapshot, generation: contentGeneration) { [weak self] in
            guard let self else { return }
            isUpdatingContent = false
            completion?()
        }
    }

    func prepend(items: [I], completion: (() -> Void)? = nil) {
        guard !items.isEmpty else {
            completion?()
            return
        }

        // Prepending adjusts contentOffset to keep visible cells stable. Doing that
        // while a pan/deceleration is active fights UIScrollView and causes visible jitter.
        if isUserInteracting {
            enqueuePrependOperation(items: items, completion: completion)
            return
        }

        performPrepend(items: items, completion: completion)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        onItemSelected?(item)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let imageCell = cell as? ItemImageCell else { return }
        imageCell.resumeAnimationIfNeeded()
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let imageCell = cell as? ItemImageCell else { return }
        imageCell.pauseAnimationIfNeeded()
    }

    func reloadVisibleItemOverlays() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let item = dataSource.itemIdentifier(for: indexPath),
                  let cell = collectionView.cellForItem(at: indexPath) as? ItemImageCell
            else {
                continue
            }

            cell.configure(
                with: item.imageURL,
                isAnimatedWebP: configuration.shouldPlayAnimatedWebP(
                    itemSupportsAnimation: item.isAnimatedWebP,
                    itemIndex: indexPath.item
                ),
                overlayConfiguration: itemOverlayConfiguration,
                item: item,
                appearance: configuration
            )
        }
    }

    private func reloadVisibleCells() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let item = dataSource.itemIdentifier(for: indexPath),
                  let cell = collectionView.cellForItem(at: indexPath) as? ItemImageCell
            else {
                continue
            }

            cell.configure(
                with: item.imageURL,
                isAnimatedWebP: configuration.shouldPlayAnimatedWebP(
                    itemSupportsAnimation: item.isAnimatedWebP,
                    itemIndex: indexPath.item
                ),
                overlayConfiguration: itemOverlayConfiguration,
                item: item,
                appearance: configuration
            )
        }
    }

    func selectItem(at index: Int) {
        let items = dataSource.snapshot().itemIdentifiers
        guard items.indices.contains(index) else { return }
        onItemSelected?(items[index])
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserInteracting = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            finishScrollInteraction()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        finishScrollInteraction()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        defer { lastContentOffsetY = contentOffsetY }

        guard !isUpdatingContent else { return }

        let deltaY = contentOffsetY - lastContentOffsetY
        if deltaY > scrollDirectionThreshold {
            lastScrollDirection = .down
        } else if deltaY < -scrollDirectionThreshold {
            lastScrollDirection = .up
        }

        let itemCount = dataSource.snapshot().numberOfItems(inSection: 0)
        guard itemCount > 0 else { return }

        if isNearBottom(itemCount: itemCount), lastScrollDirection == .down {
            requestNearBottomCallback()
        }
    }

    func contentHeight(forItemCount count: Int) -> CGFloat {
        Self.contentHeight(forItemCount: count, metrics: layoutMetrics)
    }

    private func requestNearBottomCallback() {
        guard !pendingNearBottom else { return }
        pendingNearBottom = true

        DispatchQueue.main.async { [weak self] in
            guard let self, pendingNearBottom else { return }
            pendingNearBottom = false

            let itemCount = dataSource.snapshot().numberOfItems(inSection: 0)
            guard itemCount > 0,
                  isNearBottom(itemCount: itemCount),
                  lastScrollDirection == .down
            else { return }

            onNearBottom?()
        }
    }

    private func flushPendingEdgeCallbacks() {
        guard !isUpdatingContent else { return }

        let itemCount = dataSource.snapshot().numberOfItems(inSection: 0)
        guard itemCount > 0 else { return }

        let contentOffsetY = collectionView.contentOffset.y

        if isNearBottom(itemCount: itemCount), lastScrollDirection == .down {
            onNearBottom?()
        }

        // Do not gate on scroll direction — rubber-band bounce at the top sets
        // `lastScrollDirection` to `.down`, which previously blocked previous-page loads.
        if isNearTop(itemCount: itemCount, contentOffsetY: contentOffsetY) {
            onNearTop?()
        }
    }

    private func isNearBottom(itemCount: Int) -> Bool {
        let visibleIndices = collectionView.indexPathsForVisibleItems.map(\.item)
        guard let lastVisibleIndex = visibleIndices.max() else { return false }
        return lastVisibleIndex >= itemCount - bottomEdgeThreshold
    }

    private func isNearTop(itemCount: Int, contentOffsetY: CGFloat) -> Bool {
        let visibleIndices = collectionView.indexPathsForVisibleItems.map(\.item)
        guard let firstVisibleIndex = visibleIndices.min() else { return false }

        let metrics = layoutMetrics
        // Prefetch when the first or second row is visible at the top edge.
        guard firstVisibleIndex < metrics.columnCount * 2 else { return false }

        return isAtTopContentOffset(contentOffsetY)
    }

    private func isAtTopContentOffset(_ contentOffsetY: CGFloat) -> Bool {
        let metrics = layoutMetrics
        let topTriggerOffset = metrics.sectionTopInset
            + metrics.rowSpacing
            + metrics.rowHeight
        return contentOffsetY <= topTriggerOffset
    }

    private func applySnapshot(
        _ snapshot: Snapshot,
        generation: Int? = nil,
        completion: (() -> Void)? = nil
    ) {
        let expectedGeneration = generation ?? contentGeneration
        UIView.performWithoutAnimation {
            dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self, expectedGeneration == contentGeneration else { return }
                completion?()
            }
        }
    }

    /// Applies snapshot and lays out immediately so scroll compensation can run in the same frame.
    private func applySnapshotSynchronously(_ snapshot: Snapshot) {
        UIView.performWithoutAnimation {
            dataSource.apply(snapshot, animatingDifferences: false)
            collectionView.layoutIfNeeded()
        }
    }

    private func performPrepend(items: [I], completion: (() -> Void)? = nil) {
        guard !items.isEmpty,
              let anchorItem = dataSource.snapshot().itemIdentifiers.first
        else {
            completion?()
            return
        }

        let offsetYBefore = collectionView.contentOffset.y
        let contentHeightBefore = collectionView.contentSize.height
        let anchor = captureScrollAnchorForPrepend()

        isUpdatingContent = true
        var snapshot = dataSource.snapshot()
        snapshot.insertItems(items, beforeItem: anchorItem)
        applySnapshotSynchronously(snapshot)
        restoreAfterPrepend(
            anchor: anchor,
            contentHeightBefore: contentHeightBefore,
            offsetYBefore: offsetYBefore,
            insertedItemCount: items.count,
            wasAtTopEdge: isAtTopContentOffset(offsetYBefore)
        )
        isUpdatingContent = false
        completion?()
    }

    private func finishScrollInteraction() {
        isUserInteracting = false
        flushPendingPrependOperations()
        flushPendingEdgeCallbacks()
    }

    private func enqueuePrependOperation(items: [I], completion: (() -> Void)?) {
        pendingPrependOperations.append(
            PendingPrependOperation(items: items, completion: completion)
        )
    }

    private func flushPendingPrependOperations() {
        guard !pendingPrependOperations.isEmpty else { return }

        let operations = pendingPrependOperations
        pendingPrependOperations = []

        for operation in operations {
            performPrepend(items: operation.items, completion: operation.completion)
        }
    }

    /// Anchor for prepend — pin the topmost visible item so scroll position stays stable
    /// when loading previous pages near the top edge.
    private func captureScrollAnchorForPrepend() -> ScrollAnchor? {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        guard let anchorIndexPath = visibleIndexPaths.first else { return nil }
        return scrollAnchor(at: anchorIndexPath)
    }

    private func scrollAnchor(at indexPath: IndexPath) -> ScrollAnchor? {
        guard let attributes = collectionView.layoutAttributesForItem(at: indexPath),
              let item = dataSource.itemIdentifier(for: indexPath)
        else {
            return nil
        }

        return ScrollAnchor(
            item: item,
            offsetFromItemTop: collectionView.contentOffset.y - attributes.frame.minY
        )
    }

    private func restoreAfterPrepend(
        anchor: ScrollAnchor?,
        contentHeightBefore: CGFloat,
        offsetYBefore: CGFloat,
        insertedItemCount: Int,
        wasAtTopEdge: Bool
    ) {
        // When the user scrolled to the top edge, show the newly prepended rows
        // instead of keeping the old first row pinned on screen (which hides them
        // above the viewport).
        if wasAtTopEdge {
            let inset = collectionView.adjustedContentInset
            setContentOffset(y: -inset.top)
            return
        }

        let contentHeightAfter = collectionView.contentSize.height
        let heightDelta = contentHeightAfter - contentHeightBefore

        if heightDelta != 0 {
            setContentOffset(y: offsetYBefore + heightDelta)
            return
        }

        if let anchor, restoreScrollAnchor(anchor) {
            return
        }

        let metrics = layoutMetrics
        let estimatedDelta = Self.contentHeight(forItemCount: insertedItemCount, metrics: metrics)
        if estimatedDelta > 0 {
            setContentOffset(y: offsetYBefore + estimatedDelta)
        }
    }

    @discardableResult
    private func setContentOffset(y: CGFloat) -> Bool {
        let inset = collectionView.adjustedContentInset
        let minOffsetY = -inset.top
        let maxOffsetY = max(
            minOffsetY,
            collectionView.contentSize.height
                - collectionView.bounds.height
                + inset.bottom
        )
        let clampedOffsetY = min(max(y, minOffsetY), maxOffsetY)

        UIView.performWithoutAnimation {
            collectionView.setContentOffset(
                CGPoint(x: collectionView.contentOffset.x, y: clampedOffsetY),
                animated: false
            )
        }
        return true
    }

    @discardableResult
    private func restoreScrollAnchor(_ anchor: ScrollAnchor?) -> Bool {
        guard let anchor,
              let indexPath = dataSource.indexPath(for: anchor.item),
              let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        else {
            return false
        }

        return setContentOffset(y: attributes.frame.minY + anchor.offsetFromItemTop)
    }

    private static func contentHeight(forItemCount count: Int, metrics: LayoutMetrics) -> CGFloat {
        let rowCount = Int(ceil(Double(count) / Double(metrics.columnCount)))
        guard rowCount > 0 else { return 0 }
        return CGFloat(rowCount) * metrics.rowHeight + CGFloat(max(0, rowCount - 1)) * metrics.rowSpacing
    }

    private func columnCount(for idiom: UIUserInterfaceIdiom) -> Int {
        idiom == .pad ? configuration.columnCountPad : configuration.columnCountPhone
    }

    private func resolvedLayoutMetrics(
        containerWidth: CGFloat,
        idiom: UIUserInterfaceIdiom
    ) -> LayoutMetrics {
        let columnCount = columnCount(for: idiom)
        let spacing = configuration.interItemSpacing
        let horizontalInset = configuration.contentInsets.leading + configuration.contentInsets.trailing

        let availableWidth = containerWidth
            - horizontalInset
            - (spacing * CGFloat(columnCount - 1))
        let itemWidth = floor(max(availableWidth, 0) / CGFloat(columnCount))
        let rowHeight = itemWidth * configuration.itemHeightMultiplier

        return LayoutMetrics(
            columnCount: columnCount,
            itemWidth: itemWidth,
            rowHeight: rowHeight,
            rowSpacing: configuration.interGroupSpacing,
            sectionTopInset: configuration.contentInsets.top
        )
    }

    private func currentLayoutMetrics() -> LayoutMetrics {
        resolvedLayoutMetrics(
            containerWidth: bounds.width,
            idiom: traitCollection.userInterfaceIdiom
        )
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        let configuration = configuration
        return UICollectionViewCompositionalLayout { [weak self] _, environment in
            guard let self else { return nil }

            let metrics = self.resolvedLayoutMetrics(
                containerWidth: environment.container.effectiveContentSize.width,
                idiom: environment.traitCollection.userInterfaceIdiom
            )
            let spacing = configuration.interItemSpacing
            let itemWidth = metrics.itemWidth
            let rowHeight = metrics.rowHeight

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .absolute(rowHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(rowHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: Array(repeating: item, count: metrics.columnCount)
            )
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = configuration.interGroupSpacing
            section.contentInsets = configuration.contentInsets
            return section
        }
    }
}
