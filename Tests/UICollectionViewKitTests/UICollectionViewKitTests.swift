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

        cell.configure(with: item1.imageURL, overlayConfiguration: configuration, item: item1)
        XCTAssertEqual(makeViewCallCount, 1)

        cell.configure(with: item2.imageURL, overlayConfiguration: configuration, item: item2)
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
}
