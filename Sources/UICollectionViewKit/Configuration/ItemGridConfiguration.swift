import UIKit

public struct ItemGridConfiguration: Sendable {
    public var columnCountPhone: Int
    public var columnCountPad: Int
    public var interItemSpacing: CGFloat
    public var interGroupSpacing: CGFloat
    public var contentInsets: NSDirectionalEdgeInsets
    public var cornerRadius: CGFloat
    public var imageBackgroundColor: UIColor

    public init(
        columnCountPhone: Int,
        columnCountPad: Int,
        interItemSpacing: CGFloat,
        interGroupSpacing: CGFloat,
        contentInsets: NSDirectionalEdgeInsets,
        cornerRadius: CGFloat,
        imageBackgroundColor: UIColor
    ) {
        self.columnCountPhone = columnCountPhone
        self.columnCountPad = columnCountPad
        self.interItemSpacing = interItemSpacing
        self.interGroupSpacing = interGroupSpacing
        self.contentInsets = contentInsets
        self.cornerRadius = cornerRadius
        self.imageBackgroundColor = imageBackgroundColor
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
}
