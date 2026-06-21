import UIKit

final class CategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
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
    }
}
