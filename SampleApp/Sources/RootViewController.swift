import Foundation


import BlueprintUI
import BlueprintUICommonControls
import UIKit


final class RootViewController: UIViewController {
    fileprivate var demos: [Element] {
        [
            DemoItem(title: "Accessibility", onTap: { [weak self] in
                self?.push(AccessibilityViewController())
            }),
            DemoItem(title: "Text Links", onTap: { [weak self] in
                self?.push(TextLinkViewController())
            }),
            DemoItem(title: "Post List", badgeText: "3", onTap: { [weak self] in
                self?.push(PostsViewController())
            }),
            DemoItem(title: "Keyboard Scrolling", onTap: { [weak self] in
                self?.push(ScrollViewKeyboardViewController())
            }),
            DemoItem(title: "GeometryReader Responsive Layout", onTap: { [weak self] in
                self?.push(ResponsiveViewController())
            }),

            EditingMenu { menu in
                DemoItem(title: "Show A Menu Controller") {
                    menu.show()
                }
            } items: {
                EditingMenuItem.copying("A string goes on the pasteboard")

                EditingMenuItem(.paste) {
                    print("Pasted!")
                }

                EditingMenuItem(title: "A Custom Item") {
                    // Do something here...
                    print("Performed!")
                }
            },
        ]
    }

    override func loadView() {
        let blueprintView = BlueprintView(element: contents)

        view = blueprintView

        view.backgroundColor = .init(white: 0.9, alpha: 1.0)
    }

    var contents: Element {
        Column { column in
            column.minimumVerticalSpacing = 20.0
            column.horizontalAlignment = .leading

            self.demos.forEach { demo in
                column.add(child: demo)
            }
        }
        .constrainedTo(width: .within(300...400))
        .aligned(vertically: .top, horizontally: .center)
        .inset(uniform: 40.0)
        .scrollable(.fittingHeight) { scrollView in
            scrollView.alwaysBounceVertical = true
        }
    }

    private func push(_ viewController: UIViewController) {
        navigationController?.pushViewController(viewController, animated: true)
    }
}


fileprivate struct DemoItem: ProxyElement {
    var title: String
    var badgeText: String?

    var onTap: () -> Void

    var elementRepresentation: Element {

        Label(text: title) { label in
            label.font = .systemFont(ofSize: 18.0, weight: .semibold)
        }
        .inset(uniform: 20.0)
        .box(
            background: .white,
            corners: .rounded(radius: 15.0),
            shadow: .simple(
                radius: 5.0,
                opacity: 0.3,
                offset: .init(width: 0, height: 2.0),
                color: .black
            )
        )
        .tappable {
            self.onTap()
        }
        .decorate(layering: .below, position: .inset(5)) {
            Box(backgroundColor: .init(white: 0.0, alpha: 0.1), cornerStyle: .rounded(radius: 17))
        }
        .decorate(layering: .above, position: .corner(.topLeft)) {
            guard let badge = self.badgeText else {
                return Empty()
            }

            return Label(text: badge) {
                $0.font = .systemFont(ofSize: 22.0, weight: .bold)
                $0.color = .white
            }
            .inset(uniform: 7.0)
            .box(background: .systemRed, corners: .capsule)
        }
        .accessibilityElement(
            label: title,
            value: nil,
            traits: [.staticText],
            accessibilityFrameCornerStyle: .rounded(radius: 15)
        )
    }
}
