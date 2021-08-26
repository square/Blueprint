# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Main]

### Fixed

- Fixed an [issue](https://github.com/square/Blueprint/pull/241) where `Label` and `AttributedLabel` were not accessibility elements.

### Added

- [The `Environment` is now automatically propagated through to nested `BlueprintViews` within a displayed `Element` hierarchy](https://github.com/square/Blueprint/pull/234). This means that if your view-backed `Elements` themselves contain a `BlueprintView` (eg to manage their own state), that nested view will now automatically receive the correct `Environment` across `BlueprintView` boundaries. If you were previously manually propagating `Environment` values you may remove this code. If you would like to opt-out of this behavior; you can set `view.automaticallyInheritsEnvironmentFromContainingBlueprintViews = false` on your `BlueprintView`.

- [Lifecycle hooks][#244]. You can hook into lifecycle events when an element's visibility changes.
  ```swift
  element
    .onAppear {
      // runs when `element` appears
    }
    .onDisappear {
      // runs when `element` disappears
    }
  ```

### Removed

### Changed

### Deprecated

### Security

### Documentation

### Misc

# Past Releases

## [0.27.0] - 2021-06-22

### Changed

- The signature of `Element.backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription?` has changed to `backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription?` (https://github.com/square/Blueprint/pull/231). This is a large breaking change, but is worth it as it allows us to pass additional context to `backingViewDescription` in the future in a non-breaking way. The `ViewDescriptionContext` contains the `bounds` and `subtreeExtent`, as well as the `Environment` the element is rendered in.

## [0.26.0] - 2021-06-02

### Added

- [Add `ScrollTrigger`](https://github.com/square/Blueprint/pull/224), which adds the ability set the content offset of a `ScrollView`
- [Add `UIViewElementContext`](https://github.com/square/Blueprint/pull/228) to `UIViewElement.updateUIView`. The context currently has one property, `isMeasuring`, which tells you if the view being updated is the static measuring instance.

## [0.25.0] - 2021-05-5

### Changed

- [Expose `contentInsetAdjustmentBehavior`](https://github.com/square/Blueprint/pull/222) on `ScrollView`.

## [0.24.0] - 2021-04-16

### Added

- [Add `Keyed` element](https://github.com/square/Blueprint/pull/210), which can be used to help differentiate elements during the diff and update process, eg to assist with proper animation transitions.

- [Introduce `GridRow`](https://github.com/square/Blueprint/pull/208), a `Row` alternative suited for columnar layout. `GridRow` supports the following:

  - spacing
  - vertical alignment
  - children with absolutely-sized widths
  - children with proportionally-sized widths¹
  
  ¹Proportional width in this case always means "a proportion of available layout space after spacing and absolutely-sized children are laid out."
  
  Example:
  
  ```swift
  GridRow { row in
    row.spacing = 8
    row.verticalAlignment = .center
    row.add(width: .absolute(50), child: authorLabel)
    row.add(width: .proportional(0.75), child: bodyLabel)
    row.add(width: .proportional(0.25), child: dateLabel)
  }
  ```
  
- [Added support to `LayoutWriter` to allow specifying keys for child `Element`s](https://github.com/square/Blueprint/pull/216).

- Blueprint can now emit [signpost logs](https://developer.apple.com/documentation/os/logging/recording_performance_data) during its render pass, which you can use for performance tuning. ([#209])
  
  Signpost logs are disabled by default. To enable them, set `BlueprintLogging.enabled = true`.

### Changed

- The layout system now uses a caching system to improve performance by eliminating redundant measurements. ([#209])

## [0.23.0] - 2021-03-26

### Added

- [Introduce `UserInteractionEnabled`](https://github.com/square/Blueprint/pull/203), an element which conditionally enables user interaction of wrapped elements.

```swift
searchField
    .userInteractionEnabled(canBeginSearch)
```

### Changed

- [Change `ProxyElement` to directly return the content of a child](https://github.com/square/Blueprint/pull/206). This significantly speeds up deeper element hierarchies that are made up of proxy elements, by reducing the duplicate calculation work that needs to be done to layout an element tree.

- [Change backing view of `TransitionContainer`](https://github.com/square/Blueprint/pull/205) to not directly receive touches while still allowing subviews to do so.

## [0.22.0] - 2021-03-15

### Added

- [Introduce `Decorate`](https://github.com/square/Blueprint/pull/178) to allow placing a decoration element in front or behind of an `Element`, without affecting its layout. This is useful for rendering tap or selection states which should overflow the natural bounds of the `Element`, similar to a shadow, or useful for adding a badge to an `Element`.

## [0.21.0] - 2021-02-17

### Added

- [Introduce conditionals on `Element`](https://github.com/square/Blueprint/pull/198) to allow you to perform inline checks like `if`, `if let`, and `map` when building `Element` trees.

### Changed

- [Introduce additional APIs on `Overlay`](https://github.com/square/Blueprint/pull/201) to ease conditional construction the `Overlay` elements.

## [0.20.0] - 2021-01-12

### Added

- [Add `Transformed` element](https://github.com/square/Blueprint/pull/195) to apply a `CATransform3D` to a wrapped element.

## [0.19.1] - 2021-01-06

### Removed

- [Remove compile time validation](https://github.com/square/Blueprint/pull/192) from `Element`s, since it caused compile-time errors in certain cases when extensions and `where` clauses were used.

## [0.19.0] - 2021-01-05

### Fixed

- ~~[Ensure that `Element`s are a value type](https://github.com/square/Blueprint/pull/190). This is generally assumed by Blueprint, but was previously not validated. This is only validated in `DEBUG` builds, to avoid otherwise affecting performance.~~

### Added

- [Add `LayoutWriter`](https://github.com/square/Blueprint/pull/187), which makes creating custom / arbitrary layouts much simpler. You no longer need to define a custom `Layout` type; instead, you can just utilize `LayoutWriter` and configure and place your children within its builder initializer.

## [0.18.0] - 2020-12-08

### Added

- Add `AccessibilityContainer.identifier` ([#180])

## [0.17.1] - 2020-10-30

### Fixed

- Fixed an issue where view descriptions were applied with unintentional animations while creating backing views. This could happen if an element was added during a transition. ([#175])

- Fixed pull-to-refresh inset for iOS 13+. ([#176])

## [0.17.0] - 2020-10-21

### Added

- Add alignment guides to stacks. ([#153])

  Alignment guides let you fine-tune the cross axis alignment. You can specifying a guide value for any child in that element's coordinate space. Children are aligned relatively to each other so that the guide values line up, and then the content as a whole is aligned to the stack's bounds.

  In this example, the center of one element is aligned 10 points from the bottom of another element, and the contents are collectively aligned to the bottom of the row:

  ```swift
  Row { row in
      row.verticalAlignment = .bottom

      row.add(
          alignmentGuide: { d in d[VerticalAlignment.center] },
          child: element1
      )

      row.add(
          alignmentGuide: { d in d.height - 10 },
          child: element2
      )
  }
  ```

### Removed

- [Removed support for iOS 10](https://github.com/square/Blueprint/pull/161). Future releases will only support iOS 11 and later.

### Deprecated

- `Row` alignments `leading` and `trailing` are deprecated. Use `top` and `bottom` instead. ([#153])

## [0.16.0] - 2020-09-22

### Fixed

- Fixed `EqualStack` to properly constrain children when measuring. ([#157](https://github.com/square/Blueprint/pull/157))

### Added

- Add a new `TransitionContainer.init` that supports further customization during initialization and has the same defaults as `ViewDescription`. ([#155], [#158])

- Add `transition(onAppear:onDisappear:onLayout)` and `transition(_:)` methods to `Element` to describe transition animations. ([#155], [#158])

### Removed

- [Remove `GridLayout`](https://github.com/square/Blueprint/pull/156); it's incomplete and was never really intended to be consumed widely. The intended replacement is putting `EqualStacks` inside of a `Column`, or `Rows` inside a `Column`.

### Deprecated

- `TransitionContainer(wrapping:)` is deprecated. Use the new `TransitionContainer(transitioning:)` instead. ([#158])

### Misc

- Removed some redundant work being done during rendering. ([#154])

## [0.15.1] - 2020-09-16

### Fixed

- Fixes a crash that can occur in `Box` when specifying a corner radius and shadow. ([#149])

## [0.15.0] - 2020-09-14

### Added

- Add `addFixed(child:)` and `addFlexible(child:)` methods to `StackElement` for adding children with a grow & shrink priority of 0.0 and 1.0 respectively. ([#143])

- Add `capsule` case to `Box.CornerStyle` ([#145]). This addition sugars the following pattern:

  ```swift
  GeometryReader { geometry in
    Box(cornerStyle: .rounded(geometry.constraint.height.maximum / 2.0))
  }
  ```
  
  into
  
  ```swift
  Box(cornerStyle: .capsule)
  ```
  
- Add `accessibilityFrameSize` to `AccessibilityElement` for manually specifying a size for the frame rendered by Voice Over. ([#144])

- Add `Opacity` element for modifying the opacity of a wrapped element. ([#147])

### Changed

- `BlueprintView` will call `layoutIfNeeded` on backing views during its layout pass. This allows backing views' subviews that are laid out during `layoutSubviews` to participate in animations. ([#139])

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

[main]: https://github.com/square/Blueprint/compare/0.27.0...HEAD
[0.27.0]: https://github.com/square/Blueprint/compare/0.26.0...0.27.0
[0.26.0]: https://github.com/square/Blueprint/compare/0.25.0...0.26.0
[0.25.0]: https://github.com/square/Blueprint/compare/0.24.0...0.25.0
[0.24.0]: https://github.com/square/Blueprint/compare/0.23.0...0.24.0
[0.23.0]: https://github.com/square/Blueprint/compare/0.22.0...0.23.0
[0.22.0]: https://github.com/square/Blueprint/compare/0.21.0...0.22.0
[0.21.0]: https://github.com/square/Blueprint/compare/0.20.0...0.21.0
[0.20.0]: https://github.com/square/Blueprint/compare/0.19.1...0.20.0
[0.19.1]: https://github.com/square/Blueprint/compare/0.19.0...0.19.1
[0.19.0]: https://github.com/square/Blueprint/compare/0.18.0...0.19.0
[0.18.0]: https://github.com/square/Blueprint/compare/0.17.1...0.18.0
[0.17.1]: https://github.com/square/Blueprint/compare/0.17.0...0.17.1
[0.17.0]: https://github.com/square/Blueprint/compare/0.16.0...0.17.0
[0.16.0]: https://github.com/square/Blueprint/compare/0.15.1...0.16.0
[0.15.1]: https://github.com/square/Blueprint/compare/0.15.0...0.15.1
[0.15.0]: https://github.com/square/Blueprint/compare/0.14.0...0.15.0
[0.14.0]: https://github.com/square/Blueprint/compare/0.13.1...0.14.0
[0.13.1]: https://github.com/square/Blueprint/compare/0.13.0...0.13.1
[0.13.0]: https://github.com/square/Blueprint/compare/0.12.2...0.13.0
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
[#244]: https://github.com/square/Blueprint/pull/244
[#209]: https://github.com/square/Blueprint/pull/209
[#176]: https://github.com/square/Blueprint/pull/176
[#175]: https://github.com/square/Blueprint/pull/175
[#158]: https://github.com/square/Blueprint/pull/158
[#155]: https://github.com/square/Blueprint/pull/155
[#154]: https://github.com/square/Blueprint/pull/154
[#153]: https://github.com/square/Blueprint/pull/153
[#149]: https://github.com/square/Blueprint/pull/149
[#147]: https://github.com/square/Blueprint/pull/147
[#145]: https://github.com/square/Blueprint/pull/145
[#144]: https://github.com/square/Blueprint/pull/144
[#143]: https://github.com/square/Blueprint/pull/143
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
