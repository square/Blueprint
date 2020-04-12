import XCTest
import BlueprintUI

class ConstrainedAspectRatioTests: XCTestCase {
    func test_expandWide() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fill,
            wrapping: TestElement())

        let size = element.content.size(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 200, height: 100))
    }

    func test_expandTall() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 1, height: 2),
            contentMode: .fill,
            wrapping: TestElement())

        let size = element.content.size(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 120, height: 240))
    }

    func test_expandSquare() {
        let element = ConstrainedAspectRatio(
            aspectRatio: .square,
            contentMode: .fill,
            wrapping: TestElement())

        let size = element.content.size(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 120, height: 120))
    }

    func test_shrinkWide() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fit,
            wrapping: TestElement())

        let size = element.content.size(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 120, height: 60))
    }

    func test_shrinkTall() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 1, height: 2),
            contentMode: .fit,
            wrapping: TestElement())

        let size = element.content.size(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 50, height: 100))
    }

    func test_shrinkSquare() {
        let element = ConstrainedAspectRatio(
            aspectRatio: .square,
            contentMode: .fit,
            wrapping: TestElement())

        let size = element.content.size(in: .unconstrained)
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
