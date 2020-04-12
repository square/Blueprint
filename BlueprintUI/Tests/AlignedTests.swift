import XCTest
@testable import BlueprintUI


class AlignedTests: XCTestCase {

    let testSize = CGSize(width: 100, height: 200)
    let layoutFrame = CGRect(x: 0, y: 0, width: 5000, height: 6000)

    private func childLayoutResultNodesAligned(
        horizontally: Aligned.HorizontalAlignment = .center,
        vertically: Aligned.VerticalAlignment = .center
    ) -> [LayoutResultNode] {
        let content = TestElement(size: testSize)
        let element = Aligned(vertically: vertically, horizontally: horizontally, wrapping: content)
        let children = element
            .layout(frame: layoutFrame)
            .children
            .map { $0.node }
        return children
    }

    func test_measuring() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let content = TestElement(size: testSize)
        let element = Aligned(wrapping: content)
        XCTAssertEqual(element.content.size(in: constraint), content.content.size(in: constraint))
    }

    func test_horizontalLeading() {
        let children = childLayoutResultNodesAligned(horizontally: .leading)

        XCTAssertEqual(children.count, 1)
        let frame = children[0].layoutAttributes.frame
        XCTAssertEqual(frame.minX, 0)
        XCTAssertEqual(frame.maxX, 100)
        XCTAssertTrue(children[0].element is TestElement)
    }

    func test_horizontalCenter() {
        let children = childLayoutResultNodesAligned(horizontally: .center)

        XCTAssertEqual(children.count, 1)
        let frame = children[0].layoutAttributes.frame
        XCTAssertEqual(frame.minX, 2450)
        XCTAssertEqual(frame.maxX, 2550)
        XCTAssertTrue(children[0].element is TestElement)
    }

    func test_horizontalTrailing() {
        let children = childLayoutResultNodesAligned(horizontally: .trailing)

        XCTAssertEqual(children.count, 1)
        let frame = children[0].layoutAttributes.frame
        XCTAssertEqual(frame.minX, 4900)
        XCTAssertEqual(frame.maxX, 5000)
        XCTAssertTrue(children[0].element is TestElement)
    }
    
    func test_horizontalFill() {
        let children = childLayoutResultNodesAligned(horizontally: .fill)

        XCTAssertEqual(children.count, 1)
        let frame = children[0].layoutAttributes.frame
        XCTAssertEqual(frame.minX, 0.0)
        XCTAssertEqual(frame.maxX, 5000)
        XCTAssertTrue(children[0].element is TestElement)
    }

    func test_verticalTop() {
        let children = childLayoutResultNodesAligned(vertically: .top)

        XCTAssertEqual(children.count, 1)
        let frame = children[0].layoutAttributes.frame
        XCTAssertEqual(frame.minY, 0)
        XCTAssertEqual(frame.maxY, 200)
        XCTAssertTrue(children[0].element is TestElement)
    }

    func test_verticalCenter() {
        let children = childLayoutResultNodesAligned(vertically: .center)

        XCTAssertEqual(children.count, 1)
        let frame = children[0].layoutAttributes.frame
        XCTAssertEqual(frame.minY, 2900)
        XCTAssertEqual(frame.maxY, 3100)
        XCTAssertTrue(children[0].element is TestElement)
    }

    func test_verticalBottom() {
        let children = childLayoutResultNodesAligned(vertically: .bottom)

        XCTAssertEqual(children.count, 1)
        let frame = children[0].layoutAttributes.frame
        XCTAssertEqual(frame.minY, 5800)
        XCTAssertEqual(frame.maxY, 6000)
        XCTAssertTrue(children[0].element is TestElement)
    }
    
    func test_verticalFill() {
        let children = childLayoutResultNodesAligned(vertically: .fill)

        XCTAssertEqual(children.count, 1)
        let frame = children[0].layoutAttributes.frame
        XCTAssertEqual(frame.minY, 0)
        XCTAssertEqual(frame.maxY, 6000)
        XCTAssertTrue(children[0].element is TestElement)
    }
}

private struct TestElement: Element {
    let size: CGSize

    var content: ElementContent {
        return ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}
