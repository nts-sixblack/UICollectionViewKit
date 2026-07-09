# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.9.4] - 2026-07-09

### Fixed

- Category header pills no longer clip at the bottom when custom fonts (for example Poppins) render taller than `UIFont.lineHeight`. Header height now resolves from a measured `CategoryCell` layout at runtime, with improved pre-layout estimates based on font bounding metrics.

### Tests

- Added coverage for measured header height resolution via `CategoryHeaderView.resolvedHeight(for:)`.

## [1.9.3] - 2026-07-09

### Fixed

- Category header tabs no longer clip at the top when `sectionInsets` and pill `contentInsets` require more vertical space than the configured `headerHeight`. `CategoryHeaderConfiguration` now exposes `recommendedMinimumHeight` and `effectiveHeaderHeight`, and the view controller uses the resolved height automatically.
- Category header no longer renders underneath a transparent SwiftUI navigation toolbar. `CategoryItemCollectionView` reads SwiftUI safe-area insets via `GeometryReader` and positions the header below the top inset; UIKit safe-area changes remain a fallback.
- `CategoryCell` now preserves its intrinsic content height when the flow layout proposes a height that is too small.

### Tests

- Added coverage for recommended/effective header height, SwiftUI top inset application, and intrinsic category cell height.

## [1.9.2] - 2026-06-26

### Fixed

- Animated WebP/GIF memory cache no longer stores full decoded frame sequences in the shared `NSCache`, which previously evicted static posters across an entire category and caused loading spinners when scrolling back.
- Animated variants now keep only the poster frame in memory; full sequences decode on demand from the on-disk cache.
- `ItemImageCell` no longer short-circuits configuration when an animated poster is in memory, so static posters stay visible while animation loads and `animationImages` are copied per cell to avoid reuse glitches.

### Tests

- Added coverage for animated poster-only memory caching, static poster retention after animated stores, and immediate static display without a loading spinner on memory hit.

## [1.9.1] - 2026-06-26

### Fixed

- Category header tabs no longer truncate short titles (for example `"Football"`) to `...` when using `UICollectionViewFlowLayout.automaticSize`. `CategoryCell` now implements `preferredLayoutAttributesFitting(_:)` for horizontal self-sizing.
- `CategoryHeaderView` invalidates its layout after applying categories or configuration, and when the header width changes after the first layout pass (common when embedded in SwiftUI).
- `CategoryItemCollectionView` skips redundant `updateAppearance` calls when header, grid, and background configurations are unchanged.

### Changed

- `CategoryHeaderConfiguration`, `CategoryItemStyle`, `ItemGridConfiguration`, and `CategoryItemBackgroundConfiguration` now conform to `Equatable`.

## [1.9.0] - 2026-06-23

### Changed

- **Breaking:** Replaced `isAnimatedWebP` on `ItemDisplayable` with optional `animatedURL` for a separate animated WebP/GIF preview. `imageURL` is always the static poster; animation loads from `animatedURL` when present.
- Image cache keys now distinguish static and animated variants per `itemID`, so poster and animation files are stored separately.
- Memory cache limits increased to 100 MB and 250 entries to accommodate dual-variant caching.

### Removed

- **Breaking:** `isAnimatedWebP` on `ItemDisplayable`.

### Migration

```swift
// Before (1.8.0)
struct MyItem: ItemDisplayable {
    let itemID: String
    let categoryID: String
    let imageURL: URL
    var isAnimatedWebP: Bool { true }
}

// After (1.9.0)
struct MyItem: ItemDisplayable {
    let itemID: String
    let categoryID: String
    let imageURL: URL        // static poster
    let animatedURL: URL?    // animated preview, or nil for static-only
}
```

### Documentation

- README and DocC updated for `animatedURL` and separate static/animated caching.

### Tests

- Added coverage for static/animated cache isolation per item ID and updated cell configuration tests for `animatedURL`.

## [1.8.0] - 2026-06-22

### Added

- `animatedWebPInterval` on `ItemGridConfiguration` (default `4`) to play animated WebP only at every Nth grid index (`0`, `4`, `8`, …). Set to `1` to animate every eligible item.

### Documentation

- README and DocC updated with `animatedWebPInterval` usage notes.

### Tests

- Added coverage for default `animatedWebPInterval`, interval gating logic, and static poster playback when animation is skipped.

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
