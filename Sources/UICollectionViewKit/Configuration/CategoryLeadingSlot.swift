import UIKit

public struct CategoryLeadingSlot<C: CategoryDisplayable> {
    public let category: C
    public let makeContentView: () -> UIView

    public init(category: C, makeContentView: @escaping () -> UIView) {
        self.category = category
        self.makeContentView = makeContentView
    }
}
