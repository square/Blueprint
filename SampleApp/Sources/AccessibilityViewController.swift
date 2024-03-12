import BlueprintUI
import BlueprintUICommonControls
import UIKit

final class AccessibilityViewController: UIViewController {

    private let blueprintView = BlueprintView()

    override func loadView() {
        view = blueprintView
        blueprintView.element = element
    }

    var firstTrigger = AccessibilityFocus.Trigger()
    var secondTrigger = AccessibilityFocus.Trigger()

    var element: Element {

        Column(alignment: .fill, minimumSpacing: 20) {
            Row {
                Label(text: "First")
                    .accessibilityFocus(on: firstTrigger)
                Spacer()
                Label(text: "Second")
                    .accessibilityFocus(on: secondTrigger)
            }
            Button(
                onTap: {
                    self.firstTrigger.focus()
                },
                wrapping: Label(text: "Focus on First", configure: { label in
                    label.color = .systemBlue
                })
            )

        }
        .inset(uniform: 20)
        .centered()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.secondTrigger.focus()
            }
        }
    }
}
