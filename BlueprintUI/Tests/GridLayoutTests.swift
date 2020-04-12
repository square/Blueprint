import XCTest
@testable import BlueprintUI

class GridLayoutTests: XCTestCase {

    func test_defaults() {
        let layout = GridLayout()
        XCTAssertEqual(layout.direction, GridLayout.Direction.vertical(columns: 4))
        XCTAssertEqual(layout.gutter, 10.0)
        XCTAssertEqual(layout.margin, 0.0)
    }

    func test_measuring() {

        let layout = GridLayout()

        let container = ElementContent(layout: layout) {
            for _ in 0..<20 {
                $0.add(element: TestElement())
            }
        }


        let constraint = SizeConstraint(width: 130)
        let measuredSize = container.size(in: constraint)

        /// Default grid has 4 columns (20/4 == 5)
        let rowCount = 5

        let cellSize = (130.0 - (layout.gutter * 3.0)) / 4.0

        XCTAssertEqual(measuredSize.width, 130)
        XCTAssertEqual(measuredSize.height, cellSize * CGFloat(rowCount) + layout.gutter * CGFloat(rowCount-1))

    }

    func test_layout() {

        let container = ElementContent(layout: GridLayout()) {
            $0.layout.direction = .vertical(columns: 2)
            for _ in 0..<4 {
                $0.add(element: TestElement())
            }
        }


        XCTAssertEqual(
            container
                .performLayout(attributes: LayoutAttributes(frame: CGRect(x: 0, y: 0, width: 110, height: 10000)))
                .map { $0.node.layoutAttributes.frame },
            [
                CGRect(x: 0, y: 0, width: 50, height: 50),
                CGRect(x: 60, y: 0, width: 50, height: 50),
                CGRect(x: 0, y: 60, width: 50, height: 50),
                CGRect(x: 60, y: 60, width: 50, height: 50),

            ]
        )

    }


}



fileprivate struct TestElement: Element {

    var size: CGSize

    init(size: CGSize = CGSize(width: 100, height: 100)) {
        self.size = size
    }

    var content: ElementContent {
        return ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}
