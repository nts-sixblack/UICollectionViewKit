import UIKit

public struct ItemOverlayConfiguration<I: ItemDisplayable> {
    public let makeView: () -> UIView
    public let update: (UIView, I) -> Void

    public init(
        makeView: @escaping () -> UIView,
        update: @escaping (UIView, I) -> Void
    ) {
        self.makeView = makeView
        self.update = update
    }
}
