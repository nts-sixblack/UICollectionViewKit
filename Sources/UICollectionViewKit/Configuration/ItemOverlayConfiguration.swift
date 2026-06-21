import UIKit

public struct ItemOverlayConfiguration<I: ItemDisplayable> {
    /// Snapshot of external overlay state. When this value changes,
    /// visible overlays are refreshed automatically.
    public let stateVersion: AnyHashable
    public let makeView: () -> UIView
    public let update: (UIView, I) -> Void

    public init(
        stateVersion: AnyHashable = 0,
        makeView: @escaping () -> UIView,
        update: @escaping (UIView, I) -> Void
    ) {
        self.stateVersion = stateVersion
        self.makeView = makeView
        self.update = update
    }
}
