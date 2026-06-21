import UIKit

public struct CategoryHeaderConfiguration: Sendable {
    public var normalStyle: CategoryItemStyle
    public var selectedStyle: CategoryItemStyle
    public var itemSpacing: CGFloat
    public var lineSpacing: CGFloat
    public var sectionInsets: NSDirectionalEdgeInsets
    public var headerHeight: CGFloat

    public init(
        normalStyle: CategoryItemStyle,
        selectedStyle: CategoryItemStyle,
        itemSpacing: CGFloat,
        lineSpacing: CGFloat,
        sectionInsets: NSDirectionalEdgeInsets,
        headerHeight: CGFloat
    ) {
        self.normalStyle = normalStyle
        self.selectedStyle = selectedStyle
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
        self.sectionInsets = sectionInsets
        self.headerHeight = headerHeight
    }
}

extension CategoryHeaderConfiguration {
    public static let `default` = CategoryHeaderConfiguration(
        normalStyle: .legacyNormal,
        selectedStyle: .legacySelected,
        itemSpacing: 8,
        lineSpacing: 8,
        sectionInsets: NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16),
        headerHeight: 52
    )
}
