import BlueprintUI
import BlueprintUICommonControls
import UIKit


final class ViewController: UIViewController {

    private let blueprintView = BlueprintView(element: ReceiptElement())

    override func loadView() {
        view = blueprintView
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

}
