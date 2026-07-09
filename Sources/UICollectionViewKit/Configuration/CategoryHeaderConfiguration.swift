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
        let maxPillHeight = [normalStyle, selectedStyle]
            .map { CategoryHeaderMetrics.estimatedPillHeight(for: $0) }
            .max() ?? 0
        return sectionInsets.top + maxPillHeight + sectionInsets.bottom
    }

    /// Resolved header height honoring the configured value and content requirements.
    public var effectiveHeaderHeight: CGFloat {
        effectiveHeaderHeight(measuredPillHeight: nil)
    }

    /// Resolved header height using a measured pill height when available.
    func effectiveHeaderHeight(measuredPillHeight: CGFloat?) -> CGFloat {
        if let measuredPillHeight {
            let minimumHeight = sectionInsets.top
                + measuredPillHeight
                + sectionInsets.bottom
                + CategoryHeaderMetrics.layoutSafetyMargin
            return max(headerHeight, minimumHeight)
        }
        return max(headerHeight, recommendedMinimumHeight)
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

enum CategoryHeaderMetrics {
    static let sizingSampleText = "Agy"
    static let layoutSafetyMargin: CGFloat = 2

    static func estimatedPillHeight(for style: CategoryItemStyle) -> CGFloat {
        style.contentInsets.top
            + estimatedTextHeight(for: style.font)
            + style.contentInsets.bottom
            + layoutSafetyMargin
    }

    static func estimatedTextHeight(for font: UIFont) -> CGFloat {
        let sample = sizingSampleText as NSString
        let boundingHeight = ceil(
            sample.boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).height
        )
        let metricHeight = ceil(font.ascender - font.descender + font.leading)
        return max(boundingHeight, metricHeight, ceil(font.lineHeight))
    }
}
