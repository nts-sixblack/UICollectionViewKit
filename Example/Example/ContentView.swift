import SwiftUI
import UICollectionViewKit

struct ContentView: View {
    @StateObject private var favoriteStore = DemoFavoriteStore()
    @State private var selectedItemID: String?

    var body: some View {
        DemoCollectionView(
            favoriteStore: favoriteStore,
            selectedItemID: $selectedItemID
        )
        .ignoresSafeArea(edges: .bottom)
        .alert(
            "Item Selected",
            isPresented: Binding(
                get: { selectedItemID != nil },
                set: { if !$0 { selectedItemID = nil } }
            )
        ) {
            Button("OK") {
                selectedItemID = nil
            }
        } message: {
            if let selectedItemID {
                Text("Item ID: \(selectedItemID)")
            }
        }
    }
}

private struct DemoCollectionView: UIViewControllerRepresentable {
    @ObservedObject var favoriteStore: DemoFavoriteStore
    @Binding var selectedItemID: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(favoriteStore: favoriteStore, selectedItemID: $selectedItemID)
    }

    func makeUIViewController(context: Context) -> CategoryItemViewController<DemoCategory, DemoItem, DemoItemPaginationProvider> {
        let coordinator = context.coordinator
        let overlayConfiguration = ItemOverlayConfiguration(
            makeView: { coordinator.makeHeartButton() },
            update: { view, item in coordinator.updateHeartButton(view, for: item) }
        )

        let viewController = CategoryItemViewController(
            categories: DemoDataSource.categories,
            itemProvider: DemoItemPaginationProvider(),
            pageSize: DemoDataSource.pageSize,
            itemOverlayConfiguration: overlayConfiguration,
            onItemSelected: { item in
                coordinator.selectedItemID.wrappedValue = item.itemID
            }
        )

        coordinator.viewController = viewController
        favoriteStore.onFavoritesChanged = { [weak viewController] in
            viewController?.reloadVisibleItemOverlays()
        }

        return viewController
    }

    func updateUIViewController(
        _ viewController: CategoryItemViewController<DemoCategory, DemoItem, DemoItemPaginationProvider>,
        context: Context
    ) {
        context.coordinator.viewController = viewController
        favoriteStore.onFavoritesChanged = { [weak viewController] in
            viewController?.reloadVisibleItemOverlays()
        }
    }

    final class Coordinator {
        let favoriteStore: DemoFavoriteStore
        var selectedItemID: Binding<String?>
        weak var viewController: CategoryItemViewController<DemoCategory, DemoItem, DemoItemPaginationProvider>?

        init(favoriteStore: DemoFavoriteStore, selectedItemID: Binding<String?>) {
            self.favoriteStore = favoriteStore
            self.selectedItemID = selectedItemID
        }

        func makeHeartButton() -> UIView {
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

        func updateHeartButton(_ view: UIView, for item: DemoItem) {
            guard let button = view.subviews.first as? UIButton else { return }

            let imageName = favoriteStore.isFavorite(item.itemID) ? "heart.fill" : "heart"
            button.setImage(UIImage(systemName: imageName), for: .normal)

            button.removeTarget(nil, action: nil, for: .touchUpInside)
            button.addAction(
                UIAction { [weak self] _ in
                    self?.favoriteStore.toggle(item.itemID)
                },
                for: .touchUpInside
            )
        }
    }
}

#Preview {
    ContentView()
}
