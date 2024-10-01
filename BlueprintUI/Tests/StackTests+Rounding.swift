import XCTest
@testable import BlueprintUI

class StackRoundingTests: XCTestCase {

    /// Test that fixed-size items in a stack are each rounded up when measured and laid out.
    /// Rounding up should trigger a vertical orientation of the items.
    func test_rounding_fixedItems_measure_adaptive_layout() {
        let items = AdaptiveItems()

        var env = Environment()
        env.displayScale = 2.0

        let roundedItemWidth = items.itemWidth.rounded(.up, by: env.displayScale)
        let unroundedMaxWidth = items.itemWidth * CGFloat(items.count)
        let roundedMaxWidth = roundedItemWidth * CGFloat(items.count)

        XCTAssertLessThan(unroundedMaxWidth, roundedMaxWidth)

        XCTAssertEqual(
            items.content.measure(in: .unconstrained, environment: env).width,
            roundedMaxWidth
        )

        let root = items
            .layout(frame: CGRect(x: 0, y: 0, width: unroundedMaxWidth, height: 900), environment: env)
            .children
            .map { $0.node }

        XCTAssertEqual(root.count, 1)

        let children = root[0].children.map(\.node)
        XCTAssertEqual(children.count, items.count)

        for i in 0..<items.count {
            XCTAssertEqual(
                children[i].layoutAttributes.frame,
                CGRect(x: 0, y: 100 * CGFloat(i), width: items.itemWidth, height: 100)
            )
        }
    }

    /// Test that rounded up sizes of items are used for layout.
    func test_rounding_fixedItems_layout() {
        let items = AdaptiveItems()

        var env = Environment()
        env.displayScale = 2.0

        let roundedItemWidth = items.itemWidth.rounded(.up, by: env.displayScale)
        let unroundedMaxWidth = items.itemWidth * CGFloat(items.count)
        let roundedMaxWidth = roundedItemWidth * CGFloat(items.count)

        XCTAssertLessThan(unroundedMaxWidth, roundedMaxWidth)

        let root = items
            .layout(frame: CGRect(x: 0, y: 0, width: roundedMaxWidth, height: 900), environment: env)
            .children
            .map { $0.node }

        XCTAssertEqual(root.count, 1)
        XCTAssertEqual(root[0].layoutAttributes.frame.width, roundedMaxWidth)

        let children = root[0].children.map(\.node)
        XCTAssertEqual(children.count, items.count)

        // Since there is no spacing between the children, the sum of their widths should equal the container's overall width
        XCTAssertEqual(
            root[0].layoutAttributes.frame.width,
            children.map(\.layoutAttributes.frame.width).reduce(0.0, +)
        )

        for i in 0..<items.count {
            XCTAssertEqual(
                children[i].layoutAttributes.frame,
                CGRect(x: roundedItemWidth * CGFloat(i), y: 0, width: roundedItemWidth, height: 100)
            )
        }
    }
}

private struct AdaptiveItems: ProxyElement {

    var itemWidth: CGFloat = 80.25
    var count: Int = 3

    var elementRepresentation: any BlueprintUI.Element {
        GeometryReader { proxy in
            let row = row
            guard let maxWidth = proxy.constraint.width.constrainedValue else {
                return row
            }
            let constraint = SizeConstraint(width: .unconstrained, height: proxy.constraint.height)
            let width = proxy.measure(element: row, in: constraint).width
            if width <= maxWidth {
                return row
            }
            return column
        }
    }

    var row: Element {
        Row(underflow: .justifyToStart, minimumSpacing: 0) { elements }
    }

    var column: Element {
        Column(underflow: .justifyToStart, minimumSpacing: 0) { elements }
    }

    var elements: [StackLayout.Child] {
        Array(repeating: TestElement(width: itemWidth).stackLayoutChild(priority: .fixed), count: count)
    }

}

private struct TestElement: Element {

    var size: CGSize

    init(size: CGSize) {
        self.size = size
    }

    init(width: CGFloat = 100, height: CGFloat = 100) {
        self.init(size: CGSize(width: width, height: height))
    }

    var content: ElementContent {
        ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}
