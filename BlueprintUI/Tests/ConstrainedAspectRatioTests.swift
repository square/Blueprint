import XCTest
import BlueprintUI

class ConstrainedAspectRatioTests: XCTestCase {
    func test_expandWide() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(x: 2, y: 1),
            constraint: .expand,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 200, height: 100))
    }

    func test_expandTall() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(x: 1, y: 2),
            constraint: .expand,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 120, height: 240))
    }

    func test_expandSquare() {
        let element = ConstrainedAspectRatio(
            aspectRatio: .square,
            constraint: .expand,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 120, height: 120))
    }

    func test_shrinkWide() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(x: 2, y: 1),
            constraint: .shrink,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 120, height: 60))
    }

    func test_shrinkTall() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(x: 1, y: 2),
            constraint: .shrink,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 50, height: 100))
    }

    func test_shrinkSquare() {
        let element = ConstrainedAspectRatio(
            aspectRatio: .square,
            constraint: .shrink,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 100, height: 100))
    }
}

private struct TestElement: Element {
    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 120, height: 100))
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}
