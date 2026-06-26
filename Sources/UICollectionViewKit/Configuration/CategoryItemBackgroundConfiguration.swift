import UIKit

public struct CategoryItemBackgroundConfiguration: Sendable, Equatable {
    public var viewBackgroundColor: UIColor
    public var headerBackgroundColor: UIColor
    public var gridBackgroundColor: UIColor

    public init(
        viewBackgroundColor: UIColor,
        headerBackgroundColor: UIColor,
        gridBackgroundColor: UIColor
    ) {
        self.viewBackgroundColor = viewBackgroundColor
        self.headerBackgroundColor = headerBackgroundColor
        self.gridBackgroundColor = gridBackgroundColor
    }
}

extension CategoryItemBackgroundConfiguration {
    public static func == (
        lhs: CategoryItemBackgroundConfiguration,
        rhs: CategoryItemBackgroundConfiguration
    ) -> Bool {
        lhs.viewBackgroundColor.isEqual(rhs.viewBackgroundColor)
            && lhs.headerBackgroundColor.isEqual(rhs.headerBackgroundColor)
            && lhs.gridBackgroundColor.isEqual(rhs.gridBackgroundColor)
    }

    public static let `default` = CategoryItemBackgroundConfiguration(
        viewBackgroundColor: .systemBackground,
        headerBackgroundColor: .systemBackground,
        gridBackgroundColor: .systemBackground
    )
}
