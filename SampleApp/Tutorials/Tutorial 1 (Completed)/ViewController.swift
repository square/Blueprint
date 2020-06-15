import UIKit
import BlueprintUI
import BlueprintUICommonControls


struct HelloWorldElement: ProxyElement {

    let text: String

    var elementRepresentation: Element {
        var label = Label(text: text)
        label.font = .boldSystemFont(ofSize: 24.0)
        label.color = .darkGray

        return Centered(label)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { config in
            config.updateTransition = UpdateTransition { view, animations in
                UIView.transition(with: view,
                                  duration: 1,
                                  options: [.transitionCrossDissolve],
                                  animations: animations)
            }
        }
    }
}


final class ViewController: UIViewController {

    private let blueprintView = BlueprintView(element: HelloWorldElement(text: "Hello!"))

    override func loadView() {
        self.view = blueprintView
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        blueprintView.element = HelloWorldElement(text: "Began")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        blueprintView.element = HelloWorldElement(text: "Ended")
    }
}
