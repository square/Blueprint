import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class ViewController: UIViewController {

    private let blueprintView = BlueprintView(element: ReceiptElement())

    override func loadView() {
        self.view = blueprintView
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

}
