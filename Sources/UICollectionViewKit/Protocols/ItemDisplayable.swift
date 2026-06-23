import Foundation

public protocol ItemDisplayable: Hashable {
    var itemID: String { get }
    var categoryID: String { get }
    var imageURL: URL { get }
    var animatedURL: URL? { get }
}

public extension ItemDisplayable {
    var animatedURL: URL? { nil }
}
