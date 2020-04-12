import XCTest
@testable import BlueprintUI

class OverlayTests: XCTestCase {

    func test_measuring() {
        let overlay = Overlay(elements: [
            TestElement(size: CGSize(width: 200, height: 200)),
            TestElement(size: CGSize(width: 100, height: 100)),
            TestElement(size: CGSize(width: 50, height: 50))
        ])
        XCTAssertEqual(overlay.content.size(in: .unconstrained), CGSize(width: 200, height: 200))
    }

    func test_layout() {
        let overlay = Overlay(elements: [
            TestElement(size: CGSize(width: 200, height: 200)),
            TestElement(size: CGSize(width: 100, height: 100)),
            TestElement(size: CGSize(width: 50, height: 50))
        ])
        XCTAssertEqual(
            overlay
                .layout(frame: CGRect(x: 0, y: 0, width: 456, height: 789))
                .children
                .map { $0.node.layoutAttributes.frame },
            Array(repeating: CGRect(x: 0, y: 0, width: 456, height: 789), count: 3)
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
