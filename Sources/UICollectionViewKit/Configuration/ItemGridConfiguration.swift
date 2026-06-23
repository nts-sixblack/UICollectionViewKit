import UIKit

public enum ItemAspectRatio: Sendable {
    case square
    case portrait4x3
    case landscape16x9
    case custom(CGFloat)

    public var heightMultiplier: CGFloat {
        switch self {
        case .square:
            return 1.0
        case .portrait4x3:
            return 4.0 / 3.0
        case .landscape16x9:
            return 16.0 / 9.0
        case .custom(let multiplier):
            return multiplier
        }
    }
}

public struct ItemGridConfiguration: Sendable {
    public var columnCountPhone: Int
    public var columnCountPad: Int
    public var interItemSpacing: CGFloat
    public var interGroupSpacing: CGFloat
    public var contentInsets: NSDirectionalEdgeInsets
    public var cornerRadius: CGFloat
    public var imageBackgroundColor: UIColor
    /// Cell height as a multiple of cell width. Default `1.0` produces square cells.
    public var itemHeightMultiplier: CGFloat
    /// When an item has an `animatedURL`, only indices divisible by this value play animation. Default `4`. Set to `1` to animate every eligible item.
    public var animatedWebPInterval: Int

    public init(
        columnCountPhone: Int,
        columnCountPad: Int,
        interItemSpacing: CGFloat,
        interGroupSpacing: CGFloat,
        contentInsets: NSDirectionalEdgeInsets,
        cornerRadius: CGFloat,
        imageBackgroundColor: UIColor,
        itemHeightMultiplier: CGFloat = 1.0,
        animatedWebPInterval: Int = 4
    ) {
        self.columnCountPhone = columnCountPhone
        self.columnCountPad = columnCountPad
        self.interItemSpacing = interItemSpacing
        self.interGroupSpacing = interGroupSpacing
        self.contentInsets = contentInsets
        self.cornerRadius = cornerRadius
        self.imageBackgroundColor = imageBackgroundColor
        self.itemHeightMultiplier = itemHeightMultiplier
        self.animatedWebPInterval = animatedWebPInterval
    }

    func shouldPlayAnimatedWebP(itemSupportsAnimation: Bool, itemIndex: Int) -> Bool {
        guard itemSupportsAnimation else { return false }
        guard animatedWebPInterval > 1 else { return true }
        return itemIndex % animatedWebPInterval == 0
    }
}

extension ItemGridConfiguration {
    public static let `default` = ItemGridConfiguration(
        columnCountPhone: 3,
        columnCountPad: 5,
        interItemSpacing: 8,
        interGroupSpacing: 8,
        contentInsets: NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16),
        cornerRadius: 8,
        imageBackgroundColor: .secondarySystemBackground
    )

    public mutating func applyAspectRatio(_ ratio: ItemAspectRatio) {
        itemHeightMultiplier = ratio.heightMultiplier
    }
}
