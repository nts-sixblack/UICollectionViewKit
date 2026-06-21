# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-06-21

### Added

- `stateVersion` parameter on `ItemOverlayConfiguration` to refresh visible item overlays when external overlay state changes.

### Changed

- `CategoryItemViewController.updateItemInteraction(_:)` automatically reloads visible overlays when `stateVersion` changes.

### Removed

- **Breaking:** `overlayReloadToken` parameter on `CategoryItemCollectionView`. Use `ItemOverlayConfiguration(stateVersion:)` instead.

### Migration

```swift
// Before (1.1.0)
overlayReloadToken: token
.onAppear { store.onChange = { token += 1 } }

// After (1.2.0)
itemOverlayConfiguration: ItemOverlayConfiguration(
    stateVersion: store.favorites,
    makeView: ..., update: ...
)
```

### Documentation

- README and DocC updated with `stateVersion` usage.

## [1.1.0] - 2026-06-21

### Added

- `overlayReloadToken` parameter on `CategoryItemCollectionView` to refresh visible item overlays when external state changes (e.g. favorites).
- Example app tab comparing direct UIKit integration vs SwiftUI bridge.

### Changed

- `CategoryItemViewController.update(categories:)` skips unnecessary reloads when category IDs are unchanged.
- `reloadContent()` saves scroll offset before reloading.

### Documentation

- README and DocC updated with `overlayReloadToken` usage.

## [1.0.0] - 2026-06-21

### Added

- Initial release extracted from the Example project.
- `CategoryItemCollectionView` SwiftUI bridge for embedding UIKit collection views.
- Category tabs with per-category scroll state restoration.
- Bidirectional pagination (load more at bottom, load previous at top).
- Image loading with memory + disk cache and downsampling.
- Public protocols: `CategoryDisplayable`, `ItemDisplayable`, `CategoryItemPaginationProviding`.
