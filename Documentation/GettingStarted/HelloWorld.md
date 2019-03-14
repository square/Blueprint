# Hello, World

`BlueprintView` is a `UIView` subclass that can display an element hierarchy.

```swift
import UIKit
import Blueprint


private func makeHelloWorldElement() -> Element {
    var label = Label(text: "Hello, world")
    label.font = .boldSystemFont(ofSize: 18.0)
    return Centered(label)
}

final class ViewController: UIViewController {

    private let blueprintView = BlueprintView(element: makeHelloWorldElement())

    override func loadView() {
        self.view = blueprintView
    }

}

```