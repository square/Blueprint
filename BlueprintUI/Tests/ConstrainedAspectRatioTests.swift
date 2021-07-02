import XCTest
import BlueprintUI

class ConstrainedAspectRatioTests: XCTestCase {
    func test_expandWide() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fitContent,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 200, height: 100))
    }

    func test_expandTall() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 1, height: 2),
            contentMode: .fitContent,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 120, height: 240))
    }

    func test_expandSquare() {
        let element = ConstrainedAspectRatio(
            aspectRatio: .square,
            contentMode: .fitContent,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 120, height: 120))
    }

    func test_shrinkWide() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .shrinkContent,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 120, height: 60))
    }

    func test_shrinkTall() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 1, height: 2),
            contentMode: .shrinkContent,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 50, height: 100))
    }

    func test_shrinkSquare() {
        let element = ConstrainedAspectRatio(
            aspectRatio: .square,
            contentMode: .shrinkContent,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 100, height: 100))
    }

    func test_expandWideFillParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fillParent,
            wrapping: TestElement())

        let size = element.content.measure(
            in: SizeConstraint(CGSize(width: 300, height: 400)))
        XCTAssertEqual(size, CGSize(width: 800, height: 400))
    }

    func test_expandWideFitParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fitParent,
            wrapping: TestElement())

        let size = element.content.measure(
            in: SizeConstraint(CGSize(width: 300, height: 400)))
        XCTAssertEqual(size, CGSize(width: 300, height: 150))
    }

    func test_expandTallFillParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 1, height: 2),
            contentMode: .fillParent,
            wrapping: TestElement())

        let size = element.content.measure(
            in: SizeConstraint(CGSize(width: 300, height: 400)))
        XCTAssertEqual(size, CGSize(width: 300, height: 600))
    }

    func test_expandTallFitParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 1, height: 2),
            contentMode: .fitParent,
            wrapping: TestElement())

        let size = element.content.measure(
            in: SizeConstraint(CGSize(width: 300, height: 400)))
        XCTAssertEqual(size, CGSize(width: 200, height: 400))
    }

    func test_expandSquareFillParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: .square,
            contentMode: .fillParent,
            wrapping: TestElement())

        let size = element.content.measure(
            in: SizeConstraint(CGSize(width: 300, height: 400)))
        XCTAssertEqual(size, CGSize(width: 400, height: 400))
    }

    func test_expandSquareFitParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: .square,
            contentMode: .fitParent,
            wrapping: TestElement())

        let size = element.content.measure(
            in: SizeConstraint(CGSize(width: 300, height: 400)))
        XCTAssertEqual(size, CGSize(width: 300, height: 300))
    }

    func test_unconstrainedFillParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fillParent,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 200, height: 100))
    }

    func test_unconstrainedFitParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fitParent,
            wrapping: TestElement())

        let size = element.content.measure(in: .unconstrained)
        XCTAssertEqual(size, CGSize(width: 200, height: 100))
    }

    func test_unconstrainedHeightFillLargerParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fillParent,
            wrapping: TestElement())

        let size = element.content.measure(in: SizeConstraint(width: 300))
        XCTAssertEqual(size, CGSize(width: 300, height: 150))
    }

    func test_unconstrainedHeightFillSmallerParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fillParent,
            wrapping: TestElement())

        let size = element.content.measure(in: SizeConstraint(width: 50))
        XCTAssertEqual(size, CGSize(width: 50, height: 25))
    }

    func test_unconstrainedHeightFitLargerParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fitParent,
            wrapping: TestElement())

        let size = element.content.measure(in: SizeConstraint(width: 300))
        XCTAssertEqual(size, CGSize(width: 300, height: 150))
    }

    func test_unconstrainedHeightFitSmallerParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fitParent,
            wrapping: TestElement())

        let size = element.content.measure(in: SizeConstraint(width: 50))
        XCTAssertEqual(size, CGSize(width: 50, height: 25))
    }

    func test_unconstrainedWidthFillLargerParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fillParent,
            wrapping: TestElement())

        let size = element.content.measure(in: SizeConstraint(height: 300))
        XCTAssertEqual(size, CGSize(width: 600, height: 300))
    }

    func test_unconstrainedWidthFillSmallerParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fillParent,
            wrapping: TestElement())

        let size = element.content.measure(in: SizeConstraint(height: 50))
        XCTAssertEqual(size, CGSize(width: 100, height: 50))
    }

    func test_unconstrainedWidthFitLargerParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fitParent,
            wrapping: TestElement())

        let size = element.content.measure(in: SizeConstraint(height: 300))
        XCTAssertEqual(size, CGSize(width: 600, height: 300))
    }

    func test_unconstrainedWidthFitSmallerParent() {
        let element = ConstrainedAspectRatio(
            aspectRatio: AspectRatio(width: 2, height: 1),
            contentMode: .fitParent,
            wrapping: TestElement())

        let size = element.content.measure(in: SizeConstraint(height: 50))
        XCTAssertEqual(size, CGSize(width: 100, height: 50))
    }
}

private struct TestElement: Element {
    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 120, height: 100))
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return nil
    }
}
