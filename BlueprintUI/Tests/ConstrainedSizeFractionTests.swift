import XCTest
import BlueprintUI

class ConstrainedSizeFractionTests: XCTestCase {
    func test_unconstrainedHeight() {
        let element = ConstrainedSizeFraction(
            width: 0.5,
            wrapping: TestElement()
        )
        let size = element.content.measure(in: .init(width: .atMost(300), height: .atMost(400)))
        XCTAssertEqual(size, CGSize(width: 150, height: TestElement.size.height))
    }

    func test_unconstrainedWidth() {
        let element = ConstrainedSizeFraction(
            height: 0.5,
            wrapping: TestElement()
        )
        let size = element.content.measure(in: .init(width: .atMost(300), height: .atMost(400)))
        XCTAssertEqual(size, CGSize(width: TestElement.size.width, height: 200))
    }

    func test_fullyConstrained() {
        let element = ConstrainedSizeFraction(
            width: 0.5,
            height: 0.25,
            wrapping: TestElement()
        )
        let size = element.content.measure(in: .init(width: .atMost(300), height: .atMost(400)))
        XCTAssertEqual(size, CGSize(width: 150, height: 100))
    }
}

private struct TestElement: Element {
    static let size = CGSize(width: 100, height: 110)

    var content: ElementContent {
        ElementContent { _ in TestElement.size }
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        nil
    }
}
