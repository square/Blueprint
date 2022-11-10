# BlueprintView

`BlueprintView` is a `UIView` subclass that displays a Blueprint element hierarchy.


### Creating a `BlueprintView` instance

`init(element:)` instantiates a new `BlueprintView` with the given element:

```swift
var rootElement: Element {
    Column(
        alignment: .center,
        minimumSpacing: 12.0
    ) {
        Label(text: "Hello, world!")

        Label(text: "This is a label")
    }
    .centered()
}

let blueprintView = BlueprintView(element: rootElement)
```


### Updating the element hierarchy

A `BlueprintView` instance can be updated after initialization by assigning the `.element` property:

```swift
blueprintView.element = Label(text: "This is a new element")
```

See the documentation for `ViewDescription` for more information about transitions.