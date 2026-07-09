import UIKit

public struct CategoryHeaderConfiguration: Sendable, Equatable {
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
    /// Minimum header height that fits section insets plus the tallest category pill content.
    public var recommendedMinimumHeight: CGFloat {
        let styles = [normalStyle, selectedStyle]
        let maxContentInsets = styles
            .map { $0.contentInsets.top + $0.contentInsets.bottom }
            .max() ?? 0
        let maxLineHeight = styles
            .map { ceil($0.font.lineHeight) }
            .max() ?? 0
        let contentHeight = maxContentInsets + maxLineHeight
        return sectionInsets.top + contentHeight + sectionInsets.bottom
    }

    /// Resolved header height honoring the configured value and content requirements.
    public var effectiveHeaderHeight: CGFloat {
        max(headerHeight, recommendedMinimumHeight)
    }

    public static let `default` = CategoryHeaderConfiguration(
        normalStyle: .legacyNormal,
        selectedStyle: .legacySelected,
        itemSpacing: 8,
        lineSpacing: 8,
        sectionInsets: NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16),
        headerHeight: 52
    )
}
