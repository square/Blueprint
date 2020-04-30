# Master

### Fixed

- [Fixed `ConstrainedSize`](https://github.com/square/Blueprint/pull/87) to ensure that the measurement of its inner element respects the `ConstrainedSize`'s maximum size, which matters for measuring elements which re-flow based on width, such as elements containing text.

### Added

### Removed

### Changed

### Misc

# Past Releases

## [0.10.0] - 2020-04-27

### Added

- BlueprintView will align view frames to pixel boundaries after layout ([#64]).

## 0.9.2

### Fixed

- Only support `SwiftUI` previews on 32 bit ARM devices.

## 0.9.1

### Fixed

- Weak link `SwiftUI` so if an app is not already linking `SwiftUI`, it will build correctly.

## 0.9

### Added

- [Add support](https://github.com/square/Blueprint/pull/76) for previewing Blueprint elements in Xcode / SwiftUI previews.
- [Add accessibilityIdentifier](https://github.com/square/Blueprint/pull/81) support to `AccessibilityElement`.

## 0.8

### Changed

- Change how stack [layouts are measured](https://github.com/square/Blueprint/pull/68) to resolve an issue where text would be truncated.
- [Properly measure](https://github.com/square/Blueprint/pull/73) the child of `ScrollView` to allow for unconstrained measurement.

[0.10.0]: https://github.com/square/Blueprint/compare/0.9.2...0.10.0
[#64]: https://github.com/square/Blueprint/pull/64
