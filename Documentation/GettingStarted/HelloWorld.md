# Hello, World

`BlueprintView` is a `UIView` subclass that can display an element hierarchy.

```swift
import UIKit
import BlueprintUI
import BlueprintUICommonControls

final class ViewController: UIViewController {

    private let blueprintView = BlueprintView(element: helloWorldElement)

    override func loadView() {
        self.view = blueprintView
    }

    var helloWorldElement: Element {
        Label(text: "Hello, world") { label in
            label.font = .boldSystemFont(ofSize: 18.0)
        }
        .centered()
    }
}

```