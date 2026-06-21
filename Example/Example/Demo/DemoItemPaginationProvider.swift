import Foundation
import UICollectionViewKit

struct DemoItemPaginationProvider: CategoryItemPaginationProviding {
    typealias I = DemoItem

    func totalCount(for categoryID: String) -> Int {
        DemoDataSource.itemsPerCategory
    }

    func items(for categoryID: String, offset: Int, limit: Int) -> [DemoItem] {
        guard offset < totalCount(for: categoryID) else { return [] }

        let endIndex = min(offset + limit, totalCount(for: categoryID))
        return (offset..<endIndex).map { index in
            let seed = "\(categoryID)-\(index)"
            let url = URL(string: "https://picsum.photos/seed/\(seed)/300/300")!
            return DemoItem(
                itemID: "\(categoryID)-\(index)",
                categoryID: categoryID,
                imageURL: url
            )
        }
    }
}
