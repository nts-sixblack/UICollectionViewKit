import UIKit

@MainActor
final class CategoryHeaderView<C: CategoryDisplayable>: UIView, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, C>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, C>

    var onCategorySelected: ((C) -> Void)?

    private var categories: [C] = []
    private var selectedCategoryID: String?
    private var configuration = CategoryHeaderConfiguration.default

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseIdentifier)
        return collectionView
    }()

    private lazy var dataSource: DataSource = {
        DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, category in
            guard let self else {
                return UICollectionViewCell()
            }
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CategoryCell.reuseIdentifier,
                for: indexPath
            ) as? CategoryCell else {
                return UICollectionViewCell()
            }
            let isSelected = category.categoryID == self.selectedCategoryID
            let style = isSelected ? self.configuration.selectedStyle : self.configuration.normalStyle
            cell.configure(title: category.categoryTitle, style: style)
            return cell
        }
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        applyLayout(from: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    func applyConfiguration(_ configuration: CategoryHeaderConfiguration) {
        guard self.configuration != configuration else { return }

        self.configuration = configuration
        applyLayout(from: configuration)

        guard !categories.isEmpty else { return }

        collectionView.collectionViewLayout.invalidateLayout()

        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([0])
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    func apply(categories: [C], selectedCategoryID: String?) {
        self.categories = categories
        self.selectedCategoryID = selectedCategoryID

        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(categories, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    func invalidateCategoryItemLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func resolvedHeight(for configuration: CategoryHeaderConfiguration) -> CGFloat {
        configuration.effectiveHeaderHeight(
            measuredPillHeight: resolvedCategoryItemHeight(for: configuration)
        )
    }

    func resolvedCategoryItemHeight(for configuration: CategoryHeaderConfiguration) -> CGFloat {
        [configuration.normalStyle, configuration.selectedStyle]
            .map { CategoryCell.measuredContentHeight(style: $0) }
            .max() ?? 0
    }

    func updateSelection(selectedCategoryID: String) {
        self.selectedCategoryID = selectedCategoryID
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([0])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectCategory(at: indexPath.item)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard indexPath.item < categories.count else { return .zero }

        let category = categories[indexPath.item]
        let isSelected = category.categoryID == selectedCategoryID
        let style = isSelected ? configuration.selectedStyle : configuration.normalStyle
        let measuredSize = CategoryCell.measuredContentSize(title: category.categoryTitle, style: style)
        let height = resolvedCategoryItemHeight(for: configuration)

        return CGSize(width: measuredSize.width, height: height)
    }

    func selectCategory(at index: Int) {
        guard index < categories.count else { return }
        let category = categories[index]
        onCategorySelected?(category)
    }

    func applyBackgroundColor(_ color: UIColor) {
        backgroundColor = color
        collectionView.backgroundColor = color
    }

    private func applyLayout(from configuration: CategoryHeaderConfiguration) {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        layout.minimumInteritemSpacing = configuration.itemSpacing
        layout.minimumLineSpacing = configuration.lineSpacing
        layout.sectionInset = UIEdgeInsets(
            top: configuration.sectionInsets.top,
            left: configuration.sectionInsets.leading,
            bottom: configuration.sectionInsets.bottom,
            right: configuration.sectionInsets.trailing
        )
    }
}
