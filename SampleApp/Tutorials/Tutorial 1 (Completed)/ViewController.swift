import UIKit
import BlueprintUI
import BlueprintUICommonControls


struct ButtonElement: Element {

    var isHighlighted: Bool

    let content = ElementContent(intrinsicSize: .init(width: 40, height: 40))

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        UIView.describe { config in
            config[animated: \.backgroundColor] = isHighlighted ? .blue : .purple
            config.updateTransition = { animate in
                UIViewPropertyAnimator(duration: 1, curve: .easeInOut, animations: animate)
                    .startAnimation()
            }
        }
    }
}


final class ViewController: UIViewController {

    private let blueprintView = BlueprintView()

    override func loadView() {
        self.view = blueprintView
        update(isHighlighted: false)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    private func update(isHighlighted: Bool) {
        blueprintView.element = ButtonElement(isHighlighted: isHighlighted).centered()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        update(isHighlighted: true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        update(isHighlighted: false)
    }
}
