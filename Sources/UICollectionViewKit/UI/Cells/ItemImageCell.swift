import UIKit

final class ItemImageCell: UICollectionViewCell {
    static let reuseIdentifier = "ItemImageCell"

    private(set) var loadToken = UUID()
    private var currentURL: URL?

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.addSubview(imageView)
        contentView.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelCurrentLoad()
        loadToken = UUID()
        currentURL = nil
        imageView.image = nil
        activityIndicator.stopAnimating()
    }

    func configure(with url: URL) {
        if currentURL == url, imageView.image != nil {
            activityIndicator.stopAnimating()
            return
        }

        cancelCurrentLoad()
        loadToken = UUID()
        let token = loadToken
        currentURL = url

        if let cached = PersistentImageCache.shared.memoryImage(for: url) {
            imageView.image = cached
            activityIndicator.stopAnimating()
            return
        }

        imageView.image = nil
        activityIndicator.startAnimating()

        ImageLoadHandle.load(url: url, token: token) { [weak self] receivedToken, image in
            guard let self, receivedToken == self.loadToken else { return }
            self.activityIndicator.stopAnimating()
            self.imageView.image = image
        }
    }

    private func cancelCurrentLoad() {
        ImageLoadHandle.cancel(token: loadToken, url: currentURL)
    }
}
