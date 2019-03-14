# Transitions

There are two types of transitions in Blueprint:

- Layout transitions, in which the layout attributes of an existing view change, and an animation is used when applying the new attributes.
- Visibility transitions, in which the appearance or disappearance of a view is animated.

## `LayoutTransition`

```swift
public enum LayoutTransition {
    case none
    case specific(AnimationAttributes)
    case inherited
    case inheritedWithFallback(AnimationAttributes)
}
```

**'Inherited' transitions:** the 'inherited' transition is determined by searching up the tree (not literally, but this is the resulting behavior). The nearest ancestor that defines an animation will be used, following this logic:
- Ancestors with a layout transition of `none` will result in no inherited animation for their descendents.
- Ancestors in the tree with a layout transition of `inherited` will be skipped, and the search will continue up the tree.
- Any ancestors in the tree with a layout transition of `inheritedWithFallback` will be used *if* they do not themselves inherit a layout transition from one of their ancestors.
- Ancestors with a layout transition of `specific` will always be used for their descendents inherited animation.
- If no ancestor is found that specifies a layout transition, but the containing `BlueprintView` has the `element` property assigned from within a `UIKit` animation block, that animation will be used as the inherited animation.


## `VisibilityTransition`

```swift
public struct VisibilityTransition {

    /// The alpha of the view in the hidden state (initial for appearing, final for disappearing).
    public var alpha: CGFloat

    /// The transform of the view in the hidden state (initial for appearing, final for disappearing).
    public var transform: CATransform3D

    /// The animation attributes that will be used to drive the transition.
    public var attributes: AnimationAttributes

    /// Returns a `VisibilityTransition` that scales in and out.
    public static var scale: VisibilityTransition { get }

    /// Returns a `VisibilityTransition` that fades in and out.
    public static var fade: VisibilityTransition { get }

    /// Returns a `VisibilityTransition` that simultaneously scales and fades in and out.
    public static var scaleAndFade: VisibilityTransition { get }
}
```