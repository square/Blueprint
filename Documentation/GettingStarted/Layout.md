# Layout

Unlike some declarative UI architectures (like the web), Blueprint does not have a single, complex layout model (like Flexbox).

Instead, Blueprint allows each element in the tree to use a different layout implementation that is appropriate for its use.

For example, consider the following element hierarchy

```swift
Label(text: "Hello, world")
    .box(background: .blue)
```

The label will be stretched to fill the box.

If we want to center the label within the box, we do *not* change the box or the label at all. Instead, we add another level to the tree:

```swift
Label(text: "Hello, world")
    .centered()
    .box(background: .blue)
```

By adding a `Centered` element into the hierarchy, the label will now be centered within the outer box.

## Layout Modifiers

To customize an `Element`, you call methods called modifiers. Modifiers wrap an `Element` in another `Element` to change its display or other properties. Each modifier returns a new `Element`, so it’s common to chain multiple modifiers, stacked vertically.

For example, an `Element` described as:

```swift
Label(text: "Hello, world")
    .centered()
    .box(background: .blue)
```

can also be written as:

```swift
Box(
    backgroundColor: .blue,
    wrapping: Centered(
        Label(text: "Hello, world")
    )
)
```

## Layout Elements

Blueprint includes a set of elements that make common layout tasks easier.

### `Centered`

Centers a wrapped element within its parent.

A `Centered` element always wraps a single child. During a layout pass, the layout always delegates measuring to the wrapped element.

After `Centered` has been assigned a size during a layout pass, it always sizes the wrapped element to its measured size, then centers it within the layout area.

```swift
Label(text: "Hello, world")
    .centered()
```

### `Aligned`

Aligns a single child horizontally and vertically to the left (leading edge), right (trailing edge), top, bottom, or center of the available space. Like `Centered`, it delegates measuring to the child.

```swift
Label(text: "Hello from the corner")
    .aligned(
        vertically: .bottom,
        horizontally: .trailing
    )
```

### `Spacer`

Takes up space within a layout, but does not show any visual content.

```swift
Spacer(size: CGSize(width: 100.0, height: 100.0))
```

### `Overlay`

Stretches all of its child elements to fill the layout area, stacked on top of each other.

During a layout pass, measurent is calculated as the max size (in both x and y dimensions) produced by measuring all of the child elements.

```swift
Overlay {
    Box(backgroundColor: .lightGray)

    Label(text: "Hello, world")
}
```

### `Inset`

Wraps a single element, insetting it by the given amount.

```swift
Label(text: "Hello")
    .inset(uniform: 20.0)
```

### Stack Elements: `Row` and `Column`

These elements are used to layout stacks of content in either the x (row) or y (column) dimension.

```swift
Row(
    alignment: .center,
    minimumSpacing: 8.0
) {
    Label(text: "Lorem")

    Label(text: "Ipsum")
}
```

```swift
Column(
    alignment: .center,
    minimumSpacing: 8.0
) {
    Label(text: "Lorem")

    Label(text: "Ipsum")
}
```

---

## Layout implementations

All elements are responsible for producing a `ElementContent` instance that contains both its children and a layout implementation.

There are two types of layouts in Blueprint, both defined as protocols.

### `Layout`

Defines a layout that supports an arbitrary number of children.

### `SingleChildLayout`

Defines a layout that supports exactly one child element.