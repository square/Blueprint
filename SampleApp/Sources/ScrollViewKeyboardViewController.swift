import BlueprintUI
import BlueprintUICommonControls
import UIKit


final class ScrollViewKeyboardViewController: UIViewController {
    override func loadView() {

        let view = BlueprintView()

        view.element = content()

        self.view = view
    }

    private func content() -> Element {
        Column {
            $0.horizontalAlignment = .fill

            for _ in 1...20 {
                $0.add(
                    growPriority: 0.0,
                    shrinkPriority: 0.0,
                    child: TextField(text: "Hello, World")
                        .inset(uniform: 20.0)
                        .box(background: .init(white: 0.95, alpha: 1.0))
                )
            }
        }.scrollable {
            $0.keyboardAdjustmentMode = .adjustsWhenVisible
        }
    }
}
