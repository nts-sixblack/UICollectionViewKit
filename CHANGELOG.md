# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0] - 2026-06-22

### Added

- `isAnimatedWebP` on `ItemDisplayable` (default `false`) to opt in to animated WebP playback for items whose URL points to an animated WebP file.
- Multi-frame image decoding via ImageIO when `isAnimatedWebP` is `true`, with downsampled frames (max 300px) and frame timing from WebP/GIF metadata.
- Animated playback in `ItemImageCell` using `UIImageView` animation; animation pauses when cells scroll off screen and resumes when visible.
- `LoadedImage` / `AnimatedImageSequence` types and cost-based memory caching for animated sequences (total frame bytes count toward the 50 MB limit).

### Documentation

- README and DocC updated with animated WebP usage and `isAnimatedWebP` API notes.

### Tests

- Added coverage for default `isAnimatedWebP`, multi-frame decode, animated cache round-trip, and cell animation cleanup on reuse.

## [1.6.0] - 2026-06-21

### Changed

- Image cache is now keyed by `itemID` instead of `imageURL`, so signed or rotating URLs reuse the same cached thumbnail.

### Documentation

- README and DocC updated to document item ID–based image caching.

### Tests

- Added coverage for item ID–based image cache hits and cache misses across different item IDs.

## [1.5.0] - 2026-06-21

### Added

- `CategoryItemBackgroundConfiguration` to customize view controller, header bar, and grid canvas background colors.
- `ItemAspectRatio` presets (`square`, `portrait4x3`, `landscape16x9`, `custom`) and `ItemGridConfiguration.applyAspectRatio(_:)` for convenient global item aspect ratio control.
- `itemHeightMultiplier` on `ItemGridConfiguration` to control cell height relative to width (default `1.0` for square cells).
- `CategoryLeadingSlot` and optional `leadingCategory` / `leadingCategoryContent` on `CategoryItemCollectionView` to show custom content for a leading category tab instead of the grid.
- Optional `backgroundConfiguration` parameter on `CategoryItemCollectionView` and `CategoryItemViewController`.
- `CategoryItemViewController.updateAppearance(headerConfiguration:gridConfiguration:backgroundConfiguration:)` extended to apply container backgrounds at runtime.

### Documentation

- README, DocC, and Example app updated with background, aspect ratio, and leading category examples.

### Tests

- Added coverage for `ItemAspectRatio`, background application, `applyAspectRatio`, and non-square grid layout metrics.

## [1.3.0] - 2026-06-21

### Added

- `CategoryItemStyle`, `CategoryHeaderConfiguration`, and `ItemGridConfiguration` for customizing category tab appearance (normal/selected styles, spacing, insets, header height) and item grid layout (column count, spacing, insets, corner radius, image background).
- `CategoryItemViewController.updateAppearance(headerConfiguration:gridConfiguration:)` to refresh header and grid styling at runtime.
- Optional `headerConfiguration` and `gridConfiguration` parameters on `CategoryItemCollectionView` and `CategoryItemViewController` (default `.default` preserves previous built-in styling).

### Documentation

- README and DocC updated with UI configuration examples.
- Example app demonstrates custom header and grid styling.

### Tests

- Added coverage for default configuration values, grid layout metrics, and header layout updates.

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
