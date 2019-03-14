# BlueprintView

`BlueprintView` is a `UIView` subclass that displays a Blueprint element hierarchy.


### Creating a `BlueprintView` instance

`init(element:)` instantiates a new `BlueprintView` with the given element:

```swift

let rootElement = Center(
    Column { column in

        column.layout.horizontalAlignment = .center
        column.layout.minimumVerticalSpacing = 12.0

        column.add(child: Label(text: "Hello, world!"))
        column.add(child: Label(text: "This is a label"))
    }
}

let blueprintView = BlueprintView(element: rootElement)
```


### Updating the element hierarchy

A `BlueprintView` instance can be updated after initialization by assigning the `.element` property:

```swift
blueprintView.element = Label(text: "This is a new element")
```

Updates can be animated within an animation block:

```swift

UIView.animate(withDuration) {
    blueprintView.element = Label(text: "This is a new element")
}

```

See the documentation for `ViewDescription` for more information about transitions.