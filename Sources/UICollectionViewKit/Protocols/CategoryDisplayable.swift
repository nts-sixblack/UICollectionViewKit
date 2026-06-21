import Foundation

public protocol CategoryDisplayable: Hashable {
    var categoryID: String { get }
    var categoryTitle: String { get }
}
