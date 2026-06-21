import XCTest
@testable import UICollectionViewKit

final class UICollectionViewKitTests: XCTestCase {
    func testItemDisplayableConformance() {
        struct TestItem: ItemDisplayable {
            let itemID: String
            let categoryID: String
            let imageURL: URL
        }

        let item = TestItem(
            itemID: "1",
            categoryID: "nature",
            imageURL: URL(string: "https://example.com/image.jpg")!
        )

        XCTAssertEqual(item.itemID, "1")
        XCTAssertEqual(item.categoryID, "nature")
    }

    func testCategoryDisplayableConformance() {
        struct TestCategory: CategoryDisplayable {
            let categoryID: String
            let categoryTitle: String
        }

        let category = TestCategory(categoryID: "nature", categoryTitle: "Nature")
        XCTAssertEqual(category.categoryTitle, "Nature")
    }

    func testPaginationProvider() {
        struct TestItem: ItemDisplayable {
            let itemID: String
            let categoryID: String
            let imageURL: URL
        }

        struct TestProvider: CategoryItemPaginationProviding {
            typealias I = TestItem

            func totalCount(for categoryID: String) -> Int { 100 }

            func items(for categoryID: String, offset: Int, limit: Int) -> [TestItem] {
                guard offset < totalCount(for: categoryID) else { return [] }
                let end = min(offset + limit, totalCount(for: categoryID))
                return (offset..<end).map { index in
                    TestItem(
                        itemID: "\(categoryID)-\(index)",
                        categoryID: categoryID,
                        imageURL: URL(string: "https://example.com/\(index).jpg")!
                    )
                }
            }
        }

        let provider = TestProvider()
        let page = provider.items(for: "nature", offset: 0, limit: 10)
        XCTAssertEqual(page.count, 10)
        XCTAssertEqual(page.first?.itemID, "nature-0")
    }

    @MainActor
    func testItemSelectionCallback() {
        struct TestItem: ItemDisplayable {
            let itemID: String
            let categoryID: String
            let imageURL: URL
        }

        let item = TestItem(
            itemID: "item-1",
            categoryID: "nature",
            imageURL: URL(string: "https://example.com/1.jpg")!
        )

        let gridView = ItemGridCollectionView<TestItem>(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        gridView.apply(items: [item])

        var selectedItem: TestItem?
        gridView.onItemSelected = { selectedItem = $0 }
        gridView.selectItem(at: 0)

        XCTAssertEqual(selectedItem?.itemID, "item-1")
    }

    @MainActor
    func testOverlayMakeViewCalledOncePerCell() {
        struct TestItem: ItemDisplayable {
            let itemID: String
            let categoryID: String
            let imageURL: URL
        }

        var makeViewCallCount = 0
        let configuration = ItemOverlayConfiguration<TestItem>(
            makeView: {
                makeViewCallCount += 1
                return UIView()
            },
            update: { (_: UIView, _: TestItem) in }
        )

        let cell = ItemImageCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let item1 = TestItem(
            itemID: "1",
            categoryID: "nature",
            imageURL: URL(string: "https://example.com/1.jpg")!
        )
        let item2 = TestItem(
            itemID: "2",
            categoryID: "nature",
            imageURL: URL(string: "https://example.com/2.jpg")!
        )

        cell.configure(
            with: item1.imageURL,
            overlayConfiguration: configuration,
            item: item1,
            appearance: .default
        )
        XCTAssertEqual(makeViewCallCount, 1)

        cell.configure(
            with: item2.imageURL,
            overlayConfiguration: configuration,
            item: item2,
            appearance: .default
        )
        XCTAssertEqual(makeViewCallCount, 1)
    }

    @MainActor
    func testOverlayStateVersionChangeTriggersReload() {
        struct TestItem: ItemDisplayable {
            let itemID: String
            let categoryID: String
            let imageURL: URL
        }

        struct TestCategory: CategoryDisplayable {
            let categoryID: String
            let categoryTitle: String
        }

        struct TestProvider: CategoryItemPaginationProviding {
            typealias I = TestItem

            func totalCount(for categoryID: String) -> Int { 1 }

            func items(for categoryID: String, offset: Int, limit: Int) -> [TestItem] {
                guard offset == 0 else { return [] }
                return [
                    TestItem(
                        itemID: "item-1",
                        categoryID: categoryID,
                        imageURL: URL(string: "https://example.com/1.jpg")!
                    ),
                ]
            }
        }

        var updateCallCount = 0
        func makeConfiguration(stateVersion: AnyHashable) -> ItemOverlayConfiguration<TestItem> {
            ItemOverlayConfiguration(
                stateVersion: stateVersion,
                makeView: { UIView() },
                update: { _, _ in updateCallCount += 1 }
            )
        }

        let viewController = CategoryItemViewController(
            categories: [TestCategory(categoryID: "nature", categoryTitle: "Nature")],
            itemProvider: TestProvider(),
            pageSize: 10,
            itemOverlayConfiguration: makeConfiguration(stateVersion: 0)
        )

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.loadViewIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        let countAfterInitialLoad = updateCallCount
        XCTAssertGreaterThan(countAfterInitialLoad, 0)

        viewController.updateItemInteraction(
            overlayConfiguration: makeConfiguration(stateVersion: 0),
            onItemSelected: nil
        )
        XCTAssertEqual(updateCallCount, countAfterInitialLoad)

        viewController.updateItemInteraction(
            overlayConfiguration: makeConfiguration(stateVersion: 1),
            onItemSelected: nil
        )
        XCTAssertGreaterThan(updateCallCount, countAfterInitialLoad)

        let countAfterFirstReload = updateCallCount
        viewController.updateItemInteraction(
            overlayConfiguration: makeConfiguration(stateVersion: 1),
            onItemSelected: nil
        )
        XCTAssertEqual(updateCallCount, countAfterFirstReload)
    }

    func testDefaultHeaderConfigurationMatchesLegacyValues() {
        let configuration = CategoryHeaderConfiguration.default

        XCTAssertEqual(configuration.itemSpacing, 8)
        XCTAssertEqual(configuration.lineSpacing, 8)
        XCTAssertEqual(configuration.headerHeight, 52)
        XCTAssertEqual(configuration.sectionInsets.leading, 16)
        XCTAssertEqual(configuration.normalStyle.cornerRadius, 16)
        XCTAssertEqual(configuration.selectedStyle.contentInsets.top, 8)
    }

    @MainActor
    func testGridLayoutMetricsUseConfiguration() {
        var configuration = ItemGridConfiguration.default
        configuration.columnCountPhone = 4
        configuration.interItemSpacing = 10
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)

        let gridView = ItemGridCollectionView<TestGridItem>(frame: CGRect(x: 0, y: 0, width: 400, height: 480))
        gridView.applyConfiguration(configuration)
        gridView.layoutIfNeeded()

        let metrics = gridView.layoutMetrics
        XCTAssertEqual(metrics.columnCount, 4)
        XCTAssertEqual(metrics.rowSpacing, configuration.interGroupSpacing)
        XCTAssertEqual(metrics.sectionTopInset, 12)

        let expectedWidth = floor(
            (400 - 20 - 20 - (10 * 3)) / 4
        )
        XCTAssertEqual(metrics.itemWidth, expectedWidth)
        XCTAssertEqual(metrics.rowHeight, expectedWidth)
    }

    @MainActor
    func testGridLayoutMetricsApplyItemHeightMultiplier() {
        var configuration = ItemGridConfiguration.default
        configuration.columnCountPhone = 2
        configuration.itemHeightMultiplier = 16.0 / 9.0

        let gridView = ItemGridCollectionView<TestGridItem>(frame: CGRect(x: 0, y: 0, width: 390, height: 480))
        gridView.applyConfiguration(configuration)
        gridView.layoutIfNeeded()

        let metrics = gridView.layoutMetrics
        let expectedWidth = floor((390 - 16 - 16 - 8) / 2)
        XCTAssertEqual(metrics.itemWidth, expectedWidth)
        XCTAssertEqual(metrics.rowHeight, expectedWidth * (16.0 / 9.0), accuracy: 0.01)
    }

    func testCategoryCellAppliesStyle() {
        let cell = CategoryCell(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        var style = CategoryItemStyle.legacySelected
        style.backgroundColor = .systemGreen
        style.textColor = .white
        style.cornerRadius = 20

        cell.configure(title: "Nature", style: style)

        XCTAssertEqual(cell.contentView.backgroundColor, .systemGreen)
        XCTAssertEqual(cell.contentView.layer.cornerRadius, 20)
    }

    @MainActor
    func testHeaderConfigurationUpdatesLayoutSpacing() {
        struct TestCategory: CategoryDisplayable, Hashable {
            let categoryID: String
            let categoryTitle: String
        }

        let headerView = CategoryHeaderView<TestCategory>(frame: CGRect(x: 0, y: 0, width: 320, height: 52))
        var configuration = CategoryHeaderConfiguration.default
        configuration.itemSpacing = 16
        configuration.sectionInsets = NSDirectionalEdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)

        headerView.applyConfiguration(configuration)

        guard let collectionView = headerView.subviews.first as? UICollectionView,
              let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        else {
            XCTFail("Expected flow layout collection view")
            return
        }

        XCTAssertEqual(layout.minimumInteritemSpacing, 16)
        XCTAssertEqual(layout.sectionInset.left, 24)
    }

    func testItemAspectRatioHeightMultipliers() {
        XCTAssertEqual(ItemAspectRatio.square.heightMultiplier, 1.0, accuracy: 0.001)
        XCTAssertEqual(ItemAspectRatio.portrait4x3.heightMultiplier, 4.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(ItemAspectRatio.landscape16x9.heightMultiplier, 16.0 / 9.0, accuracy: 0.001)
        XCTAssertEqual(ItemAspectRatio.custom(2.5).heightMultiplier, 2.5, accuracy: 0.001)
    }

    func testApplyAspectRatioUpdatesItemHeightMultiplier() {
        var configuration = ItemGridConfiguration.default
        configuration.applyAspectRatio(.landscape16x9)
        XCTAssertEqual(configuration.itemHeightMultiplier, 16.0 / 9.0, accuracy: 0.001)

        configuration.applyAspectRatio(.square)
        XCTAssertEqual(configuration.itemHeightMultiplier, 1.0, accuracy: 0.001)
    }

    @MainActor
    func testHeaderViewAppliesBackgroundColor() {
        struct TestCategory: CategoryDisplayable, Hashable {
            let categoryID: String
            let categoryTitle: String
        }

        let headerView = CategoryHeaderView<TestCategory>(frame: CGRect(x: 0, y: 0, width: 320, height: 52))
        headerView.applyBackgroundColor(.systemGreen)

        XCTAssertEqual(headerView.backgroundColor, .systemGreen)
        guard let collectionView = headerView.subviews.first as? UICollectionView else {
            XCTFail("Expected collection view")
            return
        }
        XCTAssertEqual(collectionView.backgroundColor, .systemGreen)
    }

    @MainActor
    func testGridViewAppliesBackgroundColor() {
        let gridView = ItemGridCollectionView<TestGridItem>(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        gridView.applyBackgroundColor(.systemGreen)

        guard let collectionView = gridView.subviews.first as? UICollectionView else {
            XCTFail("Expected collection view")
            return
        }
        XCTAssertEqual(collectionView.backgroundColor, .systemGreen)
    }

    @MainActor
    func testViewControllerUpdateAppearanceAppliesBackgroundConfiguration() {
        struct TestCategory: CategoryDisplayable, Hashable {
            let categoryID: String
            let categoryTitle: String
        }

        struct TestProvider: CategoryItemPaginationProviding {
            typealias I = TestGridItem

            func totalCount(for categoryID: String) -> Int { 0 }
            func items(for categoryID: String, offset: Int, limit: Int) -> [TestGridItem] { [] }
        }

        let viewController = CategoryItemViewController<TestCategory, TestGridItem, TestProvider>(
            categories: [TestCategory(categoryID: "nature", categoryTitle: "Nature")],
            itemProvider: TestProvider(),
            pageSize: 10
        )
        viewController.loadViewIfNeeded()

        let backgroundConfiguration = CategoryItemBackgroundConfiguration(
            viewBackgroundColor: .systemRed,
            headerBackgroundColor: .systemGreen,
            gridBackgroundColor: .systemBlue
        )

        viewController.updateAppearance(
            headerConfiguration: .default,
            gridConfiguration: .default,
            backgroundConfiguration: backgroundConfiguration
        )

        XCTAssertEqual(viewController.view.backgroundColor, .systemRed)
        XCTAssertEqual(viewController.test_headerView.backgroundColor, .systemGreen)
        guard let gridCollectionView = viewController.test_gridView.subviews.first as? UICollectionView else {
            XCTFail("Expected grid collection view")
            return
        }
        XCTAssertEqual(gridCollectionView.backgroundColor, .systemBlue)
    }
}

private struct TestGridItem: ItemDisplayable {
    let itemID: String
    let categoryID: String
    let imageURL: URL
}
