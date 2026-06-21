import Foundation

public protocol ItemDisplayable: Hashable {
    var itemID: String { get }
    var categoryID: String { get }
    var imageURL: URL { get }
    var isAnimatedWebP: Bool { get }
}

public extension ItemDisplayable {
    var isAnimatedWebP: Bool { false }
}
