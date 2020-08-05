import UIKit
import BlueprintUI
import BlueprintUICommonControls

final class ResponsiveViewController: UIViewController {
    let blueprintView = BlueprintView()

    override func loadView() {
        blueprintView.backgroundColor = .white
        self.view = blueprintView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        update()
    }

    func update() {
        blueprintView.element = element
    }

    var element: Element {
        Column { column in
            column.horizontalAlignment = .center
            column.verticalUnderflow = .justifyToCenter

            column.add(child: ResponsiveLabel(text: "Short text"))

            column.add(child: ResponsiveLabel(text: "Long text that may not fit and will turn into an ellipsis"))
        }
        .box(borders: .solid(color: .gray, width: 1))
        .constrainedTo(width: .atMost(200))
        .centered()
    }
}

struct ResponsiveLabel: ProxyElement {
    var text: String

    var elementRepresentation: Element {
        GeometryReader { (geometry) -> Element in
            let label = Label(text: self.text) { label in
                label.numberOfLines = 1
            }

            let labelWidth = geometry.measure(element: label).width

            // If the label does not fit within this constraint, replace it with "..."
            if let maxWidth = geometry.constraint.width.constrainedValue, labelWidth > maxWidth {
                return Label(text: "…")
            } else {
                return label
            }
        }
        .inset(uniform: 4)
        .box(borders: .solid(color: .red, width: 1))
    }
}
