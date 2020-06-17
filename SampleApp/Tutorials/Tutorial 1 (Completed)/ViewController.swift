import UIKit
import BlueprintUI
import BlueprintUICommonControls


struct HelloWorldElement: ProxyElement {

    let color: UIColor
    let textColor: UIColor

    var elementRepresentation: Element {
        var label = Label(text: "Hello World!")
        label.font = .boldSystemFont(ofSize: 24.0)
        label.color = textColor

        return label.textTransition().box(background: color).centered().viewTransition()
    }
}

struct TextTransition: Element {
    let wrapping: Element

    var content: ElementContent {
        ElementContent(child: wrapping)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { config in
            config.updateTransition = UpdateTransition { view, animations in
                UIView.transition(with: view,
                                  duration: 0.2,
                                  options: [.transitionCrossDissolve, .curveEaseInOut],
                                  animations: animations)
            }
        }
    }
}

struct ViewTransition: Element {
    let wrapping: Element

    var content: ElementContent {
        ElementContent(child: wrapping)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { config in
            config.updateTransition = UpdateTransition { view, animations in
                UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut, animations: animations)
                    .startAnimation()
            }
        }
    }

}

extension Element {
    func textTransition() -> Element {
        return TextTransition(wrapping: self)
    }

    func viewTransition() -> Element {
        return ViewTransition(wrapping: self)
    }
}

final class ViewController: UIViewController {

    private let blueprintView = BlueprintView(element: HelloWorldElement(color: .systemBlue, textColor: .white))

    override func loadView() {
        self.view = blueprintView
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        blueprintView.element = HelloWorldElement(color: .systemPink, textColor: UIColor.white.withAlphaComponent(0.2))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        blueprintView.element = HelloWorldElement(color: .systemBlue, textColor: .white)
    }
}
