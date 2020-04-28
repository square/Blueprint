# Master

### Fixed

### Added

### Removed

### Changed

### Misc

# Past Releases

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
