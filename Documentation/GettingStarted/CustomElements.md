# Building Custom Elements




## `ProxyElement` (easy mode)

A common motivation for defining a custom element is to create an API boundary; the custom implementation can contain its own initializers, properties, etc.

When it comes to actually displaying content, however, many custom elements simply compose other existing elements together (they don't do custom layout or provide a custom view backing).

`ProxyElement` is a tool to make this common case easier.

```swift
public protocol ProxyElement: Element {
    var elementRepresentation: Element { get }
}

/// `ProxyElement` provides default implementations of the `Element` API that delegate to the element returned by `elementRepresentation`.
extension ProxyElement {
    public var content: ElementContent { get }
    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription?
}
```

For example, let's define a custom element that displays a title and subtitle:

```swift
struct TitleSubtitleElement: ProxyElement {
    var title: String
    var subtitle: String

    var elementRepresentation: Element {
        Column(
            alignment: .leading,
            minimumSpacing: 8.0
        ) {
            Label(text: title) { label in
                label.font = .boldSystemFont(ofSize: 18.0)
            }

            Label(text: title) { label in
                label.font = .systemFont(ofSize: 14.0)
                label.color = .darkGray
            }     
        }
    }
}
```

---

## `Element` (hard mode)

For more information, please see [`Element` reference](../Reference/Element.md).

```swift
public protocol Element {
    var content: ElementContent { get }
    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription?
}
```

To implement the `Element` protocol, your custom type must implement two methods:

#### `var content: ElementContent`

`ElementContent` represents (surprise!) the content of an element. Elements generally fall into one of two types: containers and leaves.
- Containers, or elements that have children.
- Leaves: elements that have no children, but often have some intrinsic size (a label is a good example of this).

#### `func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription?`

If a [`ViewDescription`](../Reference/ViewDescription.md) is returned, the element will be view-backed.

---

## Bonus: do you need a custom element?

You may want to define a custom element so that you can reuse it throughout your codebase (great!). In other cases, however, you may simply want to generate an element for display.

For example, let's say we want to show some centered text over an image. This is only used in one place:

```swift
final class ImageViewController {

    private let blueprintView = BlueprintView()
    
    var image: UIImage {
        didSet { updateDisplay() }
    }

    var text: String {
        didSet { updateDisplay() }
    }

    private func updateDisplay() {
        let newElement = // We need an element!
        blueprintView.element = newElement
    }
    
}
```

You might simply define a function to turn input (in this case an image and some text) into an element:

```swift
private func makeElement(image: UIImage, text: String) -> Element {
    Overlay {
        Image(image: image)
        
        Label(text: text)
            .centered()   
    }
}
```

Your `updateDisplay()` method can then call this method as needed:

```swift
final class ImageViewController {

    // ...

    private func updateDisplay() {
        blueprintView.element = makeElement(image: image, text: text)
    }
    
}
```
