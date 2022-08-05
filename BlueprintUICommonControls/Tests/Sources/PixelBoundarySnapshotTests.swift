import BlueprintUI
import BlueprintUICommonControls
import XCTest

final class PixelBoundarySnapshotTests: XCTestCase {
    func test_nestedBoxes() {
        compareSnapshot(
            of: NestedBoxes(addIntermediateViews: false),
            identifier: "flat",
            scale: 2.0
        )

        // Nesting in an intermediate BlueprintView breaks layout & rounding into separate operations.
        // We want this test to appear identical to the flat version.
        compareSnapshot(
            of: NestedBoxes(addIntermediateViews: true),
            identifier: "nested",
            scale: 2.0
        )
    }

    func test_fractionRow() {
        compareSnapshot(
            of: FractionRow(addIntermediateViews: false),
            identifier: "flat",
            scale: 2.0
        )

        // Nesting in an intermediate BlueprintView breaks layout & rounding into separate operations.
        // We want this test to appear identical to the flat version.
        compareSnapshot(
            of: FractionRow(addIntermediateViews: true),
            identifier: "nested",
            scale: 2.0
        )
    }
    }
}

private struct NestedBoxes: ProxyElement {
    let colors: [UIColor] = [
        .cyan,
        .red,
        .green,
        .yellow,
        .blue,
        .magenta,
        .purple,
        .orange,
    ]
    var depth: Int = 10
    var addIntermediateViews: Bool

    var elementRepresentation: Element {
        guard depth > 0 else {
            return Box(backgroundColor: .white, wrapping: Spacer(size: CGSize(width: 10, height: 10)))
        }

        let color = colors[depth % colors.count]
        let box = Box(
            backgroundColor: color,
            wrapping: Inset(
                top: 2.0,
                bottom: 2.0,
                left: 0.3,
                right: 0.3,
                wrapping: NestedBoxes(
                    depth: depth - 1,
                    addIntermediateViews: addIntermediateViews
                )
            )
        )

        return addIntermediateViews ? box.nested() : box
    }
}

private struct FractionRow: ProxyElement {
    var addIntermediateViews: Bool
    var elementRepresentation: Element {
        Box(
            backgroundColor: .yellow,
            wrapping: ConstrainedSize(
                width: .absolute(13.0),
                wrapping: Row { row in
                    row.horizontalUnderflow = .spaceEvenly
                    for _ in 1...5 {
                        let box = Box(
                            backgroundColor: .red,
                            wrapping: Spacer(size: CGSize(width: 2.0, height: 5.0))
                        )

                        if addIntermediateViews {
                            row.add(child: box.nested())
                        } else {
                            row.add(child: box)
                        }
                    }
                }
            )
        )
    }
}

private struct Nest: Element {
    var nested: Element

    var content: ElementContent {
        ElementContent { constraint, environment in
            nested.content.measure(in: constraint, environment: environment)
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        NestView.describe { config in
            config.apply { view in
                view.blueprintView.element = nested
            }
        }
    }

    final class NestView: UIView {
        let blueprintView = BlueprintView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(blueprintView)
        }

        required init?(coder: NSCoder) {
            fatalError()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            blueprintView.frame = bounds
        }
    }
}

extension Element {
    func nested() -> Element {
        Nest(nested: self)
    }
}
