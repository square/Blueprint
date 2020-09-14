# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Main]

### Fixed

### Added

- Add `addFixed(child:)` and `addFlexible(child:)` methods to `StackElement` for adding children with a grow & shrink priority of 0.0 and 1.0 respectively.

- Add `capsule` case to `Box.CornerStyle` ([#145]). This addition sugars the following pattern  

```
GeometryReader { geometry in
  Box(cornerStyle: .rounded(geometry.constraint.height.maximum / 2.0))
}
```

into

```
Box(cornerStyle: .capsule)
```

- Add `accessibilityFrameSize` to `AccessibilityElement` for manually specifying a size for the frame rendered by Voice Over.

### Removed

### Changed

- `BlueprintView` will call `layoutIfNeeded` on backing views during its layout pass. This allows backing views' subviews that are laid out during `layoutSubviews` to participate in animations. ([#139])

### Deprecated

### Security

### Documentation

### Misc

# Past Releases

## [0.14.0] - 2020-08-12

### Added

- Add `textColor` property on TextField ([#133](https://github.com/square/Blueprint/pull/133)).
- Add the `windowSize` environment key. ([#134])

- Add `GeometryReader`. ([#135])

  This element allow you to compose elements whose contents depend on the amount of space available.

  Here is an example that dynamically chooses an image based on the width available:

  ```swift
  GeometryReader { (geometry) -> Element in
      let image: UIImage
      switch geometry.constraint.width.maximum {
      case ..<100:
          image = UIImage(named: "small")!
      case 100..<500:
          image = UIImage(named: "medium")!
      default:
          image = UIImage(named: "large")!
      }
      return Image(image: image)
  }
  ```

### Changed

- Default `ScrollView.delaysContentTouches` to `true` ([#132](https://github.com/square/Blueprint/pull/132))

### Misc

- Set an explicit shadow path on `Box` ([#137](https://github.com/square/Blueprint/pull/137))

## [0.13.1] - 2020-07-30

### Added

- Introduce `AccessibilityContainer` element for wrapping an element with multiple sub-elements that should be in a voice over container.

- Add `font` property on TextField ([#127](https://github.com/square/Blueprint/pull/127)).

## [0.13.0] - 2020-07-20

### Fixed

- [Update the scroll indicator inset](https://github.com/square/Blueprint/pull/117) when adjusting the content inset.

- `Label` & `AttributedLabel` use an internal `UILabel` for measurement. This fixes measurement when there is a line limit set. However, it also means that the screen scale cannot be specified and is always assumed to be `UIScreen.main.scale`. These elements may not be measured correctly if they are placed on a screen other than `UIScreen.main`. ([#120])

### Added

- Introduce [MeasurementCachingKey](https://github.com/square/Blueprint/pull/115), to allow for elements to provide a way to cache their measurement during layout passes. This provides performance optimizations for elements whose layout and measurement is expensive to calculate.

- Introduce `UIViewElement` [to make wrapping self-sizing UIViews easier](https://github.com/square/Blueprint/pull/106).
  
  You can now write a `UIViewElement` like this:

  ```
  struct Switch : UIViewElement
  {
    var isOn : Bool

    typealias UIViewType = UISwitch

    static func makeUIView() -> UISwitch {
        UISwitch()
    }

    func updateUIView(_ view: UISwitch) {
        view.isOn = self.isOn
    }
  }
  ```

  And the elements will be sized and presented correctly based on the view's `sizeThatFits`.

- Add `isAccessibilityElement` to `Label` and `AttributedLabel`. ([#120])
- Add `lineHeight` to `Label` for specifying custom line heights. `AttributedLabel` has a `textRectOffset` property to support this. ([#120])

### Changed

- [Update Demo app](https://github.com/square/Blueprint/pull/116) to support more demo screen types.

## [0.12.2] - 2020-06-08

### Fixed

- Fix [erroneous use of `frame` instead of `bounds`](https://github.com/square/Blueprint/pull/110) when laying out `BlueprintView`.

### Added

- Add [delaysContentTouches](https://github.com/square/Blueprint/pull/109) to the `ScrollView` element.

## [0.12.1] - 2020-06-05

### Fixed

- Use default environment when [measuring `BlueprintView`](https://github.com/square/Blueprint/pull/107).

## [0.12.0] - 2020-06-04

### Fixed

- Removed layout rounding no longer needed since [#64] ([#95]).

### Added

- [Add support for the iPhone SE 2](https://github.com/square/Blueprint/pull/96) in `ElementPreview`.
- Added `tintColor` and `contentMode` into the initializer for `Image`. ([#100])
- Added an [Empty element](https://github.com/square/Blueprint/pull/104), to mirror `EmptyView` in SwiftUI. It is an element with no size and draws no content.

- Environment ([#101]).

  You can now read and write values from an `Environment` that is automatically propagated down the element tree. You can use these values to dynamically build the contents of an element, without having to explicitly pass every value through the tree yourself.

  You can read these values with `EnvironmentReader`:

  ```swift
  struct Foo: ProxyElement {
      var elementRepresentation: Element {
          EnvironmentReader { environment -> Element in
              Label(text: "value from environment: \(environment.foo)")
          }
      }
  }
  ```

  And set them with `AdaptedEnvironment`:

  ```swift
  struct Bar: ProxyElement {
      var elementRepresentation: Element {
          ComplicatedElement()
              .adaptedEnvironment { environment in
                  environment.foo = "bar"
              }
      }
  }
  ```

  Several enviroment keys are available by default ([#102]):

  - calendar
  - display scale
  - layout direction
  - locale
  - safe area insets
  - time zone

  You can create your own by making a type that conforms to `EnvironmentKey`, and extending `Environment` with a new property:

  ```swift
  extension Environment {
      private enum FooKey: EnvironmentKey {
          static let defaultValue: String = "default value"
      }

      /// The current Foo that elements should use.
      public var foo: String {
          get { self[FooKey.self] }
          set { self[FooKey.self] = newValue }
      }
  }
  ```

## [0.11.0] - 2020-05-10

### Fixed

- [Fixed `ConstrainedSize`](https://github.com/square/Blueprint/pull/87) to ensure that the measurement of its inner element respects the `ConstrainedSize`'s maximum size, which matters for measuring elements which re-flow based on width, such as elements containing text.

- Changed [BlueprintView.sizeThatFits(:)](https://github.com/square/Blueprint/pull/92/files) to treat width and height separately when determining if measurement should be unconstrained in a given axis.

### Added

- [Added support](https://github.com/square/Blueprint/pull/88) for `SwiftUI`-style element building within `BlueprintUI` and `BlueprintUICommonControls`.

  This allows you to replace this code:

  ```swift
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

  ```swift
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

## [0.9.2] - 2020-04-27

### Fixed

- [Don't try to build](https://github.com/square/Blueprint/pull/89) `SwiftUI` previews on 32 bit ARM devices – `SwiftUI` does not exist on these devices.

## [0.9.1] - 2020-04-17

### Fixed

- Weak link `SwiftUI` so if an app is not already linking `SwiftUI`, it will build correctly.

## [0.9.0] - 2020-04-17

### Added

- [Add support](https://github.com/square/Blueprint/pull/76) for previewing Blueprint elements in Xcode / SwiftUI previews.
- [Add accessibilityIdentifier](https://github.com/square/Blueprint/pull/81) support to `AccessibilityElement`.

## [0.8.0] - 2020-04-03

### Fixed

- [Properly measure](https://github.com/square/Blueprint/pull/73) the child of `ScrollView` to allow for unconstrained measurement.
- Fix stack layout during underflow ([#72])

### Added

- ScrollView can automatically adjust its content inset for the keyboard ([#55])

### Changed

- Improved element diffing ([#56])

## [0.7.0] - 2020-03-30

### Added

- Xcode 11 and Swift 5.1 support ([#67]).

### Changed

- Change how stack [layouts are measured][#68] to resolve an issue where text would be truncated.

### Removed

- Raise minimum deployment target from iOS 9.3 to iOS 10 ([#66]).

## [0.6.0] - 2020-02-24

### Added

- Add `keyboardDismissMode` property on ScrollView ([#57]).
- Add `textAlignment` property on TextField ([#53]).

## [0.5.0] - 2020-01-24

### Fixed

- Prevent divide-by-zero when a stack contains zero-size elements ([#52]).

### Added

- Add `fill` alignment to Aligned ([#42]).

### Documentation

- Fix typos in the tutorial ([#46]).
- Add docs to Overlay ([#45]).

## [0.4.0] - 2019-12-04

### Fixed

- Public init on Aligned ([#41]).

### Changed

- Guarantee that subviews are ordered the same as their associated elements ([#32]).

## [0.3.1] - 2019-11-15

### Fixed

- Do not run snapshot tests from CocoaPods ([#40]).
- Make tests with float comparisons more lenient for 32-bit ([#35]).

### Added

- Add Swift Package Manager support ([#37]).

### Documentation

- Add Getting Started section to README ([#38]).

## [0.3.0] - 2019-11-12

### Added

- Add Stack alignment options `justifyToStart`, `justifyToCenter`, and `justifyToEnd` ([#24]).
- Add ConstrainedAspectRatio element ([#23]).
- Add EqualStack element ([#26]).
- Add Rule element ([#22]).
- Add Aligned element ([#21]).
- Add a screen scale property to some elements ([#18]).
- Swift 5 support ([#15]).

### Changed

- Reorder the parameters of ConstrainedSize, Inset, Button, and Tappapble, so that the wrapped element is the last parameter ([#19]).

## [0.2.2] - 2019-03-29

- First stable release.

[main]: https://github.com/square/Blueprint/compare/0.14.0...HEAD
[0.14.0]: https://github.com/square/Blueprint/compare/0.14.0...0.13.1
[0.13.1]: https://github.com/square/Blueprint/compare/0.13.1...0.13.0
[0.13.0]: https://github.com/square/Blueprint/compare/0.13.0...0.12.2
[0.12.2]: https://github.com/square/Blueprint/compare/0.12.1...0.12.2
[0.12.1]: https://github.com/square/Blueprint/compare/0.12.0...0.12.1
[0.12.0]: https://github.com/square/Blueprint/compare/0.11.0...0.12.0
[0.11.0]: https://github.com/square/Blueprint/compare/0.10.0...0.11.0
[0.10.0]: https://github.com/square/Blueprint/compare/0.9.2...0.10.0
[0.9.2]: https://github.com/square/Blueprint/compare/0.9.1...0.9.2
[0.9.1]: https://github.com/square/Blueprint/compare/0.9.0...0.9.1
[0.9.0]: https://github.com/square/Blueprint/compare/0.8.0...0.9.0
[0.8.0]: https://github.com/square/Blueprint/compare/0.7.0...0.8.0
[0.7.0]: https://github.com/square/Blueprint/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/square/Blueprint/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/square/Blueprint/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/square/Blueprint/compare/0.3.1...0.4.0
[0.3.1]: https://github.com/square/Blueprint/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/square/Blueprint/compare/0.2.2...0.3.0
[0.2.2]: https://github.com/square/Blueprint/releases/tag/0.2.2
[#139]: https://github.com/square/Blueprint/pull/139
[#135]: https://github.com/square/Blueprint/pull/135
[#134]: https://github.com/square/Blueprint/pull/134
[#120]: https://github.com/square/Blueprint/pull/120
[#102]: https://github.com/square/Blueprint/pull/102
[#101]: https://github.com/square/Blueprint/pull/101
[#100]: https://github.com/square/Blueprint/pull/100
[#95]: https://github.com/square/Blueprint/pull/95
[#72]: https://github.com/square/Blueprint/pull/72
[#68]: https://github.com/square/Blueprint/pull/68
[#67]: https://github.com/square/Blueprint/pull/67
[#66]: https://github.com/square/Blueprint/pull/66
[#64]: https://github.com/square/Blueprint/pull/64
[#57]: https://github.com/square/Blueprint/pull/57
[#56]: https://github.com/square/Blueprint/pull/56
[#55]: https://github.com/square/Blueprint/pull/55
[#53]: https://github.com/square/Blueprint/pull/53
[#52]: https://github.com/square/Blueprint/pull/52
[#46]: https://github.com/square/Blueprint/pull/46
[#45]: https://github.com/square/Blueprint/pull/45
[#42]: https://github.com/square/Blueprint/pull/42
[#41]: https://github.com/square/Blueprint/pull/41
[#40]: https://github.com/square/Blueprint/pull/40
[#38]: https://github.com/square/Blueprint/pull/38
[#37]: https://github.com/square/Blueprint/pull/37
[#35]: https://github.com/square/Blueprint/pull/35
[#32]: https://github.com/square/Blueprint/pull/32
[#26]: https://github.com/square/Blueprint/pull/26
[#24]: https://github.com/square/Blueprint/pull/24
[#23]: https://github.com/square/Blueprint/pull/23
[#22]: https://github.com/square/Blueprint/pull/22
[#21]: https://github.com/square/Blueprint/pull/21
[#19]: https://github.com/square/Blueprint/pull/19
[#18]: https://github.com/square/Blueprint/pull/18
[#15]: https://github.com/square/Blueprint/pull/15
