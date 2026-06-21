# UICollectionViewKit

A Swift Package that embeds a high-performance UIKit collection view inside SwiftUI. It provides category tabs, bidirectional pagination, and built-in image caching with downsampling.

## Features

- **SwiftUI bridge** — Drop `CategoryItemCollectionView` into any SwiftUI view hierarchy.
- **Category tabs** — Horizontal category picker with per-category scroll position restoration.
- **Bidirectional pagination** — Load more items when scrolling down; load previous pages when scrolling up.
- **Image loading** — Memory + disk cache with ImageIO downsampling and concurrent download limits.
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
    .package(url: "https://github.com/nts-sixblack/UICollectionViewKit.git", from: "1.0.0"),
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

## Architecture

```
CategoryItemCollectionView (SwiftUI)
        │
        ▼
CategoryItemViewController
   ├── CategoryHeaderView      ← horizontal category tabs
   └── ItemGridCollectionView  ← paginated image grid
           └── ItemImageCell   ← async image loading
                   └── ImageLoader / PersistentImageCache
```

### Pagination contract

- On first display of a category, the library requests `items(for:offset:0, limit:pageSize)`.
- When the user scrolls near the bottom, it requests the next page at `offset = nextOffset`.
- When the user scrolls near the top and `baseOffset > 0`, it prepends the previous page.
- Implement `totalCount(for:)` so the library knows when there is no more data.

### Category switching

When the user selects a different category, the current scroll offset is saved and restored when they return to that category.

## Public API

| Symbol | Description |
|---|---|
| `CategoryDisplayable` | Protocol for category tab models (`categoryID`, `categoryTitle`). |
| `ItemDisplayable` | Protocol for grid item models (`itemID`, `categoryID`, `imageURL`). |
| `CategoryItemPaginationProviding` | Protocol for paginated data access. |
| `CategoryItemCollectionView` | SwiftUI `UIViewControllerRepresentable` entry point. |

## Example

See the [`Example/`](Example/) app in this repository for a full demo with 5 categories and 10,000 items per category using [picsum.photos](https://picsum.photos) images.

Repository: [https://github.com/nts-sixblack/UICollectionViewKit](https://github.com/nts-sixblack/UICollectionViewKit)

```bash
open Example/Example.xcodeproj
```

## License

UICollectionViewKit is available under the MIT license. See [LICENSE](LICENSE) for details.
