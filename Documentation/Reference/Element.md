# The `Element` protocol

```swift
public protocol Element {
    var content: ElementContent { get }
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription?
}
```

---

## Example Elements

#### A view-backed element that displays a blue square
```swift
struct RedSquare: Element {

    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 90.0, height: 90.0))
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { config in
            config[\.backgroundColor] = .blue
        }
    }

}

```

---

## `backingViewDescription(bounds:subtreeExtent:)`

If the element is be view-backed, it should return a view description from this method.

This method is called after layout is complete, and the passed in parameters provide information about the layout:

*`bounds`*
Contains the extent of the element after the layout is calculated *in the element's local coordinate space*.

*`subtreeExtent`*
A rectangle, given within the element's local coordinate space, that completely contains all of the element's children. `nil` will be provided if the element has no children.

Most view-backed elements will not need to care about the bounds or subtree extent, but they are provided for the rare cases when they are needed.

```swift
struct MyElement: Element {

    // ...

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIImageView.describe { config in
            config[\.image] = UIImage(named: "cat")
            config[\.contentMode] = .scaleAspectFill
        }
    }

}
```

[`ViewDescription` reference](ViewDescription.md)

---

## `content`

`ElementContent` represents the content *within* an element.

Elements can contain multiple children with a complex layout, a single child, or simply an intrinsic size that allows the element to participate in a layout.

```swift
public struct ElementContent : Measurable {

    public func measure(in constraint: SizeConstraint) -> CGSize

    public var childCount: Int { get }

}

extension ElementContent {

    public static func container<LayoutType>(layout: LayoutType, configure: (inout Builder<LayoutType>) -> Void = { _ in }) -> ElementContent where LayoutType : Layout

    public static func container(element: Element, layout: SingleChildLayout) -> ElementContent

    public static func container(element: Element) -> ElementContent

    public static func leaf(measurable: Measurable) -> ElementContent

    public static func leaf(measureFunction: @escaping (SizeConstraint) -> CGSize) -> ElementContent

    public static func leaf(intrinsicSize: CGSize) -> ElementContent
    
}
```

### `content` Examples

#### An element with no children and an intrinsic size

```swift
var content: ElementContent {
    return ElementContent(intrinsicSize: CGSize(width: 100, height: 100))
}
```

#### An element with no children and a measurable intrinsic size

```swift
var content: ElementContent {
    return ElementContent(measurable: CustomMeasurer())
}
```

#### An element with no children and a custom measurable intrinsic size

```swift
var content: ElementContent {
    return ElementContent { constraint in
        return CGSize(width: constraint.max.width, height: 44.0)
    }
}
```

#### An element with a single child that performs no custom layout

```swift
var content: ElementContent {
    return ElementContent(child: WrappedElement())
}
```

#### An element with a single child that uses a custom layout

```swift
var content: ElementContent {
    return ElementContent(child: WrappedElement(), layout: MyCustomLayout())
}
```

#### An element with multiple children

```swift
var content: ElementContent {
    return ElementContent(layout: MyCustomLayout()) { builder in
        builder.add(child: WrappedElementA())
        builder.add(child: WrappedElementB())
        builder.add(child: WrappedElementC())
    }
}
