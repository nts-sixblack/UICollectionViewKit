# UICollectionViewKit

A Swift Package that embeds a high-performance UIKit collection view inside SwiftUI. It provides category tabs, bidirectional pagination, and built-in image caching keyed by item ID with downsampling.

## Features

- **SwiftUI bridge** — Drop `CategoryItemCollectionView` into any SwiftUI view hierarchy.
- **Category tabs** — Horizontal category picker with per-category scroll position restoration.
- **Customizable UI** — Configure category tab styles (normal/selected), spacing, grid layout (columns, insets, corner radius, aspect ratio), and container background colors.
- **Bidirectional pagination** — Load more items when scrolling down; load previous pages when scrolling up.
- **Image loading** — Memory + disk cache keyed by item ID with ImageIO downsampling, concurrent download limits, optional animated WebP playback, and configurable animation interval.
- **Zero third-party dependencies** — UIKit, SwiftUI, ImageIO, and CryptoKit only.

## Requirements

- iOS 15+
- Swift 5.9+

## Installation

### Swift Package Manager

Add UICollectionViewKit to your project via Xcode:

1. **File → Add Package Dependencies…**
2. Enter `https://github.com/nts-sixblack/UICollectionViewKit` (or choose **Add Local…** and select this folder).
3. Add the `UICollectionViewKit` product to your app target.

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nts-sixblack/UICollectionViewKit.git", from: "1.9.0"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["UICollectionViewKit"]
    ),
]
```

### Local development

This repository is a monorepo. The `Example/` app depends on the local package at the repository root.

## Quick Start

### 1. Conform your models to the display protocols

```swift
import UICollectionViewKit

struct MyCategory: CategoryDisplayable {
    let categoryID: String
    let categoryTitle: String
}

struct MyItem: ItemDisplayable {
    let itemID: String
    let categoryID: String
    let imageURL: URL
    // Optional animated WebP/GIF URL played for configured grid positions.
    let animatedURL: URL?
}
```

### 2. Implement a pagination provider

```swift
struct MyPaginationProvider: CategoryItemPaginationProviding {
    typealias I = MyItem

    func totalCount(for categoryID: String) -> Int {
        // Total items available for this category
    }

    func items(for categoryID: String, offset: Int, limit: Int) -> [MyItem] {
        // Return a slice of items starting at `offset`, up to `limit` items
    }
}
```

### 3. Embed in SwiftUI

```swift
import SwiftUI
import UICollectionViewKit

struct ContentView: View {
    var body: some View {
        CategoryItemCollectionView(
            categories: myCategories,
            itemProvider: MyPaginationProvider(),
            pageSize: 50
        )
    }
}
```

### 4. Optional: custom overlay views and item selection

Add a UIKit overlay view on each item (e.g. a favorite button) and handle item taps:

```swift
final class FavoriteStore: ObservableObject {
    @Published private(set) var favorites: Set<String> = []

    func toggle(_ itemID: String) {
        if favorites.contains(itemID) {
            favorites.remove(itemID)
        } else {
            favorites.insert(itemID)
        }
    }
}

struct ContentView: View {
    @StateObject private var favoriteStore = FavoriteStore()

    var body: some View {
        CategoryItemCollectionView(
            categories: myCategories,
            itemProvider: MyPaginationProvider(),
            pageSize: 50,
            itemOverlayConfiguration: ItemOverlayConfiguration(
                stateVersion: favoriteStore.favorites,
                makeView: {
                    let button = UIButton(type: .system)
                    button.tintColor = .white
                    button.translatesAutoresizingMaskIntoConstraints = false
                    return button
                },
                update: { view, item in
                    guard let button = view as? UIButton else { return }
                    let name = favoriteStore.favorites.contains(item.itemID) ? "heart.fill" : "heart"
                    button.setImage(UIImage(systemName: name), for: .normal)
                    button.removeTarget(nil, action: nil, for: .touchUpInside)
                    button.addAction(UIAction { _ in
                        favoriteStore.toggle(item.itemID)
                    }, for: .touchUpInside)
                }
            ),
            onItemSelected: { item in
                print("Selected:", item.itemID)
            }
        )
    }
}
```

`makeView` is called once per reused cell; `update` runs whenever the cell is configured. Overlay controls receive their own touches without triggering item selection.

When overlay content depends on mutable external state (e.g. a favorite store), pass a snapshot of that state as `stateVersion`. The library refreshes visible overlays automatically when `stateVersion` changes. Ensure SwiftUI observes the store (e.g. `@StateObject` / `@ObservedObject` with `@Published` properties) so the view re-renders when state updates.

### 5. Optional: customize category tabs and grid layout

Configure selected/normal tab styles, spacing between tabs, and grid columns/insets:

```swift
CategoryItemCollectionView(
    categories: myCategories,
    itemProvider: MyPaginationProvider(),
    pageSize: 50,
    headerConfiguration: CategoryHeaderConfiguration(
        normalStyle: CategoryItemStyle(
            backgroundColor: .clear,
            borderColor: .separator,
            textColor: .label,
            font: .systemFont(ofSize: 14, weight: .regular),
            cornerRadius: 20,
            borderWidth: 1,
            contentInsets: NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        ),
        selectedStyle: CategoryItemStyle(
            backgroundColor: .systemIndigo,
            borderColor: .systemIndigo,
            textColor: .white,
            font: .systemFont(ofSize: 14, weight: .semibold),
            cornerRadius: 20,
            borderWidth: 0,
            contentInsets: NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        ),
        itemSpacing: 12,
        lineSpacing: 8,
        sectionInsets: NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20),
        headerHeight: 48
    ),
    gridConfiguration: ItemGridConfiguration(
        columnCountPhone: 4,
        columnCountPad: 5,
        interItemSpacing: 10,
        interGroupSpacing: 10,
        contentInsets: NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20),
        cornerRadius: 12,
        imageBackgroundColor: .secondarySystemBackground,
        itemHeightMultiplier: ItemAspectRatio.landscape16x9.heightMultiplier
    ),
    backgroundConfiguration: CategoryItemBackgroundConfiguration(
        viewBackgroundColor: .systemBackground,
        headerBackgroundColor: .systemBackground,
        gridBackgroundColor: .secondarySystemBackground
    )
)
```

Or use aspect ratio presets:

```swift
var gridConfiguration = ItemGridConfiguration.default
gridConfiguration.applyAspectRatio(.portrait4x3)
```

Omit `headerConfiguration`, `gridConfiguration`, and `backgroundConfiguration` to keep the built-in defaults.

### 6. Optional: leading category with custom content

Add a leading category tab that shows custom SwiftUI or UIKit content instead of the paginated grid:

```swift
CategoryItemCollectionView(
    categories: myCategories,
    itemProvider: MyPaginationProvider(),
    pageSize: 50,
    leadingCategory: MyCategory(categoryID: "favorites", categoryTitle: "Favorites"),
    leadingCategoryContent: {
        FavoritesView()
    }
)
```

## Architecture

```
CategoryItemCollectionView (SwiftUI)
        │
        ▼
CategoryItemViewController
   ├── CategoryHeaderView      ← horizontal category tabs
   └── ItemGridCollectionView  ← paginated image grid
           └── ItemImageCell   ← async image loading (cache keyed by item ID)
                   └── ImageLoader / PersistentImageCache
```

### Pagination contract

- On first display of a category, the library requests `items(for:offset:0, limit:pageSize)`.
- When the user scrolls near the bottom, it requests the next page at `offset = nextOffset`.
- When the user scrolls near the top and `baseOffset > 0`, it prepends the previous page.
- Implement `totalCount(for:)` so the library knows when there is no more data.

### Category switching

When the user selects a different category, the current scroll offset is saved and restored when they return to that category.

### Image caching

Thumbnails are cached in memory and on disk by `itemID` plus image variant, not `imageURL`. Provide a stable, globally unique `itemID` on each `ItemDisplayable` model so signed or rotating image URLs reuse the same cached files.

### Animated WebP

Set `animatedURL` on items that have a separate animated WebP/GIF preview. The library shows `imageURL` first as the static poster, then decodes downsampled animated frames from `animatedURL`, caches the raw files on disk separately, and plays the animation in the grid cell. Omit the property or return `nil` to keep the lightweight static-only path.

By default, `ItemGridConfiguration.animatedWebPInterval` is `4`, so only items at grid indices `0`, `4`, `8`, … play animation when `animatedURL` exists. Other eligible items show `imageURL` only. Set `animatedWebPInterval` to `1` to animate every eligible item.

Animation pauses when a cell scrolls off screen and resumes when it becomes visible again, reducing CPU use while scrolling.

```swift
struct MyItem: ItemDisplayable {
    let itemID: String
    let categoryID: String
    let imageURL: URL
    let animatedURL: URL?
}

var gridConfiguration = ItemGridConfiguration.default
gridConfiguration.animatedWebPInterval = 1 // animate every eligible item
```

## Public API

| Symbol | Description |
|---|---|
| `CategoryDisplayable` | Protocol for category tab models (`categoryID`, `categoryTitle`). |
| `ItemDisplayable` | Protocol for grid item models (`itemID`, `categoryID`, `imageURL`, optional `animatedURL`). |
| `CategoryItemPaginationProviding` | Protocol for paginated data access. |
| `ItemOverlayConfiguration` | Factory + updater for a custom UIKit overlay on each item. Pass `stateVersion` to refresh visible overlays when external overlay state changes. |
| `CategoryItemStyle` | Appearance for one category tab state (colors, font, corner radius, content insets). |
| `CategoryHeaderConfiguration` | Category tab bar styling: normal/selected styles, spacing, section insets, header height. |
| `ItemGridConfiguration` | Grid layout and cell appearance: column counts, spacing, content insets, corner radius, item aspect ratio, animated WebP interval. |
| `ItemAspectRatio` | Presets for global item height relative to width (`square`, `portrait4x3`, `landscape16x9`, `custom`). |
| `CategoryItemBackgroundConfiguration` | Container background colors for the view controller, header bar, and grid canvas. |
| `CategoryLeadingSlot` | UIKit hook for a leading category tab with custom content instead of the grid. |
| `CategoryItemCollectionView` | SwiftUI `UIViewControllerRepresentable` entry point. |
| `CategoryItemViewController` | UIKit host with optional `onItemSelected`, overlay support, and `updateAppearance`. |

## Example

See the [`Example/`](Example/) app in this repository for a full demo with 5 categories and 10,000 items per category using [picsum.photos](https://picsum.photos) images.

Repository: [https://github.com/nts-sixblack/UICollectionViewKit](https://github.com/nts-sixblack/UICollectionViewKit)

```bash
open Example/Example.xcodeproj
```

## License

UICollectionViewKit is available under the MIT license. See [LICENSE](LICENSE) for details.
