import Foundation

enum DemoDataSource {
    static let itemsPerCategory = 10_000
    static let pageSize = 50

    static let categories: [DemoCategory] = [
        DemoCategory(categoryID: "nature", categoryTitle: "Nature"),
        DemoCategory(categoryID: "animals", categoryTitle: "Animals"),
        DemoCategory(categoryID: "city", categoryTitle: "City"),
        DemoCategory(categoryID: "food", categoryTitle: "Food"),
        DemoCategory(categoryID: "tech", categoryTitle: "Tech"),
    ]
}
