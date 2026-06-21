import UIKit
import UICollectionViewKit

enum DemoFavoriteOverlay {
    static func makeHeartButtonContainer() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowRadius = 2
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        container.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -6),
            button.widthAnchor.constraint(equalToConstant: 28),
            button.heightAnchor.constraint(equalToConstant: 28),
        ])

        return container
    }

    static func updateHeartButton(_ view: UIView, for item: DemoItem, favoriteStore: DemoFavoriteStore) {
        guard let button = view.subviews.first as? UIButton else { return }

        let imageName = favoriteStore.isFavorite(item.itemID) ? "heart.fill" : "heart"
        button.setImage(UIImage(systemName: imageName), for: .normal)

        button.removeTarget(nil, action: nil, for: .touchUpInside)
        button.addAction(
            UIAction { _ in
                favoriteStore.toggle(item.itemID)
            },
            for: .touchUpInside
        )
    }
}

func makeFavoriteOverlayConfiguration(
    favoriteStore: DemoFavoriteStore
) -> ItemOverlayConfiguration<DemoItem> {
    ItemOverlayConfiguration(
        makeView: { DemoFavoriteOverlay.makeHeartButtonContainer() },
        update: { view, item in
            DemoFavoriteOverlay.updateHeartButton(view, for: item, favoriteStore: favoriteStore)
        }
    )
}
