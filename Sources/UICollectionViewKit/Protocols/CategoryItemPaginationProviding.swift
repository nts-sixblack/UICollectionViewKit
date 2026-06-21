public protocol CategoryItemPaginationProviding<I> {
    associatedtype I: ItemDisplayable

    func totalCount(for categoryID: String) -> Int
    func items(for categoryID: String, offset: Int, limit: Int) -> [I]
}
