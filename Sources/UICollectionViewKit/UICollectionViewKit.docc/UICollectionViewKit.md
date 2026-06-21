# ``UICollectionViewKit``

A UIKit collection view kit for SwiftUI with category tabs, bidirectional pagination, and image caching.

## Overview

UICollectionViewKit wraps a UIKit-based category + grid experience in a single SwiftUI view. You provide your own models and pagination logic through three protocols, and the library handles scroll state, diffable data sources, and image loading.

## Topics

### Essentials

- ``CategoryItemCollectionView``
- ``CategoryItemViewController``
- ``CategoryDisplayable``
- ``ItemDisplayable``
- ``CategoryItemPaginationProviding``
- ``ItemOverlayConfiguration``

### Getting Started

1. Define types conforming to ``CategoryDisplayable`` and ``ItemDisplayable``.
2. Implement ``CategoryItemPaginationProviding`` to supply paginated slices of items.
3. Embed ``CategoryItemCollectionView`` in your SwiftUI view hierarchy.

```swift
CategoryItemCollectionView(
    categories: categories,
    itemProvider: MyPaginationProvider(),
    pageSize: 50
)
```

Pass `stateVersion` on ``ItemOverlayConfiguration`` when overlay views depend on mutable external state (e.g. favorites). Provide a snapshot of that state (e.g. `store.favorites`) and ensure SwiftUI observes the store so the view re-renders when state updates. Visible overlays refresh automatically when `stateVersion` changes.

For UIKit-only integration, call ``CategoryItemViewController/reloadVisibleItemOverlays()`` when external overlay state changes.

### Pagination

The provider receives `offset` and `limit` parameters for each page request:

- **Initial load**: `offset = 0`, `limit = pageSize`
- **Load more** (scroll near bottom): `offset = nextOffset`, `limit = pageSize`
- **Load previous** (scroll near top): `offset = baseOffset - pageSize`, `limit = pageSize`

Return an empty array when `offset >= totalCount(for:)`.

### Category Switching

Each category maintains its own loaded items and scroll offset. Switching categories saves the current offset and restores it when the user returns.
