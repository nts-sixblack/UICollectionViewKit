import UIKit

final class ItemImageCell: UICollectionViewCell {
    static let reuseIdentifier = "ItemImageCell"

    private(set) var loadToken = UUID()
    private var currentItemID: String?
    private var currentIsAnimatedWebP = false
    private var shouldAnimateWhenVisible = false
    private var hostedOverlayView: UIView?
    private var appearance = ItemGridConfiguration.default

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let overlayContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        applyAppearance(from: appearance)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.clipsToBounds = true
        contentView.addSubview(imageView)
        contentView.addSubview(overlayContainer)
        contentView.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            overlayContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelCurrentLoad()
        loadToken = UUID()
        currentItemID = nil
        currentIsAnimatedWebP = false
        shouldAnimateWhenVisible = false
        stopAnimationPlayback()
        activityIndicator.stopAnimating()
    }

    func applyAppearance(from configuration: ItemGridConfiguration) {
        appearance = configuration
        contentView.layer.cornerRadius = configuration.cornerRadius
        imageView.backgroundColor = configuration.imageBackgroundColor
    }

    func configure<I: ItemDisplayable>(
        with url: URL,
        isAnimatedWebP: Bool,
        overlayConfiguration: ItemOverlayConfiguration<I>?,
        item: I,
        appearance configuration: ItemGridConfiguration
    ) {
        applyAppearance(from: configuration)
        configureImage(itemID: item.itemID, url: url, isAnimatedWebP: isAnimatedWebP)
        configureOverlay(overlayConfiguration: overlayConfiguration, item: item)
    }

    func pauseAnimationIfNeeded() {
        guard shouldAnimateWhenVisible, imageView.isAnimating else { return }
        imageView.stopAnimating()
    }

    func resumeAnimationIfNeeded() {
        guard shouldAnimateWhenVisible, !imageView.isAnimating, imageView.animationImages != nil else { return }
        imageView.startAnimating()
    }

    internal var hasActiveAnimatedPlayback: Bool {
        shouldAnimateWhenVisible && imageView.animationImages != nil
    }

    private func configureImage(itemID: String, url: URL, isAnimatedWebP: Bool) {
        if currentItemID == itemID,
           currentIsAnimatedWebP == isAnimatedWebP,
           hasDisplayableContent {
            activityIndicator.stopAnimating()
            return
        }

        cancelCurrentLoad()
        loadToken = UUID()
        let token = loadToken
        currentItemID = itemID
        currentIsAnimatedWebP = isAnimatedWebP

        if let cached = PersistentImageCache.shared.memoryLoadedImage(for: itemID),
           let loadedImage = compatibleLoadedImage(cached, isAnimatedWebP: isAnimatedWebP) {
            applyLoadedImage(loadedImage, animateIfVisible: true)
            activityIndicator.stopAnimating()
            return
        }

        stopAnimationPlayback()
        imageView.image = nil
        activityIndicator.startAnimating()

        ImageLoadHandle.load(
            itemID: itemID,
            url: url,
            isAnimatedWebP: isAnimatedWebP,
            token: token
        ) { [weak self] receivedToken, loadedImage in
            guard let self, receivedToken == self.loadToken else { return }
            self.activityIndicator.stopAnimating()
            guard let loadedImage else { return }
            self.applyLoadedImage(loadedImage, animateIfVisible: true)
        }
    }

    private var hasDisplayableContent: Bool {
        imageView.image != nil || imageView.animationImages != nil
    }

    private func compatibleLoadedImage(_ cached: LoadedImage, isAnimatedWebP: Bool) -> LoadedImage? {
        switch (cached, isAnimatedWebP) {
        case (.static, false), (.animated, true):
            return cached
        case let (.animated(sequence), false):
            return .static(sequence.posterFrame)
        case (.static, true):
            return nil
        }
    }

    private func applyLoadedImage(_ loadedImage: LoadedImage, animateIfVisible: Bool) {
        switch loadedImage {
        case let .static(image):
            stopAnimationPlayback()
            imageView.image = image
        case let .animated(sequence):
            imageView.image = sequence.posterFrame
            imageView.animationImages = sequence.frames
            imageView.animationDuration = sequence.duration
            imageView.animationRepeatCount = 0
            shouldAnimateWhenVisible = true
            if animateIfVisible {
                imageView.startAnimating()
            }
        }
    }

    private func stopAnimationPlayback() {
        shouldAnimateWhenVisible = false
        imageView.stopAnimating()
        imageView.animationImages = nil
        imageView.image = nil
    }

    private func configureOverlay<I: ItemDisplayable>(
        overlayConfiguration: ItemOverlayConfiguration<I>?,
        item: I
    ) {
        guard let overlayConfiguration else {
            hostedOverlayView?.removeFromSuperview()
            hostedOverlayView = nil
            return
        }

        if hostedOverlayView == nil {
            let overlayView = overlayConfiguration.makeView()
            overlayView.translatesAutoresizingMaskIntoConstraints = false
            overlayContainer.addSubview(overlayView)
            NSLayoutConstraint.activate([
                overlayView.topAnchor.constraint(equalTo: overlayContainer.topAnchor),
                overlayView.bottomAnchor.constraint(equalTo: overlayContainer.bottomAnchor),
                overlayView.leadingAnchor.constraint(equalTo: overlayContainer.leadingAnchor),
                overlayView.trailingAnchor.constraint(equalTo: overlayContainer.trailingAnchor),
            ])
            hostedOverlayView = overlayView
        }

        if let hostedOverlayView {
            overlayConfiguration.update(hostedOverlayView, item)
        }
    }

    private func cancelCurrentLoad() {
        ImageLoadHandle.cancel(token: loadToken, itemID: currentItemID)
    }
}
