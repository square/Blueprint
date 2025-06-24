# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Main]

### Fixed

- Fixed bounding rects for VoiceOver when an attributed label's link spans more than one line.

### Added

- Added support for tabbing through links in `AttributedLabel`

### Removed

### Changed

### Deprecated

### Security

### Documentation

### Misc

### Internal

## [6.0.0] - 2025-06-16

### Added

- Layouts can define custom traits by creating types that conform to `LayoutTraitsKey`.
- The `SingleTraitLayout` protocol preserves the existing API for legacy layouts that define a single trait type.

### Removed

- `LayoutMode.legacy` has been removed.
- The `LegacyLayout` protocol has been removed, and its methods no longer required to implement `Layout`. Layouts can remove their implementations of the `measure` and `layout` methods.
- `ConstrainedAspectRatio.ContentMode.fillParent` has been removed.

### Changed

- With the removal of legacy layout, `Layout` no longer conforms to `SingleTraitLayout` by default. Existing layouts that define traits must conform to `SingleTraitLayout` explicitly.
- `LayoutMode` converted from an enum to a struct with `LayoutOptions` available as a property.

## [5.7.0] - 2025-05-16

### Added

- `AnimationAttributes` can now be initialized with more types of animations, including bezier curves, springs, and dampened springs.

### Removed

- Removed `AnimationAttributes.curve`.
- Removed `AnimationAttributes.duration`.

### Changed

- Reverted the change titled "Fixed `AccessibilityContainer` to better handle the accessibility ordering for a `UICollectionView` inside it (such as a `Listable` instance.)" pending further investigation.

## [5.6.0] - 2025-05-14

### Fixed
- Fixed `AccessibilityContainer` to better handle the accessibility ordering for a `UICollectionView` inside it (such as a `Listable` instance.)

## [5.5.0] - 2025-04-22

### Added
- Added `UserInterfaceStyleOverridingElement` which allows child elements to have their `userInterfaceStyle` to be forced to light/dark. Additionally added a `overrideUserInterfaceStyle` convenience to `Element`.

### Removed
- `AccessibilityElement.deprecated_accessibility(…)`. This was deprecated in September 2021, and renamed from .accessibility(…) to .deprecated_accessibility(…) in Oct 2024.

## [5.4.0] - 2025-03-04

### Added

- `Accessibility.Trait` now includes `.backButton` and `.toggleButton`

### Changed

- `AccessibilityElement.Trait`now a typealias to `Accessibility.Trait` 
- `AccessibilityElement.CustomAction` now a typealias to `Accessibility.CustomAction`
- `AccessibilityElement.CustomContent` now a typealias to `Accessibility.CustomContent`

### Deprecated

### Security

### Documentation

### Misc

- `Accessibility.CustomContent` now conforms to `Equatable`

### Internal

## [5.3.0] - 2025-01-30

### Fixed

- Fixed a bug in `AttributedLabel` which could cause a crash if the attributed string lacked a specified `NSTextAlignment`. 

### Added

- `AccessibilityContainer` now supports configuration of `UIAccessibilityContainerType`, `AccessibilityLabel` and `AccessibilityValue`.
- `AccessibilityElement` now supports configuration of `userInputLabels`.

### Removed

- CocoaPods podspecs removed. Blueprint will only be vended via Swift Package Manager.

### Changed

`AttributedLabel` accessibility links are now stateless.

### Deprecated

- `LayoutMode.legacy` is deprecated and will be removed in a future release.

### Security

### Documentation

### Misc

### Internal

- Local development environment switched from CocoaPods to Tuist.

## [5.2.0] - 2024-12-18

### Added

- Added `CacheCleaner` which exposes a method to force Blueprint's static caches to be cleared. 

## [5.1.0] - 2024-11-25

### Added

- The `accessibilityIdentifier` can now be set on `AttributedLabel`.

### Internal

- Added release and changelog managements scripts to streamline releases.

## [5.0.1] - 2024-11-04

### Added

- `Flow` children now support a layout `priority`, to specify if they should grow to use the extra space in a run.

### Internal

- Bump CI Xcode version to 15.4.

## [5.0.0] - 2024-10-30

### Added

- `BlueprintView` has added preconditions to some methods to ensure they are only invoked on the main queue.

### Changed

- Renamed deprecated function `accessibility(label:value:traits:hint:identifier:accessibilityFrameSize:)` to `deprecated_accessibility(label:value:traits:hint:identifier:accessibilityFrameSize:)`.

## [4.3.0] - 2024-09-18

### Added

- `BlueprintView` will now pass through touches to views lower in the view hierarchy if `passThroughTouches` is true.

### Changed

- Moved `CornerStyle` out of the `Box` namespace, and is now a root type in `BlueprintUICommonControls`. `Box.CornerStyle` is still available as a typealias.

## [4.2.1] - 2024-08-02

### Added

- Made public the `UIBezierPath` convenience init that uses a `Box.CornerStyle`.

## [4.2.0] - 2024-06-25

### Added

- `Label` and `AttributedLabel` now support `accessibilityValue`.

## [4.1.2] - 2024-06-17
- Fix a bug in which newlines were preserved in accessibility labels.

## [4.1.1] - 2024-06-14
- Fixed a string range bug when a closed range should be half open.

## [4.1.0] - 2024-06-13

### Fixed
- Fixed a bug where `AttributedLabel`'s accessibility utterance was not properly announcing links.

## [4.0.1] - 2024-06-04

### Fixed
- Fixed a bug where defining a `Box` with a `.rounded` `CornerStyle` with `Corners` set to anything other than `.all` would sometimes still round all of the corners.

## [4.0.0] - 2024-04-29

### Added
- `AccessibilityElement.CustomContent` now exposes previously internal methods for creating `AXCustomContent` objects. 
- Introduced a new `Flow` layout type, for creating flow layout based elements.

### Changed
- `AttributedLabel` now activates a single contained link when activated by accessible technologies. 
- `AccessibilityElement.CustomContent.Importance.Regular` renamed to `Default`.

## [3.1.0] - 2024-03-26

### Fixed
- Fixed a bug where `AccessibilityBlocker` would block accessibility when `isBlocking` is `false`.

### Added
- Added support for accessibility focus triggers to force VoiceOver to focus on any given element.
- Added `startTimestamp` to `BlueprintViewRenderMetrics`. This represents the mach time in seconds at which the render started, from `CACurrentMediaTime()`.

## [3.0.0] - 2024-02-21

### Fixed

- Fixed an issue where `AttributedLabel` would not properly handle tapping on links when a label was stretched.

### Added

- `AccessibilityElement` now supports providing arbitrary strings to assistive devices using the `AXCustomContent` protocol. 

### Changed

- The behavior of `name` of `ElementPreview` has been change, affecting the SwiftUI `previewName`. Instead of including device or size information (i.e. `sizeThatFits - \(name)`), it now either defaults to the Xcode default if given an empty string, and shows _only_ the `name` if `name` is non-empty.
- Updated minimum deployment target from iOS 14 to iOS 15.

### Internal
- Updated CI to use M1 machines, Xcode 15.1, and Ruby 3.2.2.
- Added iOS 17 snapshot images.
- Bump Swift version to 5.9.
- Update Ruby gems.

## [2.2.0] - 2023-09-22

### Fixed

- Fixed a bug that could cause a crash or incorrect layout when an element with lazily resolved content (such as `GeometryReader`) generated a subtree that varied within a layout pass. ([#468])

### Added

- Added a `TintAdjustmentMode` element and `.tintAdjustmentMode(:)` modifier for finer control of tint color during modal presentations.

## [2.1.0] - 2023-09-06

### Fixed

- Resolved a Swift 5.9 compilation warning: Forming 'UnsafeRawPointer' to a variable of type 'NSObject'; this is likely incorrect because 'NSObject' may contain an object reference.
- `KeyboardObserver` has been updated to handle iOS 16.1+ changes that use the screen's coordinate space to report keyboard position. This can impact reported values when the app isn't full screen in Split View, Slide Over, and Stage Manager.

### Changed

- Lifecycle callbacks like `onAppear` and `onDisappear` now occur outside of the layout pass; allowing, eg, `onAppear` to safely trigger a re-render.

### Internal

- Update CI script to reference the `xcodesorg/made/xcodes` package for installing simulator runtimes.
- Corrected a typo in `AttributedLabel`, which now exits paragraph style enumeration after encountering the first paragraph style. This is an optimization and not a functional change. The method continues to accept only a paragraph style which spans the length of the attributed string.

## [2.0.0] - 2023-05-02

### Fixed

- `ConstrainedAspectRatio`  measures correctly in `fitParent` and `fillParent` modes when the proposed constraint has the same aspect ratio as the element's constraint.
- `ConstrainedAspectRatio` adheres to the Caffeinated Layout contract when unconstrained in `fitParent` or `fillParent`, by reporting `infinity` instead of falling back to the constrained element's size.

### Changed

- Caffeinated Layout is enabled by default. You can disable it on a `BlueprintView` with the `layoutMode` property, or disable it globally by setting `LayoutMode.default`.

### Deprecated

- `ConstrainedAspectRatio` content mode `fillParent` is deprecated, due to having limited utility in Caffeinated Layout.

## [1.0.0] - 2023-04-18

### Fixed

- Restored documentation generation by executing the generate_docs.sh script with `bundle exec` to ensure gems are referenced properly.

### Added

- Introduced a new layout engine, Caffeinated Layout. Caffeinated Layout features a new API for custom layouts that is modeled after SwiftUI, and greatly improves performance.

  To enable Caffeinated Layout globally, set `LayoutMode.default` to `.caffeinated`. To enable it for a single view, set the `layoutMode` property of a `BlueprintView`.

  Caffeinated Layout is not enabled by default yet, but will be in a future release.

- Added `layoutMode` to `BlueprintViewRenderMetrics` to expose which layout mode was used to render a Blueprint view.

### Changed

- The `Layout` and `SingleChildLayout` protocols have new methods to support Caffeinated Layout.

  To improve performance, Caffeinated Layout requires elements to adhere to a new contract for sizing behavior. Many elements can be easily adapted to the new API, but certain behaviors are no longer possible, particularly with regard to behavior when the size constraint is `unconstrained`.

  For more information about implementing these protocols and the sizing contract, see [the `Layout` documentation](https://square.github.io/Blueprint/Protocols/Layout.html).

### Internal

- Updated jazzy gem (0.14.3).
- Updated cocoapods (1.12.0).
- Updated Ruby version (2.7).

## [0.50.0] - 2023-03-07

### Fixed

- The `Environment` will now automatically inherit for `BlueprintView` instances nested inside `UIViewElement` during measurement.

### Added

- Introduced `ElementContent.init(byMeasuring:)`, for use when your `Element` contains a nested `BlueprintView`, commonly used to implement stateful elements. This avoids detached measurements and improves performance. 

### Changed

- Renamed `BlueprintViewUpdateMetrics` to `BlueprintViewRenderMetrics`.
- Renamed `BlueprintViewRenderMetrics.measureDuration` to `layoutDuration`.
- Renamed `BlueprintViewMetricsDelegate.blueprintView(_:completedUpdateWith:)` to `blueprintView(_:completedRenderWith:)`.
- `BlueprintViewRenderMetrics` values are now calculated using `CACurrentMediaTime` instead of `Date`.

### Internal
- Added an Internal section to the changelog. This section is intended to capture any notable non-public changes to the project.
- `ElementContent.init(child:)` now utilizes a unique `ContentStorage` type, which improves layout performance.

## [0.49.1]

### Fixed

- `Image`'s `aspectFill` `contentMode` now measures the same as `aspectFit` to avoid aggressively taking up space when not necessary.

## [0.49.0]

### Fixed

- Fixed unexpected measurement results that could occur from `Image`s using the `aspectFit` `contentMode`.

## [0.48.1]

### Fixed

- Fix Catalyst version specifier in SPM package.

## [0.48.0]

### Added

- Added `AccessibilityElement.CustomAction` to allow custom actions for use by assistive technologies.
- Added `accessibilityCustomActions` property to `Label` and `AttributedLabel`.
- `UIViewElementContext` now passes through an `environment` property, enabling environment-dependent measurements and layouts.

### Changed

- Updated minimum deployment target from iOS 12 to iOS 14.
- `URLHandlerEnvironmentKey.defaultValue` should now be a no-op in extensions.
- Marks pod as `APPLICATION_EXTENSION_API_ONLY`

## [0.47.0]

### Added

- `accessibilityHint` property for `Label` and `AttributedLabel`.

## [0.46.0]

### Fixed

- When stacks lay out with more `fixed` magnitude than is available for layout, `flexible` items will no longer receive a negative width.

### Changed

- `StackElement` layouts have been optimized for the case of one fixed and one flexible element to improve performance. This also fixes issues as described in https://github.com/square/Blueprint/pull/265 in many cases.

## [0.45.1]

### Fixed

- Improve `AttributedLabel` rendering performance.

## [0.45.0]

### Fixed

- Fixed an issue where rounding was handled incorrectly for nested BlueprintViews.

### Added

- Added new logging option to expose aggregate measurements.

## [0.44.1]

### Fixed

- `AccessibilityContainer` now omits accessibility elements where `.accessibilityElementsHidden` is `true`.

## [0.44.0]

### Added

- `Image` now provides an override to prevent VoiceOver from generating accessibility descriptions.

## [0.43.0]

### Added

- Introduced an `Element.modify { ... }` conditional, to allow changing properties on an element.

### Changed

- `Aligned` will now constrain its content to the provided layout frame. If you need content to exceed the layout frame, please use `Decoration`.

- `AccessibilityElement` will now only return `accessibilityPath` for elements with a non-square corner style. This avoids needlessly changing AccessibilitySnapshot (https://github.com/cashapp/AccessibilitySnapshot) reference images.


## [0.42.0]

### Added

- Introduced `accessibilityFrameCornerStyle` to `AccessibilityElement`.

## [0.41.0]

### Added

- Added `.grows` and `.shrinks` to `StackLayout.Child.Priority`, to allow for extra control over how flexible elements grow and shrink.
- `AccessibilityBlocker` now takes in a `Bool` to control blocking, to avoid changing the element hierarchy to toggle if blocking is occurring.

## [0.40.0]

### Added

- Added support for optionals in builders without unwrapping via `if let`.
- Static constants on `Alignment` are now public (such as `Alignment.topTrailing`).

### Changed

- `AnimationAttributes` has gained a `.default` option.
- `LayoutTransition` has default values for its `AnimationAttributes` parameters.

## [0.39.0]

### Added

- Added support for adjusting text spacing and sizing on `AttributedLabel` and `Label` when text does not fit within the provided layout rect.

### Removed

- `MeasurementCachingKey` has been removed – Blueprint has cached measurements per render pass for many releases, so this actually slowed down layouts due to additional allocations and cache checking. This is about a 5-10% performance improvement depending on the layout.

### Changed

- Accessibility increment, decrement actions have been moved to associated values on the `AccessibilityElement.Trait` enum.

## [0.38.0]

### Added

- Shadows on `Label` and `AttributedLabel`
- Accessibility increment, decrement and activate actions now available on `AccessibilityElement`
- `Decorate` has a new `aligned` positioning, that uses stack-style `Alignment` values and alignment guides.
- The context vended to custom `Decorate` positions includes the decorated content size.

### Changed

- The context vended to custom `Decorate` positions was renamed to `PositionContext`, and the `contentFrame` property was replaced with a `contentSize`.

## [0.37.0]

### Fixed

- `Decorate` will now properly scale its base content to the full size of the rendered element, if the measured and laid out sizes differ.
- Fixed an issue where `AttributedLabel` could cause a crash when voice over was enabled.

### Added

- `LayoutWriter.Context` now exposes the layout phase, to differ any calculations between measurement and layout.

## [0.36.1]

### Fixed

- Fixed an issue where `AttributedLabel` and `Label` would not pass touches to super views when expected.

## [0.36.0]

### Fixed

- Fixed an issue where `AttributedLabel` might not detect link taps in multi-line labels.
- `.aligned(vertically:horizontally:)` now has the correct default values to match the `Aligned` initializer.

### Changed

- The default line break mode for `Label` is now `byTruncatingTail`, matching the default for `UILabel`. (It was previously `byWordWrapping`, which does not indicate that truncation occured.)
- `AttributedLabel` will normalize certain line break modes based on the number of lines.

## [0.35.1] - 2022-01-13

### Fixed

- `Label` and `AttributedLabel` now correctly report their `UIAccessibilityTraits`.

## [0.35.0] - 2022-01-11

### Added

- Added the `EditingMenu` element, which allows showing a `UIMenuController` (aka the system editing menu) on tap, long press, or based on a trigger.

### Changed

- `Label.font` now defaults to using a font of size `UIFont.labelFontSize` (17) instead of `UIFont.systemFontSize`.

## [0.34.0] - 2021-12-16

### Added

- Support `CALayerCornerCurve` for `Box` corner styles.
- Added `AttributedText`, which supports applying strongly-typed attributes to strings (much like the `AttributedString` type introduced in iOS 15).
- Added support for links to `AttributedLabel`:
  - Links can be added using the `link` attribute of the attributed string. This attribute supports `URL`s or `String`s.
  - The label also supports detecting certain types of data and links, much like UITextView. Use the `linkDetectionTypes` property to specify which types of data to detect.
  - Links are opened using the `LinkHandler` in the environment, which by default uses `UIApplication.shared.open(_:options:completionHandler:)`. Customize link handling by providing a `URLHandler` to the environment at the appropriate scope. `AttributedLabel` also has a function for easily handling links with a closure using the `onLinkTapped` method.

## [0.33.3] - 2021-12-8

### Fixed

- Fixed an issue where `Box` did not implicitly animate its shadow.

### Changed

- Reverted scroll view keyboard inset behavior to the behavior in `0.30.0`, since the recent changes were causing unexpected issues.

## [0.33.2] - 2021-11-30

### Fixed

- Fixed an issue where `ScrollView` did not adjust its content inset correctly when the keyboard height or content insets changed.

## [0.33.1] - 2021-11-22

### Fixed

- Fixed an issue where `BlueprintView` would not size correctly when used with Auto Layout.

### Added

- Added an `ElementContent` variant whose `measureFunction` takes in both a `SizeConstraint` and an `Environment`.

## [0.33.0] - 2021-11-18

### Added

- Allow measuring within an explicit `SizeConstraint` in `GeometryProxy`.
- Add an additional `stackLayoutChild(priority:)` method overload, for easier autocomplete when only customizing the layout priority.

### Changed

- Values returned from `sizeThatFits` and `systemLayoutSizeFitting` are now cached.

## [0.32.0] - 2021-11-16


### Fixed

- Fixed an issue where the keyboard inset adjustment was incorrect in some cases.
- Fixed a retain cycle in `@FocusState`. ([#285](https://github.com/square/Blueprint/pull/285))

### Added

- Add support for `for...in` loops and `available` checks to result builder APIs.

## [0.31.0] - 2021-11-09

### Fixed

- `intrinsicContentSize` is now cached.

### Added

- Improved error messages when using result builders with optional values.

## [0.30.0] - 2021-10-15

### Added

- Added a `Hidden` element and `.hidden()` modifier for hiding elements.
- `Overlay` now supports result builders.
- `SegmentedControl` now supports result builders.

### Removed

- Removed deprecated initializer from `AccessibilityElement` which was causing ambiguous initializer errors.

### Changed

- `UserInteractionEnabled` has been moved from `BlueprintUICommonControls` into `BlueprintUI`. It no longer has a backing view, and instead uses layout attributes to apply itself to elements. This change shouldn't affect consumers.

## [0.29.0] - 2021-09-21

### Added

- The `@FocusState` property wrapper can be used to manage focus of text fields. ([#259])

  After binding a text field to a state, you can programmatically focus the field by setting the state value.

  ```swift
  struct LoginForm: ProxyElement {
      enum Field: Hashable {
          case username, password
      }

      @FocusState private var focusedField: Field?

      var elementRepresentation: Element {
          // This text field will be focused when `self.focusedField = .username`
          TextField(text: "")
              .focused(when: $focusedField, equals: .username)
      }
  }
  ```
- Row, Column, EqualStack, and GridRow can now be initialized declaratively using result builders. ([#220])
  - To declare one of these containers, simply include the elements inside the `ElementBuilder` trailing closure.
  - To customize the container, pass values through the containers `init` or leave out to use the provided defaults parameters.
  - To customize one of the child element's container specific properties (key, priority, etc), tack on a corresponding modifier such as `stackLayoutChild()` and `gridRowChild()`.
  ```swift
  let row = Row(alignment: .fill) {
    TestElement()
    TestElement2()
      .stackLayoutChild(priority: .fixed, alignmentGuide: { _ in 0 }, key: "two")
  }
  ```

- The `accessibilityElement(...)` modifier has been added for wrapping an `Element` in an `AccessibilityElement`. Note that this will override all accessibility parameters of the `Element` being wrapped, even if values are left unspecified or set to `nil`.
- An initializer on `AccessibilityElement` that requires a `label`, `value`, and `traits`.
- `Overlay` supports keys for disambiguation between view updates. ([#264])

### Changed

- `BlueprintView`'s `intrinsicContentSize` will now return `UIView.noIntrinsicMetric` if there is no `element` associated with it.

- `TextField`'s `becomeActiveTrigger` and `resignActiveTrigger` properties have been replaced with a `focusBinding` for use with the new `@FocusState` property wrapper.

### Deprecated

- The `accessibility(...)` modifier has been deprecated. Use `accessibilityElement(...)` instead.
- An initializer on `AccessibilityElement` that allowed all parameters to be unspecified. Use the initializer with required parameters instead.
- `Overlay.add(_:)` deprecated in favor of `Overlay.add(key:child:)`.

## [0.28.1] - 2021-09-10

### Added

- View-backed elements may opt-in to a frame rounding behavior that prioritizes preserving the frame size rather than the frame edges. This is primarily meant for text labels, to fix an issue where labels gain or lose a pixel in rounding and become wrapped or truncated incorrectly. ([#257])

### Changed

- Lifecycle hooks are guaranteed to run after all views are updated. ([#260])

## [0.28.0] - 2021-09-01

### Fixed

- Fixed an [issue](https://github.com/square/Blueprint/pull/241) where `Label` and `AttributedLabel` were not accessibility elements.

### Added

- `Label` `AttributedLabel` and `TextField` elements now support configuration of accessibility traits.

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

- [Removed support for / deprecated iOS 11](https://github.com/square/Blueprint/pull/250).

### Changed

- [`makeUIView()` on `UIViewElement` is no longer a static function](https://github.com/square/Blueprint/pull/246), to allow access to properties during view creation.

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

[main]: https://github.com/square/Blueprint/compare/6.0.0...HEAD
[6.0.0]: https://github.com/square/Blueprint/compare/5.7.0...6.0.0
[5.7.0]: https://github.com/square/Blueprint/compare/5.6.0...5.7.0
[5.6.0]: https://github.com/square/Blueprint/compare/5.5.0...5.6.0
[5.5.0]: https://github.com/square/Blueprint/compare/5.4.0...5.5.0
[5.4.0]: https://github.com/square/Blueprint/compare/5.3.0...5.4.0
[5.3.0]: https://github.com/square/Blueprint/compare/5.2.0...5.3.0
[5.2.0]: https://github.com/square/Blueprint/compare/5.1.0...5.2.0
[5.1.0]: https://github.com/square/Blueprint/compare/5.0.1...5.1.0
[5.0.1]: https://github.com/square/Blueprint/compare/5.0.0...5.0.1
[5.0.0]: https://github.com/square/Blueprint/compare/4.3.0...5.0.0
[4.3.0]: https://github.com/square/Blueprint/compare/4.2.1...4.3.0
[4.2.1]: https://github.com/square/Blueprint/compare/4.2.0...4.2.1
[4.2.0]: https://github.com/square/Blueprint/compare/4.1.2...4.2.0
[4.1.2]: https://github.com/square/Blueprint/compare/4.1.1...4.1.2
[4.1.1]: https://github.com/square/Blueprint/compare/4.1.0...4.1.1
[4.1.0]: https://github.com/square/Blueprint/compare/4.0.1...4.1.0
[4.0.1]: https://github.com/square/Blueprint/compare/4.0.0...4.0.1
[4.0.0]: https://github.com/square/Blueprint/compare/3.1.0...4.0.0
[3.1.0]: https://github.com/square/Blueprint/compare/3.0.0...3.1.0
[3.0.0]: https://github.com/square/Blueprint/compare/2.2.0...3.0.0
[2.2.0]: https://github.com/square/Blueprint/compare/2.1.0...2.2.0
[2.1.0]: https://github.com/square/Blueprint/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/square/Blueprint/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/square/Blueprint/compare/0.50.0...1.0.0
[0.50.0]: https://github.com/square/Blueprint/compare/0.49.1...0.50.0
[0.49.1]: https://github.com/square/Blueprint/compare/0.49.0...0.49.1
[0.49.0]: https://github.com/square/Blueprint/compare/0.48.1...0.49.0
[0.48.1]: https://github.com/square/Blueprint/compare/0.48.0...0.48.1
[0.48.0]: https://github.com/square/Blueprint/compare/0.47.0...0.48.0
[0.47.0]: https://github.com/square/Blueprint/compare/0.46.0...0.47.0
[0.46.0]: https://github.com/square/Blueprint/compare/0.45.1...0.46.0
[0.45.1]: https://github.com/square/Blueprint/compare/0.45.0...0.45.1
[0.45.0]: https://github.com/square/Blueprint/compare/0.44.1...0.45.0
[0.44.1]: https://github.com/square/Blueprint/compare/0.44.0...0.44.1
[0.44.0]: https://github.com/square/Blueprint/compare/0.43.0...0.44.0
[0.43.0]: https://github.com/square/Blueprint/compare/0.42.0...0.43.0
[0.42.0]: https://github.com/square/Blueprint/compare/0.41.0...0.42.0
[0.41.0]: https://github.com/square/Blueprint/compare/0.40.0...0.41.0
[0.40.0]: https://github.com/square/Blueprint/compare/0.39.0...0.40.0
[0.39.0]: https://github.com/square/Blueprint/compare/0.38.0...0.39.0
[0.38.0]: https://github.com/square/Blueprint/compare/0.37.0...0.38.0
[0.37.0]: https://github.com/square/Blueprint/compare/0.36.1...0.37.0
[0.36.1]: https://github.com/square/Blueprint/compare/0.36.0...0.36.1
[0.36.0]: https://github.com/square/Blueprint/compare/0.35.1...0.36.0
[0.35.1]: https://github.com/square/Blueprint/compare/0.35.0...0.35.1
[0.35.0]: https://github.com/square/Blueprint/compare/0.34.0...0.35.0
[0.34.0]: https://github.com/square/Blueprint/compare/0.33.3...0.34.0
[0.33.3]: https://github.com/square/Blueprint/compare/0.33.2...0.33.3
[0.33.2]: https://github.com/square/Blueprint/compare/0.33.1...0.33.2
[0.33.1]: https://github.com/square/Blueprint/compare/0.33.0...0.33.1
[0.33.0]: https://github.com/square/Blueprint/compare/0.32.0...0.33.0
[0.32.0]: https://github.com/square/Blueprint/compare/0.31.0...0.32.0
[0.31.0]: https://github.com/square/Blueprint/compare/0.30.0...0.31.0
[0.30.0]: https://github.com/square/Blueprint/compare/0.29.0...0.30.0
[0.29.0]: https://github.com/square/Blueprint/compare/0.28.1...0.29.0
[0.28.1]: https://github.com/square/Blueprint/compare/0.28.0...0.28.1
[0.28.0]: https://github.com/square/Blueprint/compare/0.27.0...0.28.0
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
[#468]: https://github.com/square/Blueprint/pull/468
[#264]: https://github.com/square/Blueprint/pull/264
[#260]: https://github.com/square/Blueprint/pull/260
[#259]: https://github.com/square/Blueprint/pull/259
[#257]: https://github.com/square/Blueprint/pull/257
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
[5.1.0]: https://github.com/square/Blueprint/compare/5.0.1...5.1.0
[5.2.0]: https://github.com/square/Blueprint/compare/5.1.0...5.2.0
