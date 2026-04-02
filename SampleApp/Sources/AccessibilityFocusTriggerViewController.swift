import BlueprintUI
import BlueprintUICommonControls
import UIKit

final class AccessibilityFocusTriggerViewController: UIViewController {

    private let blueprintView = BlueprintView()

    private enum DemoState {
        case idle, loading, result
    }

    private var transferState: DemoState = .idle {
        didSet { update() }
    }

    private let resultTrigger = AccessibilityFocusTrigger()
    private let layoutChangeTrigger = AccessibilityFocusTrigger(notification: .layoutChanged)
    private let screenChangeTrigger = AccessibilityFocusTrigger(notification: .screenChanged)

    override func loadView() {
        view = blueprintView
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AccessibilityFocusTrigger"
        update()
    }

    private func update() {
        blueprintView.element = element
    }

    var element: Element {
        Column(alignment: .fill, minimumSpacing: 24) {

            // MARK: - Section: Layout changed

            sectionHeader("Layout Changed (.layoutChanged)")

            Label(text: "Focuses this label with .layoutChanged") { label in
                label.font = .systemFont(ofSize: 16)
                label.color = .secondaryLabel
            }
            .accessibilityFocus(trigger: layoutChangeTrigger)

            Button(
                onTap: {
                    self.layoutChangeTrigger.requestFocus()
                },
                wrapping: buttonLabel("Trigger Layout Changed")
            )

            separator()

            // MARK: - Section: Screen changed

            sectionHeader("Screen Changed (.screenChanged)")

            Label(text: "Focuses this label with .screenChanged") { label in
                label.font = .systemFont(ofSize: 16)
                label.color = .secondaryLabel
            }
            .accessibilityFocus(trigger: screenChangeTrigger)

            Button(
                onTap: {
                    self.screenChangeTrigger.requestFocus()
                },
                wrapping: buttonLabel("Trigger Screen Changed")
            )

            separator()

            // MARK: - Section: Focus after async operation

            sectionHeader("Focus After Async Operation")

            if transferState == .result {
                Label(text: "Transfer complete! $42.00 sent.") { label in
                    label.font = .systemFont(ofSize: 16, weight: .medium)
                    label.color = .systemGreen
                }
                .accessibilityFocus(trigger: resultTrigger)
            }

            Button(
                isEnabled: transferState != .loading,
                onTap: {
                    switch self.transferState {
                    case .idle:
                        self.transferState = .loading
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.transferState = .result
                            DispatchQueue.main.async {
                                self.resultTrigger.requestFocus()
                            }
                        }
                    case .result:
                        self.transferState = .idle
                    case .loading:
                        break
                    }
                },
                wrapping: buttonLabel(
                    transferState == .idle ? "Send Transfer" : transferState == .loading ? "Sending…" : "Reset",
                    color: transferState == .loading ? .systemGray : transferState == .result ? .systemGray : .systemBlue
                )
            )
        }
        .inset(uniform: 20)
        .scrollable(.fittingHeight) { scrollView in
            scrollView.alwaysBounceVertical = true
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> Element {
        Label(text: text) { label in
            label.font = .systemFont(ofSize: 20, weight: .bold)
            label.color = .label
        }
    }

    private func buttonLabel(_ text: String, color: UIColor = .systemBlue) -> Element {
        Label(text: text) { label in
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.color = color
        }
        .inset(by: UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20))
        .box(
            background: color.withAlphaComponent(0.12),
            corners: .rounded(radius: 10)
        )
    }

    private func separator() -> Element {
        Box(backgroundColor: .separator)
            .constrainedTo(height: .absolute(1.0 / UIScreen.main.scale))
    }
}
