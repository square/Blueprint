import UIKit
import XCTest
@testable import BlueprintUI


class LayoutWriterTests: XCTestCase {

    func test_buildCount() {

        // Performance – should only build the layout once during a layout pass.

        var buildCount: Int = 0

        let writer = LayoutWriter { _, layout in
            buildCount += 1
        }

        let view = BlueprintView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        view.element = writer.centered()

        XCTAssertEqual(buildCount, 0)

        view.layoutIfNeeded()

        // Two calls: Once for measurement, and once for layout.
        XCTAssertEqual(buildCount, 2)
    }

    func test_measurement() {

        /// `.unionOfChildren`, positive frames.

        do {
            let writer = LayoutWriter { context, layout in
                layout.add(with: CGRect(x: 10, y: 20, width: 50, height: 50), child: TestElement())
                layout.add(with: CGRect(x: 20, y: 10, width: 20, height: 100), child: TestElement())

                layout.sizing = .unionOfChildren
            }

            XCTAssertEqual(writer.content.measure(in: .unconstrained), CGSize(width: 60, height: 110))
        }

        /// `.unionOfChildren`, positive & negative frames.

        do {
            let writer = LayoutWriter { context, layout in
                layout.add(with: CGRect(x: -10, y: -10, width: 50, height: 50), child: TestElement())
                layout.add(with: CGRect(x: -20, y: 50, width: 20, height: 60), child: TestElement())
                layout.add(with: CGRect(x: 50, y: 25, width: 50, height: 60), child: TestElement())

                layout.sizing = .unionOfChildren
            }

            XCTAssertEqual(writer.content.measure(in: .unconstrained), CGSize(width: 100, height: 110))
        }


        /// `.fixed`

        do {
            let writer = LayoutWriter { context, layout in
                layout.add(with: CGRect(x: 10, y: 20, width: 50, height: 50), child: TestElement())

                layout.sizing = .fixed(CGSize(width: 100, height: 100))
            }

            XCTAssertEqual(writer.content.measure(in: .unconstrained), CGSize(width: 100, height: 100))
        }

    }

    func test_layout() {
        let writer = LayoutWriter { context, layout in
            layout.add(with: CGRect(x: 10, y: 20, width: 50, height: 50), child: TestElement())
            layout.add(with: CGRect(x: 20, y: 10, width: 20, height: 100), child: TestElement())
        }

        let layoutResult = writer.content.testLayout(attributes: LayoutAttributes(size: CGSize(width: 100, height: 100)))
        let innerElement = layoutResult[0]

        let nodes = innerElement.node.children.map(\.node)

        XCTAssertEqual(nodes.count, 2)

        let first = nodes[0]
        let second = nodes[1]

        XCTAssertEqual(first.layoutAttributes.frame, CGRect(x: 10, y: 20, width: 50, height: 50))
        XCTAssertEqual(second.layoutAttributes.frame, CGRect(x: 20, y: 10, width: 20, height: 100))
    }
}


fileprivate struct TestElement: Element {

    var content: ElementContent {
        ElementContent { $0.maximum }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { _ in }
    }

}
