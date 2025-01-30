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
                Label(text: "Focus") { label in
                    label.font = .systemFont(ofSize: 24, weight: .bold)
                    label.accessibilityTraits = [.header]
                }
            }

            Row {
                Label(text: "First")
                    .accessibilityFocus(on: firstTrigger)
                Spacer()
                Label(text: "Second")
                    .accessibilityFocus(on: secondTrigger)
            }

            Row {
                Button(
                    onTap: {
                        self.firstTrigger.focus()
                    },
                    wrapping: Label(text: "Focus on First", configure: { label in
                        label.color = .systemBlue
                    })
                )
            }

            Row {
                Label(text: "Blocker") { label in
                    label.font = .systemFont(ofSize: 24, weight: .bold)
                    label.accessibilityTraits = [.header]
                }
            }

            Row {
                Label(text: "Blocked label").blockAccessibility()
            }

            Row {
                Label(text: "Accessibility Element") { label in
                    label.font = .systemFont(ofSize: 24, weight: .bold)
                    label.accessibilityTraits = [.header]
                }
            }

            Row {
                Label(text: "Title")

                Spacer()

                Label(text: "Detail") { label in
                    label.color = .systemGray
                }
            }.accessibilityElement(label: "Title", value: "Detail", traits: [])

            Label(text: "This is an example of a long accessibility label")
                .accessibilityElement(
                    label: "This is an example of a long accessibility label",
                    value: "Detail",
                    traits: [],
                    userInputLabels: ["Short Input Label"]
                )

        }
        .accessibilityContainer()
        .inset(uniform: 20)
        .centered()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.secondTrigger.focus()
            }
        }
    }
}
