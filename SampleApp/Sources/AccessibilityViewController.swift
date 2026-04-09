import BlueprintUI
import BlueprintUIAccessibilityCore
import BlueprintUICommonControls
import UIKit

final class AccessibilityViewController: UIViewController {

    private let blueprintView = BlueprintView()

    private var isLongPressButtonDark: Bool = false {
        didSet {
            if oldValue != isLongPressButtonDark {
                update()
            }
        }
    }

    override func loadView() {
        view = blueprintView
    }

    func update() {
        blueprintView.element = element
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        update()
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
            }.accessibilityElement(label: "Title", value: "Detail", traits: [.staticText])

            Label(text: "This is an example of a long accessibility label")
                .accessibilityElement(
                    label: "This is an example of a long accessibility label",
                    value: "Detail",
                    traits: [.staticText],
                    userInputLabels: ["Short Input Label"]
                )
            Row {
                Button(
                    wrapping: Label(text: "Large content item 1", configure: { label in
                        label.color = .white
                    })
                    .inset(by: .init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0))
                    .box(background: .systemBlue)
                )
                .accessibilityShowsLargeContentViewer(
                    display: .title("Large content item 1 display text", nil),
                    interactionEndedCallback: { print("Interaction ended on item 1 at: \($0)") }
                )
                Button(
                    wrapping: Label(text: "Large content item 2", configure: { label in
                        label.color = .white
                    })
                    .inset(by: .init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0))
                    .box(background: .systemGreen)
                )
                .accessibilityShowsLargeContentViewer(
                    display: .title("Large content item 2 display text", nil),
                    interactionEndedCallback: { print("Interaction ended on item 2 at: \($0)") }
                )
            }.accessibilityLargeContentViewerInteractionContainer()
            Row {
                Button(
                    wrapping: Label(text: "Large content item 3", configure: { label in
                        label.color = .white
                    })
                    .inset(by: .init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0))
                    .box(background: .systemRed)
                )
                .accessibilityShowsLargeContentViewer(
                    display: .title("Large content item 3 display text", nil),
                    interactionEndedCallback: { print("Interaction ended on item 3 at: \($0)") }
                )
                Button(
                    wrapping: Label(text: "Large content item 4", configure: { label in
                        label.color = .white
                    })
                    .inset(by: .init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0))
                    .box(background: .systemYellow)
                )
                .accessibilityShowsLargeContentViewer(
                    display: .title("Large content item 4 display text", nil),
                    interactionEndedCallback: { print("Interaction ended on item 4 at: \($0)") }
                )
            }.accessibilityLargeContentViewerInteractionContainer()
            Row {
                Button(
                    wrapping: Label(text: "Non large content item", configure: { label in
                        label.color = .white
                    })
                    .inset(by: .init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0))
                    .box(background: .systemGray)
                )
                .accessibilityShowsLargeContentViewer(display: .none)
                Button(
                    wrapping: Label(text: "Large content item 5", configure: { label in
                        label.color = .white
                    })
                    .inset(by: .init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0))
                    .box(background: .systemPurple)
                )
                .accessibilityShowsLargeContentViewer(display: .title("Large content item 5 display text", nil))
            }.accessibilityLargeContentViewerInteractionContainer()
            Row {
                Label(text: "Long press large content", configure: { label in
                    label.color = isLongPressButtonDark ? .white : .black
                })
                .inset(by: .init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0))
                .box(background: isLongPressButtonDark ? .black : .lightGray)
                .onLongPress {
                    self.isLongPressButtonDark.toggle()
                }
                .accessibilityShowsLargeContentViewer(display: .title("Long press large content display text", nil))
            }.accessibilityLargeContentViewerInteractionContainer()
            Row {
                Label(text: "Deferral") { label in
                    label.font = .systemFont(ofSize: 24, weight: .bold)
                    label.accessibilityTraits = [.header]
                }
            }

            deferralDemo
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

    /// Demonstrates the Element deferral API.
    /// The eyebrow and subheading are marked as deferred sources — VoiceOver
    /// consolidates their content into the title (the receiver) so users hear
    /// one combined element instead of three separate ones.
    var deferralDemo: Element {
        let eyebrowContent = AccessibilityDeferral.Content(kind: .inherited(.high))
        let subheadingContent = AccessibilityDeferral.Content(kind: .inherited())

        return Column(alignment: .fill, minimumSpacing: 4) {
            Label(text: "FEATURED", configure: { label in
                label.font = .systemFont(ofSize: 12, weight: .semibold)
                label.color = .systemGray
            })
            .deferredAccessibilitySource(identifier: eyebrowContent.sourceIdentifier)

            Label(text: "Accessibility Deferral", configure: { label in
                label.font = .systemFont(ofSize: 20, weight: .bold)
            })
            .deferredAccessibilityReceiver()

            Label(text: "Consolidate and order accessibility independently of layout", configure: { label in
                label.font = .systemFont(ofSize: 14)
                label.color = .systemGray
            })
            .deferredAccessibilitySource(identifier: subheadingContent.sourceIdentifier)
        }
        .inset(uniform: 16)
        .box(background: .white, corners: .rounded(radius: 12))
        .deferAccessibilityToChildren(content: [eyebrowContent, subheadingContent])
    }
}
