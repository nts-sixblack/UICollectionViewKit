import UIKit

@MainActor
final class CategoryHeaderView<C: CategoryDisplayable>: UIView, UICollectionViewDelegate {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, C>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, C>

    var onCategorySelected: ((C) -> Void)?

    private var categories: [C] = []
    private var selectedCategoryID: String?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
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
            cell.configure(title: category.categoryTitle, isSelected: isSelected)
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

    private func setupViews() {
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    func apply(categories: [C], selectedCategoryID: String?) {
        self.categories = categories
        self.selectedCategoryID = selectedCategoryID

        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(categories, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func updateSelection(selectedCategoryID: String) {
        self.selectedCategoryID = selectedCategoryID
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([0])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < categories.count else { return }
        let category = categories[indexPath.item]
        onCategorySelected?(category)
    }
}
