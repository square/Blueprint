# Master

### Fixed

### Added

### Removed

### Changed

### Misc

# Past Releases

## [0.11.0] - 2020-05-10

### Fixed

- [Fixed `ConstrainedSize`](https://github.com/square/Blueprint/pull/87) to ensure that the measurement of its inner element respects the `ConstrainedSize`'s maximum size, which matters for measuring elements which re-flow based on width, such as elements containing text.

- Changed [BlueprintView.sizeThatFits(:)](https://github.com/square/Blueprint/pull/92/files) to treat width and height separately when determining if measurement should be unconstrained in a given axis.

- Removed layout rounding no longer needed since [#64] ([#95]).

### Added

- [Added support](https://github.com/square/Blueprint/pull/88) for `SwiftUI`-style element building within `BlueprintUI` and `BlueprintUICommonControls`.

This allows you to replace this code:

```
ScrollView(.fittingHeight) (
   wrapping: Box(
        backgroundColor .lightGrey,
       wrapping: Inset(
          uniformInset: 10.0,
          wrapping: ConstrainedSize(
             height: .atLeast(20.0),
             wrapping: Label(
                text: "Hello, world!"
             )
         )
      )
   )
)
```

With this code:

```
Label(text: "Hello, World!")
   .constrainedTo(height: .atLeast(20.0))
   .inset(by: 20.0)
   .box(background: .lightGrey)
   .scrollable(.fittingHeight)
```

Improving readability and conciseness of your elements.

## [0.10.0] - 2020-04-27

### Added

- BlueprintView will align view frames to pixel boundaries after layout ([#64]).

## 0.9.2

### Fixed

- [Don't try to build](https://github.com/square/Blueprint/pull/89) `SwiftUI` previews on 32 bit ARM devices – `SwiftUI` does not exist on these devices.

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
[#95]: https://github.com/square/Blueprint/pull/95
