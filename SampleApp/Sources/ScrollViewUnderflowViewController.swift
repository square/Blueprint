import BlueprintUI
import BlueprintUICommonControls
import UIKit


final class ScrollViewUnderflowViewController: UIViewController {
    override func loadView() {

        let view = BlueprintView()

        view.element = content()

        self.view = view

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Change", style: .plain, target: self, action: #selector(rotateUnderflow)),
        ]
    }

    @objc private func rotateUnderflow() {
        fatalError()
    }

    private func content() -> Element {
        ScrollView(underflow: .fill) {
            Label(text: "Underflow Behavior: `TODO`")
                .centered()
                .box(background: .systemBlue)
        }
    }
}

