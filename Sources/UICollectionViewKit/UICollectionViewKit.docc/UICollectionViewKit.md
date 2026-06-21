# ``UICollectionViewKit``

A UIKit collection view kit for SwiftUI with category tabs, bidirectional pagination, image caching, and customizable header/grid styling.

## Overview

UICollectionViewKit wraps a UIKit-based category + grid experience in a single SwiftUI view. You provide your own models and pagination logic through three protocols, and the library handles scroll state, diffable data sources, and image loading.

Customize category tab appearance with ``CategoryHeaderConfiguration`` (normal vs selected pill styles, spacing, insets, header height) and the item grid with ``ItemGridConfiguration`` (column counts, spacing, content insets, corner radius). Omit both to keep the built-in defaults.

## Topics

### Essentials

- ``CategoryItemCollectionView``
- ``CategoryItemViewController``
- ``CategoryDisplayable``
- ``ItemDisplayable``
- ``CategoryItemPaginationProviding``
- ``ItemOverlayConfiguration``
- ``CategoryItemStyle``
- ``CategoryHeaderConfiguration``
- ``ItemGridConfiguration``

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

### UI Configuration

Use ``CategoryHeaderConfiguration`` to customize category tab appearance (normal vs selected styles, spacing, insets, header height) and ``ItemGridConfiguration`` for grid columns, spacing, insets, and cell corner radius. Both default to the built-in styling when omitted.

```swift
CategoryItemCollectionView(
    categories: categories,
    itemProvider: provider,
    pageSize: 50,
    headerConfiguration: CategoryHeaderConfiguration(
        normalStyle: .legacyNormal,
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
        imageBackgroundColor: .secondarySystemBackground
    )
)
```

``CategoryItemStyle/legacyNormal`` and ``CategoryItemStyle/legacySelected`` match the original built-in pill styling if you want to override only one state.

Call ``CategoryItemViewController/updateAppearance(headerConfiguration:gridConfiguration:)`` to apply styling changes at runtime.

### Pagination

The provider receives `offset` and `limit` parameters for each page request:

- **Initial load**: `offset = 0`, `limit = pageSize`
- **Load more** (scroll near bottom): `offset = nextOffset`, `limit = pageSize`
- **Load previous** (scroll near top): `offset = baseOffset - pageSize`, `limit = pageSize`

Return an empty array when `offset >= totalCount(for:)`.

### Category Switching

Each category maintains its own loaded items and scroll offset. Switching categories saves the current offset and restores it when the user returns.
