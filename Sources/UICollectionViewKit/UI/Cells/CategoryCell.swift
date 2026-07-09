import UIKit

final class CategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(titleLabel)

        topConstraint = titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        bottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        leadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)

        NSLayoutConstraint.activate([
            topConstraint,
            bottomConstraint,
            leadingConstraint,
            trailingConstraint,
        ].compactMap { $0 })
    }

    @MainActor
    static func measuredContentSize(
        title: String = CategoryHeaderMetrics.sizingSampleText,
        style: CategoryItemStyle
    ) -> CGSize {
        let cell = CategoryCell(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        cell.configure(title: title, style: style)
        cell.contentView.setNeedsLayout()
        cell.contentView.layoutIfNeeded()
        let fittedSize = cell.contentView.systemLayoutSizeFitting(
            CGSize(
                width: UIView.layoutFittingCompressedSize.width,
                height: UIView.layoutFittingExpandedSize.height
            ),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: ceil(fittedSize.width), height: ceil(fittedSize.height))
    }

    @MainActor
    static func measuredContentHeight(title: String = CategoryHeaderMetrics.sizingSampleText, style: CategoryItemStyle) -> CGFloat {
        measuredContentSize(title: title, style: style).height
    }

    func configure(title: String, style: CategoryItemStyle) {
        titleLabel.text = title
        titleLabel.font = style.font
        titleLabel.textColor = style.textColor
        contentView.backgroundColor = style.backgroundColor
        contentView.layer.cornerRadius = style.cornerRadius
        contentView.layer.borderWidth = style.borderWidth
        contentView.layer.borderColor = style.borderColor.cgColor

        topConstraint?.constant = style.contentInsets.top
        bottomConstraint?.constant = -style.contentInsets.bottom
        leadingConstraint?.constant = style.contentInsets.leading
        trailingConstraint?.constant = -style.contentInsets.trailing

        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        guard let attributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes else {
            return layoutAttributes
        }

        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()

        let proposedHeight = max(attributes.size.height, 1)
        let intrinsicHeight = ceil(
            contentView.systemLayoutSizeFitting(
                CGSize(
                    width: UIView.layoutFittingCompressedSize.width,
                    height: UIView.layoutFittingExpandedSize.height
                ),
                withHorizontalFittingPriority: .fittingSizeLevel,
                verticalFittingPriority: .fittingSizeLevel
            ).height
        )
        let height = max(proposedHeight, intrinsicHeight)
        let fittedSize = contentView.systemLayoutSizeFitting(
            CGSize(width: UIView.layoutFittingCompressedSize.width, height: height),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .required
        )

        attributes.frame.size = CGSize(width: ceil(fittedSize.width), height: height)
        return attributes
    }
}
