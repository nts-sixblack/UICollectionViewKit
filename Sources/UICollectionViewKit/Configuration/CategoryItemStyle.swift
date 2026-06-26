import UIKit

public struct CategoryItemStyle: Sendable, Equatable {
    public var backgroundColor: UIColor
    public var borderColor: UIColor
    public var textColor: UIColor
    public var font: UIFont
    public var cornerRadius: CGFloat
    public var borderWidth: CGFloat
    public var contentInsets: NSDirectionalEdgeInsets

    public init(
        backgroundColor: UIColor,
        borderColor: UIColor,
        textColor: UIColor,
        font: UIFont,
        cornerRadius: CGFloat,
        borderWidth: CGFloat,
        contentInsets: NSDirectionalEdgeInsets
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.textColor = textColor
        self.font = font
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.contentInsets = contentInsets
    }
}

extension CategoryItemStyle {
    public static func == (lhs: CategoryItemStyle, rhs: CategoryItemStyle) -> Bool {
        lhs.backgroundColor.isEqual(rhs.backgroundColor)
            && lhs.borderColor.isEqual(rhs.borderColor)
            && lhs.textColor.isEqual(rhs.textColor)
            && lhs.font.isEqual(rhs.font)
            && lhs.cornerRadius == rhs.cornerRadius
            && lhs.borderWidth == rhs.borderWidth
            && lhs.contentInsets == rhs.contentInsets
    }

    public static let legacyNormal = CategoryItemStyle(
        backgroundColor: .secondarySystemBackground,
        borderColor: .separator,
        textColor: .label,
        font: .systemFont(ofSize: 15, weight: .medium),
        cornerRadius: 16,
        borderWidth: 1,
        contentInsets: NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    )

    public static let legacySelected = CategoryItemStyle(
        backgroundColor: .systemBlue,
        borderColor: .systemBlue,
        textColor: .white,
        font: .systemFont(ofSize: 15, weight: .medium),
        cornerRadius: 16,
        borderWidth: 1,
        contentInsets: NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    )
}
